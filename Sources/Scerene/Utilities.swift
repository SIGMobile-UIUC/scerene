//
//  Utilities.swift
//  Scerene
//
//  Created by John on 11/4/26.
//
import SwiftCrossUI

// Allow string subscripting ("hi"[index: 0] = "h")
extension String {
    subscript(index index: Int) -> Character? {
        print(index)
        guard index >= 0, let i = self.index(startIndex, offsetBy: index, limitedBy: endIndex), i != endIndex else {
            print("Inside the guard")
            return nil
        }
        print("returning")
        return self[i]
    }
}


// Used by ContentView
extension Color {
    static let themeBackground = Color(red: 0, green: 0.043, blue: 0.05)
    static let themeLink = Color(red: 0.38, green: 0.25, blue: 0.91)
    static let themeSecondary = Color(red: 0.95, green: 0.95, blue: 0.96)
}
