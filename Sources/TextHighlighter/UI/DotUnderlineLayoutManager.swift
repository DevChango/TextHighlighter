import AppKit

// MARK: - Custom underline style
public extension NSUnderlineStyle {
    /// EN: Custom underline style using large dots
    /// ES: Estilo de subrayado personalizado usando puntos grandes
    static var patternLargeDot: NSUnderlineStyle {
        return NSUnderlineStyle(rawValue: 0x11)
    }
}

// MARK: - Custom Layout Manager for Highlights
/// EN: Custom layout manager for drawing highlights and dotted underlines.
/// ES: Layout manager personalizado para dibujar highlights y subrayados punteados.
public class DotUnderlineLayoutManager: NSLayoutManager {

    public var verseGlyphRanges: [NSRange] = []
    public var underlineYOffset: CGFloat = 0
    public var highlightedVerseGlyphRanges: [NSRange] = []
    public var highlightedIDGlyphRanges: [NSRange] = []

    public var verseHighlightColor: NSColor = .systemBlue
    public var idHighlightColor: NSColor = .systemTeal

    public var verseColorMap: [NSRange: NSColor] = [:]
    public var idColorMap: [NSRange: NSColor] = [:]

    /// EN: Draw dotted underline for a specific glyph range.
    /// ES: Dibuja un subrayado punteado para un rango específico de glifos.
    public override func drawUnderline(forGlyphRange glyphRange: NSRange,
                                       underlineType: NSUnderlineStyle,
                                       baselineOffset: CGFloat,
                                       lineFragmentRect: CGRect,
                                       lineFragmentGlyphRange: NSRange,
                                       containerOrigin: CGPoint) {

        if underlineType.rawValue == NSUnderlineStyle.patternLargeDot.rawValue {
            guard let textContainer = textContainer(forGlyphAt: glyphRange.location, effectiveRange: nil),
                  let textStorage = self.textStorage else { return }

            var glyphIndex = glyphRange.location
            while glyphIndex < NSMaxRange(glyphRange) {
                var effectiveRange = NSRange(location: 0, length: 0)

                let fragmentRect = lineFragmentUsedRect(forGlyphAt: glyphIndex, effectiveRange: &effectiveRange, withoutAdditionalLayout: true)
                let offsetRect = fragmentRect.offsetBy(dx: containerOrigin.x, dy: containerOrigin.y)

                let usedRange = NSIntersectionRange(glyphRange, effectiveRange)
                if usedRange.length == 0 {
                    glyphIndex = NSMaxRange(effectiveRange)
                    continue
                }

                var firstChar = usedRange.location
                var lastChar = NSMaxRange(usedRange) - 1

                while firstChar < NSMaxRange(usedRange),
                      let char = textStorage.string[firstChar],
                      char.isWhitespace || textStorage.attribute(.baselineOffset, at: firstChar, effectiveRange: nil) != nil {
                    firstChar += 1
                }

                while lastChar >= usedRange.location,
                      let char = textStorage.string[firstChar],
                      char.isWhitespace {
                    lastChar -= 1
                }

                if firstChar > lastChar {
                    glyphIndex = NSMaxRange(effectiveRange)
                    continue
                }

                let glyphStart = self.glyphIndexForCharacter(at: firstChar)
                let glyphEnd = self.glyphIndexForCharacter(at: lastChar)

                let startX = location(forGlyphAt: glyphStart).x + containerOrigin.x
                let lastGlyphRect = boundingRect(forGlyphRange: NSRange(location: glyphEnd, length: 1), in: textContainer)
                let endX = location(forGlyphAt: glyphEnd).x + containerOrigin.x + lastGlyphRect.width

                let font = textStorage.attribute(.font, at: firstChar, effectiveRange: nil) as? NSFont ?? .systemFont(ofSize: 16)
                let underlineY = offsetRect.minY + font.ascender + underlineYOffset

                let path = NSBezierPath()
                path.lineWidth = 3.0
                path.setLineDash([0.1, 6.0], count: 2, phase: 0)
                path.lineCapStyle = .round
                path.move(to: CGPoint(x: startX, y: underlineY))
                path.line(to: CGPoint(x: endX, y: underlineY))

                let color = textStorage.attribute(.underlineColor, at: usedRange.location, effectiveRange: nil) as? NSColor ?? .labelColor
                color.setStroke()
                path.stroke()

                glyphIndex = NSMaxRange(effectiveRange)
            }
        } else {
            super.drawUnderline(forGlyphRange: glyphRange,
                                underlineType: underlineType,
                                baselineOffset: baselineOffset,
                                lineFragmentRect: lineFragmentRect,
                                lineFragmentGlyphRange: lineFragmentGlyphRange,
                                containerOrigin: containerOrigin)
        }
    }

