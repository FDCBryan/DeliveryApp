import SwiftUI

/// Marketplace home: search, cuisine filters, deals, popular stores, then every open store.
struct StoreListView: View {
    @Environment(AppSession.self) private var session
    @State private var stores: [Store] = []
    @State private var errorMessage: String?
    @State private var hasLoaded = false
    @State private var searchText = ""
    @State private var selectedCuisine: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if !cuisines.isEmpty {
                        CuisineChips(cuisines: cuisines, selection: $selectedCuisine)
                    }

                    if isBrowsing {
                        if !promos.isEmpty {
                            PromoCarousel(promos: promos)
                        }
                        if !featured.isEmpty {
                            SectionTitle(title: "Popular near you")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 14) {
                                    ForEach(featured) { store in
                                        NavigationLink(value: store) {
                                            FeaturedStoreCard(store: store)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    SectionTitle(title: selectedCuisine ?? "All stores")
                    LazyVStack(spacing: 18) {
                        ForEach(filteredStores) { store in
                            NavigationLink(value: store) {
                                StoreCard(store: store)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .overlay { overlay }
            .safeAreaInset(edge: .bottom) { CartBar() }
            .navigationTitle("Stores")
            .searchable(text: $searchText, prompt: "Search stores or cuisines")
            .navigationDestination(for: Store.self) { StoreMenuView(store: $0) }
            .task { await load() }
            .refreshable { await load() }
        }
    }

    @ViewBuilder private var overlay: some View {
        if let errorMessage {
            ContentUnavailableView("Couldn't load stores", systemImage: "wifi.exclamationmark", description: Text(errorMessage))
        } else if !hasLoaded {
            ProgressView()
        } else if stores.isEmpty {
            ContentUnavailableView("No stores open", systemImage: "storefront", description: Text("Check back later."))
        } else if filteredStores.isEmpty {
            ContentUnavailableView.search(text: searchText)
        }
    }

    /// No search text and no cuisine filter: show the deals and popular rows.
    private var isBrowsing: Bool {
        selectedCuisine == nil && searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var cuisines: [String] {
        var seen = Set<String>()
        return stores.map(\.cuisine).filter { !$0.isEmpty && seen.insert($0).inserted }
    }

    private var featured: [Store] { stores.filter(\.isFeatured) }

    private var promos: [Promo] { Promo.make(from: stores) }

    private var filteredStores: [Store] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        return stores.filter { store in
            (selectedCuisine == nil || store.cuisine == selectedCuisine)
                && (query.isEmpty
                    || store.name.localizedCaseInsensitiveContains(query)
                    || store.cuisine.localizedCaseInsensitiveContains(query)
                    || store.tagline.localizedCaseInsensitiveContains(query))
        }
    }

    private func load() async {
        do {
            stores = try await session.stores.openStores()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        hasLoaded = true
    }
}

private struct SectionTitle: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.title3.bold())
            .padding(.horizontal)
    }
}

// MARK: - Cuisine filters

private struct CuisineChips: View {
    let cuisines: [String]
    @Binding var selection: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                chip(title: "All", symbol: "square.grid.2x2.fill", value: nil)
                ForEach(cuisines, id: \.self) { cuisine in
                    chip(title: cuisine, symbol: FoodSymbol.forCategory(cuisine), value: cuisine)
                }
            }
            .padding(.horizontal)
        }
    }

