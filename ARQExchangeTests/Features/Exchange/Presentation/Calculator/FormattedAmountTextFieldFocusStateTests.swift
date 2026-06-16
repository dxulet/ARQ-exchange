import XCTest
@testable import ARQExchange

final class FormattedAmountTextFieldFocusStateTests: XCTestCase {
    func testFocusedFieldBecomesFirstResponderWhenNeeded() {
        var state = FormattedAmountTextFieldFocusState()

        let action = state.action(
            isEnabled: true,
            isFocused: true,
            isFirstResponder: false
        )

        XCTAssertEqual(action, .becomeFirstResponder)
    }

    func testTransientUnfocusedFirstResponderDoesNotResignBeforeFocusIsObserved() {
        var state = FormattedAmountTextFieldFocusState()

        let action = state.action(
            isEnabled: true,
            isFocused: false,
            isFirstResponder: true
        )

        XCTAssertEqual(action, .none)
    }

    func testConfirmedFocusLossResignsFirstResponder() {
        var state = FormattedAmountTextFieldFocusState()

        _ = state.action(
            isEnabled: true,
            isFocused: true,
            isFirstResponder: true
        )

        let action = state.action(
            isEnabled: true,
            isFocused: false,
            isFirstResponder: true
        )

        XCTAssertEqual(action, .resignFirstResponder)
    }

    func testDisabledFieldResignsFirstResponder() {
        var state = FormattedAmountTextFieldFocusState()

        let action = state.action(
            isEnabled: false,
            isFocused: false,
            isFirstResponder: true
        )

        XCTAssertEqual(action, .resignFirstResponder)
    }
}
