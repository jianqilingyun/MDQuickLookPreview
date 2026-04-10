import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var previewStore: MarkdownPreviewStore
    @StateObject private var settingsStore = PreviewSettingsStore.shared
    @State private var isDropTargeted = false

    private var strings: AppStrings {
        AppStrings(language: settingsStore.settings.language)
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .navigationSplitViewColumnWidth(min: 240, ideal: 260, max: 280)
        .toolbar {
            ToolbarItemGroup {
                Button(strings.openMarkdown) {
                    previewStore.presentOpenPanel()
                }

                Button(strings.save) {
                    previewStore.saveCurrentDocument()
                }
                .disabled(!previewStore.canSave)

                Button(strings.reload) {
                    previewStore.reloadCurrentDocument()
                }
                .disabled(!previewStore.hasOpenDocument)

                Picker("Workspace Mode", selection: workspaceModeBinding) {
                    ForEach(PreviewSettings.WorkspaceMode.allCases) { mode in
                        Text(mode.displayName(in: settingsStore.settings.language)).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 220)
                .disabled(!previewStore.hasOpenDocument)
            }
        }
        .dropDestination(for: URL.self) { items, _ in
            guard let url = items.first else {
                return false
            }

            previewStore.open(url)
            return true
        } isTargeted: { targeted in
            isDropTargeted = targeted
        }
        .overlay(alignment: .center) {
            if isDropTargeted {
                dropOverlay
            }
        }
    }

    private var sidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if previewStore.hasOpenDocument {
                    filePanel
                }
                settingsPanel
            }
            .padding(24)
        }
    }

    private var detail: some View {
        Group {
            if previewStore.hasOpenDocument {
                workspace
            } else {
                emptyState
            }
        }
    }

    private var workspace: some View {
        Group {
            switch workspaceMode {
            case .edit:
                editorPane
            case .preview:
                previewPane
            case .split:
                HSplitView {
                    editorPane
                        .frame(minWidth: 320)
                    previewPane
                        .frame(minWidth: 360)
                }
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var filePanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(strings.documentLabel)
                .font(.headline)

            if let fileName = previewStore.currentFileName {
                Text(fileName)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2)
            }

            if previewStore.hasUnsavedChanges {
                Text(strings.unsavedChangesBadge)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .panelStyle()
    }

    private var settingsPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(strings.settingsTitle)
                .font(.headline)

            if let loadError = previewStore.loadError {
                Text(loadError)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            settingRow(title: strings.languageLabel) {
                Picker(strings.languageLabel, selection: languageBinding) {
                    ForEach(PreviewSettings.AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            settingRow(title: strings.themeLabel) {
                Picker(strings.themeLabel, selection: themeBinding) {
                    ForEach(PreviewSettings.ThemePreset.allCases) { theme in
                        Text(theme.displayName(in: settingsStore.settings.language)).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            settingRow(title: strings.fontSizeLabel) {
                Picker(strings.fontSizeLabel, selection: fontSizeBinding) {
                    ForEach(PreviewSettings.FontSize.allCases) { fontSize in
                        Text(fontSize.displayName(in: settingsStore.settings.language)).tag(fontSize)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            settingRow(title: strings.contentWidthLabel) {
                Picker(strings.contentWidthLabel, selection: contentWidthBinding) {
                    ForEach(PreviewSettings.ContentWidth.allCases) { width in
                        Text(width.displayName(in: settingsStore.settings.language)).tag(width)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            settingRow(title: strings.workspaceModeLabel) {
                Picker(strings.workspaceModeLabel, selection: workspaceModeBinding) {
                    ForEach(PreviewSettings.WorkspaceMode.allCases) { mode in
                        Text(mode.displayName(in: settingsStore.settings.language)).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
        }
        .panelStyle()
    }

    private var editorPane: some View {
        VStack(spacing: 0) {
            paneHeader(title: strings.editorTitle, badge: previewStore.hasUnsavedChanges ? strings.unsavedChangesBadge : nil)

            TextEditor(text: editorBinding)
                .font(.system(size: 14, weight: .regular, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color(nsColor: .textBackgroundColor))
        }
    }

    private var previewPane: some View {
        VStack(spacing: 0) {
            paneHeader(title: strings.previewTitle, badge: nil)

            Group {
                if let document = previewStore.currentDocument {
                    MarkdownWebView(document: document, baseURL: previewStore.baseURL)
                        .background(Color(nsColor: .windowBackgroundColor))
                } else {
                    Color(nsColor: .windowBackgroundColor)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)

            Text(strings.openTitle)
                .font(.title3.weight(.semibold))

            Text(strings.emptyDescription)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 420)

            Button(strings.openMarkdownEllipsis) {
                previewStore.presentOpenPanel()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var dropOverlay: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [10]))
            .foregroundStyle(Color.accentColor)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.accentColor.opacity(0.08))
            )
            .padding(28)
            .overlay {
                Text(strings.dropMarkdownHere)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }
    }

    @ViewBuilder
    private func settingRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            content()
        }
    }

    @ViewBuilder
    private func paneHeader(title: String, badge: String?) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            if let badge {
                Text(badge)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var themeBinding: Binding<PreviewSettings.ThemePreset> {
        Binding(
            get: { settingsStore.settings.theme },
            set: { settingsStore.updateTheme($0) }
        )
    }

    private var languageBinding: Binding<PreviewSettings.AppLanguage> {
        Binding(
            get: { settingsStore.settings.language },
            set: { settingsStore.updateLanguage($0) }
        )
    }

    private var fontSizeBinding: Binding<PreviewSettings.FontSize> {
        Binding(
            get: { settingsStore.settings.fontSize },
            set: { settingsStore.updateFontSize($0) }
        )
    }

    private var contentWidthBinding: Binding<PreviewSettings.ContentWidth> {
        Binding(
            get: { settingsStore.settings.contentWidth },
            set: { settingsStore.updateContentWidth($0) }
        )
    }

    private var editorBinding: Binding<String> {
        Binding(
            get: { previewStore.currentMarkdown },
            set: { previewStore.updateCurrentMarkdown($0) }
        )
    }

    private var workspaceMode: PreviewSettings.WorkspaceMode {
        settingsStore.settings.workspaceMode
    }

    private var workspaceModeBinding: Binding<PreviewSettings.WorkspaceMode> {
        Binding(
            get: { settingsStore.settings.workspaceMode },
            set: { settingsStore.updateWorkspaceMode($0) }
        )
    }
}

#Preview {
    ContentView()
        .environmentObject(MarkdownPreviewStore.shared)
}

@MainActor
final class PreviewSettingsStore: ObservableObject {
    static let shared = PreviewSettingsStore()

    @Published private(set) var settings: PreviewSettings

    init(settings: PreviewSettings = .load()) {
        self.settings = settings
    }

    func updateLanguage(_ language: PreviewSettings.AppLanguage) {
        var updated = settings
        updated.language = language
        apply(updated)
    }

    func updateTheme(_ theme: PreviewSettings.ThemePreset) {
        var updated = settings
        updated.theme = theme
        apply(updated)
    }

    func updateFontSize(_ fontSize: PreviewSettings.FontSize) {
        var updated = settings
        updated.fontSize = fontSize
        apply(updated)
    }

    func updateContentWidth(_ contentWidth: PreviewSettings.ContentWidth) {
        var updated = settings
        updated.contentWidth = contentWidth
        apply(updated)
    }

    func updateWorkspaceMode(_ workspaceMode: PreviewSettings.WorkspaceMode) {
        var updated = settings
        updated.workspaceMode = workspaceMode
        apply(updated, refreshPreview: false)
    }

    private func apply(_ updated: PreviewSettings, refreshPreview: Bool = true) {
        updated.save()
        settings = updated
        if refreshPreview {
            MarkdownPreviewStore.shared.refreshForSettingsChange()
        }
    }
}

private extension View {
    func panelStyle() -> some View {
        padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
    }
}
