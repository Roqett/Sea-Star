import SwiftUI

/// The ways to lay out the same four rows (DECISIONS.md D-001).
///
/// They are deliberately three *readings* and not three products: every row,
/// every value and every picker is identical between them, so switching one for
/// another changes how the cockpit reads and nothing about what it says. That
/// is what makes them worth comparing.
///
/// `stack` and `chain` are the two designs. `both` is not a third design — it is
/// the two of them at once, side by side, so the comparison the founder asked
/// for is a single tap rather than a memory test. It exists to be left behind
/// once a reading is chosen.
enum PanelLayout: String, CaseIterable, Identifiable, Sendable {
    /// Four rows, one under the next. The familiar reading: a column you can
    /// scan down, every value on the same baseline.
    case stack
    /// Four connected cards reading top to bottom. Each card hands off to the
    /// next, so the chain a request actually travels is visible as a shape.
    case chain
    /// Both readings at once, in two columns, for choosing between them.
    case both

    var id: String { rawValue }

    /// Standard Apple symbols, so the toggle matches the header's other icons.
    var symbol: String {
        switch self {
        case .stack: return "rectangle.grid.1x2"
        case .chain: return "arrow.triangle.branch"
        case .both: return "rectangle.split.2x1"
        }
    }

    var label: String { Strings.PanelVariant.label(self) }
    var help: String { Strings.PanelVariant.help(self) }

    /// The stored preference, or the opening default. The stack leads because it
    /// is the reading this panel has always been, and a new layout should not
    /// arrive as a surprise.
    static func resolved(from raw: String) -> PanelLayout {
        PanelLayout(rawValue: raw) ?? .stack
    }

    /// Whether this reading needs room for two columns.
    var isWide: Bool { self == .both }
}

