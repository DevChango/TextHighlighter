import AppKit

public class UnderlineTextView: NSTextView {
    
    public weak var controller : UnderlineTextViewController?
    
    public var selectedVerses: Set<String> = []
    public var underlineColor: NSColor = .systemPink
    public var underlineColorDark: NSColor = .systemPink

    public var verseTextColor: NSColor = .white
    public var verseTextColorDark: NSColor = .white
    public var idTextColor: NSColor = .gray
    public var idTextColorDark: NSColor = .gray

    public var verseTextColorLightBase: NSColor = .white
    public var verseTextColorDarkBase: NSColor = .white
    public var idTextColorLightBase: NSColor = .gray
    public var idTextColorDarkBase: NSColor = .gray
    public var underlineColorLightBase: NSColor = .systemBlue
    public var underlineColorDarkBase: NSColor = .systemTeal

    public var verseRangesById: [String: NSRange] = [:]
    public var idRangesById: [String: NSRange] = [:]
    public var onVerseClick: ((String) -> Void)?
    public var horizontalSpacing: CGFloat = 10
    public var lineSpacing: CGFloat = 0

    public var highlightManager: HighlightManager?

    public var usedFont: NSFont = NSFont.systemFont(ofSize: 16)
    public var currentVerses: [[String: Any]] = []
    public var selectedVerseUUID: String?

    private var isDarkMode: Bool {
        return effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }

