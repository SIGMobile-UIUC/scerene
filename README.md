
# Scerene

Scerene uses a forked copy of `moreSwift/swift-cross-ui`, which is located inside the toplevel folder. You can build the project with either XCode or with `swift-bundler` in your terminal:


```bash
brew install mint
mint install stackotter/swift-bundler@main
...cd to the directory of Scerene/Package.swift...
swift-bundler run
```
If your version of Swift does not support swift-bundler, getting the latest version of XCode is recommended, as their installation process updates your version of Swift automatically.
Since the UI components within the original library were very basic, we built custom components directly under the framework. For instance, we added a widget that incorporates a smooth cursor animation. We plan to expand Scerene's feature set by adding custom widgets to the UI library over time.

To see a demo, comment out the entire entry point file in `ScereneApp.Swift`, and uncomment `Example.Swift`:

**Example.swift**

```swift
import AppKit
import SwiftCrossUI
import AppKitBackend

@main
struct Example: App {
    var body: some Scene {
        WindowGroup("Window Title") {
            TextField(normal: true).background(Color.black)  // Note the "normal" flag
        }
    }
}
```

Building the project will yield the base `swift-cross-ui` text editor on a black background. If you change the `normal` flag to `false`:

```
TextField(normal: false).background(Color.black)  // Make a not-normal text editor!
```

You will be using our custom-built CaretTextEditor (defined in `swift-cross-ui/AppKitBackend/Helpers/CaretTextView`).

&nbsp;

# OS-dependent backends (Mainly for building under Windows)

The current imports for `AppKit` and `AppKitBackend` are MacOS-specific. In order to get the some portion of the code running for Windows, you will need to change lines in certain places to grab the right dependencies:

**Package.Swift**

```swift
.product(name: "AppKitBackend", package: "swift-cross-ui"),  // Change AppKitBackend to WinUIBackend
```

**ScereneApp/ContentView/etc.Swift**

```swift
import AppKit         // Delete this line
import AppKitBackend  // Change to WinUIBackend
```

If you follow the instructions on `swift-cross-ui`'s [current website](https://swiftcrossui.dev), they will suggest that you import `DefaultBackend` in the same places to get your app running across platforms. However, the build process will not work on MacOS or Windows using this method. There are a couple reasons as to why:

* `DefaultBackend` is outdated in both operating systems.

* Scerene uses custom-defined widgets that we implemented in `AppKit`, which are not ported to `WinUI` yet.
