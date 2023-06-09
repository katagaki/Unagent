//
//  SiteSettingsView.swift
//  Unagent
//
//  Created by シンジャスティン on 2023/05/28.
//

import SwiftUI

struct SiteSettingsView: View {
    
    let defaults: UserDefaults = UserDefaults(suiteName: "group.com.tsubuzaki.BingBong")!
    
    @State var siteSettings: [SiteSetting] = []
    @State var willSaveSiteSettingsToMemory: Bool = false
    @State var isShowingNewSiteSettingView: Bool = false
    
    @State var newSiteSettingDomain: String = ""
    @State var newSiteSettingUserAgent: String = ""
    @State var newSiteSettingWillBeCreated: Bool = false
    
    var body: some View {
        NavigationStack {
            List(siteSettings, id: \.domain) { siteSetting in
                HStack(spacing: 8.0) {
                    Image(systemName: "globe")
                    VStack(alignment: .leading, spacing: 2.0) {
                        Text(siteSetting.domain)
                        Text(siteSetting.userAgent)
                            .font(.caption)
                    }
                }
                .swipeActions {
                    Button("Delete") {
                        siteSettings.removeAll(where: {$0.domain == siteSetting.domain})
                        saveToMemory()
                    }
                    .tint(.red)
                }
            }
            .navigationTitle("Site Settings")
            .sheet(isPresented: $isShowingNewSiteSettingView, content: {
                SiteSettingsNewView(domain: $newSiteSettingDomain,
                                    userAgent: $newSiteSettingUserAgent,
                                    willCreateSiteSetting: $newSiteSettingWillBeCreated)
                .presentationDetents([.medium])
            })
            .onAppear {
                let decoder = JSONDecoder()
                if defaults.string(forKey: "SiteSettings") != nil {
                    if let jsonString = defaults.string(forKey: "SiteSettings"),
                       let jsonData = jsonString.data(using: .utf8),
                       let siteSettings = try? decoder.decode([SiteSetting].self, from: jsonData) {
                        self.siteSettings = siteSettings
                    }
                } else {
                    defaults.set([] as [SiteSetting], forKey: "SiteSettings")
                }
                willSaveSiteSettingsToMemory = true
            }
            .onChange(of: isShowingNewSiteSettingView, perform: { newValue in
                if !newValue && newSiteSettingWillBeCreated {
                    siteSettings.append(SiteSetting(domain: newSiteSettingDomain,
                                                    userAgent: newSiteSettingUserAgent))
                    newSiteSettingDomain = ""
                    newSiteSettingUserAgent = ""
                    newSiteSettingWillBeCreated = false
                    saveToMemory()
                }
            })
            .scrollDismissesKeyboard(.immediately)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isShowingNewSiteSettingView = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
    
    func saveToMemory() {
        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(siteSettings),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            defaults.set(jsonString, forKey: "SiteSettings")
        }
    }
}