        // MARK: - Load Verses
    public func setVersesFromAPI(_ verses: [[String: Any]]) {
        currentVerses = verses

        let fullText = NSMutableAttributedString()
        verseRangesById.removeAll()
        idRangesById.removeAll()

        let idColor = isDarkMode ? idTextColorDarkBase : idTextColorLightBase
        let verseColor = isDarkMode ? verseTextColorDarkBase : verseTextColorLightBase

        for (index, verse) in verses.enumerated() {
            guard let uuid = verse["uuid"] as? String,
                    let id = verse["id"] as? Int,
                    let text = verse["texto"] as? String else { continue }

            let idString = " \(id). "
            let idAttr = NSMutableAttributedString(
                string: idString,
                attributes: [
                    .font: NSFont.systemFont(ofSize: 10),
                    .foregroundColor: idColor,
                    .baselineOffset: 6
                ]
            )

            let textAttr = NSMutableAttributedString(
                string: " \(text)",
                attributes: [
                    .font: usedFont,
                    .foregroundColor: verseColor
                ]
            )

            let paragraphStyle = NSMutableParagraphStyle()
            if lineSpacing > 0 { paragraphStyle.lineSpacing = lineSpacing }

            idAttr.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: idAttr.length))
            textAttr.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: textAttr.length))

            let start = fullText.length
            idRangesById[uuid] = NSRange(location: start, length: idAttr.length)
            verseRangesById[uuid] = NSRange(location: start + idAttr.length, length: textAttr.length)

            fullText.append(idAttr)
            fullText.append(textAttr)

            if index < verses.count - 1 {
                fullText.append(NSAttributedString(string: " "))
            }
        }

        self.textStorage?.setAttributedString(fullText)
        self.setNeedsDisplay(bounds)
    }

    // MARK: - Interactive Underline
    /// Toggles the underline for a given verse.
    /// Alterna el subrayado para un verso dado.
    func toggleUnderline(for uuid: String) {
        guard let range = verseRangesById[uuid],
              let textStorage = self.textStorage else { return }

        let currentAttributes = textStorage.attributes(at: range.location, effectiveRange: nil)
        let currentStyle = currentAttributes[.underlineStyle] as? Int ?? 0

        let underlineColor = isDarkMode ? underlineColorDarkBase : underlineColorLightBase


        if NSUnderlineStyle(rawValue: currentStyle).contains(.patternLargeDot) {
            textStorage.removeAttribute(.underlineStyle, range: range)
            textStorage.removeAttribute(.underlineColor, range: range)
            selectedVerses.remove(uuid)
        } else {
            let style = NSUnderlineStyle.single.rawValue | NSUnderlineStyle.patternLargeDot.rawValue
            textStorage.addAttribute(.underlineStyle, value: style, range: range)
            textStorage.addAttribute(.underlineColor, value: underlineColor, range: range)
            selectedVerses.insert(uuid)
        }
        
        controller?.objectWillChange.send()

        layoutManager?.invalidateLayout(forCharacterRange: range, actualCharacterRange: nil)
        setNeedsDisplay(visibleRect)
    }
    
    /// Handles mouse clicks to toggle underlines on verse interaction.
    /// Maneja clics del mouse para alternar subrayado al interactuar con versos.
    public override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        let point = convert(event.locationInWindow, from: nil)

        guard let layoutManager = layoutManager,
              let textContainer = textContainer else { return }

        let containerOrigin = textContainerOrigin
        let pointInContainer = NSPoint(x: point.x - containerOrigin.x, y: point.y - containerOrigin.y)
        let glyphIndex = layoutManager.glyphIndex(for: pointInContainer, in: textContainer)
        let charIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)

        for (uuid, range) in verseRangesById {
            if NSLocationInRange(charIndex, range) {
                toggleUnderline(for: uuid)
                onVerseClick?(uuid)
                selectedVerseUUID = uuid
                break
            }
        }
    }
    
    /// Highlights verse IDs based on UUIDs using the layout manager.
    /// Resalta los IDs de versos según sus UUIDs usando el layout manager.
    public func highlightIDs(_ uuids: [String]) {
        guard let layoutManager = self.layoutManager as? DotUnderlineLayoutManager else { return }
        layoutManager.highlightedIDGlyphRanges.removeAll()

        for uuid in uuids {
            if let charRange = idRangesById[uuid] {
                let glyphRange = layoutManager.glyphRange(forCharacterRange: charRange, actualCharacterRange: nil)
                layoutManager.highlightedIDGlyphRanges.append(glyphRange)
            }
        }

        setNeedsDisplay(bounds)
    }
    
    /// Updates the text color of verses and their IDs, considering highlights and underlines.
    /// Actualiza el color de texto de los versos y sus IDs, considerando highlights y subrayados.
    func updateTextColors(underlinedVerses: [String] = []) {
        guard let textStorage = self.textStorage else { return }

        let isDark = isDarkMode
        let baseVerseColor = isDark ? verseTextColorDarkBase : verseTextColorLightBase
        let baseIDColor = isDark ? idTextColorDarkBase : idTextColorLightBase

        let paragraphStyle = NSMutableParagraphStyle()
        if lineSpacing > 0 {
            paragraphStyle.lineSpacing = lineSpacing
        }

        let currentHighlights = highlightManager?.getAllHighlights() ?? []

        // Update verse colors
        for (uuid, range) in verseRangesById {
            var attributes: [NSAttributedString.Key: Any] = [
                .paragraphStyle: paragraphStyle
            ]

            if currentHighlights.contains(where: { $0.uuid == uuid }) {
                attributes[.foregroundColor] = NSColor.black
            } else {
                attributes[.foregroundColor] = underlinedVerses.contains(uuid) ? baseVerseColor : baseVerseColor
            }

            textStorage.removeAttribute(.foregroundColor, range: range)
            textStorage.addAttributes(attributes, range: range)
        }

        // Update ID colors
        for (uuid, range) in idRangesById {
            var attributes: [NSAttributedString.Key: Any] = [
                .paragraphStyle: paragraphStyle
            ]

            if currentHighlights.contains(where: { $0.uuid == uuid }) {
                attributes[.foregroundColor] = NSColor.black
            } else {
                attributes[.foregroundColor] = underlinedVerses.contains(uuid) ? baseIDColor : baseIDColor
            }

            textStorage.removeAttribute(.foregroundColor, range: range)
            textStorage.addAttributes(attributes, range: range)
        }

        self.setNeedsDisplay(bounds)
    }
    
    

    /// Updates text colors from SwiftUI values (light/dark mode aware).
    /// Actualiza los colores del texto desde valores de SwiftUI (considera modo claro/oscuro).
    @discardableResult
    public func updateColorsFromSwiftUI(
        verseColor: NSColor,
        verseColorDark: NSColor,
        idColor: NSColor,
        idColorDark: NSColor
    ) -> Bool {
        var changed = false

        if self.verseTextColorLightBase != verseColor {
            self.verseTextColorLightBase = verseColor
            changed = true
        }

        if self.verseTextColorDarkBase != verseColorDark {
            self.verseTextColorDarkBase = verseColorDark
            changed = true
        }

        if self.idTextColorLightBase != idColor {
            self.idTextColorLightBase = idColor
            changed = true
        }

        if self.idTextColorDarkBase != idColorDark {
            self.idTextColorDarkBase = idColorDark
            changed = true
        }

        let isDark = isDarkMode
        let newVerseColor = isDark ? verseColorDark : verseColor
        let newIDColor = isDark ? idColorDark : idColor

        if self.verseTextColor != newVerseColor {
            self.verseTextColor = newVerseColor
            changed = true
        }

        if self.idTextColor != newIDColor {
            self.idTextColor = newIDColor
            changed = true
        }

        if changed {
            updateTextColors(underlinedVerses: Array(selectedVerses))
        }

        return changed
    }
    

    /// Called when the system appearance changes (e.g., light/dark mode).
    /// Llamado cuando cambia la apariencia del sistema (modo claro/oscuro).
    public override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()

        let isDark = isDarkMode

        // Update base colors
        verseTextColor = isDark ? verseTextColorDarkBase : verseTextColorLightBase
        idTextColor = isDark ? idTextColorDarkBase : idTextColorLightBase
        underlineColor = isDark ? underlineColorDarkBase : underlineColorLightBase

        // Save highlights before reloading content
        var highlightedGlyphRanges: [NSRange] = []
        var highlightedIDGlyphRanges: [NSRange] = []

        if let layoutManager = self.layoutManager as? DotUnderlineLayoutManager {
            highlightedGlyphRanges = layoutManager.highlightedVerseGlyphRanges
            highlightedIDGlyphRanges = layoutManager.highlightedIDGlyphRanges
        }

        let previouslyUnderlined = Set(selectedVerses)

        // Reload content with new colors
        setVersesFromAPI(currentVerses)

        // Restore highlights
        if let layoutManager = self.layoutManager as? DotUnderlineLayoutManager {
            layoutManager.highlightedVerseGlyphRanges = highlightedGlyphRanges
            layoutManager.highlightedIDGlyphRanges = highlightedIDGlyphRanges
        }

        // Restore underlines
        selectedVerses = previouslyUnderlined
        for uuid in previouslyUnderlined {
            if let range = verseRangesById[uuid], let textStorage = self.textStorage {
                let underlineColor = isDark ? underlineColorDarkBase : underlineColorLightBase
                let style = NSUnderlineStyle.single.rawValue | NSUnderlineStyle.patternLargeDot.rawValue
                textStorage.addAttribute(.underlineStyle, value: style, range: range)
                textStorage.addAttribute(.underlineColor, value: underlineColor, range: range)
            }
        }

        updateTextColors(underlinedVerses: Array(selectedVerses))
    }
    
    /// Clears all underline styles from the text view.
    /// Limpia todos los estilos de subrayado del text view.
    public func clearAllUnderlines() {
        guard let textStorage = self.textStorage else { return }

        for (_, range) in verseRangesById {
            textStorage.removeAttribute(.underlineStyle, range: range)
            textStorage.removeAttribute(.underlineColor, range: range)
        }

        selectedVerses.removeAll()
        setNeedsDisplay(bounds)
    }
        
    /// Checks if a verse is currently highlighted.
    /// Verifica si un verso está actualmente highlighteado.
    func isVerseHighlighted(_ uuid: String) -> Bool {
        guard let manager = highlightManager else { return false }
        return manager.hasHighlight(uuid: uuid)
    }
        
    /// Gets the highlight color for a specific verse.
    /// Obtiene el color de highlight de un verso específico.
    func getVerseHighlightColor(_ uuid: String) -> HighlightColorScheme? {
        guard let manager = highlightManager else { return nil }
        return manager.getHighlightColor(uuid: uuid)
    }
        
        /// Método mejorado para actualizar colores que considera los highlights
    /// Improved text color update logic that considers highlights.
    /// Lógica mejorada para actualizar colores de texto considerando highlights.
    func updateTextColorsImproved() {
        guard let textStorage = self.textStorage else { return }

        let isDark = isDarkMode
        let baseVerseColor = isDark ? verseTextColorDarkBase : verseTextColorLightBase
        let baseIDColor = isDark ? idTextColorDarkBase : idTextColorLightBase

        let paragraphStyle = NSMutableParagraphStyle()
        if lineSpacing > 0 {
            paragraphStyle.lineSpacing = lineSpacing
        }

        let currentHighlights = highlightManager?.getAllHighlights() ?? []
        let highlightedUUIDs = Set(currentHighlights.map { $0.uuid })

        // Update verse colors
        for (uuid, range) in verseRangesById {
            var attributes: [NSAttributedString.Key: Any] = [.paragraphStyle: paragraphStyle]

            attributes[.foregroundColor] = highlightedUUIDs.contains(uuid)
                ? NSColor.black
                : baseVerseColor

            textStorage.removeAttribute(.foregroundColor, range: range)
            textStorage.addAttributes(attributes, range: range)
        }

        // Update ID colors
        for (uuid, range) in idRangesById {
            var attributes: [NSAttributedString.Key: Any] = [.paragraphStyle: paragraphStyle]

            attributes[.foregroundColor] = highlightedUUIDs.contains(uuid)
                ? NSColor.black
                : baseIDColor

            textStorage.removeAttribute(.foregroundColor, range: range)
            textStorage.addAttributes(attributes, range: range)
        }

        self.setNeedsDisplay(bounds)
    }
        
    /// Syncs visual highlight state with the highlight manager.
    /// Sincroniza el estado visual de highlights con el gestor.
    public func syncWithHighlightManager() {
        updateTextColorsImproved()
    }

}

extension UnderlineTextView: NSTextStorageDelegate {}
