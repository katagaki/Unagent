import SwiftUI

enum GroupedMetrics {
    static let horizontalInset: CGFloat = 16.0
    static let rowHorizontalPadding: CGFloat = 16.0
    static let rowVerticalPadding: CGFloat = 11.0
    static var minRowHeight: CGFloat {
        if #available(iOS 26.0, *) {
            50.0
        } else {
            44.0
        }
    }
    static let headerSpacing: CGFloat = 8.0
    static let headerInset: CGFloat = horizontalInset + rowHorizontalPadding

    static var cornerRadius: CGFloat {
        if #available(iOS 26.0, *) {
            minRowHeight / 2.0
        } else {
            10.0
        }
    }
}

struct GroupedSection<Header: View, Footer: View, Content: View>: View {

    private let content: Content
    private let header: Header
    private let footer: Footer
    private let showsBackground: Bool

    init(
        showsBackground: Bool = true,
        @ViewBuilder content: () -> Content,
        @ViewBuilder header: () -> Header = { EmptyView() },
        @ViewBuilder footer: () -> Footer = { EmptyView() }
    ) {
        self.showsBackground = showsBackground
        self.content = content()
        self.header = header()
        self.footer = footer()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: GroupedMetrics.headerSpacing) {
            if !(Header.self == EmptyView.self) {
                header
                    .font(.body.weight(.semibold))
                    .padding(.horizontal, GroupedMetrics.headerInset)
            }
            VStack(spacing: 0.0) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if showsBackground {
                    RoundedRectangle(cornerRadius: GroupedMetrics.cornerRadius, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: GroupedMetrics.cornerRadius, style: .continuous))
            .padding(.horizontal, GroupedMetrics.horizontalInset)
            if !(Footer.self == EmptyView.self) {
                footer
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, GroupedMetrics.headerInset)
            }
        }
    }
}

struct GroupedDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, GroupedMetrics.rowHorizontalPadding)
    }
}

struct GroupedRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color(uiColor: .systemGray4) : Color.clear)
            .animation(.smooth.speed(2), value: configuration.isPressed)
    }
}

struct GroupedNavigationRow<Destination: View, Label: View, Accessory: View>: View {

    private let destination: () -> Destination
    private let label: () -> Label
    private let accessory: () -> Accessory

    init(
        @ViewBuilder destination: @escaping () -> Destination,
        @ViewBuilder label: @escaping () -> Label,
        @ViewBuilder accessory: @escaping () -> Accessory = { EmptyView() }
    ) {
        self.destination = destination
        self.label = label
        self.accessory = accessory
    }

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 8.0) {
                label()
                Spacer(minLength: 8.0)
                accessory()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .groupedRowPadding()
            .contentShape(Rectangle())
        }
        .buttonStyle(GroupedRowButtonStyle())
    }
}

extension View {
    func groupedRowPadding() -> some View {
        padding(.horizontal, GroupedMetrics.rowHorizontalPadding)
            .padding(.vertical, GroupedMetrics.rowVerticalPadding)
            .frame(minHeight: GroupedMetrics.minRowHeight)
    }
}
