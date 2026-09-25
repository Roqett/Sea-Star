import SwiftUI

/// The cockpit popover: what the engine found, at a glance, with one button to
/// start or stop the server (spec §8). Glass is applied to the control layer
/// only — the canvas stays flat so the accents read as glowing (spec §7).
struct CockpitPopoverView: View {
    let controller: ServerController

    /// The header mark's side in points; also the caustic shimmer's scale, so the
    /// two can never drift apart.
    private static let markSize: CGFloat = 26

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            details
            controls
            if let message = controller.message {
                guidance(message)
            }
        }
        .padding(18)
        .frame(width: 320)
        .background(Palette.canvas)
        .task { await controller.refresh() }
    }

    private var header: some View {
        HStack(spacing: 12) {
            AppIconMark(icon: controller.currentIcon, size: Self.markSize)
                .foregroundStyle(controller.currentIcon.accent)
                .caustics(size: Self.markSize)
                .shadow(color: controller.currentIcon.accent.opacity(0.55), radius: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(Strings.Header.title)
                    .font(.headline)
                    .foregroundStyle(Palette.bone)
                Text(Strings.Header.subtitle)
                    .font(.caption)
                    .foregroundStyle(Palette.mauve)
            }

            Spacer()

            statePill
        }
    }

    private var statePill: some View {
        Text(stateText)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(stateColour)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(stateColour.opacity(0.16), in: Capsule())
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 10) {
            PickerRow(
                label: Strings.Rows.vault,
                value: vaultValue,
                accent: Palette.teal,
                options: controller.vaultOptions,
                selection: Binding(
                    get: { controller.report?.vault.path ?? "" },
                    set: { controller.selectVault($0) }
                ),
                display: Self.vaultName
            )
            .help(Strings.Actions.chooseVault)

            if controller.harnessOptions.count > 1 {
                PickerRow(
                    label: Strings.Rows.harness,
                    value: harnessValue,
                    accent: Palette.electricBlue,
                    options: controller.harnessOptions.map(\.baseURL),
                    selection: Binding(
                        get: { controller.report?.baseURL ?? "" },
                        set: { controller.selectHarness($0) }
                    ),
                    display: harnessLabel
                )
                .help(Strings.Actions.chooseHarness)
            } else {
                StatusRow(label: Strings.Rows.harness, value: harnessValue, accent: Palette.electricBlue)
            }

            PickerRow(
                label: Strings.Rows.model,
                value: modelValue,
                accent: Palette.neonGreen,
                options: controller.modelOptions,
                selection: Binding(
                    get: { controller.report?.model ?? "" },
                    set: { controller.selectModel($0) }
                ),
                display: { $0 }
            )
            .help(Strings.Actions.chooseModel)
        }
    }

    /// Vaults read better as their folder name in the menu; the row itself shows
    /// the full path so two vaults with the same name stay distinguishable.
    private static func vaultName(_ path: String) -> String {
        (path as NSString).lastPathComponent
    }

    private var controls: some View {
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                Button(controller.isServerRunning ? Strings.Actions.stop : Strings.Actions.start) {
                    controller.toggleServer()
                }
                .buttonStyle(.glassProminent)
                .disabled(!controller.isReady && !controller.isServerRunning)

                Button(Strings.Actions.refresh) {
                    Task { await controller.refresh() }
                }
                .buttonStyle(.glass)
                .disabled(controller.isRefreshing)
            }
        }
    }

    private func guidance(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(Palette.bone.opacity(0.85))
            .fixedSize(horizontal: false, vertical: true)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.vermilion.opacity(0.14), in: RoundedRectangle(cornerRadius: 10))
    }

    private var stateText: String {
        if controller.isServerRunning { return Strings.States.running }
        if controller.isRefreshing { return Strings.States.checking }
        return controller.isReady ? Strings.States.ready : Strings.States.notReady
    }

    private var stateColour: Color {
        if controller.isServerRunning { return Palette.neonGreen }
        if controller.isRefreshing { return Palette.working }
        return controller.isReady ? Palette.neonGreen : Palette.offline
    }

    private var vaultValue: String {
        controller.report?.vault.path ?? Strings.States.unknown
    }

    private var harnessValue: String {
        guard let report = controller.report else { return Strings.States.unknown }
        return "\(report.runtime) · \(report.baseURL)"
    }

    /// A harness is its name plus where it lives — the URL alone can't say which
    /// app is answering on a shared port.
    private func harnessLabel(_ baseURL: String) -> String {
        guard let option = controller.harnessOptions.first(where: { $0.baseURL == baseURL }) else {
            return baseURL
        }
        return "\(option.name) · \(baseURL)"
    }

    private var modelValue: String {
        controller.report?.model ?? Strings.States.unknown
    }
}

/// The palette accent bar: same idea, same colour, every time (spec §7).
private struct AccentBar: View {
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(color)
            .frame(width: 3, height: 14)
            .shadow(color: color.opacity(0.6), radius: 4)
    }
}

/// One labelled fact. The accent bar carries the palette colour so the same
/// idea always glows the same (spec §7).
private struct StatusRow: View {
    let label: String
    let value: String
    let accent: Color

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            AccentBar(color: accent)

            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.mauve)
                .frame(width: 60, alignment: .leading)

            Text(value)
                .font(.caption)
                .foregroundStyle(Palette.bone)
                .lineLimit(2)
                .truncationMode(.middle)

            Spacer(minLength: 0)
        }
    }
}

/// A labelled fact whose value is a picker (spec §8.1, §8.3). The row shows the
/// full current choice; the menu lists the alternatives. Disabled when there is
/// nothing to switch to, so a single-vault or single-model machine stays quiet.
private struct PickerRow: View {
    let label: String
    let value: String
    let accent: Color
    let options: [String]
    let selection: Binding<String>
    let display: (String) -> String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            AccentBar(color: accent)

            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.mauve)
                .frame(width: 60, alignment: .leading)

            Menu {
                Picker(label, selection: selection) {
                    ForEach(options, id: \.self) { option in
                        Text(display(option)).tag(option)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } label: {
                HStack(spacing: 4) {
                    Text(value)
                        .font(.caption)
                        .foregroundStyle(Palette.bone)
                        .lineLimit(2)
                        .truncationMode(.middle)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(Palette.mauve)
                }
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .disabled(options.count <= 1)

            Spacer(minLength: 0)
        }
    }
}
