;; Simple Registry - main-contract.clar
;; A secure key-value registry where each key is owned by its creator.
;; Tailored for: "Youth Mental Health Crisis Center" registry (anonymized metadata only).
;; Author: Generated for user
;; License: MIT

(define-map entries
  ;; Primary map: key -> entry tuple
  ;; key: up to 64 ascii chars
  ((key (string-ascii 64)))
  ((owner principal)
   (value (string-ascii 256))
   (created uint)
   (updated uint)
   (version uint)
   (frozen bool)))

(define-map owner-keys
  ;; Secondary map: (owner, index) -> key
  ((owner principal) (index uint))
  ((key (string-ascii 64))))

(define-map owner-key-count
  ;; Track how many keys each owner has: owner -> count
  ((owner principal))
  ((count uint)))

;; Moderators map (admin can add/remove moderators). Moderators can freeze/unfreeze keys.
(define-map moderators
  ((who principal))
  ((is-mod bool)))

;; Admin and pause state
(define-data-var admin principal tx-sender)
(define-data-var paused bool false)

;; Error codes
(define-constant err-not-owner u100)
(define-constant err-key-exists u101)
(define-constant err-key-not-found u102)
(define-constant err-paused u103)
(define-constant err-not-admin u104)
(define-constant err-already-initialized u105)
(define-constant err-invalid-addr u106)
(define-constant err-invalid-key u107)
(define-constant err-invalid-value u108)
(define-constant err-frozen u109)
(define-constant err-not-moderator u110)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Configuration limits and recommendations
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Concrete limits used by validation logic
(define-constant MAX_KEY_LEN u64)
(define-constant MAX_VALUE_LEN u256)

;; Security note (informational only): This contract MUST NOT store PII or chat content.
;; Off-chain systems MUST store references/hashes to any sensitive content instead of raw PII.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Internal helpers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-private (is-admin (who principal))
  (is-eq who (var-get admin)))

(define-private (is-moderator (who principal))
  (match (map-get? moderators ((who who)))
    m (ok (get is-mod m))
    (ok false)))

;; Validate key length and non-empty
(define-private (validate-key (k (string-ascii 64)))
  (let ((l (len k)))
    (if (and (> l u0) (<= l MAX_KEY_LEN))
        (ok true)
        (err err-invalid-key))))

;; Validate value length guardrails
(define-private (validate-value (v (string-ascii 256)))
  (let ((l (len v)))
    (if (<= l MAX_VALUE_LEN)
        (ok true)
        (err err-invalid-value))))

;; increment owner's key count and store key at next index
(define-private (owner-add-key (owner principal) (key (string-ascii 64)))
  (let ((cnt-entry (map-get? owner-key-count ((owner owner)))))
    (match cnt-entry
      entry
      (let ((count (get count entry)))
        (map-set owner-keys ((owner owner) (index count)) ((key key)))
        (map-set owner-key-count ((owner owner)) ((count (+ count u1))))
        (ok count))
      (begin
        ;; first key for owner
        (map-set owner-keys ((owner owner) (index u0)) ((key key)))
        (map-set owner-key-count ((owner owner)) ((count u1)))
        (ok u0)))))

(define-private (owner-remove-key (owner principal) (key (string-ascii 64)))
  ;; When deleting a key, we swap-last into the removed slot to keep indices contiguous
  (let ((cnt-entry (map-get? owner-key-count ((owner owner)))))
    (match cnt-entry
      entry
      (let ((count (get count entry)))
        (if (<= count u0)
            (err err-key-not-found)
            (let loop ((i u0))
              (if (>= i count)
                  (err err-key-not-found)
                  (let ((k (map-get? owner-keys ((owner owner) (index i)))))
                    (match k
                      kentry
                      (if (is-eq (get key kentry) key)
                          ;; found at index i, replace with last and decrement count
                          (let ((last-idx (- count u1)))
                            (if (is-eq last-idx i)
                                (begin
                                  (map-delete owner-keys ((owner owner) (index i)))
                                  (map-set owner-key-count ((owner owner)) ((count (- count u1))))
                                  (ok true))
                                (let ((last-k (map-get? owner-keys ((owner owner) (index last-idx)))))
                                  (match last-k
                                    lastk
                                    (begin
                                      (map-set owner-keys ((owner owner) (index i)) ((key (get key lastk))))
                                      (map-delete owner-keys ((owner owner) (index last-idx)))
                                      (map-set owner-key-count ((owner owner)) ((count (- count u1))))
                                      (ok true))
                                    (err err-key-not-found)))))
                          (loop (+ i u1))))
                      (loop (+ i u1)))))))
      (err err-key-not-found))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Public & Read-only functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; initialize: optional explicit initializer to set admin if needed. Safe to call only by tx-sender who deployed contract.
(define-public (initialize)
  (begin
    (if (is-eq (var-get admin) tx-sender)
        (err err-already-initialized)
        (begin
          (var-set admin tx-sender)
          (ok true)))))

;; Pause/Unpause the creation of new entries - admin-only
(define-public (set-paused (p bool))
  (begin
    (if (is-admin tx-sender)
        (begin
          (var-set paused p)
          (ok true))
        (err err-not-admin))))

;; Admin: add moderator
(define-public (add-moderator (who principal))
  (begin
    (if (is-admin tx-sender)
        (begin
          (map-set moderators ((who who)) ((is-mod true)))
          (ok true))
        (err err-not-admin))))

;; Admin: remove moderator
(define-public (remove-moderator (who principal))
  (begin
    (if (is-admin tx-sender)
        (begin
          (map-set moderators ((who who)) ((is-mod false)))
          (ok true))
        (err err-not-admin))))

;; Moderator/Admin: freeze/unfreeze a key. When frozen, updates/transfers/deletes are blocked.
(define-public (set-key-frozen (key (string-ascii 64)) (f bool))
  (let ((entry (map-get? entries ((key key)))))
    (match entry
      e
      (let ((is-admin-or-mod (or (is-admin tx-sender)
                                 (match (map-get? moderators ((who tx-sender))) m (is-eq (get is-mod m) true) false))))
        (if is-admin-or-mod
            (begin
              (map-set entries ((key key))
                       ((owner (get owner e))
                        (value (get value e))
                        (created (get created e))
                        (updated (get-block-height))
                        (version (get version e))
                        (frozen f)))
              (print { "event": (tuple (action "freeze") (key key) (by tx-sender) (f f) (block (get-block-height))) })
              (ok true))
            (err err-not-moderator))))
      (err err-key-not-found)))))

