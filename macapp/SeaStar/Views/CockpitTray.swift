import SwiftUI

/// The QuickTime drawer: a ledge at the foot of a reading, holding the things
/// that belong to *that* reading rather than to the panel as a whole (spec §8.7).
///
/// The reference is the drawer in QuickTime 4 — a panel that physically extends
/// downward, with an Aqua grip at the top of what it reveals. Two things carry
/// the nostalgia, and both are native: the **attachment** (the tray belongs to
/// the reading and grows out of its lower edge; it is not a second window or a
/// popover) and the **motion** (a connected slide that tracks the opening edge).
/// No `NSDrawer`, no deprecated API, no Aqua-era bitmap.
///
/// It is generic on purpose. It began as the harness roster's home, but the same
/// ledge is the right place for any control that is *about the reading you are
/// in* — which is what let the header shed its second pair of buttons. The host
/// passes whatever belongs there.
struct CockpitTray<Content: View>: View {
    /// Open state is owned by the host, because opening the tray changes how
    /// much room the reading itself may take.
    @Binding var isOpen: Bool
    /// Named for what the drawer holds, in the host's words.
    let title: String
    @ViewBuilder let content: Content

    /// The drawer's grip: two thin rules on a recessed capsule, which is the
    /// visual language that says "handle" to anyone who has ever closed one of
    /// these. It sits centred at the top of the open tray and it *closes* the
    /// tray, which is why it is a button rather than decoration.
    private var grip: some View {
        Button {
            isOpen = false
        } label: {
            ZStack {
                Capsule()
                    .fill(Palette.ink.opacity(0.10))
                    .frame(width: 56, height: 8)

                VStack(spacing: 2) {
                    Capsule()
                        .fill(Palette.ink.opacity(0.45))
                        .frame(width: 36, height: 1)
                    Capsule()
                        .fill(Palette.ink.opacity(0.25))
                        .frame(width: 36, height: 1)
                }
            }
            // The visible grip stays small; the tap target does not. Padding
            // brings the hit area to roughly 28pt tall around an 8pt grip.
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(Strings.Views.trayCloseHelp)
    }

    /// The ledge at the foot of the reading, and the only thing a closed drawer
    /// shows. It is a **grip, not a labelled bar**: three long rules, drawn here
    /// rather than taken from `line.3.horizontal`, because the symbol's own lines
    /// are short and thin and read as a menu icon — the QuickTime tab's grooves
    /// are wider and heavier, and that is the reference. What the grip does is
    /// said on hover, so the closed drawer stays one small mark.
    private var trigger: some View {
        Button {
            isOpen.toggle()
        } label: {
            VStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { _ in
                    Capsule()
                        .fill(isOpen ? Palette.harnessGlow : Palette.inkMuted)
                        .frame(width: 34, height: 2)
                }
            }
            .frame(width: 54, height: 24)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(Strings.Views.trayHelp(title))
    }

    /// How tall the open tray may grow before it scrolls inside itself, so a long
    /// roster cannot push the controls off the display.
    private let maxTrayHeight: CGFloat = 244

    var body: some View {
        VStack(spacing: 0) {
            if isOpen {
                grip

                ScrollView {
                    content
                        .padding(.horizontal, 12)
                        .padding(.bottom, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: maxTrayHeight)
            }

            trigger
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.top, 2)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Palette.canvas.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Palette.ink.opacity(0.12), lineWidth: 1)
        )
        // The connected slide. Short enough to read as one movement rather than
        // an animation, which is what makes it feel like the panel extending.
        .animation(.easeInOut(duration: 0.22), value: isOpen)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
    }
}

/// One labelled row of mutually exclusive choices, for a drawer's own settings:
/// the two depths of the pool, or the two layouts of the rows. It exists so the
/// header does not have to carry a pair of buttons for a choice that is only
/// meaningful inside one reading.
struct TrayChoiceRow: View {
    let title: String
    let options: [(id: String, symbol: String, label: String)]
    let selected: String
    let choose: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title.uppercased())
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(Palette.mauve)

            HStack(spacing: 6) {
                ForEach(options, id: \.id) { option in
                    Button {
                        choose(option.id)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: option.symbol)
                                .font(.system(size: 10, weight: .semibold))
                            Text(option.label)
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                        }
                        .foregroundStyle(option.id == selected ? Palette.ink : Palette.inkMuted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            option.id == selected ? Palette.ink.opacity(0.12) : Color.clear,
                            in: RoundedRectangle(cornerRadius: 6)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Palette.ink.opacity(option.id == selected ? 0.18 : 0.08), lineWidth: 1)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 2)
    }
}
