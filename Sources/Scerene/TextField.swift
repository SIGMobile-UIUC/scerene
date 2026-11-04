//
//  TextField.swift
//  Scerene
//
//  Created by John on 11/3/26.
//

import AppKit
import SwiftCrossUI
import AppKitBackend
import Markdown

// I wanna make the cursor flash a certain color, but nothing
// is exposed for me to change that. I guess I'll have to change
// the internals.


struct HeadingRangeCollector: MarkupWalker {
    var rangeDetails: [(level: Int, text: String, range: SourceRange?)] = []
    
    // Automatically called by the walker whenever a heading node is encountered
    mutating func visitHeading(_ heading: Heading) {
        let headingText = heading.format().trimmingCharacters(in: .whitespacesAndNewlines)
        rangeDetails.append((
            level: heading.level,       // The number of hashtags
            text: headingText,          // The actual text, may do post-processing on this
            range: heading.range        // The range within the string. 1:1..<1:10, for example, denotes
                                        // the first ten characters of the first line
        ))
        descendInto(heading)
    }
}


struct TextField: View {
    @State var textInput: String = ""
    
    init(normal: Bool) {
        if (!normal) {
            AppKitBackend.useCaretEditor = true
        }
        
        CaretTextView.addTextEditListener(listener: updateHeadingFont)
        //CaretTextView.addTextEditListener(listener: printString)
        //CaretTextView.addTextEditListener(listener: underLine)
        //CaretTextView.addTextEditListener(listener: applyCursor)
    }
    
    var body: some View {
        TextEditor(text: $textInput)
    }
    
    private func nsRange(from sourceRange: Range<SourceLocation>, in text: String) -> NSRange? {
        // Convert the Markdown SourceRanges into NSRanges for use by AppKit
        let lines = text.components(separatedBy: .newlines)
        
        func offset(for location: SourceLocation) -> Int? {
            guard location.line >= 1, location.line <= lines.count else { return nil }
            
            var currentOffset = 0
            // Sum up lengths of all preceding lines + their newline characters (+1)
            for i in 0..<(location.line - 1) {
                currentOffset += lines[i].utf16.count + 1
            }
            
            let targetLine = lines[location.line - 1]
            let targetColumn = max(0, location.column - 1)
            
            if targetColumn <= targetLine.utf16.count {
                return currentOffset + targetColumn
            }
            return nil
        }
        
        guard let start = offset(for: sourceRange.lowerBound),
              let end = offset(for: sourceRange.upperBound) else {
            return nil
        }
        
        return NSRange(location: start, length: max(0, end - start))
    }
    
    // TODO: Add post-processing on the text here after
    // since the text editor does not get rid of the hashtags
    
    // Also, check special case where the text is next to the hashtag,
    // such as #123 instead of # 123. The font should remain at default
    // for the hashtag in that case, I believe.
    public func updateHeadingFont(textView: NSTextView) {
        let gottenString = textView.string                  // Grab the text
        let document = Document(parsing: gottenString)      // Parse it with Markdown.Document
        var rangeCollector = HeadingRangeCollector()
        rangeCollector.visit(document)                      // Find the ranges of strings to font-change
        
        // Change the font
        guard let textStorage = textView.textStorage else { return }
        textStorage.beginEditing()
        for detail in rangeCollector.rangeDetails {
            // Convert the Markdown SourceRanges into NSRanges for use by AppKit
            guard let sourceRange = detail.range,
                  let nsRange = nsRange(from: sourceRange, in: gottenString) else {
                continue
            }
            
            // Decide the font based on the number of hashtags in our line (#)
            let fontSize: CGFloat
            switch detail.level {
                case 1: fontSize = 26
                case 2: fontSize = 22
                case 3: fontSize = 18
                default: fontSize = 16
            }
            
            let headingFont = NSFont.boldSystemFont(ofSize: fontSize)
            
            textStorage.addAttribute(
                .font,
                value: headingFont,
                range: nsRange
            )
        }
        textStorage.endEditing()
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
