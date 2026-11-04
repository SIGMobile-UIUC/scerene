import AppKit
@_spi(Backends) import SwiftCrossUI

extension AppKitBackend: BackendFeatures.TextEditors {

    public static var useCaretEditor: Bool = false
    public func createTextEditor() -> Widget {
        let textEditor: NSTextView
        if (Self.useCaretEditor) {
            textEditor = CaretTextView()
        } else {
            textEditor = NSObservableTextView()
        }

        textEditor.drawsBackground = false
        textEditor.delegate = textEditor as? any NSTextViewDelegate
        textEditor.allowsUndo = true
        textEditor.isRichText = false
        textEditor.textContainerInset = NSSize(width: 80, height: 80)       // Start the editor with an indent relative to the window
        textEditor.textContainer?.lineFragmentPadding = 0
        return textEditor
    }

    public func updateTextEditor(
        _ textEditor: Widget,
        environment: EnvironmentValues,
        onChange: @escaping (String) -> Void
    ) {
        let textEditor = textEditor as! NSObservableTextView
        textEditor.onEdit = { textView in
            onChange(self.getContent(ofTextEditor: textView))
        }
        
        // appliedFont is a note we keep to ourselves of the
        // most recently used font. We only change the textEditor's .font
        // attribute if there is different resolved font.
        let resolvedFont = Self.font(for: environment.resolvedFont)
        if textEditor.appliedFont != resolvedFont {
            textEditor.appliedFont = resolvedFont
            textEditor.font = resolvedFont
        }
        
        textEditor.appearance = environment.colorScheme.nsAppearance
        textEditor.isEditable = environment.isEnabled

        // Since we are using a black background right now, keep this
        // here temporarily. However, we may want to make this pickable later.
        let color = NSColor.white
        if textEditor.appliedColor != color {
            textEditor.appliedColor = color
            textEditor.textColor = color
        }
        
        

        if #available(macOS 14, *) {
            textEditor.contentType =
                switch environment.textContentType {
                    case .url:
                        .URL
                    case .phoneNumber:
                        .telephoneNumber
                    case .name:
                        .name
                    case .emailAddress:
                        .emailAddress
                    case .text, .digits(_), .decimal(_):
                        nil
                }
        }
    }

    public func setContent(ofTextEditor textEditor: Widget, to content: String) {
        let textView = textEditor as! NSTextView
        if textView.string != content {     // Only change the string if the content is new,
            textView.string = content       // Not if setContent was called from a font change or something
        }
    }

    public func getContent(ofTextEditor textEditor: Widget) -> String {
        (textEditor as! NSTextView).string
    }
}
