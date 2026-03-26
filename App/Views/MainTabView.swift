//
//  MainTabView.swift
//  Unagent
//
//  Created by シン・ジャスティン on 2024/03/08.
//

import StoreKit
import SwiftUI

struct MainTabView: View {

    @Environment(\.requestReview) var requestReview
    @AppStorage(wrappedValue: false, "ReviewPrompted", store: .standard) var hasReviewBeenPrompted: Bool
    @AppStorage(wrappedValue: 0, "LaunchCount", store: .standard) var launchCount: Int

    @State var selectedTab: String = "Settings"
    @State var presetStore = PresetStore()
    @State var presetUpdater = PresetUpdater()
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Tab.SetUp", systemImage: "checklist", value: "SetUp") {
                SetUpView()
            }
            Tab("Tab.Settings", systemImage: "gearshape", value: "Settings") {
                SettingsView()
            }
            Tab("Tab.Presets", systemImage: "star", value: "Presets") {
                PresetsView()
            }
            Tab("Tab.More", systemImage: "ellipsis", value: "More") {
                MoreView()
            }
            .badge(presetUpdater.pendingUpdates.count)
        }
        .environment(presetStore)
        .environment(presetUpdater)
        .task {
            launchCount += 1
            if launchCount > 2 && !hasReviewBeenPrompted {
                requestReview()
                hasReviewBeenPrompted = true
            }
            await presetUpdater.checkForUpdatesQuietly()
        }
    }
}
