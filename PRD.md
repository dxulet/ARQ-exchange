# PRD / Implementation Brief: ARQ Exchange Calculator iOS App

## 1. Context

Build a native iOS currency exchange calculator for ARQ.

The app converts between USDc and selected local currencies. It should support editing either amount field, selecting a local currency from a bottom sheet, swapping currency positions, fetching exchange rates from the provided API, and handling API degradation gracefully.

This document is a private implementation brief. It should guide product behavior, architecture, edge cases, testing, and README decisions.

The implementation should demonstrate senior-level product and engineering judgment without overengineering.

---

## 2. Core Goal

Build a polished, reliable, native iOS exchange calculator that feels like a small fintech product surface.

The app should show:

* Clear product decisions under ambiguity
* Correct financial calculation handling
* Good UX for loading, error, empty, and retry states
* Clean architecture with testable seams
* Simple but maintainable code
* No unnecessary complexity

The final app should communicate:

```text
I can build a small product surface with production-quality seams.
I can make reasonable product decisions under ambiguity.
I understand fintech correctness and user trust.
I can keep architecture clean without overengineering.
I can use AI as support without outsourcing judgment.
```

---

## 3. Platform and Tech Choices

Use:

* iOS minimum target: 16.4
* Swift
* SwiftUI
* MVVM
* `ObservableObject` + `@Published`
* `@StateObject` in the view
* async/await
* URLSession
* XCTest
* No third-party dependencies unless truly necessary

Avoid:

* iOS 17-only Observation APIs such as `@Observable`
* TCA
* RIBs
* CoreData
* Database persistence
* WebSockets
* Auth/session systems
* Complex modular Swift Package setup
* Heavy design system abstractions

Reasoning:

The first release is a single-screen app. Architecture should be clean and extensible, but not performative. Use small boundaries that can scale without making the project feel like a framework exercise.

---

## 4. Product Requirements

### 4.1 Main Screen

The app contains one main screen:

* Title: `Exchange calculator`
* Rate label under the title, for example: `1 USDc = 17.4382 MXN`
* Two currency amount rows:

  * One row for USDc
  * One row for the selected local currency
* Swap button between the two rows
* Bottom sheet for selecting local currency
* Loading/error/retry states where needed

The design should visually follow the provided Figma reference, but exact custom fonts are optional. System font is acceptable.

---

## 5. Initial State

Do not prefill a fake amount such as `$9,999`.

Treat Figma values as example content, not initial app state.

Initial state:

* USDc on top
* MXN on bottom
* Both amount fields empty
* Placeholders visible
* Rate label visible once rates load
* Conversion begins only after user input

Suggested placeholders:

```text
0
0.00
```

Rationale:

A real calculator should not imply that the user already entered a transaction amount. Starting empty is more realistic and avoids fake financial values.

---

## 6. Supported Currencies

USDc is always one side of the pair.

The local selectable currencies are:

```text
MXN
ARS
BRL
COP
```

The planned currencies API is unavailable, so the app should try to fetch it but fall back to the expected list above.

USDc should not appear in the bottom sheet because it is always part of the calculator pair.

---

## 7. User Stories and Acceptance Criteria

### 7.1 Convert from USDc to selected currency

As a user, I want to enter a USDc amount and see the equivalent amount in the selected local currency.

Acceptance criteria:

* User can type into the USDc field.
* The selected currency field updates automatically.
* Conversion uses the correct quote side based on row order.
* Empty input clears the calculated field.
* Invalid or partial input does not crash the app.

### 7.2 Convert from selected currency to USDc

As a user, I want to enter an amount in the selected currency and see the equivalent USDc amount.

Acceptance criteria:

* User can type into the selected currency field.
* The USDc field updates automatically.
* The active field remains stable while typing.
* The inactive field is formatted as a calculated result.
* Conversion uses the correct quote side based on row order.

### 7.3 Select a currency

As a user, I want to choose another local currency from a bottom sheet.

Acceptance criteria:

* Tapping the non-USDc currency row opens a bottom sheet.
* Bottom sheet displays available currencies.
* Current selected currency is visually marked.
* Selecting a currency dismisses the sheet.
* The calculator recalculates using the new selected currency.
* If a currency has no available rate, it should not produce misleading conversion output.

