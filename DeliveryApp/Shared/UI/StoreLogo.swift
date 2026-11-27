import SwiftUI

/// Round store logo: the uploaded logo when there is one, otherwise the store's
/// monogram on its own color, so every store is recognizable at a glance.
struct StoreLogo: View {
    let store: Store
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            monogram
            if let logoURL = store.logoURL {
                AsyncImage(url: logoURL) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(.white, lineWidth: max(2, size / 22)))
        .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
        .accessibilityLabel("\(store.name) logo")
    }

    private var monogram: some View {
        let colors = Self.palette[Self.paletteIndex(for: store.id)]
        return Circle()
            .fill(colors.background)
            .overlay {
                Text(store.monogram)
                    .font(.system(size: size * 0.38, weight: .heavy, design: .rounded))
                    .foregroundStyle(colors.text)
                    .minimumScaleFactor(0.5)
            }
    }

    /// Warm, brand-friendly pairs that stay distinct from each other.
    private static let palette: [(background: Color, text: Color)] = [
        (Color(red: 0.84, green: 0.15, blue: 0.17), Brand.yellow),
        (Brand.yellow, Color(red: 0.70, green: 0.10, blue: 0.12)),
        (Color(red: 0.55, green: 0.09, blue: 0.13), .white),
        (Color(red: 0.93, green: 0.45, blue: 0.13), .white),
        (Color(red: 0.36, green: 0.20, blue: 0.10), Brand.yellow),
        (Color(red: 1.00, green: 0.93, blue: 0.80), Color(red: 0.84, green: 0.15, blue: 0.17)),
        (Color(red: 0.20, green: 0.45, blue: 0.25), .white),
        (Color(red: 0.98, green: 0.62, blue: 0.20), Color(red: 0.36, green: 0.20, blue: 0.10)),
    ]

    static func paletteIndex(for seed: String) -> Int {
        let hash = seed.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0xFFFF }
        return hash % palette.count
    }
}

#Preview {
    HStack {
        ForEach(MockData.stores) { StoreLogo(store: $0) }
    }
    .padding()
}
