import SwiftUI

enum ExchangeDesign {
    enum Colors {
        static let background = Color(red: 0.972549, green: 0.972549, blue: 0.972549)
        static let fieldBackground = Color.white
        static let contentPrimary = Color(red: 0.172549, green: 0.172549, blue: 0.180392)
        static let brand = Color(red: 0.133333, green: 0.815686, blue: 0.505882)
        static let separator = Color(red: 0.84, green: 0.84, blue: 0.85)
    }

    enum Layout {
        static let minimumScaleFactor: CGFloat = 0.8
        static let minimumHitTarget: CGFloat = 44
        static let rowHeight: CGFloat = 66
        static let rowCornerRadius: CGFloat = 16
        static let rowHorizontalPadding: CGFloat = 16
        static let rowSpacing: CGFloat = 16
        static let swapButtonSize: CGFloat = 24
        static let swapIconSize: CGFloat = 14
        static let swapButtonBorderWidth: CGFloat = 6
        static let flagSize: CGFloat = 16
        static let currencyLabelSpacing: CGFloat = 8
        static let unavailableOpacity: CGFloat = 0.6
    }

    enum Font {
        static let title = SwiftUI.Font.system(size: 30, weight: .bold)
        static let rate = SwiftUI.Font.system(size: 16, weight: .semibold)
        static let body = SwiftUI.Font.system(size: 16, weight: .semibold)
        static let sheetTitle = SwiftUI.Font.system(size: 24, weight: .semibold)
        static let chevron = SwiftUI.Font.system(size: 13, weight: .bold)
        static let closeIcon = SwiftUI.Font.system(size: 20, weight: .regular)
        static let checkmark = SwiftUI.Font.system(size: 11, weight: .bold)
    }

    enum Tracking {
        static let title: CGFloat = -0.6
        static let sheetTitle: CGFloat = -0.48
        static let body: CGFloat = 0.32
    }
}
