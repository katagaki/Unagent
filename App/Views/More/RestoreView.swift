import SwiftUI

struct RestoreView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(PresetStore.self) private var presetStore

    @State private var backups: [BackupFile] = []
    @State private var isLoading: Bool = true

    @State private var isImportingFile: Bool = false

    @State private var pendingBackup: BackupData?
    @State private var isShowingStrategyAlert: Bool = false

    @State private var isShowingRestoreComplete: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                Button {
                    isImportingFile = true
                } label: {
                    Label("Restore.OpenFile", systemImage: "folder")
                }
            } footer: {
                Text("Restore.OpenFile.Description")
            }

            Section {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding(.vertical, 8.0)
                } else if backups.isEmpty {
                    ContentUnavailableView(
                        "Restore.NoBackups.Title",
                        systemImage: "icloud.slash",
                        description: Text("Restore.NoBackups.Text")
                    )
                } else {
                    ForEach(backups) { backup in
                        Button {
                            loadiCloudBackup(backup)
                        } label: {
                            HStack {
                                Label {
                                    Text(backup.timestamp, format: .dateTime
                                        .year().month().day().hour().minute())
                                    .foregroundStyle(.primary)
                                } icon: {
                                    Image(systemName: "clock.arrow.circlepath")
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            } header: {
                Text("Restore.iCloudBackups")
            }
        }
        .scrollContentBackground(.hidden)
        .gradientBackground()
        .navigationTitle("ViewTitle.Restore")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await reloadBackups()
        }
        .fileImporter(
            isPresented: $isImportingFile,
            allowedContentTypes: [.json]
        ) { result in
            handleFileImport(result)
        }
        .alert("Restore.ChooseStrategy", isPresented: $isShowingStrategyAlert) {
            Button("Restore.Merge") {
                applyRestore(strategy: .merge)
            }
            Button("Restore.Overwrite", role: .destructive) {
                applyRestore(strategy: .overwrite)
            }
            Button("Shared.Cancel", role: .cancel) {
                pendingBackup = nil
            }
        } message: {
            Text("Restore.ChooseStrategy.Description")
        }
        .alert("Restore.Complete", isPresented: $isShowingRestoreComplete) {
            Button("Shared.OK") {
                dismiss()
            }
        } message: {
            Text("Restore.Complete.Message")
        }
        .alert(
            "Restore.Failed",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("Shared.OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func reloadBackups() async {
        isLoading = true
        backups = await BackupManager.listiCloudBackups()
        isLoading = false
    }

    private func loadiCloudBackup(_ file: BackupFile) {
        Task {
            do {
                let backup = try await BackupManager.loadBackup(at: file.url)
                pendingBackup = backup
                isShowingStrategyAlert = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func handleFileImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            Task {
                let didAccess = url.startAccessingSecurityScopedResource()
                defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
                do {
                    let data = try Data(contentsOf: url)
                    pendingBackup = try BackupManager.decode(data)
                    isShowingStrategyAlert = true
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        case .failure(let error):
            if (error as? CocoaError)?.code != .userCancelled {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func applyRestore(strategy: BackupManager.RestoreStrategy) {
        guard let backup = pendingBackup else { return }
        BackupManager.restore(backup, strategy: strategy)
        presetStore.loadPresets()
        pendingBackup = nil
        isShowingRestoreComplete = true
    }
}