### 7.4 Swap currencies

As a user, I want to swap the top and bottom currency rows.

Acceptance criteria:

* Tapping the swap button switches the positions of USDc and selected currency.
* The app recalculates using the correct directional quote side.
* The displayed rate label updates after swap.
* The UI remains consistent after multiple swaps.
* Where possible, preserve the USDc amount and recalculate the selected currency amount.

### 7.5 Recover from API issues

As a user, I want the app to handle API failures gracefully.

Acceptance criteria:

* If the currencies endpoint is unavailable, the app falls back to the provided expected currency list.
* If exchange rates fail to load, the app shows a user-friendly error state.
* User can retry loading rates.
* The app should not crash or show fake financial values.

---

## 8. API Requirements

### 8.1 Exchange Rate API

Use:

```text
GET https://api.dolarapp.dev/v1/tickers?currencies=MXN,ARS
```

It can also be called with one or multiple currencies:

```text
GET https://api.dolarapp.dev/v1/tickers?currencies=MXN
GET https://api.dolarapp.dev/v1/tickers?currencies=MXN,ARS,BRL,COP
```

Example response:

```json
[
  {
    "ask": "17.4418000000",
    "bid": "17.4382000000",
    "book": "usdc_mxn",
    "date": "2026-06-10T12:35:55.356249099"
  },
  {
    "ask": "1510.0700000000",
    "bid": "1505.2275000000",
    "book": "usdc_ars",
    "date": "2026-06-10T12:35:55.360025169"
  }
]
```

Implementation details:

* Parse `ask` as `Decimal`.
* Parse `bid` as `Decimal`.
* Parse `book`, e.g. `usdc_mxn`, to determine the quote currency.
* Store `date` as `String` unless freshness display is implemented.
* Do not use `Double` for financial calculations.

### 8.2 Available Currencies API

Planned endpoint:

```text
GET https://api.dolarapp.dev/v1/tickers-currencies
```

Expected future response:

```json
[
  "MXN",
  "ARS",
  "BRL",
  "COP"
]
```

This endpoint is not available yet.

Behavior:

* Try to fetch the endpoint.
* If it fails, use fallback currencies: `MXN, ARS, BRL, COP`.
* Do not treat unavailable currencies endpoint as fatal.
* Continue to fetch rates using the fallback list.

### 8.3 API Failure Rules

Currencies endpoint failure:

* Use fallback list.
* Do not show a fatal error.
* Continue loading exchange rates.

Rates endpoint failure:

* Show user-facing error state.
* Provide retry.
* Do not show fake rates.
* Do not crash.

Individual missing ticker:

* Do not fake conversion.
* Either disable that currency in picker or show it as unavailable.
* If selected currency becomes unavailable, show `Rate unavailable`.

---

## 9. Exchange Rate Logic

The API returns `bid` and `ask` values for each USDc/local currency pair.

Example:

```json
{
  "ask": "17.4418000000",
  "bid": "17.4382000000",
  "book": "usdc_mxn",
  "date": "2026-06-10T12:35:55.356249099"
}
```

The app should not average `bid` and `ask`.

### 9.1 Quote Side Interpretation

The quote side is determined by the current row order, not only by the source/target currencies.

Rules:

* If USDc is on top and local currency is on bottom, use `bid`.
* If local currency is on top and USDc is on bottom, use `ask`.

Rationale:

The swap action is not only visual. It changes the conversion mode:

* USDc on top represents converting/selling USDc into the selected local currency.
* Local currency on top represents converting local currency into/buying USDc.

This makes the bid/ask spread visible and keeps swap behavior meaningful.

### 9.2 Calculation Matrix

| Row order              | Quote side | User edits top field | User edits bottom field |
| ---------------------- | ---------- | -------------------- | ----------------------- |
| USDc top, local bottom | bid        | local = USDc × bid   | USDc = local ÷ bid      |
| local top, USDc bottom | ask        | USDc = local ÷ ask   | local = USDc × ask      |

### 9.3 Implementation Guidance

The conversion logic should receive an explicit quote side or mode instead of inferring everything only from source and target currencies.

Recommended model:

```swift
enum QuoteSide {
    case bid
    case ask
}
```