    /// EN: Draw custom highlight background for glyph ranges.
    /// ES: Dibuja el fondo de los highlights personalizados para los rangos de glifos.
    public override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)

        func drawHighlight(_ glyphRanges: [NSRange], color: NSColor, roundLeft: Bool = false, roundRight: Bool = false) {
            for highlightRange in glyphRanges {
                let intersectedRange = NSIntersectionRange(glyphsToShow, highlightRange)
                if intersectedRange.length == 0 { continue }

                guard let textContainer = self.textContainers.first else { continue }

                var glyphIndex = intersectedRange.location
                while glyphIndex < NSMaxRange(intersectedRange) {
                    var effectiveRange = NSRange(location: 0, length: 0)

                    let fragmentRect = lineFragmentUsedRect(forGlyphAt: glyphIndex,
                                                            effectiveRange: &effectiveRange,
                                                            withoutAdditionalLayout: true)
                    let offsetRect = fragmentRect.offsetBy(dx: origin.x, dy: origin.y)

                    let usedRange = NSIntersectionRange(intersectedRange, effectiveRange)
                    if usedRange.length == 0 {
                        glyphIndex = NSMaxRange(effectiveRange)
                        continue
                    }

                    let startX = location(forGlyphAt: usedRange.location).x + origin.x
                    let lastGlyphRect = boundingRect(forGlyphRange: NSRange(location: NSMaxRange(usedRange) - 1, length: 1), in: textContainer)
                    let endX = location(forGlyphAt: NSMaxRange(usedRange) - 1).x + origin.x + lastGlyphRect.width

                    var textCharIndex = usedRange.location
                    while textCharIndex < NSMaxRange(usedRange) {
                        if let baselineOffset = textStorage?.attribute(.baselineOffset, at: textCharIndex, effectiveRange: nil) as? NSNumber,
                           baselineOffset.doubleValue != 0 {
                            textCharIndex += 1
                        } else {
                            break
                        }
                    }

                    let font = textStorage?.attribute(.font, at: textCharIndex, effectiveRange: nil) as? NSFont ?? .systemFont(ofSize: 16)
                    let height: CGFloat = font.ascender + abs(font.descender) + 4

                    let highlightRect = CGRect(x: startX, y: offsetRect.minY, width: max(endX - startX, 1), height: height)

                    let path = customRoundedRect(highlightRect,
                                                 roundTopLeft: roundLeft,
                                                 roundTopRight: roundRight,
                                                 roundBottomLeft: roundLeft,
                                                 roundBottomRight: roundRight,
                                                 radius: 6)

                    color.setFill()
                    path.fill()

                    glyphIndex = NSMaxRange(effectiveRange)
                }
            }
        }

        for range in highlightedIDGlyphRanges {
            let color = idColorMap[range] ?? idHighlightColor
            drawHighlight([range], color: color, roundLeft: true, roundRight: false)
        }

        for range in highlightedVerseGlyphRanges {
            let color = verseColorMap[range] ?? verseHighlightColor
            drawHighlight([range], color: color, roundLeft: false, roundRight: true)
        }
    }
}

    // MARK: - Custom Rounded Highlight Shape
    /// EN: Creates a rounded rectangle path with selective corner rounding.
    /// ES: Crea un path de rectángulo redondeado con esquinas seleccionables.
    public func customRoundedRect(_ rect: CGRect,
                                  roundTopLeft: Bool,
                                  roundTopRight: Bool,
                                  roundBottomLeft: Bool,
                                  roundBottomRight: Bool,
                                  radius: CGFloat) -> NSBezierPath {
        let path = NSBezierPath()
        let minX = rect.minX, maxX = rect.maxX
        let minY = rect.minY, maxY = rect.maxY

        path.move(to: CGPoint(x: minX + (roundBottomLeft ? radius : 0), y: minY))
        path.line(to: CGPoint(x: maxX - (roundBottomRight ? radius : 0), y: minY))

        if roundBottomRight {
            path.curve(to: CGPoint(x: maxX, y: minY + radius),
                       controlPoint1: CGPoint(x: maxX - radius * 0.5, y: minY),
                       controlPoint2: CGPoint(x: maxX, y: minY + radius * 0.5))
        } else {
            path.line(to: CGPoint(x: maxX, y: minY))
        }

        path.line(to: CGPoint(x: maxX, y: maxY - (roundTopRight ? radius : 0)))
        if roundTopRight {
            path.curve(to: CGPoint(x: maxX - radius, y: maxY),
                       controlPoint1: CGPoint(x: maxX, y: maxY - radius * 0.5),
                       controlPoint2: CGPoint(x: maxX - radius * 0.5, y: maxY))
        } else {
            path.line(to: CGPoint(x: maxX, y: maxY))
        }

        path.line(to: CGPoint(x: minX + (roundTopLeft ? radius : 0), y: maxY))
        if roundTopLeft {
            path.curve(to: CGPoint(x: minX, y: maxY - radius),
                       controlPoint1: CGPoint(x: minX + radius * 0.5, y: maxY),
                       controlPoint2: CGPoint(x: minX, y: maxY - radius * 0.5))
        } else {
            path.line(to: CGPoint(x: minX, y: maxY))
        }

        path.line(to: CGPoint(x: minX, y: minY + (roundBottomLeft ? radius : 0)))
        if roundBottomLeft {
            path.curve(to: CGPoint(x: minX + radius, y: minY),
                       controlPoint1: CGPoint(x: minX, y: minY + radius * 0.5),
                       controlPoint2: CGPoint(x: minX + radius * 0.5, y: minY))
        } else {
            path.line(to: CGPoint(x: minX, y: minY))
        }

        path.close()
        return path
    }

    // MARK: - String Safe Subscript
    /// EN: Safe subscript to access characters by index.
    /// ES: Subíndice seguro para acceder a caracteres por índice.
    extension String {
        subscript(_ i: Int) -> Character? {
            guard i >= 0 && i < self.count else { return nil }
            return self[index(startIndex, offsetBy: i)]
        }
}
