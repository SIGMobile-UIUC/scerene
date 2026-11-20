//
//  Tabs.swift
//  Scerene
//
//  Editor tabs, persisted to Application Support so they reopen with the app.
//

import AppKit
import Foundation
import SwiftCrossUI

struct EditorTab: Codable, Equatable, Identifiable {
    var id = UUID()
    var title: String
    var text: String = ""
}

struct TabSession: Codable, Equatable {
    var tabs: [EditorTab]
    var selectedID: UUID?

    static let empty = TabSession(tabs: [EditorTab(title: "Untitled")], selectedID: nil)

    private static var fileURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Scerene", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("tabs.json")
    }

    static func load() -> TabSession {
        guard let data = try? Data(contentsOf: fileURL),
              let session = try? JSONDecoder().decode(TabSession.self, from: data),
              !session.tabs.isEmpty
        else { return .empty }
        return session
    }

    /// Latest in-memory session, written to disk when the app quits.
    @MainActor static var current: TabSession?

    @MainActor static let quitObserver: NSObjectProtocol = NotificationCenter.default.addObserver(
        forName: NSApplication.willTerminateNotification, object: nil, queue: .main
    ) { _ in
        MainActor.assumeIsolated { current?.save() }
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        try? data.write(to: Self.fileURL, options: .atomic)
    }
}

struct TabbedEditor: View {
    @State private var session = TabSession.load() {
        didSet { TabSession.current = session }
    }

    init() {
        _ = TabSession.quitObserver
    }

    private var selectedIndex: Int {
        session.tabs.firstIndex { $0.id == session.selectedID } ?? 0
    }

    private var selectedText: Binding<String> {
        Binding(
            get: { session.tabs[selectedIndex].text },
            set: { newValue in
                session.tabs[selectedIndex].text = newValue
            }
        )
    }

    /// Only the set of tabs and the selection; text edits don't trigger a save.
    private var tabLayout: [UUID?] {
        session.tabs.map(\.id) + [session.selectedID]
    }

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            TextField(normal: false, text: selectedText)
                .background(Color.black)
        }
        .onChange(of: tabLayout) { session.save() }
    }

    private var tabBar: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 2) {
                ForEach(session.tabs) { tab in
                    TabButton(
                        title: tab.title,
                        isSelected: tab.id == session.tabs[selectedIndex].id,
                        onSelect: { session.selectedID = tab.id },
                        onClose: { close(tab.id) }
                    )
                }
                Button("+") { newTab() }
                    .buttonStyle(.plain)
                    .foregroundColor(.themeSecondary)
                    .padding(.horizontal, 10)
            }
            .padding(4)
        }
        .frame(height: 36)
    }

    private func newTab() {
        let tab = EditorTab(title: "Untitled")
        session.tabs.append(tab)
        session.selectedID = tab.id
    }

    private func close(_ id: UUID) {
        guard let index = session.tabs.firstIndex(where: { $0.id == id }) else { return }
        let wasSelected = index == selectedIndex
        session.tabs.remove(at: index)
        if session.tabs.isEmpty {
            session.tabs = [EditorTab(title: "Untitled")]
        }
        if wasSelected {
            session.selectedID = session.tabs[min(index, session.tabs.count - 1)].id
        }
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let onSelect: @MainActor @Sendable () -> Void
    let onClose: @MainActor @Sendable () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 6) {
            Button(action: onSelect) {
                Text(title)
                    .foregroundColor(isSelected ? .themeSecondary : .themeSecondary.opacity(0.6))
            }
            .buttonStyle(.plain)
            Button("×", action: onClose)
                .buttonStyle(.plain)
                .foregroundColor(.themeSecondary.opacity(isHovering || isSelected ? 0.8 : 0))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            isSelected ? Color.themeLink.opacity(0.35)
                : isHovering ? Color.themeLink.opacity(0.15) : Color.clear
        )
        .cornerRadius(6)
        .onHover { isHovering = $0 }
    }
}