The ViewModel determines the quote side from row order:

```swift
var quoteSide: QuoteSide {
    state.topCurrency == .usdc ? .bid : .ask
}
```

The pure calculator receives the quote side explicitly:

```swift
struct ExchangeCalculator {
    func convert(
        amount: Decimal,
        from source: CurrencyCode,
        to target: CurrencyCode,
        using rate: ExchangeRate,
        quoteSide: QuoteSide
    ) -> Decimal?
}
```

The calculator should then apply:

```text
USDc -> local with bid: amount × bid
local -> USDc with bid: amount ÷ bid

local -> USDc with ask: amount ÷ ask
USDc -> local with ask: amount × ask
```

This keeps the business rule explicit, testable, and independent of SwiftUI.

---

## 10. Swap Behavior

The swap button switches the positions of USDc and the selected local currency.

Behavior:

* If USDc is top, selected currency moves top and USDc moves bottom.
* If selected currency is top, USDc moves top and selected currency moves bottom.
* Swap changes the quote side:

  * USDc top → use bid
  * Local top → use ask
* Recalculate using the new quote side.
* Preserve the USDc amount where possible and recalculate the selected currency amount.

Rationale:

USDc is the base currency in the API. The reference design appears to preserve the USDc amount after swapping and updates the local currency amount based on the opposite quote side.

Implementation note:

* If the user has only entered a local currency amount and no USDc amount exists, derive USDc first, then swap and recalculate local amount using the new quote side.
* If both fields are empty, simply swap rows without calculation.

---

## 11. Input Behavior

Both fields are editable.

Rules:

* Editing the top field recalculates the bottom field.
* Editing the bottom field recalculates the top field.
* The active field should not be aggressively formatted while typing.
* The inactive field can be formatted as a calculated value.
* Empty input clears the opposite field.
* Partial input like `.` should not crash.
* Input should allow one decimal separator.
* Ignore non-numeric characters such as `$` and `,`.
* Very large values should not break layout.

Use an `InputSanitizer` to normalize raw user input.

Suggested behavior:

```text
Raw input: "$1,234.56"
Sanitized input: "1234.56"
```

Do not block normal typing behavior.

---

## 12. Formatting

Use separate formatters for input/output and rate display.

### 12.1 Amount Formatting

Calculated values:

* Use grouping separators.
* Use up to 2 decimal places.
* Use `$` prefix to match the reference design.
* Avoid forcing formatting into the active field while typing.

Examples:

```text
$0
$9,999
$184,065.59
$38,320,367.58
```

### 12.2 Rate Formatting

Rate label should be readable and precise enough.

Suggested:

* Up to 4 decimal places
* Grouping separators for large values

Examples:

```text
1 USDc = 17.4382 MXN
1 USDc = 1,505.2275 ARS
1 USDc = 3,832.42 COP
```

If rate unavailable:

```text
Rate unavailable
```

---

## 13. UX States

### 13.1 Loading

On launch:

* Show loading state while fetching currencies/rates.
* Avoid misleading conversions before rates are available.

### 13.2 Loaded

When rates load:

* Show calculator.
* Show rate label.
* Allow editing both fields.
* Allow currency selection.
* Allow swap.

### 13.3 Error

If rates fail:

* Show a clear error state.
* Provide retry action.
* Do not show fake rates.

Suggested message:

```text
We couldn’t load exchange rates. Please try again.
```

### 13.4 Empty Input

If user clears active field:

* Active field becomes empty.
* Opposite field clears.
* Rate label remains visible if rate exists.

### 13.5 Missing Rate

If selected currency has no rate:

* Show `Rate unavailable`.
* Clear or disable calculated output.
* Avoid fake conversion.

---

## 14. Bottom Sheet

Tapping the non-USDc currency opens a bottom sheet.

Bottom sheet contents:

* Drag indicator if native sheet provides it
* Title: `Choose currency`
* Close button
* List of currencies
* Selected state indicator
* Disabled/unavailable state for missing-rate currencies if needed

Currency row:

* Flag or simple icon
* Currency code
* Selection indicator

Emoji flags are acceptable for this timebox unless Figma assets are easily exportable.

Suggested mappings:

