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

    @State private var isShowingAutoRefreshAlert: Bool = false

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
            .alert("More.AutoRefresh", isPresented: $isShowingAutoRefreshAlert) {
                Button("Shared.TurnOn") {
                    setAutoRefresh(true)
                }
                Button("Shared.TurnOff") {
                    setAutoRefresh(false)
                }
            } message: {
                Text("More.AutoRefresh.Description")
            }
            .refreshable {
                await presetUpdater.checkForUpdatesQuietly()
            }
        }
        .environment(presetStore)
        .environment(presetUpdater)
        .task {
            monitor.refresh()
            launchCount += 1
            if launchCount > 2 && !hasReviewBeenPrompted {
                requestReview()
                hasReviewBeenPrompted = true
            }
            await presetUpdater.checkForUpdatesQuietly()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
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

    private func setAutoRefresh(_ enabled: Bool) {
        defaults.set(enabled, forKey: "AutoRefreshEnabled")
        defaults.set(true, forKey: "ShouldExtensionUpdate")
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