/// The cockpit's four rows and the `Working now` band beneath them.
///
/// The ontology is the point (DECISIONS.md D-001):
///
/// ```
/// Vault      → the knowledge source being read
/// Harness    → the app that answers            (picker kept — it is a real action)
/// Agent      → the persona inside it            (additive)
/// Inference  → the endpoint *and* the model     (where the URL moved to)
/// ```
///
/// The server URL used to be fused into the Harness row, which made an endpoint
/// look like an identity. It lives in `Inference` now, where it is a property
/// of a call rather than of an app.
struct CockpitPanel: View {
    let controller: ServerController
    /// Which reading to draw. A binding rather than the panel's own storage so
    /// the header toggle and the panel can never disagree about what is on
    /// screen — there is one source of truth, and it is the header's.
    @Binding var layout: PanelLayout
    /// Opens the vault folder picker. The panel owns the importer because the
    /// vault row is the one row that can adopt something the engine never found.
    var onChooseFolder: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            switch layout {
            case .stack:
                stackLayout
            case .chain:
                chainLayout
            case .both:
                compareLayout
            }
            WorkingNowBand(controller: controller)
        }
    }

    // MARK: - Compare

    /// The two designs side by side, each under its own name. Deliberately not
    /// a third design: the point is to *choose* one, and a person choosing
    /// between two pictures needs both pictures in front of them at once, not
    /// remembered from a flip.
    private var compareLayout: some View {
        HStack(alignment: .top, spacing: 20) {
            column(.stack) { stackLayout }
            column(.chain) { chainLayout }
        }
    }

    @ViewBuilder
    private func column<Content: View>(
        _ variant: PanelLayout,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(variant.label)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Palette.inkMuted)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .help(variant.help)
    }

    // MARK: - Variant A — Stack

    /// Four rows on one baseline, then the band. Nothing is enclosed, so the
    /// eye reads a list and can compare values down the column without the
    /// boxes getting in the way.
    private var stackLayout: some View {
        VStack(alignment: .leading, spacing: 10) {
            row(.vault)
            row(.harness)
            row(.agent)
            row(.inference)
        }
    }

    @ViewBuilder
    private func row(_ kind: PanelRowKind) -> some View {
        switch kind {
        case .vault:
            PickerRow(
                label: Strings.Rows.vault,
                value: vaultValue,
                accent: Palette.vaultGlow,
                options: controller.vaultOptions,
                selection: Binding(
                    get: { controller.report?.vault.path ?? "" },
                    set: { controller.selectVault($0) }
                ),
                display: Self.vaultName,
                onChooseFolder: onChooseFolder
            )
            .help(Strings.Rows.vaultHelp)

        case .harness:
            // The picker is *kept*, not removed. Switching harness is a real,
            // working action; the thing that was wrong was the URL sharing the
            // row, and that moved to Inference rather than taking the control
            // with it.
            if controller.harnessOptions.count > 1 {
                PickerRow(
                    label: Strings.Rows.harness,
                    value: harnessValue,
                    accent: Palette.harnessGlow,
                    options: controller.harnessOptions.map(\.baseURL),
                    selection: Binding(
                        get: { controller.report?.baseURL ?? "" },
                        set: { controller.selectHarness($0) }
                    ),
                    display: harnessLabel
                )
                .help(Strings.Rows.harnessHelp)
            } else {
                StatusRow(
                    label: Strings.Rows.harness,
                    value: harnessValue,
                    accent: Palette.harnessGlow
                )
                .help(Strings.Rows.harnessHelp)
            }

        case .agent:
            agentRow

        case .inference:
            inferenceRow
        }
    }

    /// The Agent row, which is additive by design. It has four honest states
    /// and they are not interchangeable:
    ///
    /// - a roster, labelled with **whose** roster it is;
    /// - a roster found and empty;
    /// - no roster found at all;
    /// - an engine too old to say, where the app refuses to guess.
    ///
    /// Showing "no agent" for all four would be a small lie each time, and it
    /// is the lie the foundation exists to prevent.
    @ViewBuilder
    private var agentRow: some View {
        let state = controller.agentState
        switch state {
        case .roster(let options):
            PickerRow(
                label: Strings.Rows.agent,
                value: agentValue(options),
                accent: Palette.agentGlow,
                options: options.map(\.name),
                selection: Binding(
                    get: { controller.selectedAgentName ?? options.first?.name ?? "" },
                    set: { controller.selectAgent($0) }
                ),
                display: { $0 }
            )
            .help(Strings.Rows.agentHelp + " " + agentScopeSuffix(state))

        case .empty, .notFound, .unconfirmed:
            StatusRow(
                label: Strings.Rows.agent,
                value: agentStateValue(state),
                accent: Palette.agentGlow
            )
            .help(Strings.Rows.agentHelp + " " + agentScopeSuffix(state))
        }
    }

    /// The Inference row: where the call goes, and on what. Both live together
    /// because they are both properties of the call — the endpoint chose the
    /// model, so splitting them would hide the relationship.
    private var inferenceRow: some View {
        PickerRow(
            label: Strings.Rows.inference,
            value: inferenceValue,
            accent: Palette.modelGlow,
            options: controller.modelOptions,
            selection: Binding(
                get: { controller.report?.model ?? "" },
                set: { controller.selectModel($0) }
            ),
            display: { $0 }
        )
        .help(Strings.Rows.inferenceHelp + " " + Strings.Detail.endpoint + ": " + endpointValue)
    }

    // MARK: - Variant B — Chain

    /// The same four facts as connected cards. Each card is a link in the chain
    /// a request travels — vault to harness to persona to endpoint — so the
    /// shape itself carries the order that a stack leaves to be inferred.
    private var chainLayout: some View {
        VStack(spacing: 0) {
            chainCard(.vault)
            ChainLink()
            chainCard(.harness)
            ChainLink()
            chainCard(.agent)
            ChainLink()
            chainCard(.inference)
        }
    }

    /// Each chain card, built from the same four facts the stack rows use. Not a
    /// `@ViewBuilder`: the switch below picks *values*, and only the one card at
    /// the end is a view.
    private func chainCard(_ kind: PanelRowKind) -> some View {
        let accent: Color
        let title: String
        let value: String
        let detail: String

        switch kind {
        case .vault:
            accent = Palette.vaultGlow
            title = Strings.Rows.vault
            value = Self.vaultName(controller.report?.vault.path ?? Strings.States.unknown)
            detail = Strings.Detail.notes
        case .harness:
            accent = Palette.harnessGlow
            title = Strings.Rows.harness
            value = harnessValue
            detail = controller.harnessOptions.count > 1
                ? Strings.Actions.chooseHarness
                : (controller.currentHarness?.name ?? Strings.States.unknown)
        case .agent:
            accent = Palette.agentGlow
            title = Strings.Rows.agent
            value = agentValue(controller.agentOptions)
            detail = agentDetail
        case .inference:
            accent = Palette.modelGlow
            title = Strings.Rows.inference
            value = controller.report?.model ?? Strings.States.unknown
            detail = endpointValue
        }

        return ChainCard(accent: accent, title: title, value: value, detail: detail)
    }

    /// The one line of detail under a chain card. Each names the fact the card
    /// is *about*, so a card is readable on its own without the row below it.
    private var agentDetail: String {
        switch controller.agentState {
        case .roster: return Strings.Rows.agentCount(controller.agentOptions.count)
        case .empty: return Strings.Rows.agentRosterEmpty
        case .notFound: return Strings.Rows.agentNoneFound
        case .unconfirmed: return Strings.Rows.agentScopeUnknown
        }
    }

    // MARK: - Values

    private static func vaultName(_ path: String) -> String {
        (path as NSString).lastPathComponent
    }

    private var vaultValue: String {
        controller.report?.vault.path ?? Strings.States.unknown
    }

    /// The Harness row shows the app's name and nothing else. The URL it used
    /// to carry is in `Inference`, where an endpoint belongs.
    private var harnessValue: String {
        guard let report = controller.report else { return Strings.States.unknown }
        return controller.currentHarness?.name ?? report.runtime
    }

    private func harnessLabel(_ baseURL: String) -> String {
        controller.harnessOptions.first { $0.baseURL == baseURL }?.name ?? baseURL
    }

    private var endpointValue: String {
        controller.report?.baseURL ?? Strings.States.unknown
    }

    /// The Inference row reads as one sentence: the model, then where it runs.
    private var inferenceValue: String {
        let model = controller.report?.model ?? Strings.States.unknown
        let endpoint = controller.report?.baseURL ?? Strings.States.unknown
        return "\(model) · \(endpoint)"
    }

    private func agentValue(_ options: [AgentOption]) -> String {
        guard !options.isEmpty else { return agentStateValue(controller.agentState) }
        let selected = controller.selectedAgentName ?? options[0].name
        return selected
    }

    /// The exact words for each non-roster agent state. Kept as one place so
    /// the stack and the chain cannot drift into saying different things.
    private func agentStateValue(_ state: AgentState) -> String {
        switch state {
        case .roster: return Strings.Rows.agentRosterFrom(controller.agentScopeLabel)
        case .empty: return Strings.Rows.agentRosterEmpty
        case .notFound: return Strings.Rows.agentNoneFound
        case .unconfirmed: return Strings.Rows.agentScopeUnknown
        }
    }

    /// A sentence naming whose roster this is, so a persona list is never
    /// presented as though it belonged to the whole machine.
    private func agentScopeSuffix(_ state: AgentState) -> String {
        switch state {
        case .roster:
            return Strings.Rows.agentRosterFrom(controller.agentScopeLabel)
        case .empty:
            return Strings.Rows.agentRosterFrom(controller.agentScopeLabel)
        case .notFound:
            return Strings.Advice.agentScopeHint
        case .unconfirmed:
            return Strings.Advice.agentScopeUnconfirmed
        }
    }
}

