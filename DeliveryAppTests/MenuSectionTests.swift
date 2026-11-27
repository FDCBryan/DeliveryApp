import Testing
@testable import DeliveryApp

struct MenuSectionTests {
    private func item(_ id: String, _ category: String, popular: Bool = false, available: Bool = true) -> MenuItem {
        MenuItem(id: id, storeID: "s", name: id, price: 100, isAvailable: available, category: category, isPopular: popular)
    }

    @Test func groupsByCategoryInFirstSeenOrder() {
        let sections = MenuSection.group([item("a", "Mains"), item("b", "Drinks"), item("c", "Mains")])
        #expect(sections.map(\.title) == ["Mains", "Drinks"])
        #expect(sections[0].items.map(\.id) == ["a", "c"])
    }

    @Test func popularAvailableItemsLeadInTheirOwnSection() {
        let sections = MenuSection.group([
            item("a", "Mains", popular: true),
            item("b", "Mains", popular: true, available: false),
            item("c", "Drinks"),
        ])
        #expect(sections.map(\.title) == ["Popular", "Mains", "Drinks"])
        #expect(sections[0].items.map(\.id) == ["a"])
    }

    @Test func emptyMenuHasNoSections() {
        #expect(MenuSection.group([]).isEmpty)
    }

    @Test func deliveryTimeRange() {
        var store = Fixture.store
        store.deliveryMinutes = 25
        #expect(store.deliveryTimeText == "20–30 min")
    }
}
