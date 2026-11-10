import AppKit
import Foundation
import SwiftCrossUI

enum ComponentCategory: String, CaseIterable {
    case controls = "Controls"
    case text = "Text Input"
    case display = "Display"
    case collections = "Collections"
    case navigation = "Navigation"
    case layout = "Layout"
    case shapes = "Shapes"
    case gradients = "Gradients"
    case presentation = "Presentation"
}

struct ComponentDemo: Identifiable {
    let id: String
    let category: ComponentCategory
    let makeView: @MainActor () -> AnyView

    init<Content: View>(
        _ name: String,
        in category: ComponentCategory,
        @ViewBuilder _ content: @escaping @MainActor () -> Content
    ) {
        self.id = name
        self.category = category
        self.makeView = { AnyView(content()) }
    }
}

struct ComponentRoute: Codable {
    let name: String
}

struct Stateful<Value, Content: View>: View {
    @State private var value: Value
    private let content: (Binding<Value>) -> Content

    init(_ initialValue: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        self._value = State(wrappedValue: initialValue)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}

struct GhostButton: View {
    let title: String
    var width: Int? = nil
    let action: @MainActor @Sendable () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(.themeLink)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .frame(width: width.map(Double.init))
                .background(isHovering ? Color.themeLink.opacity(0.15) : Color.clear)
                .overlay {
                    RoundedRectangle(cornerRadius: 6).stroke(.themeLink)
                }
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}

struct ComponentExplorer: View {
    @State private var path = NavigationPath()

    private let columns = 4
    private let buttonWidth = 170

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Component Explorer")
                        .font(.largeTitle)
                        .emphasized()
                    ForEach(ComponentCategory.allCases, id: \.self) { category in
                        categorySection(category)
                    }
                }
                .padding(24)
            }
        }
        .navigationDestination(for: ComponentRoute.self) { route in
            ComponentPage(
                demo: ComponentCatalog.demo(named: route.name),
                onBack: { path.removeLast() }
            )
        }
    }

    @ViewBuilder
    private func categorySection(_ category: ComponentCategory) -> some View {
        let rows = ComponentCatalog.demos(in: category).chunked(into: columns)
        VStack(alignment: .leading, spacing: 8) {
            Text(category.rawValue)
                .font(.title3)
                .emphasized()
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 8) {
                    ForEach(row) { demo in
                        GhostButton(title: demo.id, width: buttonWidth) {
                            path.append(ComponentRoute(name: demo.id))
                        }
                    }
                }
            }
        }
    }
}

