import Foundation

nonisolated enum AppConfig {
    /// Placeholder until the currency is decided (docs/PLAN.md §10, question 1).
    static let currencyCode = "USD"
}

/// Amounts are stored as `Int` in minor units (cents) to avoid floating-point rounding.
nonisolated enum Money {
    static func format(_ minorUnits: Int, currencyCode: String = AppConfig.currencyCode) -> String {
        (Decimal(minorUnits) / 100).formatted(.currency(code: currencyCode))
    }
}
