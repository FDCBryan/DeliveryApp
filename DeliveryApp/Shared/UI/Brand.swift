import SwiftUI

/// App palette: warm red (the asset catalog's AccentColor, used as the tint everywhere)
/// plus a sunny yellow for highlights such as deals and free-delivery badges.
enum Brand {
    static let red = Color.accentColor
    static let yellow = Color(.brandYellow)
    /// Dark text that stays readable on the yellow.
    static let onYellow = Color(red: 0.25, green: 0.12, blue: 0.0)
}