```text
USDc 🇺🇸
MXN 🇲🇽
ARS 🇦🇷
BRL 🇧🇷
COP 🇨🇴
```

---

## 15. Accessibility

Add basic accessibility labels:

```text
USDc amount
MXN amount
Select MXN currency
Swap currencies
Choose currency
Retry loading exchange rates
```

Do not overinvest, but make sure key controls are labeled.

---

## 16. Architecture

Use lightweight MVVM with explicit boundaries.

Preferred folder structure:

```text
ARQExchange/
├── App/
│   └── ARQExchangeApp.swift
│
├── Features/
│   └── Exchange/
│       ├── Domain/
│       │   ├── CurrencyCode.swift
│       │   ├── CurrencyMetadata.swift
│       │   ├── ExchangeRate.swift
│       │   ├── QuoteSide.swift
│       │   ├── ExchangeCalculator.swift
│       │   └── InputField.swift
│       ├── Data/
│       │   ├── APIClient.swift
│       │   ├── APIEndpoint.swift
│       │   ├── APIError.swift
│       │   ├── RatesService.swift
│       │   ├── LiveRatesRepository.swift
│       │   ├── LiveRatesService.swift
│       │   ├── RatesSnapshotCache.swift
│       │   └── TickerResponse.swift
│       ├── Application/
│       │   ├── ExchangeLogger.swift
│       │   ├── ExchangeRatesSnapshot.swift
│       │   └── RatesRepository.swift
│       ├── Presentation/
│       │   ├── Calculator/
│       │   │   ├── ExchangeCalculatorView.swift
│       │   │   ├── ExchangeCalculatorViewModel.swift
│       │   │   ├── ExchangeCalculatorState.swift
│       │   │   └── ExchangeCalculatorStateReducer.swift
│       │   ├── Components/
│       │   │   ├── CurrencyAmountField.swift
│       │   │   ├── CurrencyFlagView.swift
│       │   │   ├── CurrencyPickerSheet.swift
│       │   │   └── SwapButton.swift
│       │   └── Styling/
│       │       ├── ExchangeCalculatorCopy.swift
│       │       └── ExchangeDesign.swift
│       └── Support/
│           ├── AmountFormatter.swift
│           ├── RateFormatter.swift
│           └── InputSanitizer.swift
│
└── Tests/
    ├── ExchangeCalculatorTests.swift
    ├── ExchangeCalculatorViewModelTests.swift
    ├── FormatterTests.swift
    └── InputSanitizerTests.swift
```

Keep it as a single app target and one test target for now. Move feature layers into Swift packages only when there is a real reuse boundary, parallel team ownership, or measurable build-time pressure.

Do not create multiple Swift packages just to look scalable.

---

## 17. ViewModel State Management

Avoid many scattered `@Published` properties.

Use one published state object:

```swift
@MainActor
final class ExchangeCalculatorViewModel: ObservableObject {
    @Published private(set) var state: ExchangeCalculatorViewState

    func load() async
    func retry() async
    func updateAmount(_ text: String, in field: InputField)
    func selectCurrency(_ currency: CurrencyCode)
    func swapCurrencies()
}
```

Keep sheet presentation state in the View if possible:

```swift
@State private var isCurrencyPickerPresented = false
```

Rationale:

The calculator has related state that can easily desync:

* top currency
* bottom currency
* selected currency
* active input
* top amount
* bottom amount
* current rate
* available currencies
* loading state
* error state

A single state object makes rendering predictable and invalid combinations easier to avoid.

---

## 18. Suggested View State

```swift
struct ExchangeCalculatorViewState: Equatable {
    var loadState: LoadState = .idle

    var topCurrency: CurrencyCode = .usdc
    var bottomCurrency: CurrencyCode = .mxn

    var topAmountText: String = ""
    var bottomAmountText: String = ""

    var activeInput: InputField?
    var availableCurrencies: [CurrencyCode] = [.mxn, .ars, .brl, .cop]
    var rates: [CurrencyCode: ExchangeRate] = [:]

    var selectedCurrency: CurrencyCode {
        topCurrency == .usdc ? bottomCurrency : topCurrency
    }

    var isUSDcOnTop: Bool {
        topCurrency == .usdc
    }

    var quoteSide: QuoteSide {
        isUSDcOnTop ? .bid : .ask
    }

    var currentRate: ExchangeRate? {
        rates[selectedCurrency]
    }
}
```

