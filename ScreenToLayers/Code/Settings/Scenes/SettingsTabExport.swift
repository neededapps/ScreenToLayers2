
import SwiftUI
import QuartzCore

public struct SettingsTabExport: View {
    
    // MARK: Initializer
    
    public init(userSettings: UserSettings) {
        self.userSettings = userSettings
    }
    
    // MARK: States
    
    @ObservedObject
    private var userSettings: UserSettings
    
    @State
    private var showsExportChooser: Bool = false
    
    @State
    private var hoverExportDestination: Bool = false
    
    @State
    private var wrappedError: WrappedError = .none
    
    // MARK: Views
    
    public var body: some View {
        VStack(spacing: 8.0) {
            Grid(alignment: .leading, horizontalSpacing: 20.0, verticalSpacing: 8.0) {
                GridRow {
                    Text("Open the files after exporting them")
                        .gridCellAnchor(.topLeading)
                        .gridColumnAlignment(.leading)
                    Spacer()
                    Toggle(isOn: userSettings.$opensFilesAfterExport) {
                        Text("Open the files after exporting them")
                    }
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .gridColumnAlignment(.trailing)
                }
                GridRow {
                    Text("Open the folder after exporting files")
                        .gridCellAnchor(.topLeading)
                        .gridColumnAlignment(.leading)
                    Spacer()
                    Toggle(isOn: userSettings.$opensFolderAfterExport) {
                        Text("Open the export folder after exporting files")
                    }
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .gridColumnAlignment(.trailing)
                }
            }
            Divider().padding(.vertical, 8.0)
            HStack {
                Text("Export destination")
                    .gridCellAnchor(.topLeading)
                    .gridColumnAlignment(.leading)
                Spacer(minLength: 0.0)
                HStack {
                    Button("Choose") {
                        showsExportChooser = true
                    }
                    .controlSize(.small)
                    Button("Reset") {
                        Task { await setExportDirectory(url: nil) }
                    }
                    .controlSize(.small)
                }
            }
            Text(userSettings.userExportDirectoryURL?.abreviatedContainerPath() ?? "No path set")
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .foregroundStyle(.primary)
                .padding(.horizontal, 12.0)
                .padding(.vertical, 6.0)
                .background {
                    RoundedRectangle(cornerRadius: 4.0)
                        .fill(Color.textBackground)
                        .stroke(
                            hoverExportDestination
                            ? Color.accentColor
                            : Color.gray.opacity(0.0),
                            lineWidth: 1.0
                        )
                }
                .gridCellColumns(2)
                .padding(.top, 2.0)
                .pointerStyle(.link)
                .onHover { hoverExportDestination = $0 }
                .onTapGesture {
                    guard let urlToOpen = userSettings.userExportDirectoryURL else { return }
                    NSWorkspace.shared.activateFileViewerSelecting([urlToOpen])
                }
                .animation(.default, value: hoverExportDestination)
        }
        .fileImporter(isPresented: $showsExportChooser, allowedContentTypes: [.folder]) {
            guard case .success(let url) = $0 else { return }
            Task { await setExportDirectory(url: url) }
        }
        .fileDialogMessage("Select the folder where you want to export your files.")
        .fileDialogConfirmationLabel("Select")
        .alert(isPresented: $wrappedError.isPresented(), error: wrappedError, actions: { })
        .padding(30.0)
        .tabItem { Label("Export", systemImage: "square.and.arrow.up") }
        .frame(width: 400.0)
        .fixedSize(horizontal: true, vertical: true)
    }
    
    // MARK: Actions
    
    private func setExportDirectory(url: URL?) async {
        do {
            try await userSettings.setExportDirectory(url: url)
        } catch let error {
            wrappedError = .wrapped(error)
        }
    }
}

#Preview {
    PreviewEnvironmentsWrapView { data in
        SettingsTabExport(userSettings: data.userSettings)
    }
}
