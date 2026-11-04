//
//  ContentView.swift
//  Scerene
//
//  Created by John on 11/3/26.
//

import AppKit
import SwiftCrossUI
import AppKitBackend

struct ContentView: View {
    var body: some View {
        var cmd: String {
            #if os(macOS)
                "⌘"
            #elseif os(Windows)
                "Ctrl"
            #elseif os(Linux)
                "Ctrl"
            #endif
        }
        Text("What are we doing today, ari?")
            .font(.largeTitle)
            .emphasized()
            .padding();
        HStack {
            Text("\(cmd) + N")
            Text("Create a new file")
        }
            .foregroundColor(Color.themeLink);
        HStack {
            Text("\(cmd) + O")
            Text("Open a file")
        }
            .foregroundColor(Color.themeLink);
    }
}
