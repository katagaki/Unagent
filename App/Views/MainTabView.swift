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
    @AppStorage(wrappedValue: false, "HideSetUpTab") var hideSetUpTab: Bool
    @AppStorage(wrappedValue: false, "ReviewPrompted", store: .standard) var hasReviewBeenPrompted: Bool
    @AppStorage(wrappedValue: 0, "LaunchCount", store: .standard) var launchCount: Int

    var body: some View {
        TabView {
            // TODO: Cannot be refactored, will cause More tab to exhibit odd behavior
            if !hideSetUpTab {
                SetUpView()
                    .tabItem {
                        Label("Tab.SetUp", systemImage: "checklist")
                    }
                GlobalSettingsView()
                    .tabItem {
                        Label("Tab.GlobalSettings", systemImage: "gear")
                    }
                SiteSettingsView()
                    .tabItem {
                        Label("Tab.SiteSettings", systemImage: "globe")
                    }
                MoreView()
                    .tabItem {
                        Label("Tab.More", systemImage: "ellipsis")
                    }
            } else {
                GlobalSettingsView()
                    .tabItem {
                        Label("Tab.GlobalSettings", systemImage: "gear")
                    }
                SiteSettingsView()
                    .tabItem {
                        Label("Tab.SiteSettings", systemImage: "globe")
                    }
                MoreView()
                    .tabItem {
                        Label("Tab.More", systemImage: "ellipsis")
                    }
            }
        }
        .task {
            launchCount += 1
            if launchCount > 2 && !hasReviewBeenPrompted {
                requestReview()
                hasReviewBeenPrompted = true
            }
        }
    }
}
