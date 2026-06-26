//
//  MainListView.swift
//  Unagent
//
//  Created by シン・ジャスティン on 2024/03/08.
//

import StoreKit
import SwiftUI

struct MainListView: View {

    @Environment(\.requestReview) var requestReview
    @AppStorage(wrappedValue: false, "ReviewPrompted", store: .standard) var hasReviewBeenPrompted: Bool
    @AppStorage(wrappedValue: 0, "LaunchCount", store: .standard) var launchCount: Int

    @State var presetStore = PresetStore()
    @State var presetUpdater = PresetUpdater()

    var body: some View {
        NavigationStack {
            List {
                SetUpView()
                SettingsView()
                PresetsView()
                MoreView()
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(.compact)
            .scrollContentBackground(.hidden)
            .gradientBackground()
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle("Unagent")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await presetUpdater.checkForUpdatesQuietly()
            }
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
