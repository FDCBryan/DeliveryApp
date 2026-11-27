import Foundation

nonisolated struct Store: Identifiable, Codable, Hashable, Sendable {
    let id: String
    var name: String
    var address: Address
    /// Cover photo shown as the banner.
    var imageURL: URL?
    /// The store's logo. Required when a store is created (see `StoreDraft`);
    /// sample stores have none and fall back to `monogram`.
    var logoURL: URL?
    var isOpen: Bool
    /// Flat per-store fee in minor units.
    var deliveryFee: Int
    var cuisine: String = ""
    /// Typical delivery time in minutes, shown as a range on the store card.
    var deliveryMinutes: Int = 30
    var tagline: String = ""
    /// Shown in the "Popular near you" row.
    var isFeatured: Bool = false

    /// Up to two initials from the store name, e.g. "Burger Barn" → "BB".
    /// Shown as the logo placeholder when there's no logo image.
    var monogram: String {
        let skipped: Set<String> = ["co", "co.", "inc", "inc.", "the", "&", "and", "of"]
        let words = name.split(whereSeparator: { $0.isWhitespace || $0 == "-" })
            .map(String.init)
            .filter { !skipped.contains($0.lowercased()) }
        let letters = words.compactMap { $0.first(where: \.isLetter) }.prefix(2)
        return letters.isEmpty ? "?" : String(letters).uppercased()
    }

    /// e.g. "20–30 min"
    var deliveryTimeText: String {
        "\(max(deliveryMinutes - 5, 5))–\(deliveryMinutes + 5) min"
    }
}

nonisolated struct MenuItem: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let storeID: String
    var name: String
    var price: Int
    var imageURL: URL?
    var isAvailable: Bool
    var category: String = "Menu"
    var details: String = ""
    var isPopular: Bool = false
}

/// One titled group of menu items, e.g. "Burgers" or "Drinks".
nonisolated struct MenuSection: Identifiable, Hashable, Sendable {
    let title: String
    let items: [MenuItem]

    var id: String { title }

    /// Groups items by category, keeping categories in the order they first appear.
    /// Popular items are also repeated in a leading "Popular" section.
    static func group(_ items: [MenuItem]) -> [MenuSection] {
        var order: [String] = []
        var byCategory: [String: [MenuItem]] = [:]
        for item in items {
            if byCategory[item.category] == nil { order.append(item.category) }
            byCategory[item.category, default: []].append(item)
        }
        let sections = order.map { MenuSection(title: $0, items: byCategory[$0, default: []]) }
        let popular = items.filter { $0.isPopular && $0.isAvailable }
        return popular.isEmpty ? sections : [MenuSection(title: "Popular", items: popular)] + sections
    }
}
