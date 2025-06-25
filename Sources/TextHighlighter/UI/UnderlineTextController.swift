import AppKit

/// `UnderlineTextViewController`
///
/// EN: Manages the interaction between the highlight manager and the text view.
/// ES: Controla la interacción entre el gestor de highlights y la vista de texto.
public class UnderlineTextViewController: ObservableObject {

    /// EN: Reference to the managed text view.
    /// ES: Referencia a la vista de texto gestionada.
    public weak var textView: UnderlineTextView?

    /// EN: Currently selected highlight color scheme.
    /// ES: Esquema de color de resaltado seleccionado actualmente.
    @Published public var highlightColorScheme: HighlightColorScheme = .blue

    /// EN: Whether there are any selected verses.
    /// ES: Indica si hay versos seleccionados.
    @Published public var hasSelectedVerses: Bool = false

    /// EN: Last error that occurred.
    /// ES: Último error ocurrido.
    @Published public var lastError: HighlightError?

    /// EN: Public initializer.
    /// ES: Inicializador público.
    public init() {}

    /// EN: Applies all highlights from the manager to the text view.
    /// ES: Aplica todos los highlights del gestor a la vista de texto.
    public func applyHighlights(from manager: HighlightManager) {
        guard let textView = textView,
              let layoutManager = textView.layoutManager as? DotUnderlineLayoutManager else { return }

        layoutManager.highlightedVerseGlyphRanges.removeAll()
        layoutManager.highlightedIDGlyphRanges.removeAll()
        layoutManager.verseColorMap.removeAll()
        layoutManager.idColorMap.removeAll()

        let highlights = manager.getAllHighlights()

        for highlight in highlights {
            if let verseRange = textView.verseRangesById[highlight.uuid] {
                let glyphRange = layoutManager.glyphRange(forCharacterRange: verseRange, actualCharacterRange: nil)
                layoutManager.highlightedVerseGlyphRanges.append(glyphRange)
                layoutManager.verseColorMap[verseRange] = highlight.color.textColor
            }
            if let idRange = textView.idRangesById[highlight.uuid] {
                let glyphRange = layoutManager.glyphRange(forCharacterRange: idRange, actualCharacterRange: nil)
                layoutManager.highlightedIDGlyphRanges.append(glyphRange)
                layoutManager.idColorMap[idRange] = highlight.color.idColor
            }
        }

        textView.updateTextColors(underlinedVerses: Array(textView.selectedVerses))
        textView.setNeedsDisplay(textView.bounds)
        hasSelectedVerses = !(textView.selectedVerses.isEmpty)
    }

    /// EN: Converts underlined verses into highlights.
    /// ES: Convierte versos subrayados en highlights.
    public func convertUnderlinesToHighlights(manager: HighlightManager) {
        guard let textView = textView else { return }
        lastError = nil

        for uuid in textView.selectedVerses {
            let verseText = getVerseText(uuid: uuid, from: textView)
            do {
                try manager.setHighlight(uuid: uuid, color: highlightColorScheme, text: verseText)
            } catch {
                lastError = error as? HighlightError
                print("Error creating highlight for \(uuid): \(error)")
                return
            }
        }
        applyHighlights(from: manager)
    }

    /// EN: Removes highlights from the selected verses.
    /// ES: Elimina los highlights de los versos seleccionados.
    public func removeHighlightsFromSelected(manager: HighlightManager) {
        guard let textView = textView else { return }
        lastError = nil

        let uuidsToRemove = Array(textView.selectedVerses)
        for uuid in uuidsToRemove {
            do {
                try manager.removeHighlight(uuid: uuid)
            } catch {
                lastError = error as? HighlightError
                print("Error removing highlight for \(uuid): \(error)")
            }
        }
        clearUnderlines(textView: textView)
        applyHighlights(from: manager)
    }

    /// EN: Updates the color of selected highlights.
    /// ES: Actualiza el color de los highlights seleccionados.
    public func updateSelectedHighlightsColor(manager: HighlightManager, newColor: HighlightColorScheme) {
        guard let textView = textView else { return }
        lastError = nil

        for uuid in textView.selectedVerses {
            if manager.hasHighlight(uuid: uuid) {
                do {
                    try manager.updateHighlight(uuid: uuid, color: newColor)
                } catch {
                    lastError = error as? HighlightError
                    print("Error updating highlight color for \(uuid): \(error)")
                }
            }
        }
        applyHighlights(from: manager)
    }

    /// EN: Syncs the view with the highlight manager.
    /// ES: Sincroniza la vista con el gestor de highlights.
    public func syncWithManager(_ manager: HighlightManager) {
        applyHighlights(from: manager)
    }

    // MARK: - Private Helpers

    /// EN: Retrieves the text of a specific verse.
    /// ES: Obtiene el texto de un verso específico.
    private func getVerseText(uuid: String, from textView: UnderlineTextView) -> String {
        guard let range = textView.verseRangesById[uuid],
              let textStorage = textView.textStorage else {
            return ""
        }
        return textStorage.attributedSubstring(from: range).string.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// EN: Clears all underlines from selected verses.
    /// ES: Limpia todos los subrayados de los versos seleccionados.
    private func clearUnderlines(textView: UnderlineTextView) {
        guard let textStorage = textView.textStorage else { return }

        for uuid in textView.selectedVerses {
            if let range = textView.verseRangesById[uuid] {
                textStorage.removeAttribute(.underlineStyle, range: range)
                textStorage.removeAttribute(.underlineColor, range: range)
            }
        }

        textView.selectedVerses.removeAll()
        hasSelectedVerses = false
        textView.setNeedsDisplay(textView.bounds)
    }
}
