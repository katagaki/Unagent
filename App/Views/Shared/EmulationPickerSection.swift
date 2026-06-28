import SwiftUI

struct EmulationPickerSection: View {

    @Binding var emulation: Emulation?
    // isOptional adds a "Default" (auto-detect) choice for global/per-site editors;
    // the preset editor offers only the three explicit values.
    var isOptional: Bool = false

    var body: some View {
        Section {
            if isOptional {
                Picker("Emulation", selection: $emulation) {
                    Text("Default").tag(Emulation?.none)
                    ForEach(Emulation.allCases, id: \.self) { option in
                        Text(option.displayName).tag(Emulation?.some(option))
                    }
                }
            } else {
                Picker("Emulation", selection: Binding(
                    get: { emulation ?? Emulation.off },
                    set: { emulation = $0 }
                )) {
                    ForEach(Emulation.allCases, id: \.self) { option in
                        Text(option.displayName).tag(option)
                    }
                }
            }
        } header: {
            Text("Emulation")
        } footer: {
            Text("About.Emulation")
        }
    }
}
