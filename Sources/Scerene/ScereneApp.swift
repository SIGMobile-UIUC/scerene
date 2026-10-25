import SwiftCrossUI
import DefaultBackend

extension Color {
    static let themeBackground = Color(red: 0, green: 0.043, blue: 0.05)
    static let themeLink = Color(red: 0.38, green: 0.25, blue: 0.91)
    static let themeSecondary = Color(red: 0.95, green: 0.95, blue: 0.96)
}

@main
struct ScereneApp: App {
    var body: some Scene {
        WindowGroup("Scerene") {
            VStack {
                ContentView()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.themeBackground);
        }
    }
}

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