/// The four rows, named once so both layouts cannot disagree about the order.
enum PanelRowKind: CaseIterable, Sendable {
    case vault, harness, agent, inference
}

/// One labelled fact. The accent bar carries the palette colour so the same
/// idea always glows the same (spec §7). Not private: the chain cards and the
/// stack rows are two drawings of the same four facts, and one definition is
/// what stops the two readings drifting apart.
struct StatusRow: View {
    let label: String
    let value: String
    let accent: Color

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            AccentBar(color: accent)

            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.inkMuted)
                .frame(width: 60, alignment: .leading)

            Text(value)
                .font(.caption)
                .foregroundStyle(Palette.ink)
                .lineLimit(2)
                .truncationMode(.middle)

            Spacer(minLength: 0)
        }
    }
}

/// A labelled fact whose value is a picker (spec §8.1, §8.3). The row shows the
/// full current choice; the menu lists the alternatives. Disabled when there is
/// nothing to switch to, so a single-vault or single-model machine stays quiet.
struct PickerRow: View {
    let label: String
    let value: String
    let accent: Color
    let options: [String]
    let selection: Binding<String>
    let display: (String) -> String
    /// Optional extra menu entry — the vault row uses it to adopt any folder.
    var onChooseFolder: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            AccentBar(color: accent)

            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.inkMuted)
                .frame(width: 60, alignment: .leading)

            Menu {
                Picker(label, selection: selection) {
                    ForEach(options, id: \.self) { option in
                        Text(display(option)).tag(option)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()

                if let onChooseFolder {
                    Divider()
                    Button(Strings.Actions.openFolder, action: onChooseFolder)
                }
            } label: {
                HStack(spacing: 4) {
                    Text(value)
                        .font(.caption)
                        .foregroundStyle(Palette.ink)
                        .lineLimit(2)
                        .truncationMode(.middle)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(Palette.inkMuted)
                }
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .disabled(options.count <= 1 && onChooseFolder == nil)

            Spacer(minLength: 0)
        }
    }
}

