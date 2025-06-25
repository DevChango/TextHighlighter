import Foundation

// MARK: - Persistence Manager
/// EN: Handles saving, loading, and migrating highlight data.
/// ES: Maneja el guardado, carga y migración de datos de subrayado.
public class HighlightPersistenceManager {
    private let userDefaults = UserDefaults.standard
    private let highlightsKey = "TextHighlighter.SavedHighlights"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    /// EN: Saves highlights asynchronously.
    /// ES: Guarda los subrayados de forma asíncrona.
    public func saveHighlights(_ highlights: [HighlightData]) async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let data = try encoder.encode(highlights)
                userDefaults.set(data, forKey: highlightsKey)
                userDefaults.synchronize()
                continuation.resume()
            } catch {
                continuation.resume(throwing: HighlightError.persistenceError("Error encoding highlights: \(error.localizedDescription)"))
            }
        }
    }

    /// EN: Loads highlights asynchronously.
    /// ES: Carga los subrayados de forma asíncrona.
    public func loadHighlights() async throws -> [HighlightData] {
        return try await withCheckedThrowingContinuation { continuation in
            guard let data = userDefaults.data(forKey: highlightsKey) else {
                continuation.resume(returning: [])
                return
            }
            do {
                let highlights = try decoder.decode([HighlightData].self, from: data)
                continuation.resume(returning: highlights)
            } catch {
                continuation.resume(throwing: HighlightError.persistenceError("Error decoding highlights: \(error.localizedDescription)"))
            }
        }
    }

    /// EN: Saves highlights synchronously.
    /// ES: Guarda los subrayados de forma síncrona.
    public func saveHighlightsSync(_ highlights: [HighlightData]) throws {
        do {
            let data = try encoder.encode(highlights)
            userDefaults.set(data, forKey: highlightsKey)
            userDefaults.synchronize()
        } catch {
            throw HighlightError.persistenceError("Error encoding highlights: \(error.localizedDescription)")
        }
    }

    /// EN: Loads highlights synchronously.
    /// ES: Carga los subrayados de forma síncrona.
    public func loadHighlightsSync() throws -> [HighlightData] {
        guard let data = userDefaults.data(forKey: highlightsKey) else { return [] }
        do {
            return try decoder.decode([HighlightData].self, from: data)
        } catch {
            throw HighlightError.persistenceError("Error decoding highlights: \(error.localizedDescription)")
        }
    }

    /// EN: Clears all stored highlight data.
    /// ES: Elimina todos los datos guardados de subrayado.
    public func clearAllData() {
        userDefaults.removeObject(forKey: highlightsKey)
        userDefaults.synchronize()
    }

    /// EN: Checks if persisted data exists.
    /// ES: Verifica si existen datos guardados.
    public func hasPersistedData() -> Bool {
        return userDefaults.data(forKey: highlightsKey) != nil
    }

    /// EN: Performs migration if needed.
    /// ES: Realiza la migración si es necesario.
    public func migrateIfNeeded() {
        let currentVersion = userDefaults.integer(forKey: "TextHighlighter.DataVersion")
        let targetVersion = 1

        if currentVersion < targetVersion {
            performMigration(from: currentVersion, to: targetVersion)
            userDefaults.set(targetVersion, forKey: "TextHighlighter.DataVersion")
        }
    }

    private func performMigration(from oldVersion: Int, to newVersion: Int) {
        print("Migrating highlights data from version \(oldVersion) to \(newVersion)")
    }
}

// MARK: - Export Manager
/// EN: Handles exporting highlights to different formats.
/// ES: Maneja la exportación de subrayados a diferentes formatos.
public class HighlightExporter {
    private let encoder = JSONEncoder()

