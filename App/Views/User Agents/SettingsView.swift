import SwiftUI

struct SettingsView: View {

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

    @Binding var isShowingNewSiteSettingView: Bool
    @State var newSiteSettingDomain: String = ""
    @State var newSiteSettingUserAgent: String = ""
    @State var newSiteSettingViewport: Viewport?
    @State var newSiteSettingShouldSave: Bool = false

    @State var isShowingEditSiteSettingView: Bool = false
    @State var editingSiteSettingDomain: String = ""
    @State var editingSiteSettingUserAgent: String = ""
    @State var editingSiteSettingViewport: Viewport?
    @State var editingSiteSettingShouldSave: Bool = false

    var body: some View {
        Group {
            GroupedSection {
                GroupedNavigationRow {
                    GlobalSettingsView(
                        globalUserAgent: $globalUserAgent,
                        globalViewportString: $globalViewportString,
                        synchronizeDefaults: synchronizeDefaults
                    )
                } label: {
                    Label("ViewTitle.GlobalSettings", systemImage: "globe")
                }
            }

            GroupedSection {
                if perSiteSettings.isEmpty {
                    ContentUnavailableView(
                        "SiteSettings.EmptyText.Title",
                        systemImage: "plus.square.on.square",
                        description: Text("SiteSettings.EmptyText.Text")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8.0)
                } else {
                    ForEach(Array(perSiteSettings.enumerated()), id: \.element.domain) { index, siteSetting in
                        if index > 0 { GroupedDivider() }
                        Button {
                            startEditingPerSiteSetting(siteSetting)
                        } label: {
                            SiteSettingRow(
                                title: siteSetting.domain,
                                subtitle: siteSetting.userAgent
                            )
                            .groupedRowPadding()
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(GroupedRowButtonStyle())
                        .contextMenu {
                            Button("Shared.Edit") {
                                startEditingPerSiteSetting(siteSetting)
                            }
                            Button("Shared.Delete", role: .destructive) {
                                deletePerSiteSetting(siteSetting)
                            }
                        }
                    }
                }
            } header: {
                Text("UserAgent.PerSite")
            }
        }
        .onChange(of: globalUserAgent, synchronizeDefaults)
        .onChange(of: isShowingNewSiteSettingView, createNewPerSiteSetting)
        .onChange(of: isShowingEditSiteSettingView, editPerSiteSetting)
        .sheet(isPresented: $isShowingNewSiteSettingView) {
            SiteSettingEditor(
                mode: .new,
                domain: $newSiteSettingDomain,
                userAgent: $newSiteSettingUserAgent,
                viewport: $newSiteSettingViewport,
                shouldSave: $newSiteSettingShouldSave,
                onValidate: { domain in
                    // Return true if domain already exists (triggers error)
                    return perSiteSettings.contains(where: { $0.domain == domain })
                }
            )
            .presentationDetents([.large, .medium])
        }
        .sheet(isPresented: $isShowingEditSiteSettingView) {
            SiteSettingEditor(
                mode: .edit,
                domain: $editingSiteSettingDomain,
                userAgent: $editingSiteSettingUserAgent,
                viewport: $editingSiteSettingViewport,
                shouldSave: $editingSiteSettingShouldSave
            )
            .presentationDetents([.large, .medium])
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
