import Foundation

final class InMemoryStoreRepository: StoreRepository {
    private let stores: [Store]
    private let menus: [String: [MenuItem]]

    init(stores: [Store], menuItems: [MenuItem]) {
        self.stores = stores
        self.menus = Dictionary(grouping: menuItems, by: \.storeID)
    }

    func openStores() async throws -> [Store] {
        stores.filter(\.isOpen).sorted { $0.name < $1.name }
    }

    func menu(storeID: String) async throws -> [MenuItem] {
        menus[storeID, default: []]
    }
}
