# ARQ Exchange

Native SwiftUI exchange calculator built as a small production product surface, not a throwaway sample.

## Tech

- iOS 16.4+
- SwiftUI
- MVVM with one published view state
- async/await + URLSession
- Complete strict concurrency checking
- XCTest
- No third-party runtime dependencies
- Checked-in Xcode project, no project generator required

## Behavior

- Fetches local currencies from `/v1/tickers-currencies`.
- Falls back to `MXN`, `ARS`, `BRL`, `COP` if currency discovery fails, is empty, or times out.
- Fetches rates from `/v1/tickers?currencies=...`.
- Uses `Decimal` for bid/ask calculations.
- Uses row order to select quote side:
  - USDc on top uses `bid`.
  - Local currency on top uses `ask`.
- Keeps active input unformatted while typing and formats only calculated output as grouped numeric text.
- Keeps currency identity in the row label instead of adding a generic `$` prefix to every amount.
- Preserves the USDc amount on swap where possible.
- Shows stale cached rates if the latest rate request fails after a prior successful load.

## Architecture

The exchange feature is split into small layers that can grow without forcing SwiftUI views to own product logic:

- `Domain`: currency codes, exchange rates, quote side, calculator rules, and currency metadata.
- `Data`: API client, endpoint definitions, live service, disk snapshot cache, and live repository.
- `Application`: snapshot loading use case, repository contracts, and analytics events.
- `Presentation`: SwiftUI view, ViewModel, state reducer, components, and styling.
- `Support`: input sanitizing and display formatting.

The `ExchangeCalculatorViewModel` depends on `RatesLoadingUseCase`, not a concrete network service. The use case depends on `RatesRepository`, which owns freshness, timeout fallback, and stale-cache recovery. This keeps UI state transitions deterministic and makes rate-loading behavior testable without live network calls.

`ARQExchangeApp` builds live dependencies once and passes protocol-backed `ExchangeFeatureDependencies` into the feature entry view. Presentation code does not create API clients, repositories, disk caches, or UIKit presenters.

## Production Readiness

- Disk cache stores the last successful rates snapshot in `Caches/exchange-rates-snapshot.json`.
- Fresh cache is reused for short reloads; stale cache is used only as a failure fallback.
- Network timeouts are configured at the `URLSession` level.
- Currency discovery has a bounded fallback delay so the app does not block indefinitely on a non-critical endpoint.
- Load outcomes are emitted through an analytics boundary, with an `OSLog` implementation for local diagnostics.
- Discovery fallbacks, stale-cache fallback, cache failures, and skipped malformed ticker rows are emitted through a diagnostics boundary.
- The currency picker uses SwiftUI sheet presentation and handles unknown API currency codes without hard-crashing the UI.

## Run

Open `ARQExchange.xcodeproj` in Xcode and run the `ARQExchange` scheme.

To run tests from the command line:

```sh
xcodebuild test \
  -project ARQExchange.xcodeproj \
  -scheme ARQExchange \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest'
```

You can override the simulator destination:

```sh
xcodebuild test \
  -project ARQExchange.xcodeproj \
  -scheme ARQExchange \
  -destination 'platform=iOS Simulator,name=<device>,OS=latest'
```

## Notes

Flags are PNG assets in the asset catalog and are clipped circularly in SwiftUI. System font is used for portability.

Current deliberate tradeoffs: one app target and one test target, no modular Swift packages yet, no persistent transaction history, and no live network tests.
