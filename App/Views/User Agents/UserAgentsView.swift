//
//  UserAgentsView.swift
//  Unagent
//
//  Created by シン・ジャスティン on 2025/08/24.
//

import Komponents
import SwiftUI

struct UserAgentsView: View {

    @AppStorage(wrappedValue: "", "UserAgent", store: defaults) var globalUserAgent: String
    @AppStorage(wrappedValue: "", "GlobalViewport", store: defaults) var globalViewportString: String
    @AppStorage(wrappedValue: "", "SiteSettings", store: defaults) var perSiteUserAgentData: String

    let decoder = JSONDecoder()
    let encoder = JSONEncoder()
    var perSiteSettings: [SiteSetting] {
        guard let jsonData = perSiteUserAgentData.data(using: .utf8) else { return [] }
        guard let siteSettings: [SiteSetting] = try? decoder.decode(
            [SiteSetting].self,
            from: jsonData
        ) else { return [] }
        return siteSettings
    }
    
    var globalViewport: Viewport? {
        get {
            if globalViewportString.isEmpty {
                return nil
            }
            return Viewport(rawValue: globalViewportString)
        }
    }

    @State var isShowingNewSiteSettingView: Bool = false
    @State var newSiteSettingDomain: String = ""
    @State var newSiteSettingUserAgent: String = ""
    @State var newSiteSettingViewport: Viewport? = nil
    @State var newSiteSettingShouldSave: Bool = false