    private func chip(title: String, symbol: String, value: String?) -> some View {
        let isSelected = selection == value
        return Button {
            withAnimation(.snappy) { selection = value }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.title3)
                    .frame(width: 56, height: 56)
                    .background(isSelected ? AnyShapeStyle(Brand.red) : AnyShapeStyle(Brand.yellow.opacity(0.22)), in: Circle())
                    .foregroundStyle(isSelected ? AnyShapeStyle(.white) : AnyShapeStyle(Brand.red))
                Text(title)
                    .font(.caption.weight(isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Deals

/// A deal shown in the carousel, built from store data until the backend has real promotions.
struct Promo: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let symbol: String
    let store: Store?
    let style: Style

    enum Style { case red, yellow }

    static func make(from stores: [Store]) -> [Promo] {
        var promos: [Promo] = []
        if let free = stores.first(where: { $0.deliveryFee == 0 }) {
            promos.append(Promo(id: "free-\(free.id)", title: "Free delivery",
                                subtitle: "Every order from \(free.name)", symbol: "bicycle", store: free, style: .red))
        }
        if let fastest = stores.min(by: { $0.deliveryMinutes < $1.deliveryMinutes }) {
            promos.append(Promo(id: "fast-\(fastest.id)", title: "Hungry now?",
                                subtitle: "\(fastest.name) delivers in \(fastest.deliveryTimeText)", symbol: "bolt.fill",
                                store: fastest, style: .yellow))
        }
        if stores.count > 1 {
            promos.append(Promo(id: "count", title: "\(stores.count) stores open",
                                subtitle: "Burgers, noodles, pizza and more", symbol: "storefront.fill", store: nil, style: .red))
        }
        return promos
    }
}

private struct PromoCarousel: View {
    let promos: [Promo]

    var body: some View {
        TabView {
            ForEach(promos) { promo in
                Group {
                    if let store = promo.store {
                        NavigationLink(value: store) { PromoCard(promo: promo) }
                            .buttonStyle(.plain)
                    } else {
                        PromoCard(promo: promo)
                    }
                }
                .padding(.horizontal)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .frame(height: 150)
    }
}

private struct PromoCard: View {
    let promo: Promo

    var body: some View {
        let isRed = promo.style == .red
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(promo.title)
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(isRed ? Brand.yellow : Brand.red)
                Text(promo.subtitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isRed ? .white : Brand.onYellow)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            Image(systemName: promo.symbol)
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(isRed ? Brand.yellow : Brand.red)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .background(isRed ? Brand.red : Brand.yellow, in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Store cards

private struct FeaturedStoreCard: View {
    let store: Store

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            FoodArtwork(imageURL: store.imageURL, symbol: store.symbolName, seed: store.id, symbolSize: 32)
                .frame(width: 220, height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(alignment: .topLeading) { FreeDeliveryBadge(store: store) }
                .overlay(alignment: .bottomTrailing) { StoreLogo(store: store, size: 40).padding(8) }
            Text(store.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
            StoreMeta(store: store)
        }
        .frame(width: 220, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// Compact card for the main list.
struct StoreCard: View {
    let store: Store

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            FoodArtwork(imageURL: store.imageURL, symbol: store.symbolName, seed: store.id, symbolSize: 34)
                .frame(height: 110)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(alignment: .topLeading) { FreeDeliveryBadge(store: store) }
            HStack(alignment: .top, spacing: 10) {
                StoreLogo(store: store, size: 44)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(store.name)
                            .font(.headline)
                        Spacer()
                        Text(store.cuisine)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Brand.red)
                    }
                    Text(store.tagline)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    StoreMeta(store: store)
                }
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

private struct StoreMeta: View {
    let store: Store

    var body: some View {
        HStack(spacing: 10) {
            Label(store.deliveryTimeText, systemImage: "clock")
            Label(store.deliveryFee == 0 ? "Free" : Money.format(store.deliveryFee), systemImage: "bicycle")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

private struct FreeDeliveryBadge: View {
    let store: Store

    var body: some View {
        if store.deliveryFee == 0 {
            Text("Free delivery")
                .font(.caption2.weight(.heavy))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Brand.yellow, in: RoundedRectangle(cornerRadius: 6))
                .foregroundStyle(Brand.onYellow)
                .padding(8)
        }
    }
}

#Preview {
    StoreListView()
        .environment(AppSession.mock(signedInAs: MockData.customer))
        .environment(CustomerRouter())
}
