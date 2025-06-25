import Foundation
import Combine

// MARK: - Enhanced HighlightManager with Persistence & Error Handling
/// EN: Central class to create, update and persist text highlights.
/// ES: Clase central para crear, actualizar y persistir resaltados de texto.
public final class HighlightManager: ObservableObject {

    // MARK: Published State
    @Published public private(set) var highlights: Set<HighlightData> = []
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var lastError: HighlightError?
    @Published public private(set) var statistics = HighlightStatistics()

    // MARK: Private helpers
    private let configuration: HighlightConfiguration
    private let persistenceManager: HighlightPersistenceManager
    private var autoSaveTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: Initialization
    /// EN: Public initializer with optional configuration.
    /// ES: Inicializador público con configuración opcional.
    public init(configuration: HighlightConfiguration = .default) {
        self.configuration = configuration
        self.persistenceManager = HighlightPersistenceManager()

        setupAutoSave()
        setupStatisticsObserver()
    }

    deinit { autoSaveTimer?.invalidate() }

    // MARK: - Core Operations
    /// EN: Create or update a highlight.
    /// ES: Crea o actualiza un resaltado.
    public func setHighlight(uuid: String, color: HighlightColorScheme, text: String, note: String? = nil, tags: [String] = []) throws {
        if !hasHighlight(uuid: uuid) && highlights.count >= configuration.maxHighlights {
            throw HighlightError.maxHighlightsReached(configuration.maxHighlights)
        }
        highlights = highlights.filter { $0.uuid != uuid }
        highlights.insert(HighlightData(uuid: uuid, color: color, text: text, note: note, tags: tags))
        if configuration.autoSave { saveHighlights() }
        updateStatistics()
    }

    /// EN: Update an existing highlight’s color / note / tags.
    /// ES: Actualiza color, nota o etiquetas de un resaltado existente.
    public func updateHighlight(uuid: String, color: HighlightColorScheme? = nil, note: String? = nil, tags: [String]? = nil) throws {
        guard let existing = highlights.first(where: { $0.uuid == uuid }) else {
            throw HighlightError.highlightNotFound(uuid)
        }
        highlights.remove(existing)
        highlights.insert(existing.updated(color: color, note: note, tags: tags))
        if configuration.autoSave { saveHighlights() }
        updateStatistics()
    }

    /// EN: Remove a single highlight.
    /// ES: Elimina un resaltado.
    public func removeHighlight(uuid: String) throws {
        let oldCount = highlights.count
        highlights = highlights.filter { $0.uuid != uuid }
        if highlights.count == oldCount {
            throw HighlightError.highlightNotFound(uuid)
        }
        if configuration.autoSave { saveHighlights() }
        updateStatistics()
    }

    /// EN: Remove multiple highlights.
    /// ES: Elimina múltiples resaltados.
    public func removeHighlights(uuids: [String]) {
        highlights = highlights.filter { !uuids.contains($0.uuid) }
        if configuration.autoSave { saveHighlights() }
        updateStatistics()
    }

    // MARK: - Query Helpers
    public func hasHighlight(uuid: String) -> Bool {
        highlights.contains { $0.uuid == uuid }
    }

    public func getHighlight(uuid: String) -> HighlightData? {
        highlights.first { $0.uuid == uuid }
    }

    public func getHighlightColor(uuid: String) -> HighlightColorScheme? {
        highlights.first { $0.uuid == uuid }?.color
    }

    public func getAllHighlights(sortedBy: HighlightSortOption = .createdDate) -> [HighlightData] {
        let array = Array(highlights)
        switch sortedBy {
        case .createdDate: return array.sorted { $0.createdAt > $1.createdAt }
        case .updatedDate: return array.sorted { $0.updatedAt > $1.updatedAt }
        case .color:       return array.sorted { $0.color.rawValue < $1.color.rawValue }
        case .text:        return array.sorted { $0.text < $1.text }
        }
    }

    public func searchHighlights(query: String) -> [HighlightData] {
        let q = query.lowercased()
        return highlights.filter {
            $0.text.lowercased().contains(q) ||
            $0.note?.lowercased().contains(q) == true ||
            $0.tags.contains { $0.lowercased().contains(q) }
        }
    }

    public func getHighlights(byColor color: HighlightColorScheme) -> [HighlightData] {
        highlights.filter { $0.color == color }
    }

    public func getHighlights(byTag tag: String) -> [HighlightData] {
        highlights.filter { $0.tags.contains(tag) }
    }

    public func getHighlights(from start: Date, to end: Date) -> [HighlightData] {
        highlights.filter { $0.createdAt >= start && $0.createdAt <= end }
    }

    public func clearAll() {
        highlights.removeAll()
        if configuration.autoSave { saveHighlights() }
        updateStatistics()
    }

    // MARK: - Persistence (internal)
    @MainActor
    public func loadHighlights() async {
        isLoading = true
        do {
            let items = try await persistenceManager.loadHighlights()
            highlights = Set(items)
            updateStatistics()
            isLoading = false
        } catch {
            lastError = .persistenceError(error.localizedDescription)
            isLoading = false
        }
    }

    private func saveHighlights() {
        Task {
            do {
                try await persistenceManager.saveHighlights(Array(highlights))
            } catch {
                await MainActor.run {
                    self.lastError = .persistenceError(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Auto-Save & Stats
    private func setupAutoSave() {
        guard configuration.autoSave else { return }
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: configuration.autoSaveInterval, repeats: true) { _ in
            self.saveHighlights()
        }
    }

    private func setupStatisticsObserver() {
        $highlights
            .sink { [weak self] _ in self?.updateStatistics() }
            .store(in: &cancellables)
    }

    private func updateStatistics() {
        statistics = HighlightStatistics(highlights: Array(highlights))
    }

    // MARK: - Export (Optional)
//    public func exportHighlights(format: ExportFormat = .json) throws -> Data {
//        try HighlightExporter().export(highlights: Array(highlights), format: format)
//    }

    // MARK: - Utility
    public func getAllTags() -> [String] {
        Set(highlights.flatMap { $0.tags }).sorted()
    }

    public func getColorDistribution() -> [HighlightColorScheme: Int] {
        highlights.reduce(into: [:]) { $0[$1.color, default: 0] += 1 }
    }
}

// MARK: - Supporting Types
public enum HighlightSortOption {
    case createdDate, updatedDate, color, text
}

public struct HighlightStatistics {
    public let totalHighlights: Int
    public let colorDistribution: [HighlightColorScheme: Int]
    public let totalTags: Int
    public let averageTextLength: Double
    public let oldestHighlight: Date?
    public let newestHighlight: Date?

    public init(highlights: [HighlightData] = []) {
        totalHighlights = highlights.count
        colorDistribution = highlights.reduce(into: [:]) { $0[$1.color, default: 0] += 1 }
        totalTags = Set(highlights.flatMap { $0.tags }).count
        averageTextLength = highlights.isEmpty ? 0 : Double(highlights.map(\.text.count).reduce(0, +)) / Double(highlights.count)
        oldestHighlight = highlights.map(\.createdAt).min()
        newestHighlight = highlights.map(\.createdAt).max()
    }
}

public enum ExportFormat {
    case json, csv, markdown
}
