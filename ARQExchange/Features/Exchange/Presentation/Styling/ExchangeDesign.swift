import SwiftUI

enum ExchangeDesign {
    enum Colors {
        static let background = Color(red: 0.98, green: 0.98, blue: 0.98)
        static let fieldBackground = Color.white
        static let contentPrimary = Color(red: 0.17, green: 0.17, blue: 0.18)
        static let brand = Color(red: 0.13, green: 0.82, blue: 0.51)
        static let separator = Color(red: 0.84, green: 0.84, blue: 0.85)
    }

    enum Layout {
        static let horizontalPadding: CGFloat = 16
        static let titleTopPadding: CGFloat = 64
        static let headerBottomPadding: CGFloat = 24
        static let bottomPadding: CGFloat = 32
        static let contentMaxWidth: CGFloat = 375
        static let headerRateHeight: CGFloat = 20
        static let minimumScaleFactor: CGFloat = 0.8
        static let rowHeight: CGFloat = 64
        static let rowCornerRadius: CGFloat = 14
        static let rowHorizontalPadding: CGFloat = 16
        static let rowSpacing: CGFloat = 16
        static let swapButtonSize: CGFloat = 28
        static let swapButtonBorderWidth: CGFloat = 6
        static let flagSize: CGFloat = 18
        static let sheetHorizontalPadding: CGFloat = 16
        static let sheetTopPadding: CGFloat = 30
        static let sheetContentSpacing: CGFloat = 16
        static let sheetListBottomPadding: CGFloat = 16
        static let sheetListVerticalPadding: CGFloat = 8
        static let sheetListCornerRadius: CGFloat = 14
        static let closeButtonSize: CGFloat = 44
        static let retryButtonHeight: CGFloat = 50
        static let retryButtonCornerRadius: CGFloat = 12
        static let pickerRowSpacing: CGFloat = 12
        static let pickerRowHorizontalPadding: CGFloat = 16
        static let pickerRowHeight: CGFloat = 56
        static let pickerFlagSize: CGFloat = 26
        static let pickerFlagContainerSize: CGFloat = 36
        static let pickerFlagContainerCornerRadius: CGFloat = 14
        static let selectionIndicatorSize: CGFloat = 22
        static let selectionIndicatorStrokeWidth: CGFloat = 2
        static let unavailableOpacity: CGFloat = 0.6
        static let disabledCurrencyOpacity: CGFloat = 0.45
    }

    enum Font {
        static let title = SwiftUI.Font.system(size: 30, weight: .bold)
        static let titleLineHeight: CGFloat = 33
        static let titleTracking: CGFloat = -0.6
        static let rate = SwiftUI.Font.system(size: 14, weight: .bold)
        static let body = SwiftUI.Font.system(size: 16, weight: .semibold)
        static let amount = SwiftUI.Font.system(size: 16, weight: .bold)
        static let sheetTitle = SwiftUI.Font.system(size: 22, weight: .bold)
        static let chevron = SwiftUI.Font.system(size: 13, weight: .bold)
        static let swapIcon = SwiftUI.Font.system(size: 14, weight: .bold)
        static let closeIcon = SwiftUI.Font.system(size: 20, weight: .regular)
        static let checkmark = SwiftUI.Font.system(size: 11, weight: .bold)
    }
}