    public init() {
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    public func export(highlights: [HighlightData], format: ExportFormat) throws -> Data {
        switch format {
        case .json: return try exportAsJSON(highlights)
        case .csv: return try exportAsCSV(highlights)
        case .markdown: return try exportAsMarkdown(highlights)
        }
    }

    private func exportAsJSON(_ highlights: [HighlightData]) throws -> Data {
        return try encoder.encode(highlights)
    }

    private func exportAsCSV(_ highlights: [HighlightData]) throws -> Data {
        var csv = "UUID,Color,Text,Note,Tags,Created,Updated\n"
        let dateFormatter = ISO8601DateFormatter()
        for h in highlights {
            let escapedText = escapeCSVField(h.text)
            let escapedNote = escapeCSVField(h.note ?? "")
            let tags = h.tags.joined(separator: ";")
            let created = dateFormatter.string(from: h.createdAt)
            let updated = dateFormatter.string(from: h.updatedAt)
            csv += "\(h.uuid),\(h.color.rawValue),\(escapedText),\(escapedNote),\(tags),\(created),\(updated)\n"
        }
        guard let data = csv.data(using: .utf8) else {
            throw HighlightError.persistenceError("Failed to encode CSV data")
        }
        return data
    }

    private func exportAsMarkdown(_ highlights: [HighlightData]) throws -> Data {
        var md = "# Highlights Export\n\nGenerated on \(Date())\n\n"
        let grouped = Dictionary(grouping: highlights) { $0.color }
        for color in HighlightColorScheme.allCases {
            guard let group = grouped[color], !group.isEmpty else { continue }
            md += "## \(color.icon) \(color.displayName)\n\n"
            for h in group.sorted(by: { $0.createdAt < $1.createdAt }) {
                md += "### \(h.text)\n\n"
                if let note = h.note, !note.isEmpty {
                    md += "**Note:** \(note)\n\n"
                }
                if !h.tags.isEmpty {
                    md += "**Tags:** \(h.tags.joined(separator: ", "))\n\n"
                }
                md += "**Created:** \(DateFormatter.localizedString(from: h.createdAt, dateStyle: .medium, timeStyle: .short))\n\n---\n\n"
            }
        }
        guard let data = md.data(using: .utf8) else {
            throw HighlightError.persistenceError("Failed to encode Markdown data")
        }
        return data
    }

    private func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return field
    }
}

// MARK: - Import Manager
/// EN: Handles importing highlights from different formats.
/// ES: Maneja la importación de subrayados desde diferentes formatos.
public class HighlightImporter {
    private let decoder = JSONDecoder()

    public init() {
        decoder.dateDecodingStrategy = .iso8601
    }

    public func importFromJSON(_ data: Data) throws -> [HighlightData] {
        do {
            return try decoder.decode([HighlightData].self, from: data)
        } catch {
            throw HighlightError.invalidData("Invalid JSON format: \(error.localizedDescription)")
        }
    }

    public func importFromCSV(_ data: Data) throws -> [HighlightData] {
        guard let csvString = String(data: data, encoding: .utf8) else {
            throw HighlightError.invalidData("Invalid CSV encoding")
        }

        let lines = csvString.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard lines.count > 1 else {
            throw HighlightError.invalidData("CSV file must have header and at least one data row")
        }

        let dateFormatter = ISO8601DateFormatter()
        var highlights: [HighlightData] = []

        for line in lines.dropFirst() {
            let fields = parseCSVLine(line)
            guard fields.count >= 7,
                  let color = HighlightColorScheme(rawValue: fields[1]),
                  let created = dateFormatter.date(from: fields[5]),
                  let updated = dateFormatter.date(from: fields[6]) else { continue }
            let tags = fields[4].isEmpty ? [] : fields[4].components(separatedBy: ";")
            let note = fields[3].isEmpty ? nil : fields[3]
            let highlight = HighlightData(uuid: fields[0], color: color, text: fields[2], note: note, tags: tags)
            highlights.append(highlight)
        }
        return highlights
    }

    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var insideQuotes = false
        var i = line.startIndex

        while i < line.endIndex {
            let char = line[i]
            if char == "\"" {
                if insideQuotes && i < line.index(before: line.endIndex) && line[line.index(after: i)] == "\"" {
                    current += "\""
                    i = line.index(after: i)
                } else {
                    insideQuotes.toggle()
                }
            } else if char == "," && !insideQuotes {
                fields.append(current)
                current = ""
            } else {
                current += String(char)
            }
            i = line.index(after: i)
        }
        fields.append(current)
        return fields
    }
}