Suggested load state:

```swift
enum LoadState: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
}
```

Suggested input field:

```swift
enum InputField: Equatable {
    case top
    case bottom
}
```

Suggested quote side:

```swift
enum QuoteSide: Equatable {
    case bid
    case ask
}
```

---

## 19. Domain Models

### 19.1 CurrencyCode

```swift
struct CurrencyCode: RawRepresentable, Identifiable, Equatable, Hashable, Codable, Sendable {
    let rawValue: String

    var id: String { rawValue }

    static let usdc = CurrencyCode(rawValue: "USDc")
    static let mxn = CurrencyCode(rawValue: "MXN")
    static let ars = CurrencyCode(rawValue: "ARS")
    static let brl = CurrencyCode(rawValue: "BRL")
    static let cop = CurrencyCode(rawValue: "COP")
}
```

Note:

API `book` values use lowercase, e.g. `usdc_mxn`. Normalize them safely to `CurrencyCode` while still allowing unknown remote currency codes.

### 19.2 ExchangeRate

```swift
struct ExchangeRate: Equatable {
    let base: CurrencyCode
    let quote: CurrencyCode
    let bid: Decimal
    let ask: Decimal
    let timestamp: String
}
```

### 19.3 ExchangeCalculator

Pure business logic. No SwiftUI. No networking.

Responsibilities:

* Convert amounts using bid/ask rules
* Use explicit quote side
* Keep calculation testable
* Avoid formatting concerns

Example API:

```swift
struct ExchangeCalculator {
    func convert(
        amount: Decimal,
        from source: CurrencyCode,
        to target: CurrencyCode,
        using rate: ExchangeRate,
        quoteSide: QuoteSide
    ) -> Decimal?
}
```

Rules:

* Return nil if pair is unsupported.
* If quote side is `.bid`:

  * USDc → local: multiply by bid
  * local → USDc: divide by bid
* If quote side is `.ask`:

  * local → USDc: divide by ask
  * USDc → local: multiply by ask
* Return nil if source and target are unsupported.

---

## 20. Networking Layer

Keep networking small and explicit.

### 20.1 APIEndpoint

Responsibilities:

* Build paths
* Build query items

Cases:

```swift
enum APIEndpoint {
    case tickers(currencies: [CurrencyCode])
    case tickerCurrencies
}
```

### 20.2 APIClient

Responsibilities:

* Execute URLSession request
* Validate HTTP status
* Decode JSON
* Map errors to APIError

Suggested API:

```swift
struct APIClient {
    func send<T: Decodable>(_ endpoint: APIEndpoint, as type: T.Type) async throws -> T
}
```

### 20.3 APIError

Include simple cases:

```swift
enum APIError: Error, Equatable {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case decoding
    case transport
}
```

Do not build auth, token refresh, middleware, interceptors, or retry policies.

### 20.4 RatesService

Feature-facing protocol:

```swift
protocol RatesService {
    func fetchAvailableCurrencies() async throws -> CurrencyDiscoveryResult
    func fetchRates(for currencies: [CurrencyCode]) async throws -> [ExchangeRate]
}
```

### 20.5 LiveRatesService

Responsibilities:

* Try to fetch available currencies
* Return the currency discovery source for observability
* Fall back to static currency list if currencies endpoint fails or returns empty data
* Fetch tickers for resulting currencies
* Map DTOs into domain models

### 20.6 RatesRepository

Feature-facing loading protocol:

```swift
protocol RatesRepository {
    func loadRatesSnapshot() async throws -> RatesRepositoryResult
}
```

Responsibilities:

* Fetch a network snapshot on normal load.
* Persist successful network snapshots.
* Return cached snapshots only when the latest network refresh fails.
* Bound currency discovery latency with a timeout fallback.

### 20.7 MockRatesService

Use for:

* SwiftUI previews
* ViewModel tests
* Error simulation
* Fallback simulation

---

## 21. DTO Mapping

Ticker DTO:

```swift
struct TickerResponse: Decodable {
    let ask: String
    let bid: String
    let book: String
    let date: String
}
```

Map `ask` and `bid` strings to `Decimal`.

Map `book`:

```text
usdc_mxn -> quote = MXN
usdc_ars -> quote = ARS
```

If mapping fails, ignore that ticker or throw a mapping error depending on context.

Do not parse `date` into `Date` unless needed. The timestamp may contain high-precision fractional seconds, and freshness display is not required by the task.

---

## 22. Testing Strategy

Prioritize tests that prove product and financial behavior.

Avoid live network tests. Use mock services.

### 22.1 ExchangeCalculatorTests

Test:

* USDc top + edit USDc uses bid multiplication.
* USDc top + edit local uses bid division.
* Local top + edit local uses ask division.
* Local top + edit USDc uses ask multiplication.
* Unsupported pair returns nil.
* Decimal calculation does not use Double.
* Swap-related conversion uses opposite side when quote side changes.

### 22.2 InputSanitizerTests

Test:

* Removes `$`.
* Removes `,`.
* Allows one decimal separator.
* Handles empty input.
* Handles partial decimal input.
* Rejects invalid characters safely.

### 22.3 FormatterTests

Test:

* Formats amount with grouping separators.
* Formats amount with up to 2 decimals.
* Formats rate with readable precision.
* Handles zero.

### 22.4 ViewModelTests

Test:

* Initial state has empty amount fields.
* Successful load populates rates.
* Currencies endpoint failure uses fallback.
* Rates endpoint failure shows error state.
* Retry reloads rates.
* Editing top amount updates bottom.
* Editing bottom amount updates top.
* Selecting currency recalculates.
* Swapping currencies changes row order.
* Swapping changes quote side from bid to ask or ask to bid.
* Swapping preserves USDc amount where possible and recalculates local amount using the new quote side.
* Empty input clears opposite field.

### 22.5 RepositoryTests

Test:

* Normal load fetches from the network even when a cached snapshot exists.
* Successful load stores a network snapshot.
* Cached snapshot is returned when the network fails.
* Currency discovery timeout falls back to the local currency list.

---

## 23. README Requirements

Create a concise README.

Include:

1. Overview
2. How to run
3. Tech stack
4. Architecture
5. Key product/technical decisions
6. API handling
7. Testing
8. Assumptions
9. AI usage
10. Tradeoffs / future improvements

Do not make the README a huge manifesto.

Recommended README length: around 700–1,200 words.

### 23.1 README: Key Decisions to Mention

Mention:

* iOS 16.4 target
* SwiftUI + MVVM
* Single published ViewState
* Protocol-based `RatesService`
* `Decimal` for financial calculations
* Directional bid/ask handling based on row order
* Currencies endpoint fallback
* Empty initial input rather than fake prefilled amount
* Active input is not aggressively formatted
* No third-party dependencies
* Tests for calculation, formatting, and ViewModel state

### 23.2 README: AI Usage

Use short wording:

```markdown
## AI Usage

I used AI tools to speed up boilerplate and review edge cases. I manually made the product, architecture, and implementation decisions, and reviewed the final code myself.
```

---

## 24. Out of Scope

Keep out of scope small and relevant:

* Real transaction execution or order preview
* Authentication or user balances
* Long-term historical rate storage
* Custom numeric keyboard
* Live streaming rates

Do not over-discuss out-of-scope items.

---

## 25. Manual QA Checklist

Before submission:

* App opens and runs without modification.
* iOS target is 16.4.
* Initial fields are empty.
* Rate label loads.
* USDc input updates selected currency.
* Selected currency input updates USDc.
* Swap works repeatedly.
* Swap changes quote side.
* Swap preserves USDc amount where possible.
* Currency picker opens and dismisses.
* Selected currency updates rate and conversion.
* Currencies endpoint failure uses fallback.
* Rates endpoint failure shows retry.
* Missing-rate currency does not fake conversion.
* Empty input clears opposite field.
* Decimal input works.
* Large input does not break layout.
* iPhone SE layout is acceptable.
* Large iPhone layout is acceptable.
* Basic accessibility labels exist.
* Tests pass.
* README is complete.
* Repository has no local paths, secrets, or unnecessary files.

---
