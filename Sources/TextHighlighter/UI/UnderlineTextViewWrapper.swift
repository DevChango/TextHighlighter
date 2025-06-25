import SwiftUI
import AppKit

public struct UnderlineTextViewWrapper: NSViewRepresentable {
    public var verses: [[String: Any]]
    public var lineSpacing: CGFloat
    public var horizontalSpacing: CGFloat = 10
    public var underlineColor: NSColor
    public var underlineColorDark: NSColor
    public var underlineYOffset: CGFloat
    public var fontName: String
    public var fontSize: CGFloat
    public var verseTextColor: NSColor
    public var verseTextColorDark: NSColor
    public var idTextColor: NSColor
    public var idTextColorDark: NSColor
    public var onVerseClick: ((String) -> Void)?
        
    public var controller: UnderlineTextViewController
    public var highlightManager: HighlightManager
    
    public init(
            verses: [[String: Any]],
            lineSpacing: CGFloat,
            horizontalSpacing: CGFloat = 10,
            underlineColor: NSColor,
            underlineColorDark: NSColor,
            underlineYOffset: CGFloat,
            fontName: String,
            fontSize: CGFloat,
            verseTextColor: NSColor,
            verseTextColorDark: NSColor,
            idTextColor: NSColor,
            idTextColorDark: NSColor,
            onVerseClick: ((String) -> Void)?,
            controller: UnderlineTextViewController,
            highlightManager: HighlightManager
        ) {
            self.verses = verses
            self.lineSpacing = lineSpacing
            self.horizontalSpacing = horizontalSpacing
            self.underlineColor = underlineColor
            self.underlineColorDark = underlineColorDark
            self.underlineYOffset = underlineYOffset
            self.fontName = fontName
            self.fontSize = fontSize
            self.verseTextColor = verseTextColor
            self.verseTextColorDark = verseTextColorDark
            self.idTextColor = idTextColor
            self.idTextColorDark = idTextColorDark
            self.onVerseClick = onVerseClick
            self.controller = controller
            self.highlightManager = highlightManager
        }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public func makeNSView(context: Context) -> NSScrollView {
        let font = NSFont(name: fontName, size: fontSize) ?? NSFont.systemFont(ofSize: fontSize)
        let textStorage = NSTextStorage()
        let layoutManager = DotUnderlineLayoutManager()
        layoutManager.underlineYOffset = underlineYOffset

        let textContainer = NSTextContainer(size: NSSize(width: 600, height: CGFloat.greatestFiniteMagnitude))
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        let textView = UnderlineTextView(frame: .zero, textContainer: textContainer)

        // Configure base colors
        textView.verseTextColorLightBase = verseTextColor
        textView.verseTextColorDarkBase = verseTextColorDark
        textView.idTextColorLightBase = idTextColor
        textView.idTextColorDarkBase = idTextColorDark
        textView.underlineColorLightBase = underlineColor
        textView.underlineColorDarkBase = underlineColorDark

        // Configure properties
        textView.usedFont = font
        textView.onVerseClick = onVerseClick
        textView.horizontalSpacing = horizontalSpacing
        textView.lineSpacing = lineSpacing
        
        textView.highlightManager = highlightManager
        controller.textView = textView
        textView.controller = controller

        // Load verses
        textView.setVersesFromAPI(verses)

        // Visual configuration
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.textContainerInset = NSSize(width: 10, height: 10)
        textView.isEditable = false
        textView.isSelectable = true
        textView.isVerticallyResizable = true
        textView.maxSize = NSSize(width: .greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.autoresizingMask = [.width]

        textContainer.widthTracksTextView = true
        textContainer.lineBreakMode = .byWordWrapping
        textView.isHorizontallyResizable = false

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.drawsBackground = false
        scrollView.backgroundColor = .clear

        return scrollView
    }

    public func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? UnderlineTextView else { return }
        
        var needsRedraw = false

        if textView.lineSpacing != lineSpacing {
            textView.lineSpacing = lineSpacing
            needsRedraw = true
        }

        if textView.horizontalSpacing != horizontalSpacing {
            textView.horizontalSpacing = horizontalSpacing
            needsRedraw = true
        }

        let colorsChanged = textView.updateColorsFromSwiftUI(
            verseColor: verseTextColor,
            verseColorDark: verseTextColorDark,
            idColor: idTextColor,
            idColorDark: idTextColorDark
        )

        if textView.underlineColorLightBase != underlineColor {
            textView.underlineColorLightBase = underlineColor
            needsRedraw = true
        }

        if textView.underlineColorDarkBase != underlineColorDark {
            textView.underlineColorDarkBase = underlineColorDark
            needsRedraw = true
        }

        if needsRedraw || colorsChanged {
            textView.setNeedsDisplay(textView.visibleRect)
        }
        
        
    }
}
