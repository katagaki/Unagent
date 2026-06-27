import SwiftUI

struct GlobalSettingsView: View {

    @Binding var globalUserAgent: String
    @Binding var globalViewportString: String
    var synchronizeDefaults: () -> Void

    var globalViewport: Viewport? {
        if globalViewportString.isEmpty {
            return nil
        }
        return Viewport(rawValue: globalViewportString)
    }

    var body: some View {
        List {
            Section {
                Text("GlobalSettings.Description")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            UserAgentEditorSection(
                userAgent: $globalUserAgent,
                viewport: Binding(
                    get: { globalViewport },
                    set: { newValue in
                        globalViewportString = newValue?.rawValue ?? ""
                        synchronizeDefaults()
                    }
                )
            )

            ViewportPickerSection(
                viewport: Binding(
                    get: { globalViewport },
                    set: { newValue in
                        globalViewportString = newValue?.rawValue ?? ""
                        synchronizeDefaults()
                    }
                )
            )
        }
        .scrollContentBackground(.hidden)
        .gradientBackground()
        .navigationTitle("ViewTitle.GlobalSettings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
