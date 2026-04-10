import AppKit
import Dispatch
import Darwin
import Foundation

@MainActor
final class MarkdownPreviewStore: ObservableObject {
    static let shared = MarkdownPreviewStore()

    @Published private(set) var currentURL: URL?
    @Published private(set) var currentDocument: MarkdownPreviewDocument?
    @Published private(set) var loadError: String?
    @Published private(set) var isMonitoring = false

    private let monitorQueue = DispatchQueue(label: "MDQuickLookPreview.FileMonitor")
    private var monitorSource: DispatchSourceFileSystemObject?
    private var restartMonitorTask: Task<Void, Never>?
    private var lastObservedStamp: FileStamp?

    var hasOpenDocument: Bool {
        currentURL != nil
    }

    var baseURL: URL? {
        currentURL?.deletingLastPathComponent()
    }

    func open(_ url: URL) {
        let normalizedURL = url.standardizedFileURL
        guard normalizedURL.isFileURL else {
            loadError = AppStrings(language: PreviewSettings.load().language).localFilesOnlyError
            return
        }

        restartMonitorTask?.cancel()
        currentURL = normalizedURL
        reloadCurrentDocument()
        startMonitoring(normalizedURL)
    }

    func reloadCurrentDocument() {
        guard let url = currentURL else {
            return
        }

        do {
            currentDocument = try MarkdownPreviewDocument.load(from: url)
            loadError = nil
            lastObservedStamp = fileStamp(for: url)
        } catch {
            loadError = error.localizedDescription
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

    private func reloadIfNeeded() {
        guard let url = currentURL else {
            stopMonitoring()
            return
        }

        let latestStamp = fileStamp(for: url)
        if latestStamp != lastObservedStamp {
            reloadCurrentDocument()
        }
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
        reloadIfNeeded()

        restartMonitorTask?.cancel()
        stopMonitoring()
        restartMonitorTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(250))
            guard let self, self.currentURL == url else {
                return
            }

            self.reloadIfNeeded()
            self.startMonitoring(url)
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
