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
- Formats active input while typing and formats calculated output as grouped numeric text.
- Keeps currency identity in the row label instead of adding a generic `$` prefix to every amount.
- Preserves the USDc amount on swap where possible.
- Shows an error with retry when rates fail to load.

## Assumptions

- The Figma values are treated as sample content, so the calculator starts with empty input fields and calculates after user input.
- The Figma reference includes EURc, but the provided API contract lists MXN, ARS, BRL, and COP. I used the API contract as the source of truth and excluded unsupported currencies from the picker.
- The currencies endpoint is not available yet, so the app falls back to MXN, ARS, BRL, and COP.
- Row order determines quote side: USDc on top uses bid, local currency on top uses ask.
- I used Decimal for all exchange calculations to avoid floating-point precision issues.
- The visible rate label follows the Figma format while the displayed value is quote-side aware.

## Architecture

The exchange feature is split into small layers that can grow without forcing SwiftUI views to own product logic:

- `Domain`: currency codes, exchange rates, quote side, and calculator rules.
- `Data`: API client, endpoint definitions, live service, and live repository.
- `Application`: repository contracts, exchange snapshots, and exchange log events.
- `Presentation`: SwiftUI view, ViewModel, state reducer, components, display metadata, copy, and styling.
- `Support`: input sanitizing and display formatting.

The `ExchangeCalculatorViewModel` depends on `RatesRepository`, not a concrete network service. The repository owns currency-discovery timeout fallback, keeping UI state transitions deterministic and rate-loading behavior testable without live network calls.

`ARQExchangeApp` builds live dependencies once and passes protocol-backed `ExchangeFeatureDependencies` into the feature entry view. Presentation code does not create API clients, repositories, or UIKit presenters.

## Production Readiness

- Network timeouts are configured at the `URLSession` level.
- Currency discovery has a bounded fallback delay so the app does not block indefinitely on a non-critical endpoint.
- Load outcomes, discovery fallbacks, and skipped malformed ticker rows are emitted through one `ExchangeLogger` boundary with an `OSLog` implementation.
- The UI can render unknown discovered currency codes safely, while currencies without usable rates are not selectable.

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
