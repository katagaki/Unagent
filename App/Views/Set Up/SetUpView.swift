import SwiftUI

enum SetUpStepState {
    case complete
    case active
    case pending
}

struct SetUpView: View {

    @Environment(\.scenePhase) private var scenePhase
    var monitor: ExtensionActivationMonitor

    private var settingsURL: URL { URL(string: UIApplication.openSettingsURLString)! }
    private var safariURL: URL { URL(string: "https://www.example.com")! }

    // Step 2 — turning the extension on. Complete once the extension has ever
    // contacted the app.
    private var enableState: SetUpStepState {
        monitor.isExtensionEnabled ? .complete : .active
    }

    // Step 3 — granting website access. Active only once the extension is on,
    // otherwise it waits for step 2.
    private var accessState: SetUpStepState {
        if monitor.hasWebsiteAccess { return .complete }
        return monitor.isExtensionEnabled ? .active : .pending
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SetUpStepRow(
                number: 1,
                title: "SetUp.Step1.Title",
                state: enableState,
                summary: "SetUp.Step1",
                instructions: "SetUp.Step1.iOS18+",
                actionTitle: enableActionTitle,
                actionURL: enableActionURL,
                confirmTitle: "SetUp.MarkDone",
                onConfirm: { withAnimation(.smooth.speed(2)) { monitor.confirmEnabled() } },
                isLast: false
            )
            SetUpStepRow(
                number: 2,
                title: "SetUp.Step2.Title",
                state: accessState,
                summary: "SetUp.Step2",
                instructions: "SetUp.Step2",
                actionTitle: "SetUp.OpenSafari",
                actionURL: safariURL,
                confirmTitle: "SetUp.MarkDone",
                onConfirm: { withAnimation(.smooth.speed(2)) { monitor.confirmWebsiteAccess() } },
                isLast: true
            )
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 20.0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { monitor.refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                withAnimation(.smooth.speed(2)) { monitor.refresh() }
            }
        }
    }

    // On Mac Catalyst there is no Safari extension settings page to deep-link to,
    // so fall back to opening Safari like the original onboarding did.
    #if targetEnvironment(macCatalyst)
    private var enableActionTitle: LocalizedStringKey { "SetUp.OpenSafari" }
    private var enableActionURL: URL { safariURL }
    #else
    private var enableActionTitle: LocalizedStringKey { "SetUp.OpenSettings" }
    private var enableActionURL: URL { settingsURL }
    #endif
}

struct SetUpStepRow: View {

    let number: Int
    let title: LocalizedStringKey
    let state: SetUpStepState
    let summary: LocalizedStringKey?
    let instructions: LocalizedStringKey?
    let actionTitle: LocalizedStringKey?
    let actionURL: URL?
    var confirmTitle: LocalizedStringKey? = nil
    var onConfirm: (() -> Void)? = nil
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            indicator

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(state == .pending ? .secondary : .primary)
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, isLast ? 0 : 24)
        }
        // The connector is drawn as a background so it stretches to the full
        // height of the row's content, from just below the indicator to the
        // next step's indicator.
        .background(alignment: .topLeading) {
            if !isLast {
                Rectangle()
                    .fill(connectorColor)
                    .frame(width: 2.0)
                    .padding(.top, 28.0)
                    .frame(width: 28.0)
            }
        }
    }

    @ViewBuilder
    private var indicator: some View {
        ZStack {
            switch state {
            case .complete:
                Circle().fill(Color.green)
                Image(systemName: "checkmark")
                    .font(.system(size: 13.0, weight: .bold))
                    .foregroundStyle(.white)
            case .active:
                Circle().fill(Color.accentColor)
                Text(String(number))
                    .font(.system(size: 14.0, weight: .bold))
                    .foregroundStyle(.white)
            case .pending:
                Circle().strokeBorder(Color.secondary.opacity(0.4), lineWidth: 1.5)
                Text(String(number))
                    .font(.system(size: 14.0, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 28.0, height: 28.0)
    }

    private var connectorColor: Color {
        state == .complete ? Color.green : Color.secondary.opacity(0.3)
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .complete:
            Text("SetUp.StepComplete")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        case .active:
            VStack(alignment: .leading, spacing: 14) {
                if let instructions {
                    Text(instructions)
                        .font(.subheadline)
                        .lineSpacing(4.0)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let actionTitle, let actionURL {
                    Link(destination: actionURL) {
                        HStack(spacing: 4.0) {
                            Text(actionTitle)
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                }
                if let confirmTitle, let onConfirm {
                    Button(action: onConfirm) {
                        Text(confirmTitle)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                }
            }
            .padding(16.0)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: GroupedMetrics.cornerRadius, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
            .padding(.top, 4.0)
        case .pending:
            if let summary {
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
