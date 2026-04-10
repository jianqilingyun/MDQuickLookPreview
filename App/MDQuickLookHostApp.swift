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

        CommandGroup(replacing: .saveItem) {
            Button(strings.saveMarkdown) {
                MarkdownPreviewStore.shared.saveCurrentDocument()
            }
            .keyboardShortcut("s")
            .disabled(!previewStore.canSave)
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

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else {
            return
        }

        MarkdownPreviewStore.shared.open(url)
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        MarkdownPreviewStore.shared.confirmTermination() ? .terminateNow : .terminateCancel
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
