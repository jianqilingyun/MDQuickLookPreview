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

                Button(strings.reload) {
                    previewStore.reloadCurrentDocument()
                }
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
                settingsPanel
            }
            .padding(24)
        }
    }

    private var detail: some View {
        Group {
            if let document = previewStore.currentDocument {
                MarkdownWebView(document: document, baseURL: previewStore.baseURL)
                    .background(Color(nsColor: .windowBackgroundColor))
            } else {
                emptyState
            }
        }
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
        }
        .panelStyle()
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

    private func apply(_ updated: PreviewSettings) {
        updated.save()
        settings = updated
        MarkdownPreviewStore.shared.refreshForSettingsChange()
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
