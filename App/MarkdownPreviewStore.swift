import AppKit
import Foundation

@MainActor
final class MarkdownPreviewStore: ObservableObject {
    static let shared = MarkdownPreviewStore()

    @Published private(set) var currentURL: URL?
    @Published private(set) var currentDocument: MarkdownPreviewDocument?
    @Published private(set) var loadError: String?
    @Published private(set) var isMonitoring = false

    private var monitorTask: Task<Void, Never>?
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
        monitorTask?.cancel()
        lastObservedStamp = fileStamp(for: url)
        isMonitoring = true

        monitorTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else {
                    break
                }

                await MainActor.run {
                    self?.reloadIfNeeded()
                }
            }
        }
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
        monitorTask?.cancel()
        monitorTask = nil
        isMonitoring = false
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
