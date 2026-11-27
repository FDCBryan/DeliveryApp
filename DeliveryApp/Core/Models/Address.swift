import Foundation

nonisolated struct Address: Codable, Hashable, Sendable {
    var line: String
    var note: String?
    var latitude: Double?
    var longitude: Double?

    init(line: String, note: String? = nil, latitude: Double? = nil, longitude: Double? = nil) {
        self.line = line
        self.note = note
        self.latitude = latitude
        self.longitude = longitude
    }
}
