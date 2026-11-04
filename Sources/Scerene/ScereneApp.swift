import AppKit
import SwiftCrossUI
import AppKitBackend


@main
struct ScereneApp: App {
    var body: some Scene {
        WindowGroup("Scerene") {
            VStack {
                TextField(normal: false).background(Color.black)
                //ContentView()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.themeBackground);
        }
    }
}

