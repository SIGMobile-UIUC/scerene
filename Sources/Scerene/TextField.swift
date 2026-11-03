//
//  TextField.swift
//  Scerene
//
//  Created by John on 11/3/26.
//

import AppKit
import SwiftCrossUI
import AppKitBackend

// I wanna make the cursor flash a certain color, but nothing
// is exposed for me to change that. I guess I'll have to change
// the internals.
struct TextField: View {
    @State var textInput: String = ""
    
    init(normal: Bool) {
        if (!normal) {
            AppKitBackend.useCaretEditor = true
        }
        //CaretTextView.addTextEditListener(listener: printString)
        //CaretTextView.addTextEditListener(listener: underLine)
        //CaretTextView.addTextEditListener(listener: applyCursor)
    }
    
    var body: some View {
        TextEditor(text: $textInput)
    }
    
    public func printString(textView: NSTextView) {
        let gottenString = textView.string
        print("Typed from view: \(gottenString)")
    }
    
    public func underLine(textView: NSTextView) {
        // Make sure we have a text storage object to manipulate
        guard let textStorage = textView.textStorage else { return }
        
        let fullRange = NSRange(location: 0, length: textStorage.length)
        
        // Apply the single-line underline attribute to the entire text length
        textStorage.beginEditing()
        textStorage.addAttribute(
            .underlineStyle,
            value: NSUnderlineStyle.single.rawValue,
            range: fullRange
        )
        textStorage.endEditing()
    }
    
    public func applyCursor(textView: NSTextView) {
        // Change the cursor color to whatever color you want (e.g., system red, or a custom NSColor)
        textView.insertionPointColor = .systemRed
        
        // Forces the cursor to redraw immediately with the new color and restart its blink cycle
        textView.updateInsertionPointStateAndRestartTimer(true)
    }
    
}
