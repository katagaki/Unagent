import SwiftUI

struct GlobalSettingsView: View {

    @Binding var globalUserAgent: String
    @Binding var globalViewportString: String
    @Binding var globalEmulationString: String
    var synchronizeDefaults: () -> Void

    var globalViewport: Viewport? {
        globalViewportString.isEmpty ? nil : Viewport(rawValue: globalViewportString)
    }

    var globalEmulation: Emulation? {
        globalEmulationString.isEmpty ? nil : Emulation(rawValue: globalEmulationString)
    }

    private var viewportBinding: Binding<Viewport?> {
        Binding(
            get: { globalViewport },
            set: { newValue in
                globalViewportString = newValue?.rawValue ?? ""
                synchronizeDefaults()
            }
        )
    }

    private var emulationBinding: Binding<Emulation?> {
        Binding(
            get: { globalEmulation },
            set: { newValue in
                globalEmulationString = newValue?.rawValue ?? ""
                synchronizeDefaults()
            }
        )
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
                viewport: viewportBinding,
                emulation: emulationBinding
            )

            ViewportPickerSection(viewport: viewportBinding)

            EmulationPickerSection(emulation: emulationBinding, isOptional: true)
        }
        .scrollContentBackground(.hidden)
        .gradientBackground()
        .navigationTitle("ViewTitle.GlobalSettings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
