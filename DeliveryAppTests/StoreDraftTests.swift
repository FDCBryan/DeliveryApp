import Foundation
import Testing
@testable import DeliveryApp

struct StoreDraftTests {
    static let png = ImageUpload(data: Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00]))
    static let jpeg = ImageUpload(data: Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00]))
    static let gif = ImageUpload(data: Data("GIF89a".utf8))

    private func valid() -> StoreDraft {
        var draft = StoreDraft()
        draft.name = "Taco Town"
        draft.cuisine = "Mexican"
        draft.address = Address(line: "1 Main St")
        draft.deliveryFee = 199
        draft.logo = Self.png
        return draft
    }

    @Test func validDraftPasses() throws {
        try valid().validate()
        var withCover = valid()
        withCover.cover = Self.jpeg
        try withCover.validate()
    }

    @Test func logoIsRequired() {
        var draft = valid()
        draft.logo = nil
        #expect(throws: StoreValidationError.missingLogo) { try draft.validate() }
    }

    @Test func logoMustBeJPEGOrPNG() {
        var draft = valid()
        draft.logo = Self.gif
        #expect(throws: StoreValidationError.unsupportedImage(.logo)) { try draft.validate() }
    }

    @Test func imagesOver2MBAreRejected() {
        var big = Data([0xFF, 0xD8, 0xFF])
        big.append(Data(count: StoreDraft.maxImageBytes))
        var draft = valid()
        draft.logo = ImageUpload(data: big)
        #expect(throws: StoreValidationError.imageTooLarge(.logo)) { try draft.validate() }

        var coverDraft = valid()
        coverDraft.cover = ImageUpload(data: big)
        #expect(throws: StoreValidationError.imageTooLarge(.cover)) { try coverDraft.validate() }
    }

    @Test func coverIsOptionalButChecked() {
        var draft = valid()
        draft.cover = Self.gif
        #expect(throws: StoreValidationError.unsupportedImage(.cover)) { try draft.validate() }
    }

    @Test func requiredTextFields() {
        var draft = valid()
        draft.name = "  "
        #expect(throws: StoreValidationError.missingName) { try draft.validate() }
        draft = valid()
        draft.cuisine = ""
        #expect(throws: StoreValidationError.missingCuisine) { try draft.validate() }
        draft = valid()
        draft.address = Address(line: "")
        #expect(throws: StoreValidationError.missingAddress) { try draft.validate() }
    }

    @Test func feeAndTimeBounds() {
        var draft = valid()
        draft.deliveryFee = -1
        #expect(throws: StoreValidationError.invalidDeliveryFee) { try draft.validate() }
        draft = valid()
        draft.deliveryMinutes = 0
        #expect(throws: StoreValidationError.invalidDeliveryTime) { try draft.validate() }
    }
}

struct StoreMonogramTests {
    private func store(_ name: String) -> Store {
        Store(id: name, name: name, address: Address(line: "x"), isOpen: true, deliveryFee: 0)
    }

    @Test(arguments: [
        ("Burger Barn", "BB"),
        ("Green Bowl Co.", "GB"),
        ("The Corner Bakery", "CB"),
        ("Slice", "S"),
        ("Fish & Chips", "FC"),
        ("7-Eleven", "E"),
        ("   ", "?"),
    ])
    func monogram(name: String, expected: String) {
        #expect(store(name).monogram == expected)
    }

    @Test func sampleStoresHaveDistinctMonograms() {
        let monograms = MockData.stores.map(\.monogram)
        #expect(Set(monograms).count == monograms.count)
    }
}
