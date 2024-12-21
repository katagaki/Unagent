//
//  SiteSettingsView.swift
//  Unagent
//
//  Created by シンジャスティン on 2023/05/28.
//

import SwiftUI

struct SiteSettingsView: View {
    
    let defaults: UserDefaults = UserDefaults(suiteName: "group.\(Bundle.main.bundleIdentifier!)")!
    
    @State var siteSettings: [SiteSetting] = []
    @State var willSaveSiteSettingsToMemory: Bool = false
    
    @State var isShowingNewSiteSettingView: Bool = false
    @State var newSiteSettingDomain: String = ""
    @State var newSiteSettingUserAgent: String = ""
    @State var newSiteSettingShouldSave: Bool = false
    
    @State var isShowingEditSiteSettingView: Bool = false
    @State var editingSiteSettingDomain: String = ""
    @State var editingSiteSettingUserAgent: String = ""
    @State var editingSiteSettingShouldSave: Bool = false
    
    var body: some View {
        NavigationStack {
            Group {
                if siteSettings.isEmpty {
                    if #available(iOS 17.0, *) {
                        ContentUnavailableView("SiteSettings.EmptyText.Title", systemImage: "plus.square.on.square", description: Text("SiteSettings.EmptyText.Text"))
                    } else {
                        Text("SiteSettings.EmptyText.Text")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                } else {
                    List(siteSettings, id: \.domain) { siteSetting in
                        SiteSettingRow(title: siteSetting.domain,
                                       subtitle: siteSetting.userAgent)
                        .swipeActions {
                            Button("Shared.Delete") {
                                siteSettings.removeAll(where: {$0.domain == siteSetting.domain})
                                saveToMemory()
                            }
                            .tint(.red)
                            Button("Shared.Edit") {
                                editingSiteSettingDomain = siteSetting.domain
                                editingSiteSettingUserAgent = siteSetting.userAgent
                                isShowingEditSiteSettingView = true
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
            .navigationTitle("ViewTitle.SiteSettings")
            .sheet(isPresented: $isShowingNewSiteSettingView, content: {
                SiteSettingEditor(mode: .new,
                                  domain: $newSiteSettingDomain,
                                  userAgent: $newSiteSettingUserAgent,
                                  shouldSave: $newSiteSettingShouldSave)
                .presentationDetents([.large, .medium])
            })
            .sheet(isPresented: $isShowingEditSiteSettingView, content: {
                SiteSettingEditor(mode: .edit,
                                  domain: $editingSiteSettingDomain,
                                  userAgent: $editingSiteSettingUserAgent,
                                  shouldSave: $editingSiteSettingShouldSave)
                .presentationDetents([.large, .medium])
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
                if !newValue && newSiteSettingShouldSave {
                    siteSettings.append(SiteSetting(domain: newSiteSettingDomain,
                                                    userAgent: newSiteSettingUserAgent))
                    newSiteSettingDomain = ""
                    newSiteSettingUserAgent = ""
                    newSiteSettingShouldSave = false
                    saveToMemory()
                }
            })
            .onChange(of: isShowingEditSiteSettingView, perform: { newValue in
                if !newValue && editingSiteSettingShouldSave {
                    if let indexOfEditingSiteSetting = siteSettings.firstIndex(where: {$0.domain == editingSiteSettingDomain}) {
                        siteSettings[indexOfEditingSiteSetting] = SiteSetting(
                            domain: editingSiteSettingDomain,
                            userAgent: editingSiteSettingUserAgent
                        )
                        editingSiteSettingDomain = ""
                        editingSiteSettingUserAgent = ""
                        editingSiteSettingShouldSave = false
                        saveToMemory()
                    }
                }
            })
            .scrollDismissesKeyboard(.immediately)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Shared.Add", systemImage: "plus") {
                        isShowingNewSiteSettingView = true
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
            defaults.set(true, forKey: "ShouldExtensionUpdate")
            defaults.synchronize()
        }
    }
}