/// The connector drawn between two chain cards. It is a short vertical rule
/// with a nudibranch gradient, so the link reads as the same material as the
/// bars rather than as a UI affordance bolted on.
///
/// This is wiring, not liveness, so it wears blue-white like every other rule
/// in the cockpit. The orange-to-green art is reserved for the graph, where it
/// means an endpoint actually answered — spending it here would spend the
/// distinction before the graph had a chance to make it.
private struct ChainLink: View {
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Palette.ink.opacity(0.18))
                .frame(width: 1, height: 10)
            NudiStrip(style: .blueWhite, height: 2, expands: false)
                .frame(width: 18)
            Rectangle()
                .fill(Palette.ink.opacity(0.18))
                .frame(width: 1, height: 10)
        }
        .frame(height: 22)
        .accessibilityHidden(true)
    }
}

/// One card in the chain reading: accent, title, value, and the detail line
/// that makes the card self-sufficient.
private struct ChainCard: View {
    let accent: Color
    let title: String
    let value: String
    let detail: String

    @State private var hovering = false

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            AccentBar(color: accent)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Palette.inkMuted)
                Text(value)
                    .font(.caption)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 8)

            Text(detail)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Palette.inkMuted)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Palette.ink.opacity(hovering ? 0.07 : 0.04),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(accent.opacity(hovering ? 0.35 : 0.18), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .onHover { hovering = $0 }
        .help("\(title) — \(detail)")
    }
}

/// The `Working now` band: what the cockpit can see happening, and — just as
/// importantly — how far that seeing was proven.
///
/// It is **observation-only**. It never shows a prompt, an output, or a claim
/// that a person used anything, because nothing in Sea-Star observes those yet.
/// "Live" here means *a probe answered this port during the last read*, and the
/// evidence line says so in as many words. The stronger claim — that a request
/// actually went somewhere — waits for the activity stream, and until then the
/// band would rather be quiet than promising something it cannot prove.
private struct WorkingNowBand: View {
    let controller: ServerController

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(Strings.WorkingNow.title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Palette.inkMuted)

                Spacer(minLength: 0)

                LivenessBar(isLive: hasAnswered, count: 1, height: 3)
                    .frame(width: 54)
            }

            if let observation = observation {
                ObservationRow(
                    label: observation.label,
                    value: observation.value,
                    detail: observation.detail,
                    isLive: observation.isLive
                )
            } else {
                Text(Strings.WorkingNow.idle)
                    .font(.caption)
                    .foregroundStyle(Palette.inkMuted)
            }

            Text(hasAnswered ? Strings.WorkingNow.evidenceProbe : Strings.WorkingNow.evidenceNone)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Palette.inkMuted.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.ink.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
    }

    /// A probe answered during the last read. This is the only thing that earns
    /// the word "live" in the cockpit, and the band is explicit about it.
    private var hasAnswered: Bool {
        controller.isReady
    }

    private struct Observation {
        let label: String
        let value: String
        let detail: String
        let isLive: Bool
    }

    /// The single most useful thing to say right now: whether the server this
    /// app owns is actually up, and what the engine could reach behind it.
    private var observation: Observation? {
        guard let report = controller.report else { return nil }
        let serving = controller.isServerRunning
        let answering = hasAnswered ? Strings.WorkingNow.answering : Strings.WorkingNow.notAnswering
        return Observation(
            label: serving ? Strings.WorkingNow.server : Strings.WorkingNow.endpoint,
            value: serving ? Strings.WorkingNow.serving : answering,
            detail: serving
                ? Strings.WorkingNow.serving
                : (report.baseURL.isEmpty
                    ? answering
                    : "\(answering) · \(report.baseURL)"),
            isLive: serving || hasAnswered
        )
    }
}

/// One line inside `Working now`: what is being reported, what it is, and a
/// liveness bar that only moves when the thing was actually reached.
private struct ObservationRow: View {
    let label: String
    let value: String
    let detail: String
    let isLive: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Palette.inkMuted)
                .frame(width: 58, alignment: .leading)

            Text(value)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer(minLength: 6)

            LivenessBar(isLive: isLive, count: 2, height: 3)
                .frame(width: 34)
        }
        .help("\(label) — \(detail)")
    }
}
