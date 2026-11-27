import SwiftUI

/// A store's page: banner, store info, a pinned category bar, and the menu grouped by category.
/// Items go into the cart with the + button; the cart bar at the bottom opens checkout.
struct StoreMenuView: View {
    let store: Store

    @Environment(AppSession.self) private var session
    @State private var sections: [MenuSection] = []
    @State private var selectedSection: String?
    @State private var errorMessage: String?
    @State private var hasLoaded = false
    /// True once the banner has scrolled under the navigation bar.
    @State private var isHeaderCollapsed = false
    /// An item from this store tapped while the cart holds another store's items.
    @State private var pendingItem: MenuItem?

    private let bannerHeight: CGFloat = 240

    var body: some View {
        GeometryReader { outer in
            let topInset = outer.safeAreaInsets.top
            ScrollViewReader { proxy in
                ScrollView {
                    StretchyBanner(store: store, height: bannerHeight)
                        .onGeometryChange(for: Bool.self) { geo in
                            geo.frame(in: .scrollView).maxY < topInset + 20
                        } action: { collapsed in
                            withAnimation(.easeInOut(duration: 0.2)) { isHeaderCollapsed = collapsed }
                        }

                    StoreInfoHeader(store: store)
                        .background(.background, in: UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24))
                        .padding(.top, -24)
                        // Leaves room for the pinned bar's spacer below without a visible gap.
                        .padding(.bottom, -topInset)

                    LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                        Section {
                            ForEach(sections) { section in
                                MenuSectionView(section: section, scrollAnchorOffset: topInset + 56, onAdd: add)
                            }
                        } header: {
                            VStack(spacing: 0) {
                                // Sits under the navigation bar once the bar is pinned.
                                Color.clear.frame(height: topInset)
                                if sections.count > 1 {
                                    CategoryBar(sections: sections, selection: selectedSection) { id in
                                        selectedSection = id
                                        withAnimation(.snappy) { proxy.scrollTo(id, anchor: .top) }
                                    }
                                }
                            }
                        }
                    }
                }
                .ignoresSafeArea(edges: .top)
            }
        }
        .overlay { overlay }
        .safeAreaInset(edge: .bottom) { CartBar() }
        .confirmationDialog(
            "Start a new cart?",
            isPresented: Binding(get: { pendingItem != nil }, set: { if !$0 { pendingItem = nil } }),
            titleVisibility: .visible,
            presenting: pendingItem
        ) { item in
            Button("Start new cart") {
                session.cart.startNew(with: item, from: store)
            }
            Button("Keep current cart", role: .cancel) {}
        } message: { item in
            Text("Your cart has items from \(session.cart.store?.name ?? "another store"). Orders come from one store at a time. Clear it and add \(item.name) from \(store.name)?")
        }
        .navigationTitle(isHeaderCollapsed ? store.name : "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(isHeaderCollapsed ? .visible : .hidden, for: .navigationBar)
        .task { await load() }
    }

    @ViewBuilder private var overlay: some View {
        if let errorMessage {
            ContentUnavailableView("Couldn't load menu", systemImage: "wifi.exclamationmark", description: Text(errorMessage))
        } else if !hasLoaded {
            ProgressView()
        } else if sections.isEmpty {
            ContentUnavailableView("No menu yet", systemImage: "menucard")
        }
    }

    private func add(_ item: MenuItem) {
        if case .needsNewCart = session.cart.add(item, from: store) {
            pendingItem = item
        }
    }

    private func load() async {
        do {
            sections = MenuSection.group(try await session.stores.menu(storeID: store.id))
            selectedSection = selectedSection ?? sections.first?.id
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        hasLoaded = true
    }
}

/// Store banner that stretches when the page is pulled down past the top.
private struct StretchyBanner: View {
    let store: Store
    let height: CGFloat

    var body: some View {
        GeometryReader { geo in
            let pull = max(0, geo.frame(in: .scrollView).minY)
            FoodArtwork(imageURL: store.imageURL, symbol: store.symbolName, seed: store.id, symbolSize: 64)
                .frame(width: geo.size.width, height: height + pull)
                .offset(y: -pull)
        }
        .frame(height: height)
    }
}

private struct StoreInfoHeader: View {
    let store: Store

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            StoreLogo(store: store, size: 72)
                .padding(.top, -52)
            Text(store.name)
                .font(.title2.bold())
            Text(store.tagline)
                .foregroundStyle(.secondary)

