# Simple Registry - Contract Guide

This document describes the `main-contract.clar` and `helper-contract.clar` contracts, their functions, parameters, return values, and interactions.

## main-contract.clar

Purpose: A secure key-value registry where each key is owned by the creator. Supports create, update, transfer, delete, and query operations. Emits events via `print` for off-chain indexing.

Data structures:
- `entries` map: key -> tuple (owner, value, created, updated)
- `owner-keys` map: (owner, index) -> key
- `owner-key-count` map: owner -> count

Initialization:
- `initialize()` sets the contract admin to the tx-sender if not already set.

Public functions:
- `create-entry(key, value)`: Creates a new key-value pair. Fails if key exists or contract is paused. Emits `create` event.
- `update-entry(key, new-value)`: Owner-only. Updates the value and `updated` timestamp. Emits `update` event.
- `transfer-entry(key, new-owner)`: Owner-only. Transfers ownership, updates owner lists. Emits `transfer` event.
- `delete-entry(key)`: Owner-only. Deletes the entry and removes it from owner's key list. Emits `delete` event.

Read-only functions:
- `get-entry(key)`: Returns entry tuple or error if not found.
- `get-key-count(owner)`: Returns number of keys owned.
- `get-key-by-owner(owner, index)`: Returns the key at index for owner.
- `get-admin()`, `is-paused()`

Security notes:
- Only owner can modify their entries.
- Admin can pause creation of new entries.
- Events are emitted with `print` for off-chain indexing.

## helper-contract.clar

Purpose: Example utility contract showing trait usage and proxy calls.

Functions:
- `query-entry(contract-principal, key)`: Calls `get-entry` on a registrable contract.
- `query-count(contract-principal, owner)`: Calls `get-key-count` on a registrable contract.
- `concat-keys(a,b)`: Utility to concatenate keys.


