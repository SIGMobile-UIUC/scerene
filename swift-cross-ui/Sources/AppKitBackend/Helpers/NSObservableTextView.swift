import AppKit

public class NSObservableTextView: NSTextView, NSTextViewDelegate {
    var appliedFont: NSFont?        // Will use these for saving font and color states
    var appliedColor: NSColor?

    public func textDidChange(_ notification: Notification) {
        onEdit?(self)
    }

    var onEdit: ((NSTextView) -> Void)?
}
