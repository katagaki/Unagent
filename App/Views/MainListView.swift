import StoreKit
import SwiftUI

struct MainListView: View {

    @Environment(\.requestReview) var requestReview
    @AppStorage(wrappedValue: false, "ReviewPrompted", store: .standard) var hasReviewBeenPrompted: Bool
    @AppStorage(wrappedValue: 0, "LaunchCount", store: .standard) var launchCount: Int

    @Environment(\.scenePhase) private var scenePhase

    @State var presetStore = PresetStore()
    @State var presetUpdater = PresetUpdater()
    @State private var monitor = ExtensionActivationMonitor()

    @State private var isShowingAttributions: Bool = false
    @State private var isShowingNewSiteSetting: Bool = false
    @State private var isShowingNewPreset: Bool = false

    @AppStorage(wrappedValue: false, "AutoRefreshEnabled", store: defaults) private var isAutoRefreshEnabled: Bool
    @State private var isShowingAutoRefreshAlert: Bool = false

    @State private var isiCloudAvailable: Bool = false
    @State private var isShowingBackupAlert: Bool = false
    @State private var isShowingRestore: Bool = false

    @State private var isExportingBackup: Bool = false
    @State private var backupDocument: BackupDocument?
    @State private var backupExportName: String = ""

    @State private var isShowingBackupComplete: Bool = false
    @State private var backupErrorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24.0) {
                    if !monitor.isFullySetUp {
                        SetUpView(monitor: monitor)
                    }
                    SettingsView(isShowingNewSiteSettingView: $isShowingNewSiteSetting)
                    PresetsView(isShowingNewPreset: $isShowingNewPreset)
                }
                .padding(.vertical, 8.0)
            }
            .contentMargins(.top, 0, for: .scrollContent)
            .scrollDismissesKeyboard(.immediately)
            .gradientBackground()
            .navigationTitle("Unagent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        if !presetUpdater.pendingUpdates.isEmpty {
                            Section {
                                Button {
                                    withAnimation(.smooth.speed(2)) {
                                        presetUpdater.applyAllPendingUpdates()
                                        presetStore.loadPresets()
                                    }
                                } label: {
                                    Label("More.PresetUpdates.UpdateAllPresets", systemImage: "arrow.down.circle")
                                }
                            }
                        }
                        Section("More.ExtensionSettings") {
                            Button("More.AutoRefresh") {
                                isShowingAutoRefreshAlert = true
                            }
                        }
                        if isiCloudAvailable {
                            Section("More.ManageData") {
                                Button {
                                    isShowingBackupAlert = true
                                } label: {
                                    Label("More.Backup", systemImage: "arrow.up.doc")
                                }
                                Button {
                                    isShowingRestore = true
                                } label: {
                                    Label("More.Restore", systemImage: "arrow.down.doc")
                                }
                            }
                        }
                        Section {
                            Link(destination: URL(string: "https://github.com/katagaki/Unagent")!) {
                                Label("More.SourceCode", systemImage: "chevron.left.forwardslash.chevron.right")
                            }
                            Button("More.Attribution") {
                                isShowingAttributions = true
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
                bottomBarContent
            }
            .navigationDestination(isPresented: $isShowingAttributions) {
                AttributionsView()
            }
            .navigationDestination(isPresented: $isShowingRestore) {
                RestoreView()
            }
            .alert("More.AutoRefresh", isPresented: $isShowingAutoRefreshAlert) {
                Button("More.AutoRefresh.ReloadAutomatically") {
                    setAutoRefresh(true)
                }
                Button("More.AutoRefresh.DoNotReload") {
                    setAutoRefresh(false)
                }
            } message: {
                Text("More.AutoRefresh.Description")
                + Text("\n\n")
                + currentAutoRefreshBehavior
            }
            .alert("More.Backup.ChooseDestination", isPresented: $isShowingBackupAlert) {
                Button("More.Backup.ToiCloud") {
                    backUpToiCloud()
                }
                Button("More.Backup.ToFile") {
                    prepareFileBackup()
                }
                Button("Shared.Cancel", role: .cancel) { }
            }
            .fileExporter(
                isPresented: $isExportingBackup,
                document: backupDocument,
                contentType: .json,
                defaultFilename: backupExportName
            ) { result in
                switch result {
                case .success:
                    isShowingBackupComplete = true
                case .failure(let error):
                    if (error as? CocoaError)?.code != .userCancelled {
                        backupErrorMessage = error.localizedDescription
                    }
                }
                backupDocument = nil
            }
            .alert("More.Backup.Complete", isPresented: $isShowingBackupComplete) {
                Button("Shared.OK") { }
            } message: {
                Text("More.Backup.Complete.Message")
            }
            .alert(
                "More.Backup.Failed",
                isPresented: Binding(
                    get: { backupErrorMessage != nil },
                    set: { if !$0 { backupErrorMessage = nil } }
                )
            ) {
                Button("Shared.OK") {
                    backupErrorMessage = nil
                }
            } message: {
                Text(backupErrorMessage ?? "")
            }
            .refreshable {
                await presetUpdater.checkForUpdatesQuietly()
            }
        }
        .environment(presetStore)
        .environment(presetUpdater)
        .task {
            monitor.refresh()
            isiCloudAvailable = BackupManager.isiCloudAvailable
            launchCount += 1
            if launchCount > 2 && !hasReviewBeenPrompted {
                requestReview()
                hasReviewBeenPrompted = true
            }
            await presetUpdater.checkForUpdatesQuietly()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                isiCloudAvailable = BackupManager.isiCloudAvailable
                withAnimation(.smooth.speed(2)) { monitor.refresh() }
            }
        }
    }

    // A trailing "+" menu in the bottom toolbar, pushed to the trailing edge
    // with a flexible spacer (with a fallback for iOS 18–25).
    @ToolbarContentBuilder
    private var bottomBarContent: some ToolbarContent {
        if #available(iOS 26.0, *) {
            ToolbarSpacer(.flexible, placement: .bottomBar)
            ToolbarItem(placement: .bottomBar) {
                addMenu
            }
        } else {
            ToolbarItemGroup(placement: .bottomBar) {
                Spacer()
                addMenu
            }
        }
    }

    private var currentAutoRefreshBehavior: Text {
        let behavior = String(localized: isAutoRefreshEnabled
            ? "More.AutoRefresh.ReloadAutomatically"
            : "More.AutoRefresh.DoNotReload")
        let format = String(localized: "More.AutoRefresh.CurrentBehavior")
        return Text(String(format: format, behavior))
    }

    private func setAutoRefresh(_ enabled: Bool) {
        defaults.set(enabled, forKey: "AutoRefreshEnabled")
        defaults.set(true, forKey: "ShouldExtensionUpdate")
    }

    private func backUpToiCloud() {
        Task {
            do {
                try await BackupManager.backUpToiCloud(timestamp: Date())
                isShowingBackupComplete = true
            } catch {
                backupErrorMessage = error.localizedDescription
            }
        }
    }

    private func prepareFileBackup() {
        let timestamp = Date()
        let backup = BackupManager.snapshot(timestamp: timestamp)
        do {
            let data = try BackupManager.encode(backup)
            backupDocument = BackupDocument(data: data)
            backupExportName = BackupManager.defaultExportName(for: timestamp)
            isExportingBackup = true
        } catch {
            backupErrorMessage = error.localizedDescription
        }
    }

    private var addMenu: some View {
        Menu {
            Button {
                isShowingNewSiteSetting = true
            } label: {
                Label("ViewTitle.SiteSettings.New", systemImage: "globe")
            }
            Button {
                isShowingNewPreset = true
            } label: {
                Label("ViewTitle.Presets.New", systemImage: "star")
            }
        } label: {
            Image(systemName: "plus")
        }
    }
}
