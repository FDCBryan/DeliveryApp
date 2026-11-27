import SwiftUI

/// Shows the remote image when there is one; otherwise a stable colored placeholder
/// with a food symbol, so sample data without photos still looks like a menu.
struct FoodArtwork: View {
    let imageURL: URL?
    let symbol: String
    /// Any stable string (e.g. the store or item id); picks the placeholder colors.
    let seed: String
    var symbolSize: CGFloat = 36

    var body: some View {
        ZStack {
            placeholder
            if let imageURL {
                AsyncImage(url: imageURL) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    }
                }
            }
        }
        .clipped()
    }

    private var placeholder: some View {
        // Warm tones only (red → orange → amber) so placeholders sit well with the red/yellow brand.
        let hash = seed.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0xFFFF }
        let hue = Double(hash % 45) / 360
        let saturation = 0.55 + Double(hash % 4) * 0.08
        return LinearGradient(
            colors: [Color(hue: hue, saturation: saturation - 0.15, brightness: 0.98),
                     Color(hue: hue, saturation: saturation, brightness: 0.85)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            Image(systemName: symbol)
                .font(.system(size: symbolSize, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
        }
    }
}

extension Store {
    var symbolName: String { FoodSymbol.forCategory(cuisine) }
}

extension MenuItem {
    var symbolName: String { FoodSymbol.forCategory(category) }
}

enum FoodSymbol {
    static func forCategory(_ name: String) -> String {
        switch name.lowercased() {
        case "burgers": "takeoutbag.and.cup.and.straw.fill"
        case "noodles", "noodle soups": "fork.knife"
        case "bakery", "pastries", "bread": "birthday.cake.fill"
        case "coffee": "cup.and.saucer.fill"
        case "drinks", "juices": "mug.fill"
        case "pizza", "pizzas": "circle.grid.cross.fill"
        case "healthy", "salads", "bowls": "leaf.fill"
        case "chicken", "rice meals": "flame.fill"
        case "sides", "small plates": "takeoutbag.and.cup.and.straw"
        case "mexican", "tacos": "sun.max.fill"
        default: "fork.knife.circle.fill"
        }
    }
}

#Preview {
    FoodArtwork(imageURL: nil, symbol: "fork.knife", seed: "store-noodle")
        .frame(width: 200, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 12))
}
