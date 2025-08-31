;; Helper contract for Simple Registry - helper-contract.clar
;; Provides utility functions and cross-contract examples for the Registry.
;; Tailored to interact with `main-contract.clar` implemented registry.
;; Author: Generated for user
;; License: MIT

;; Trait describing the registry interface expected by helper functions.
(define-trait registrable-trait
  (
    ;; get-entry returns a tuple with fields: owner, value, created, updated, version, frozen
    (get-entry (string-ascii 64) (response (tuple (owner principal) (value (string-ascii 256)) (created uint) (updated uint) (version uint) (frozen bool)) uint))
    (get-key-count (principal) (response uint uint))
    (get-key-by-owner (principal uint) (response (string-ascii 64) uint))
  ))

;; Proxy read-only call to another contract implementing registrable-trait
(define-read-only (query-entry (contract-principal principal) (key (string-ascii 64)))
  (contract-call? contract-principal get-entry key))

(define-read-only (query-count (contract-principal principal) (owner principal))
  (contract-call? contract-principal get-key-count owner))

(define-read-only (query-key-by-owner (contract-principal principal) (owner principal) (index uint))
  (contract-call? contract-principal get-key-by-owner owner index))

;; Note: Cross-contract helpers are meant to simplify off-chain indexing & integration.
;; For pagination, callers should iterate over indices using `get-key-by-owner` and `get-key-count`.
