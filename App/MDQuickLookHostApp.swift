import AppKit
import SwiftUI

@main
struct MDQuickLookHostApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var previewStore = MarkdownPreviewStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(previewStore)
                .frame(minWidth: 1020, minHeight: 680)
        }
        .windowResizability(.contentMinSize)
        .commands {
            MarkdownViewerCommands()
        }
    }
}

struct MarkdownViewerCommands: Commands {
    @ObservedObject private var previewStore = MarkdownPreviewStore.shared
    @ObservedObject private var settingsStore = PreviewSettingsStore.shared

    private var strings: AppStrings {
        AppStrings(language: settingsStore.settings.language)
    }

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button(strings.openMarkdownEllipsis) {
                MarkdownPreviewStore.shared.presentOpenPanel()
            }
            .keyboardShortcut("o")
        }

        CommandMenu(strings.previewMenu) {
            Button(strings.reloadPreview) {
                MarkdownPreviewStore.shared.reloadCurrentDocument()
            }
            .keyboardShortcut("r")
            .disabled(!previewStore.hasOpenDocument)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else {
            return
        }

        Task { @MainActor in
            MarkdownPreviewStore.shared.open(url)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
