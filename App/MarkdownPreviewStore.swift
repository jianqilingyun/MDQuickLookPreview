import AppKit
import Dispatch
import Darwin
import Foundation

@MainActor
final class MarkdownPreviewStore: ObservableObject {
    static let shared = MarkdownPreviewStore()

    @Published private(set) var currentURL: URL?
    @Published private(set) var currentMarkdown = ""
    @Published private(set) var currentDocument: MarkdownPreviewDocument?
    @Published private(set) var loadError: String?
    @Published private(set) var isMonitoring = false

    private let monitorQueue = DispatchQueue(label: "MDQuickLookPreview.FileMonitor")
    private var monitorSource: DispatchSourceFileSystemObject?
    private var restartMonitorTask: Task<Void, Never>?
    private var lastObservedStamp: FileStamp?
    private var savedMarkdown = ""

    var hasOpenDocument: Bool {
        currentURL != nil
    }

    var currentFileName: String? {
        currentURL?.lastPathComponent
    }

    var baseURL: URL? {
        currentURL?.deletingLastPathComponent()
    }

    var hasUnsavedChanges: Bool {
        hasOpenDocument && currentMarkdown != savedMarkdown
    }

    var canSave: Bool {
        hasUnsavedChanges
    }

    func open(_ url: URL) {
        let normalizedURL = url.standardizedFileURL
        guard normalizedURL.isFileURL else {
            loadError = AppStrings(language: PreviewSettings.load().language).localFilesOnlyError
            return
        }

        if normalizedURL == currentURL {
            return
        }

        guard resolveUnsavedChangesIfNeeded() else {
            return
        }

        do {
            let markdown = try MarkdownPreviewDocument.loadMarkdown(from: normalizedURL)
            restartMonitorTask?.cancel()
            stopMonitoring()
            currentURL = normalizedURL
            currentMarkdown = markdown
            savedMarkdown = markdown
            try renderCurrentDocument()
            loadError = nil
            lastObservedStamp = fileStamp(for: normalizedURL)
            startMonitoring(normalizedURL)
        } catch {
            loadError = error.localizedDescription
        }
    }

    func reloadCurrentDocument() {
        guard hasOpenDocument else {
            return
        }

        do {
            try renderCurrentDocument()
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
    }

    func updateCurrentMarkdown(_ markdown: String) {
        guard hasOpenDocument else {
            return
        }

        currentMarkdown = markdown
        reloadCurrentDocument()

        guard let url = currentURL else {
            return
        }

        if hasUnsavedChanges {
            stopMonitoring()
        } else if !isMonitoring {
            lastObservedStamp = fileStamp(for: url)
            startMonitoring(url)
        }
    }

    @discardableResult
    func saveCurrentDocument() -> Bool {
        guard let url = currentURL else {
            return false
        }

        stopMonitoring()

        do {
            try Data(currentMarkdown.utf8).write(to: url, options: .atomic)
            savedMarkdown = currentMarkdown
            lastObservedStamp = fileStamp(for: url)
            startMonitoring(url)
            try renderCurrentDocument()
            loadError = nil
            return true
        } catch {
            loadError = error.localizedDescription
            startMonitoring(url)
            return false
        }
    }

    func presentOpenPanel() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = MarkdownPreviewDocument.supportedContentTypes
        panel.title = AppStrings(language: PreviewSettings.load().language).openPanelTitle

        if panel.runModal() == .OK, let url = panel.url {
            open(url)
        }
    }

    func refreshForSettingsChange() {
        reloadCurrentDocument()
    }

    func confirmTermination() -> Bool {
        resolveUnsavedChangesIfNeeded()
    }

    private func startMonitoring(_ url: URL) {
        stopMonitoring()
        lastObservedStamp = fileStamp(for: url)
        guard let source = makeMonitorSource(for: url) else {
            isMonitoring = false
            return
        }

        monitorSource = source
        isMonitoring = true
        source.resume()
    }

    private func stopMonitoring() {
        monitorSource?.cancel()
        monitorSource = nil
        isMonitoring = false
    }

    private func makeMonitorSource(for url: URL) -> DispatchSourceFileSystemObject? {
        let eventHandler: @Sendable () -> Void = { [weak self] in
            Task { @MainActor [weak self] in
                self?.handleMonitorEvent(for: url)
            }
        }

        return makeFileMonitorSource(for: url, queue: monitorQueue, handler: eventHandler)
    }

    private func handleMonitorEvent(for url: URL) {
        guard !hasUnsavedChanges else {
            return
        }

        let latestStamp = fileStamp(for: url)
        if latestStamp != lastObservedStamp {
            do {
                let markdown = try MarkdownPreviewDocument.loadMarkdown(from: url)
                currentMarkdown = markdown
                savedMarkdown = markdown
                currentURL = url
                try renderCurrentDocument()
                loadError = nil
                lastObservedStamp = latestStamp
            } catch {
                loadError = error.localizedDescription
            }
        }

        restartMonitorTask?.cancel()
        stopMonitoring()
        restartMonitorTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(250))
            guard let self, self.currentURL == url else {
                return
            }

            self.startMonitoring(url)
        }
    }

    private func renderCurrentDocument() throws {
        guard let url = currentURL else {
            currentDocument = nil
            return
        }

        currentDocument = try MarkdownPreviewDocument.make(
            markdown: currentMarkdown,
            fallbackTitle: url.deletingPathExtension().lastPathComponent,
            settings: .load()
        )
    }

    private func resolveUnsavedChangesIfNeeded() -> Bool {
        guard hasUnsavedChanges else {
            return true
        }

        let strings = AppStrings(language: PreviewSettings.load().language)
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = strings.unsavedChangesTitle
        alert.informativeText = strings.unsavedChangesMessage(fileName: currentFileName ?? "Markdown")
        alert.addButton(withTitle: strings.save)
        alert.addButton(withTitle: strings.discardChanges)
        alert.addButton(withTitle: strings.cancel)

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            return saveCurrentDocument()
        case .alertSecondButtonReturn:
            return true
        default:
            return false
        }
    }

    private func fileStamp(for url: URL) -> FileStamp? {
        guard let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]) else {
            return nil
        }

        return FileStamp(
            modificationDate: values.contentModificationDate,
            fileSize: values.fileSize
        )
    }
}

private struct FileStamp: Equatable {
    let modificationDate: Date?
    let fileSize: Int?
}

private func makeFileMonitorSource(
    for url: URL,
    queue: DispatchQueue,
    handler: @escaping @Sendable () -> Void
) -> DispatchSourceFileSystemObject? {
    let fileDescriptor = Darwin.open(url.path, O_EVTONLY)
    guard fileDescriptor >= 0 else {
        return nil
    }

    let source = DispatchSource.makeFileSystemObjectSource(
        fileDescriptor: fileDescriptor,
        eventMask: [.write, .extend, .attrib, .rename, .delete, .revoke],
        queue: queue
    )

    source.setEventHandler(handler: handler)
    source.setCancelHandler {
        Darwin.close(fileDescriptor)
    }

    return source
}