;; Create a new key-value pair. Fails if key exists or contract paused.
(define-public (create-entry (key (string-ascii 64)) (value (string-ascii 256)))
  (begin
    (if (var-get paused)
        (err err-paused)
        (let ((validk (validate-key key)))
          (match validk
            (err e) (err e)
            (ok _)
            (let ((validv (validate-value value)))
              (match validv
                (err e) (err e)
                (ok _)
                (let ((existing (map-get? entries ((key key)))))
                  (match existing
                    _ (err err-key-exists)
                    (begin
                      (map-set entries ((key key)) ((owner tx-sender) (value value) (created (get-block-height)) (updated (get-block-height)) (version u1) (frozen false)))
                      (let ((res (owner-add-key tx-sender key)))
                        (print { "event": (tuple (action "create") (key key) (owner tx-sender) (value value) (version u1) (block (get-block-height))) })
                        (ok true)))))))))))

;; Update value of an existing key. Only the owner can update; cannot update when frozen.
(define-public (update-entry (key (string-ascii 64)) (new-value (string-ascii 256)))
  (let ((entry (map-get? entries ((key key)))))
    (match entry
      e
      (if (is-eq (get owner e) tx-sender)
          (begin
            (if (get frozen e)
                (err err-frozen)
                (let ((validv (validate-value new-value)))
                  (match validv
                    (err er) (err er)
                    (ok _)
                    (let ((new-version (+ (get version e) u1)))
                      (map-set entries ((key key)) ((owner tx-sender) (value new-value) (created (get created e)) (updated (get-block-height)) (version new-version) (frozen false)))
                      (print { "event": (tuple (action "update") (key key) (owner tx-sender) (value new-value) (version new-version) (block (get-block-height))) })
                      (ok true))))))
          (err err-not-owner))
      (err err-key-not-found))))

;; Transfer ownership to another principal. Only current owner can transfer. Transfer blocked if frozen.
(define-public (transfer-entry (key (string-ascii 64)) (new-owner principal))
  (let ((entry (map-get? entries ((key key)))))
    (match entry
      e
      (if (is-eq (get owner e) tx-sender)
          (begin
            (if (get frozen e)
                (err err-frozen)
                (begin
                  ;; add key to new owner's list
                  (owner-add-key new-owner key)
                  ;; remove key from previous owner's list
                  (owner-remove-key tx-sender key)
                  ;; update entry
                  (map-set entries ((key key)) ((owner new-owner) (value (get value e)) (created (get created e)) (updated (get-block-height)) (version (get version e)) (frozen (get frozen e))))
                  (print { "event": (tuple (action "transfer") (key key) (old-owner tx-sender) (new-owner new-owner) (block (get-block-height))) })
                  (ok true))))
          (err err-not-owner))
      (err err-key-not-found))))

;; Delete an entry. Only owner can delete. Delete blocked if frozen.
(define-public (delete-entry (key (string-ascii 64)))
  (let ((entry (map-get? entries ((key key)))))
    (match entry
      e
      (if (is-eq (get owner e) tx-sender)
          (begin
            (if (get frozen e)
                (err err-frozen)
                (begin
                  (map-delete entries ((key key)))
                  (owner-remove-key tx-sender key)
                  (print { "event": (tuple (action "delete") (key key) (owner tx-sender) (block (get-block-height))) })
                  (ok true))))
          (err err-not-owner))
      (err err-key-not-found))))

;; Read-only: get entry tuple for a key
(define-read-only (get-entry (key (string-ascii 64)))
  (match (map-get? entries ((key key)))
    e (ok e)
    (err err-key-not-found)))

;; Read-only: get number of keys owned by an address
(define-read-only (get-key-count (owner principal))
  (match (map-get? owner-key-count ((owner owner)))
    e (ok (get count e))
    (ok u0)))

;; Read-only: get key by owner and index
(define-read-only (get-key-by-owner (owner principal) (index uint))
  (match (map-get? owner-keys ((owner owner) (index index)))
    e (ok (get key e))
    (err err-key-not-found)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Public utility: contract admin info
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define-read-only (get-admin)
  (ok (var-get admin)))

(define-read-only (is-paused)
  (ok (var-get paused)))

(define-read-only (is-moderator-read (who principal))
  (match (map-get? moderators ((who who)))
    m (ok (get is-mod m))
    (ok false)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; End of contract
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
