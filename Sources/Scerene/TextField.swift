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



struct HeadingRangeCollector: MarkupWalker {
    var normalDetails: [(text: String, range: SourceRange?)] = []
    var rangeDetails: [(level: Int, text: String, range: SourceRange?)] = []
    var italicDetails: [(text: String, range: SourceRange?)] = []
    var boldDetails: [(text: String, range: SourceRange?)] = []
    
    
    // Automatically called by the walker whenever a heading node is encountered
    mutating func visitHeading(_ heading: Heading) {
        let headingText = heading.format().trimmingCharacters(in: .whitespacesAndNewlines)

        var level = 0
        if headingText[index: heading.level] == " " {       // Only change the heading level
            level = heading.level                           // if we have a space between our hashtag and other stuff
        }
        
        rangeDetails.append((
            level: level,               // The number of hashtags
            text: headingText,          // The actual text, may do post-processing on this
            range: heading.range        // The range within the string. 1:1..<1:10, for example, denotes
                                        // the first ten characters of the first line
        ))
        descendInto(heading)
    }

    // Visit italicized text
    mutating func visitEmphasis(_ emphasis: Emphasis) -> () {
        print("Visiting italic text")

        italicDetails.append((
            text: emphasis.format(),    // The actual text, may do post-processing on this
            range: emphasis.range       // The range within the string. 1:1..<1:10, for example, denotes
                                        // the first ten characters of the first line
        ))
        descendInto(emphasis)
    }
    
    // Visit bolded text
    mutating func visitStrong(_ strong: Strong) -> () {
        print("Visiting bold text")
        boldDetails.append((
            text: strong.format(),    // The actual text, may do post-processing on this
            range: strong.range       // The range within the string. 1:1..<1:10, for example, denotes
                                        // the first ten characters of the first line
        ))
        descendInto(strong)
    }
    
    // Visit normal text
    mutating func visitText(_ text: Markdown.Text) -> () {
        print("Visiting normal text")
        normalDetails.append((
            text: text.format(),    // The actual text, may do post-processing on this
            range: text.range       // The range within the string. 1:1..<1:10, for example, denotes
                                        // the first ten characters of the first line
        ))
    }
}


struct TextField: View {
    @State var textInput: String = ""
    
    init(normal: Bool) {
        if (!normal) {
            AppKitBackend.useCaretEditor = true
        }
        
        CaretTextView.addTextEditListener(listener: updateMarkdown)
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
    
    public func updateMarkdown(textView: NSTextView) {
        // Change attributes of the text based on Markdown rules (such as boldness, font, etc)
        
        let gottenString = textView.string                  // Grab the text
        let document = Document(parsing: gottenString)      // Parse it with Markdown.Document
        var rangeCollector = HeadingRangeCollector()
        rangeCollector.visit(document)                      // Find the ranges of strings to font-change
        let baseSize: CGFloat = 16                          // Base font size
        
        // Do operations on the text
        guard let textStorage = textView.textStorage else { return }
        textStorage.beginEditing()
        
        normalizeText(collector: rangeCollector, string: gottenString, textStorage: textStorage, baseSize: baseSize)
        boldHeadingText(collector: rangeCollector, string: gottenString, textStorage: textStorage, baseSize: baseSize)
        italicizeText(collector: rangeCollector, string: gottenString, textStorage: textStorage)
        boldText(collector: rangeCollector, string: gottenString, textStorage: textStorage)
        
        textStorage.endEditing()
    }
    
    
    
    // Make text normal font
    private func normalizeText(collector: HeadingRangeCollector, string: String, textStorage: NSTextStorage, baseSize: CGFloat) {
        for detail in collector.normalDetails {
            // Convert the Markdown SourceRanges into NSRanges for use by AppKit
            guard let sourceRange = detail.range,
                  let nsRange = nsRange(from: sourceRange, in: string) else {
                continue
            }

            textStorage.enumerateAttribute(.font, in: nsRange, options: []) { value, subRange, _ in
                let current = (value as? NSFont) ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
                var plain = NSFontManager.shared.convert(current, toNotHaveTrait: [.boldFontMask, .italicFontMask])
                plain = NSFontManager.shared.convert(plain, toSize: baseSize)
                textStorage.addAttribute(.font, value: plain, range: subRange)
            }
        }
    }

    // Bold text marked by hashtags
    private func boldHeadingText(collector: HeadingRangeCollector, string: String, textStorage: NSTextStorage, baseSize: CGFloat) {
        for detail in collector.rangeDetails {
            // Convert the Markdown SourceRanges into NSRanges for use by AppKit
            guard let sourceRange = detail.range,
                  let nsRange = nsRange(from: sourceRange, in: string) else {
                continue
            }
            
            // Decide the font based on the number of hashtags in our line (#)
            let fontSize: CGFloat
            switch detail.level {
                case 1: fontSize = 30
                case 2: fontSize = 26
                case 3: fontSize = 22
                default: fontSize = baseSize
            }
            
            let headingFont = NSFont.boldSystemFont(ofSize: fontSize)
            
            textStorage.addAttribute(
                .font,
                value: headingFont,
                range: nsRange
            )
        }
    }
    
    // Italicize _underlined_ text
    private func italicizeText(collector: HeadingRangeCollector, string: String, textStorage: NSTextStorage) {
        for detail in collector.italicDetails {
            // Convert the Markdown SourceRanges into NSRanges for use by AppKit
            guard let sourceRange = detail.range,
                  let nsRange = nsRange(from: sourceRange, in: string) else {
                continue
            }

            textStorage.enumerateAttribute(.font, in: nsRange, options: []) { value, subRange, _ in
                let current = (value as? NSFont) ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
                let italic = NSFontManager.shared.convert(current, toHaveTrait: [.italicFontMask])
                textStorage.addAttribute(.font, value: italic, range: subRange)
            }
        }
    }

    // Bold __double underlined__ text
    private func boldText(collector: HeadingRangeCollector, string: String, textStorage: NSTextStorage) {
        for detail in collector.boldDetails {
            // Convert the Markdown SourceRanges into NSRanges for use by AppKit
            guard let sourceRange = detail.range,
                  let nsRange = nsRange(from: sourceRange, in: string) else {
                continue
            }

            textStorage.enumerateAttribute(.font, in: nsRange, options: []) { value, subRange, _ in
                let current = (value as? NSFont) ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
                let bold = NSFontManager.shared.convert(current, toHaveTrait: [.boldFontMask])
                textStorage.addAttribute(.font, value: bold, range: subRange)
            }
        }
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
