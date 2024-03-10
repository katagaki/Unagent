//
//  MainTabView.swift
//  Unagent
//
//  Created by シン・ジャスティン on 2024/03/08.
//

import SwiftUI

struct MainTabView: View {

    @AppStorage(wrappedValue: false, "HideSetUpTab") var hideSetUpTab: Bool

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
    }
}
