//
//  MainTabView.swift
//  Unagent
//
//  Created by シン・ジャスティン on 2024/03/08.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            SetUpView()
                .tabItem {
                    Label("Set Up", systemImage: "checklist")
                }
            GlobalSettingsView()
                .tabItem {
                    Label("Global Settings", systemImage: "gear")
                }
            SiteSettingsView()
                .tabItem {
                    Label("Site Settings", systemImage: "globe")
                }
            MoreView()
                .tabItem {
                    Label("More", systemImage: "ellipsis")
                }
        }
    }
}