    @State var isShowingEditSiteSettingView: Bool = false
    @State var editingSiteSettingDomain: String = ""
    @State var editingSiteSettingUserAgent: String = ""
    @State var editingSiteSettingViewport: Viewport? = nil
    @State var editingSiteSettingShouldSave: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextEditor(text: $globalUserAgent)
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                        .font(
                            .monospaced(
                                .custom(
                                    "", size: 14.0, relativeTo: .body
                                )
                            )()
                        )
                        .frame(height: 80)
                        .scrollIndicators(.never)
                    Menu {
                        PresetsSection {
                            return globalUserAgent
                        } onSelect: { newUserAgent in
                            globalUserAgent = newUserAgent
                        }
                    } label: {
                        Text("Shared.SelectPreset")
                    }
                } header: {
                    HStack(alignment: .center) {
                        Text("UserAgent.Global")
                        Spacer()
                        if UIPasteboard.general.hasStrings {
                            Button("Shared.Paste") {
                                if let pasteboardString = UIPasteboard.general.string {
                                    globalUserAgent = pasteboardString
                                }
                            }
                            .textCase(.none)
                        }
                    }
                } footer: {
                    Text("GlobalSettings.GlobalUserAgent.Footer")
                }
                Section {
                    Picker("Viewport", selection: Binding(
                        get: { globalViewport ?? .none },
                        set: { newValue in
                            globalViewportString = newValue.rawValue
                            synchronizeDefaults()
                        }
                    )) {
                        Text("Default").tag(Viewport.none)
                        ForEach(Viewport.allCases.filter { $0 != .none }, id: \.self) { viewportOption in
                            Text(viewportOption.displayName).tag(viewportOption)
                        }
                    }
                } header: {
                    Text("Viewport.Global")
                } footer: {
                    Text("GlobalSettings.GlobalViewport.Footer")
                }
                Section {
                    if perSiteSettings.isEmpty {
                        if #available(iOS 17.0, *) {
                            ContentUnavailableView(
                                "SiteSettings.EmptyText.Title",
                                systemImage: "plus.square.on.square",
                                description: Text("SiteSettings.EmptyText.Text")
                            )
                        } else {
                            Text("SiteSettings.EmptyText.Text")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                    } else {
                        ForEach(perSiteSettings, id: \.domain) { siteSetting in
                            Button {
                                startEditingPerSiteSetting(siteSetting)
                            } label: {
                                SiteSettingRow(
                                    title: siteSetting.domain,
                                    subtitle: siteSetting.userAgent
                                )
                            }
                            .swipeActions {
                                Button("Shared.Delete") {
                                    deletePerSiteSetting(siteSetting)
                                }
                                .tint(.red)
                                Button("Shared.Edit") {
                                    startEditingPerSiteSetting(siteSetting)
                                }
                                .tint(.blue)
                            }
                        }
                    }
                } header: {
                    HStack(alignment: .center) {
                        Text("UserAgent.PerSite")
                        Spacer()
                        Button("Shared.Add", systemImage: "plus") {
                            isShowingNewSiteSettingView = true
                        }
                    }
                }
            }
            .navigationTitle("ViewTitle.UserAgents")
            .onChange(of: globalUserAgent, synchronizeDefaults)
            .onChange(of: isShowingNewSiteSettingView, createNewPerSiteSetting)
            .onChange(of: isShowingEditSiteSettingView, editPerSiteSetting)
            .scrollDismissesKeyboard(.immediately)
            .sheet(isPresented: $isShowingNewSiteSettingView) {
                SiteSettingEditor(mode: .new,
                                  domain: $newSiteSettingDomain,
                                  userAgent: $newSiteSettingUserAgent,
                                  viewport: $newSiteSettingViewport,
                                  shouldSave: $newSiteSettingShouldSave)
                .presentationDetents([.large, .medium])
            }
            .sheet(isPresented: $isShowingEditSiteSettingView) {
                SiteSettingEditor(mode: .edit,
                                  domain: $editingSiteSettingDomain,
                                  userAgent: $editingSiteSettingUserAgent,
                                  viewport: $editingSiteSettingViewport,
                                  shouldSave: $editingSiteSettingShouldSave)
                .presentationDetents([.large, .medium])
            }
        }
    }

    func synchronizeDefaults() {
        defaults.set(true, forKey: "ShouldExtensionUpdate")
        defaults.synchronize()
    }

    func createNewPerSiteSetting() {
        if !isShowingNewSiteSettingView && newSiteSettingShouldSave {
            var newSiteSettings: [SiteSetting] = []
            newSiteSettings.append(contentsOf: perSiteSettings)
            newSiteSettings.append(
                SiteSetting(
                    domain: newSiteSettingDomain,
                    userAgent: newSiteSettingUserAgent,
                    viewport: newSiteSettingViewport
                )
            )
            updatePerSiteSettings(newSiteSettings)

            newSiteSettingDomain = ""
            newSiteSettingUserAgent = ""
            newSiteSettingViewport = nil
            newSiteSettingShouldSave = false
        }
    }

    func editPerSiteSetting() {
        if !isShowingEditSiteSettingView && editingSiteSettingShouldSave {
            if let indexOfEditingSiteSetting = perSiteSettings.firstIndex(
                where: {$0.domain == editingSiteSettingDomain}
            ) {
                var newSiteSettings: [SiteSetting] = []
                newSiteSettings.append(contentsOf: perSiteSettings)

                newSiteSettings[indexOfEditingSiteSetting] = SiteSetting(
                    domain: editingSiteSettingDomain,
                    userAgent: editingSiteSettingUserAgent,
                    viewport: editingSiteSettingViewport
                )
                updatePerSiteSettings(newSiteSettings)

                editingSiteSettingDomain = ""
                editingSiteSettingUserAgent = ""
                editingSiteSettingViewport = nil
                editingSiteSettingShouldSave = false
            }
        }
    }

    func deletePerSiteSetting(_ siteSetting: SiteSetting) {
        updatePerSiteSettings(
            perSiteSettings.filter({
                $0.domain != siteSetting.domain
            })
        )
    }

    func startEditingPerSiteSetting(_ siteSetting: SiteSetting) {
        editingSiteSettingDomain = siteSetting.domain
        editingSiteSettingUserAgent = siteSetting.userAgent
        editingSiteSettingViewport = siteSetting.viewport
        isShowingEditSiteSettingView = true
    }

    func updatePerSiteSettings(_ newSiteSettings: [SiteSetting]) {
        if let jsonData = try? encoder.encode(newSiteSettings),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            perSiteUserAgentData = jsonString
            synchronizeDefaults()
        }
    }
}
