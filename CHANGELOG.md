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
