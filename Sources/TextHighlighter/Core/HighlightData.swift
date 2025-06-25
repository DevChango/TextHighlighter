import Foundation
import AppKit

// MARK: - HighlightData with metadata
public struct HighlightData: Hashable, Equatable, Codable {
    public let uuid: String
    public let color: HighlightColorScheme
    public let createdAt: Date
    public let updatedAt: Date
    public let text: String
    public let note: String?
    public let tags: [String]

    public init(
        uuid: String,
        color: HighlightColorScheme,
        text: String,
        note: String? = nil,
        tags: [String] = []
    ) {
        self.uuid = uuid
        self.color = color
        self.text = text
        self.note = note
        self.tags = tags
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    public func updated(
        color: HighlightColorScheme? = nil,
        note: String? = nil,
        tags: [String]? = nil
    ) -> HighlightData {
        return HighlightData(
            uuid: self.uuid,
            color: color ?? self.color,
            createdAt: self.createdAt,
            updatedAt: Date(),
            text: self.text,
            note: note ?? self.note,
            tags: tags ?? self.tags
        )
    }

    private init(
        uuid: String,
        color: HighlightColorScheme,
        createdAt: Date,
        updatedAt: Date,
        text: String,
        note: String?,
        tags: [String]
    ) {
        self.uuid = uuid
        self.color = color
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.text = text
        self.note = note
        self.tags = tags
    }
}

// MARK: - Color scheme for highlights
public enum HighlightColorScheme: String, CaseIterable, Hashable, Codable {
    case green, blue, purple, pink, orange

    public var textColor: NSColor {
        switch self {
        case .green: return NSColor(red: 140/255, green: 255/255, blue: 180/255, alpha: 1.0)
        case .blue: return NSColor(red: 26/255, green: 205/255, blue: 254/255, alpha: 1.0)
        case .purple: return NSColor(red: 180/255, green: 130/255, blue: 255/255, alpha: 1.0)
        case .pink: return NSColor(red: 255/255, green: 110/255, blue: 200/255, alpha: 1.0)
        case .orange: return NSColor(red: 255/255, green: 160/255, blue: 100/255, alpha: 1.0)
        }
    }

    public var idColor: NSColor {
        switch self {
        case .green: return NSColor(red: 100/255, green: 230/255, blue: 150/255, alpha: 1.0)
        case .blue: return NSColor(red: 22/255, green: 179/255, blue: 223/255, alpha: 1.0)
        case .purple: return NSColor(red: 150/255, green: 100/255, blue: 230/255, alpha: 1.0)
        case .pink: return NSColor(red: 240/255, green: 90/255, blue: 180/255, alpha: 1.0)
        case .orange: return NSColor(red: 230/255, green: 130/255, blue: 80/255, alpha: 1.0)
        }
    }

    public var displayName: String {
        switch self {
        case .green: return "Green"
        case .blue: return "Blue"
        case .purple: return "Purple"
        case .pink: return "Pink"
        case .orange: return "Orange"
        }
    }

    public var icon: String {
        switch self {
        case .green: return "🟢"
        case .blue: return "🔵"
        case .purple: return "🟣"
        case .pink: return "🩷"
        case .orange: return "🟠"
        }
    }
}

// MARK: - Highlight configuration
public struct HighlightConfiguration {
    public var maxHighlights: Int
    public var allowOverlappingHighlights: Bool
    public var autoSave: Bool
    public var autoSaveInterval: TimeInterval
    public var customColors: [HighlightColorScheme]
    public var enableNotifications: Bool

    public init(
        maxHighlights: Int = 1000,
        allowOverlappingHighlights: Bool = false,
        autoSave: Bool = true,
        autoSaveInterval: TimeInterval = 30.0,
        customColors: [HighlightColorScheme] = [],
        enableNotifications: Bool = true
    ) {
        self.maxHighlights = maxHighlights
        self.allowOverlappingHighlights = allowOverlappingHighlights
        self.autoSave = autoSave
        self.autoSaveInterval = autoSaveInterval
        self.customColors = customColors
        self.enableNotifications = enableNotifications
    }

    public static let `default` = HighlightConfiguration()
}

// MARK: - Highlight-related errors
public enum HighlightError: LocalizedError {
    case maxHighlightsReached(Int)
    case highlightNotFound(String)
    case persistenceError(String)
    case invalidData(String)
    case overlappingHighlight(String)

    public var errorDescription: String? {
        switch self {
        case .maxHighlightsReached(let max):
            return "Maximum number of highlights reached: \(max)"
        case .highlightNotFound(let uuid):
            return "Highlight with UUID \(uuid) not found"
        case .persistenceError(let message):
            return "Persistence error: \(message)"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        case .overlappingHighlight(let uuid):
            return "Overlapping highlight detected with UUID: \(uuid)"
        }
    }
}
