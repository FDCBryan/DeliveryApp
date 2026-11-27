import Foundation

/// An image picked on the device, before upload.
nonisolated struct ImageUpload: Hashable, Sendable {
    enum Format: String, Sendable { case jpeg, png }

    let data: Data

    /// Detected from the file's first bytes rather than its name or extension.
    var format: Format? {
        if data.starts(with: [0xFF, 0xD8, 0xFF]) { return .jpeg }
        if data.starts(with: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) { return .png }
        return nil
    }
}

/// What a store owner fills in to create a store. A logo is required;
/// the cover photo is optional (the store page falls back to a placeholder).
/// The backend must apply the same rules (docs/PLAN.md §6).
nonisolated struct StoreDraft: Sendable {
    static let maxImageBytes = 2 * 1024 * 1024

    var name = ""
    var tagline = ""
    var cuisine = ""
    var address = Address(line: "")
    var deliveryFee = 0
    var deliveryMinutes = 30
    var logo: ImageUpload?
    var cover: ImageUpload?

    /// Throws the first problem found, in form order.
    func validate() throws(StoreValidationError) {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw .missingName }
        guard !cuisine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw .missingCuisine }
        guard !address.line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw .missingAddress }
        guard deliveryFee >= 0 else { throw .invalidDeliveryFee }
        guard (5...180).contains(deliveryMinutes) else { throw .invalidDeliveryTime }
        guard let logo else { throw .missingLogo }
        try Self.check(logo, field: .logo)
        if let cover { try Self.check(cover, field: .cover) }
    }

    private static func check(_ image: ImageUpload, field: StoreValidationError.ImageField) throws(StoreValidationError) {
        guard image.format != nil else { throw .unsupportedImage(field) }
        guard image.data.count <= maxImageBytes else { throw .imageTooLarge(field) }
    }
}

nonisolated enum StoreValidationError: Error, Equatable, LocalizedError {
    enum ImageField: String, Sendable { case logo, cover }

    case missingName
    case missingCuisine
    case missingAddress
    case invalidDeliveryFee
    case invalidDeliveryTime
    case missingLogo
    case unsupportedImage(ImageField)
    case imageTooLarge(ImageField)

    var errorDescription: String? {
        switch self {
        case .missingName: "Enter the store name."
        case .missingCuisine: "Choose a cuisine."
        case .missingAddress: "Enter the store address."
        case .invalidDeliveryFee: "The delivery fee can't be negative."
        case .invalidDeliveryTime: "Delivery time must be between 5 and 180 minutes."
        case .missingLogo: "Add your store logo."
        case let .unsupportedImage(field): "The \(field.rawValue) must be a JPEG or PNG image."
        case let .imageTooLarge(field): "The \(field.rawValue) must be 2 MB or smaller."
        }
    }
}