            HStack(spacing: 0) {
                info(store.deliveryTimeText, caption: "Delivery", symbol: "clock")
                Divider().frame(height: 32)
                info(store.deliveryFee == 0 ? "Free" : Money.format(store.deliveryFee), caption: "Delivery fee", symbol: "bicycle")
                Divider().frame(height: 32)
                info(store.cuisine, caption: "Cuisine", symbol: store.symbolName)
            }
            .padding(.vertical, 10)
            .background(Brand.yellow.opacity(0.18), in: RoundedRectangle(cornerRadius: 12))

            Label(store.address.line, systemImage: "mappin.and.ellipse")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private func info(_ value: String, caption: String, symbol: String) -> some View {
        VStack(spacing: 2) {
            Label(value, systemImage: symbol)
                .font(.subheadline.weight(.semibold))
                .labelStyle(.titleAndIcon)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(caption)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct CategoryBar: View {
    let sections: [MenuSection]
    let selection: String?
    let onSelect: (String) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(sections) { section in
                        let isSelected = section.id == selection
                        Button {
                            onSelect(section.id)
                        } label: {
                            Text(section.title)
                                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(isSelected ? AnyShapeStyle(Brand.red) : AnyShapeStyle(.fill.tertiary), in: Capsule())
                                .foregroundStyle(isSelected ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
                        }
                        .buttonStyle(.plain)
                        .id("chip-\(section.id)")
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
            .onChange(of: selection) { _, id in
                if let id { withAnimation { proxy.scrollTo("chip-\(id)", anchor: .center) } }
            }
        }
        .background(.bar)
        .overlay(alignment: .bottom) { Divider() }
    }
}

private struct MenuSectionView: View {
    let section: MenuSection
    /// Height of the pinned header; the scroll target sits this far above the section
    /// so a category tap lands the title just below the pinned bar.
    let scrollAnchorOffset: CGFloat
    let onAdd: (MenuItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear
                .frame(height: scrollAnchorOffset)
                .id(section.id)
                .padding(.top, -scrollAnchorOffset)
            Text(section.title)
                .font(.title3.bold())
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 4)
            ForEach(section.items) { item in
                MenuItemRow(item: item, onAdd: onAdd)
                Divider().padding(.leading)
            }
        }
    }
}

private struct MenuItemRow: View {
    let item: MenuItem
    let onAdd: (MenuItem) -> Void

    @Environment(AppSession.self) private var session

    private var quantity: Int { session.cart.quantity(of: item.id) }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                if !item.details.isEmpty {
                    Text(item.details)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 4)
                if item.isAvailable {
                    Text(Money.format(item.price))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Brand.red)
                        .monospacedDigit()
                } else {
                    Text("Sold out")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            FoodArtwork(imageURL: item.imageURL, symbol: item.symbolName, seed: item.id, symbolSize: 28)
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .saturation(item.isAvailable ? 1 : 0)
                .overlay(alignment: .bottomTrailing) {
                    if item.isAvailable { addButton }
                }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .opacity(item.isAvailable ? 1 : 0.55)
        .accessibilityElement(children: .contain)
        .sensoryFeedback(.increase, trigger: quantity)
    }

    /// "+" when the item isn't in the cart, otherwise the quantity; each tap adds one.
    private var addButton: some View {
        Button {
            onAdd(item)
        } label: {
            Group {
                if quantity > 0 {
                    Text("\(quantity)")
                        .font(.subheadline.weight(.heavy))
                        .monospacedDigit()
                } else {
                    Image(systemName: "plus")
                        .font(.subheadline.weight(.heavy))
                }
            }
            .foregroundStyle(.white)
            .frame(width: 34, height: 34)
            .background(Brand.red, in: Circle())
            .overlay(Circle().strokeBorder(.white, lineWidth: 2))
            .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
        .padding(6)
        .contentShape(Rectangle())
        .accessibilityLabel(quantity > 0 ? "Add another \(item.name), \(quantity) in cart" : "Add \(item.name) to cart")
    }
}

#Preview {
    NavigationStack {
        StoreMenuView(store: MockData.stores[0])
    }
    .environment(AppSession.mock(signedInAs: MockData.customer))
    .environment(CustomerRouter())
}
