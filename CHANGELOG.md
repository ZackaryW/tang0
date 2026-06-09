## 0.10.0

* **Breaking**: Ground-up rebuild into layered cross-tab primitives — `Tang0Channel`, `T0SyncVar` (old), `SyncEnum`, and the templates are removed
* Added `T0Platform` — injectable browser surface (clock, storage, channel, Web Locks) so the protocol is testable without a browser
* Added `T0Presence` — live tab awareness with per-tab metadata, heartbeat, and stale pruning
* Added `T0Leader` — true single-leader election over Web Locks; fails loud when unavailable instead of degrading
* Added `T0SoftLock` — explicitly advisory localStorage lease for best-effort coordination (never a true leader)
* Added `T0Rpc` — request/response over a bus for cross-tab queries
* Added `T0Hydrator` — new-tab state catch-up from a peer snapshot or persisted storage
* Added `T0LwwRegister` — last-write-wins conflict resolution (version, timestamp, origin tiebreak)
* Rebuilt `T0SyncVar<T>` on LWW with persistence and new-tab catch-up
* Rebuilt `T0TabDeduper` on presence; added `T0SharedDraft` for shared editing sessions
* Kept `T0Bus`, `T0Store`, `T0DispatchPool`, and the `T0Codec` registry as the core layer
* Fixed Zone-capture handling in channel listeners; bundled the example with web scaffolding
* Tests run under `flutter test --platform chrome` against an in-memory multi-tab fake

## 0.9.0

* **Breaking**: Complete API redesign — crypto/SyncedWidget replaced with lightweight cross-tab sync toolkit
* Added `Tang0Channel` — BroadcastChannel wrapper with multi-listener support, payload hooks, JSON mutators
* Added `T0SyncVar<T>` — ValueNotifier-based state sync with codec registry and SyncEnum modes
* Added `T0ReactiveStream<T>` — ChangeNotifier + broadcast stream for cross-tab events
* Added `T0DispatchPool` — global rate limiter/queue with optional coalescing
* Added `SyncVarCodecs` — built-in codecs for primitives, DateTime, Uri, JSON maps/lists
* Added example app with timer and tab-dedup demos

## 0.1.0 (legacy)

* Supporting async message handlers with error strategies

## 0.0.3 (legacy)

* Minor wording update

## 0.0.2 (legacy)

* Users can now set `optionalSecurityEncrypt` and `optionalSecurityDecrypt` for enhanced data security
* One-way messaging with `OneWaySender` and `OneWayReceiver`
* Flutter Secure Storage integration with automatic fallback
* Updated documentation with custom encryption examples

## 0.0.1 (legacy)

* Initial release of Tang0 — Flutter web cross-tab communication package
* BroadcastChannel-based messaging with HMAC-SHA256 security
* Synced widgets with `SyncedWidget` and `SyncedVar<T>` for automatic state synchronization
* Helper methods and UI components for easy widget creation
* Examples for both one-way communication and synced widgets