struct ComponentPage: View {
    let demo: ComponentDemo?
    let onBack: @MainActor @Sendable () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                GhostButton(title: "← Back", action: onBack)
                Text(demo?.id ?? "Unknown component")
                    .font(.title2)
                    .emphasized()
                Spacer()
            }
            Divider()
            if let demo {
                demo.makeView()
                    .padding(16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                Text("No demo is registered for this component.")
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

struct SampleRow: Identifiable {
    let id: Int
    let name: String
    let kind: String
}

enum SampleData {
    static let fruits = ["Apple", "Banana", "Cherry", "Durian", "Elderberry"]

    static let rows = [
        SampleRow(id: 1, name: "Heading", kind: "Block"),
        SampleRow(id: 2, name: "Emphasis", kind: "Inline"),
        SampleRow(id: 3, name: "Strong", kind: "Inline"),
        SampleRow(id: 4, name: "Code Block", kind: "Block"),
    ]

    static let imageURL: URL = {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("scerene-component-explorer-sample.png")
        let image = NSImage(size: NSSize(width: 160, height: 160), flipped: false) { rect in
            NSColor.systemIndigo.setFill()
            NSBezierPath(roundedRect: rect, xRadius: 24, yRadius: 24).fill()
            NSColor.white.setFill()
            NSBezierPath(ovalIn: rect.insetBy(dx: 40, dy: 40)).fill()
            return true
        }
        if let tiff = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiff),
            let png = bitmap.representation(using: .png, properties: [:])
        {
            try? png.write(to: url)
        }
        return url
    }()
}

enum ComponentCatalog {
    static func demos(in category: ComponentCategory) -> [ComponentDemo] {
        all.filter { $0.category == category }
    }

    static func demo(named name: String) -> ComponentDemo? {
        all.first { $0.id == name }
    }

    static let all: [ComponentDemo] = [
        ComponentDemo("Button", in: .controls) {
            Stateful(0) { count in
                HStack {
                    Button("Clicked \(count.wrappedValue) times") { count.wrappedValue += 1 }
                    Button("Plain style") { count.wrappedValue += 1 }.buttonStyle(.plain)
                    Button("Borderless style") { count.wrappedValue += 1 }.buttonStyle(.borderless)
                }
            }
        },
        ComponentDemo("Toggle", in: .controls) {
            Stateful(true) { isOn in
                VStack(alignment: .leading) {
                    Toggle("Switch style", isOn: isOn).toggleStyle(.switch)
                    Toggle("Checkbox style", isOn: isOn).toggleStyle(.checkbox)
                    Toggle("Button style", isOn: isOn).toggleStyle(.button)
                    Text("Value: \(isOn.wrappedValue)")
                }
                .frame(width: 280)
            }
        },
        ComponentDemo("Slider", in: .controls) {
            Stateful(50.0) { value in
                VStack(alignment: .leading) {
                    Slider(value: value, in: 0...100)
                    Text("Value: \(Int(value.wrappedValue))")
                }
                .frame(width: 300)
            }
        },
        ComponentDemo("Picker", in: .controls) {
            Stateful(String?.some("Apple")) { selection in
                VStack(alignment: .leading) {
                    Picker(of: SampleData.fruits, selection: selection)
                    Picker(of: SampleData.fruits, selection: selection).pickerStyle(.segmented)
                    Picker(of: SampleData.fruits, selection: selection).pickerStyle(.radioGroup)
                    Text("Selected: \(selection.wrappedValue ?? "none")")
                }
            }
        },
        ComponentDemo("Menu", in: .controls) {
            Stateful("Nothing chosen yet") { message in
                VStack(alignment: .leading) {
                    Menu("Actions") {
                        Button("New file") { message.wrappedValue = "New file" }
                        Button("Open file") { message.wrappedValue = "Open file" }
                        Menu("More") {
                            Button("Export") { message.wrappedValue = "Export" }
                        }
                    }
                    Text(message.wrappedValue)
                }
            }
        },
        ComponentDemo("ColorPicker", in: .controls) {
            Stateful(Color.themeLink) { color in
                HStack {
                    ColorPicker("Accent color", selection: color)
                    RoundedRectangle(cornerRadius: 8).fill(color.wrappedValue).frame(width: 60, height: 30)
                }
                .frame(width: 300)
            }
        },
        ComponentDemo("DatePicker", in: .controls) {
            Stateful(Date()) { date in
                VStack(alignment: .leading) {
                    DatePicker("Date", selection: date)
                    Text("Selected: \(date.wrappedValue.description)")
                }
            }
        },
        ComponentDemo("TextField", in: .text) {
            Stateful("") { text in
                VStack(alignment: .leading) {
                    SwiftCrossUI.TextField("Type something", text: text)
                    Text("You typed: \(text.wrappedValue)")
                }
                .frame(width: 300)
            }
        },
        ComponentDemo("SecureField", in: .text) {
            Stateful("") { text in
                VStack(alignment: .leading) {
                    SecureField("Password", text: text)
                    Text("Length: \(text.wrappedValue.count)")
                }
                .frame(width: 300)
            }
        },
        ComponentDemo("TextEditor", in: .text) {
            Stateful("# Heading\nSome *emphasis* and **strong** text.") { text in
                TextEditor(text: text)
                    .frame(width: 400, height: 200)
            }
        },
        ComponentDemo("Text", in: .display) {
            VStack(alignment: .leading) {
                Text("Large title").font(.largeTitle)
                Text("Title").font(.title)
                Text("Headline").font(.headline)
                Text("Body").font(.body)
                Text("Caption").font(.caption)
                Text("Emphasized").emphasized()
                Text("Colored").foregroundColor(.themeLink)
            }
        },
        ComponentDemo("Image", in: .display) {
            Image(SampleData.imageURL)
                .resizable()
                .frame(width: 120, height: 120)
        },
        ComponentDemo("ProgressView", in: .display) {
            Stateful(0.4) { value in
                VStack(alignment: .leading) {
                    ProgressView()
                    ProgressView("Determinate", value: value.wrappedValue)
                    Slider(value: value, in: 0...1)
                }
                .frame(width: 300)
            }
        },
        ComponentDemo("Divider", in: .display) {
            VStack {
                Text("Above")
                Divider()
                Text("Below")
                Divider(.themeLink)
                Text("Below a colored divider")
            }
            .frame(width: 300)
        },
        ComponentDemo("ContentUnavailableView", in: .display) {
            ContentUnavailableView {
                Text("No Results")
            } description: {
                Text("Try a different search term.")
            } actions: {
                Button("Retry") {}
            }
        },
        ComponentDemo("WebView", in: .display) {
            Stateful(URL(string: "https://example.com")!) { url in
                WebView(url)
                    .frame(width: 600, height: 400)
            }
        },
        ComponentDemo("List", in: .collections) {
            Stateful(String?.none) { selection in
                VStack(alignment: .leading) {
                    List(SampleData.fruits, id: \.self, selection: selection)
                        .frame(width: 250, height: 180)
                    Text("Selected: \(selection.wrappedValue ?? "none")")
                }
            }
        },
        ComponentDemo("Table", in: .collections) {
            Table(SampleData.rows) {
                TableColumn("Name", value: \SampleRow.name)
                TableColumn("Kind", value: \SampleRow.kind)
            }
            .frame(width: 400, height: 180)
        },
        ComponentDemo("ForEach", in: .collections) {
            VStack(alignment: .leading) {
                ForEach(SampleData.fruits, id: \.self) { fruit in
                    Text("• \(fruit)")
                }
            }
        },
        ComponentDemo("ScrollView", in: .collections) {
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(Array(1...50), id: \.self) { index in
                        Text("Row \(index)")
                    }
                }
            }
            .frame(width: 250, height: 200)
        },
        ComponentDemo("NavigationStack", in: .navigation) {
            NavigationDemo()
        },
        ComponentDemo("NavigationLink", in: .navigation) {
            NavigationDemo()
        },
        ComponentDemo("NavigationSplitView", in: .navigation) {
            Stateful(String?.some("Apple")) { selection in
                NavigationSplitView {
                    List(SampleData.fruits, id: \.self, selection: selection)
                } detail: {
                    Text("Detail for \(selection.wrappedValue ?? "nothing")")
                        .padding()
                }
                .frame(width: 500, height: 250)
            }
        },
        ComponentDemo("HStack", in: .layout) {
            HStack(spacing: 12) {
                swatch(.red)
                swatch(.green)
                swatch(.blue)
            }
        },
        ComponentDemo("VStack", in: .layout) {
            VStack(spacing: 12) {
                swatch(.red)
                swatch(.green)
                swatch(.blue)
            }
        },
        ComponentDemo("ZStack", in: .layout) {
            ZStack {
                Rectangle().fill(.blue).frame(width: 140, height: 140)
                Circle().fill(.orange).frame(width: 90, height: 90)
                Text("Top")
            }
        },
        ComponentDemo("Spacer", in: .layout) {
            HStack {
                Text("Leading")
                Spacer()
                Text("Trailing")
            }
            .padding(8)
            .frame(width: 350)
            .overlay { Rectangle().stroke(.gray) }
        },
        ComponentDemo("GeometryReader", in: .layout) {
            GeometryReader { proxy in
                Text("Proposed size: \(Int(proxy.size.width)) × \(Int(proxy.size.height))")
            }
            .frame(width: 300, height: 120)
            .overlay { Rectangle().stroke(.gray) }
        },
        ComponentDemo("Rectangle", in: .shapes) {
            Rectangle().fill(.themeLink).frame(width: 160, height: 100)
        },
        ComponentDemo("RoundedRectangle", in: .shapes) {
            RoundedRectangle(cornerRadius: 16).fill(.themeLink).frame(width: 160, height: 100)
        },
        ComponentDemo("Circle", in: .shapes) {
            Circle().fill(.themeLink).frame(width: 120, height: 120)
        },
        ComponentDemo("Ellipse", in: .shapes) {
            Ellipse().fill(.themeLink).frame(width: 180, height: 100)
        },
        ComponentDemo("Capsule", in: .shapes) {
            Capsule().stroke(.themeLink).frame(width: 180, height: 60)
        },
        ComponentDemo("LinearGradient", in: .gradients) {
            LinearGradient(colors: [.themeLink, .orange], startPoint: .leading, endPoint: .trailing)
                .frame(width: 240, height: 120)
        },
        ComponentDemo("RadialGradient", in: .gradients) {
            RadialGradient(colors: [.themeLink, .black], center: .center, startRadius: 0, endRadius: 100)
                .frame(width: 200, height: 200)
        },
        ComponentDemo("AngularGradient", in: .gradients) {
            AngularGradient(colors: [.red, .green, .blue, .red], center: .center)
                .frame(width: 200, height: 200)
        },
        ComponentDemo("Alert", in: .presentation) {
            Stateful(false) { isPresented in
                GhostButton(title: "Show alert") { isPresented.wrappedValue = true }
                    .alert("Hello from the explorer", isPresented: isPresented) {
                        Button("OK") {}
                    }
            }
        },
        ComponentDemo("Sheet", in: .presentation) {
            Stateful(false) { isPresented in
                GhostButton(title: "Show sheet") { isPresented.wrappedValue = true }
                    .sheet(isPresented: isPresented) {
                        VStack {
                            Text("This is a sheet")
                            GhostButton(title: "Dismiss") { isPresented.wrappedValue = false }
                        }
                        .padding(24)
                    }
            }
        },
    ]

    @MainActor
    private static func swatch(_ color: Color) -> some View {
        RoundedRectangle(cornerRadius: 6).fill(color).frame(width: 60, height: 60)
    }
}

struct NavigationDemo: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            VStack(alignment: .leading) {
                Text("Root of a nested NavigationStack")
                NavigationLink("Push \"First\"", value: "First", path: $path)
                NavigationLink("Push \"Second\"", value: "Second", path: $path)
            }
        }
        .navigationDestination(for: String.self) { value in
            VStack(alignment: .leading) {
                Text("Pushed: \(value)")
                NavigationLink("Push another", value: value + "+", path: $path)
                GhostButton(title: "Pop") { path.removeLast() }
            }
        }
        .frame(width: 350, height: 160)
    }
}
