import SwiftUI

/// The onboarding window: the home for everything that is *about the machine*
/// rather than about the moment.
///
/// Three sections, each with one job (D-012):
///
/// - **What each app is doing** — the behaviour ledger. It answers "is anything
///   on this machine doing something I should know about?", which is a question
///   a person asks when setting up, not every time they glance at the cockpit.
/// - **Things to decide** — the register. Found things are named here, once,
///   with the evidence shown. After this window is cleared, it stays mostly
///   quiet.
/// - **On your graph** — which of the installed harnesses should float on the
///   starfield. The same list also lives in the graph reading, because it
///   changes what the graph shows; here it is offered once so the first graph
///   a person sees is already the one they wanted.
///
/// This window is deliberately *not* the cockpit. The cockpit is a reading you
/// take in a moment; this is a desk you clear once.
struct OnboardingView: View {
    let controller: ServerController
    let onClose: () -> Void

    private static let markSize: CGFloat = 26

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    ledgerSection
                    registerSection
                    graphSection
                }
                .padding(.bottom, 8)
            }

            footer
        }
        .padding(20)
        .frame(width: 460)
        .background(Palette.canvas)
        .environment(\.seaStarCockpitOpen, true)
        .task { await controller.refresh() }
    }

    private var header: some View {
        HStack(spacing: 12) {
            AppIconMark(icon: controller.currentIcon, size: Self.markSize)
                .foregroundStyle(controller.currentIcon.accent)
                .caustics(size: Self.markSize)
                .shadow(color: controller.currentIcon.accent.opacity(0.55), radius: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(Strings.Onboarding.title)
                    .font(.headline)
                    .foregroundStyle(Palette.ink)
                Text(Strings.Onboarding.subtitle)
                    .font(.caption)
                    .foregroundStyle(Palette.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }

    // MARK: - The ledger

    @ViewBuilder
    private var ledgerSection: some View {
        section(Strings.Rows.behaviour, help: Strings.Rows.behaviourHelp) {
            if controller.appBehaviour.isEmpty {
                emptyLine(Strings.Rows.nothingToReport)
            } else {
                ForEach(controller.appBehaviour) { row in
                    BehaviourRow(row: row)
                }
            }
        }
    }

    // MARK: - The register

    @ViewBuilder
    private var registerSection: some View {
        section(Strings.Rows.newHere, help: Strings.Rows.newHereHelp) {
            if controller.candidates.isEmpty {
                emptyLine(Strings.Rows.nothingToDecide)
            } else {
                Text(Strings.Rows.newHereCount(controller.candidates.count))
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Palette.inkMuted)

                // All of them, in the one place that exists to hold them. Folding
                // a backlog behind a word makes sense in a reading; here the
                // window is the backlog, so it shows it whole.
                ForEach(controller.candidates) { candidate in
                    NewCandidateRow(
                        candidate: candidate,
                        isBusy: controller.isDeciding,
                        adopt: { name in
                            Task { await controller.adoptCandidate(candidate.identity, name: name) }
                        },
                        dismiss: {
                            Task { await controller.dismissCandidate(candidate.identity) }
                        }
                    )
                }
            }
        }
    }

    // MARK: - The graph's cast

    @ViewBuilder
    private var graphSection: some View {
        section(Strings.Rows.onGraph, help: Strings.Rows.onGraphHelp) {
            if controller.latentHarnessOptions.isEmpty {
                emptyLine(Strings.Rows.noHarnessesInstalled)
            } else {
                HarnessVisibilityList(controller: controller)
            }
        }
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button(Strings.Onboarding.done, action: onClose)
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(Palette.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Palette.ink.opacity(0.10), in: RoundedRectangle(cornerRadius: 7))
        }
    }

    /// A titled section in the onboarding's own quiet style: a small mono
    /// heading, the body beneath it, and a help line only as a tooltip.
    private func section<Content: View>(
        _ title: String,
        help: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.ink)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .help(help)
    }

    private func emptyLine(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(Palette.inkMuted)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Which installed harnesses float on the graph, and which stay off it.
///
/// Shared between the onboarding window and the graph reading on purpose: these
/// buttons change what the starfield shows, so they belong beside the starfield
/// in the cockpit *and* offered once up front, when the person decides what
/// their graph should look like before they have seen it.
struct HarnessVisibilityList: View {
    let controller: ServerController

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(controller.latentHarnessOptions) { latent in
                LatentRow(
                    name: latent.name,
                    path: latent.path,
                    rung: latent.rung,
                    isFloating: controller.isLatentHarnessEnabled(latent.bundleID),
                    toggle: { controller.toggleLatentHarness(latent.bundleID) }
                )
            }
        }
    }
}

/// One installed harness and the word that floats it onto the graph or takes it
/// back off. The path is only ever a tooltip — the row stays as quiet as the
/// rest of the panel.
struct LatentRow: View {
    let name: String
    let path: String
    /// How far this app got. Shown beside the name rather than hidden in a
    /// tooltip, because "up, not answering yet" is the single most useful thing
    /// to know about a harness that is not driving Sea-Star.
    let rung: HarnessRung?
    let isFloating: Bool
    let toggle: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            AccentBar(color: Palette.harnessGlow)

            Text(name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
                .truncationMode(.middle)

            if let rung, rung != .present {
                Text(rung.label)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(rung == .running ? Palette.ready : Palette.inkMuted)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Button(action: toggle) {
                Text(isFloating ? Strings.Actions.sinkHarness : Strings.Actions.floatHarness)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(isFloating ? Palette.harnessGlow : Palette.inkMuted)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(path)
        }
    }
}

/// One harness and what it is observed to be doing with models.
///
/// The distinction that earns this row its place: an app that ships a model
/// server *and* is reaching outside the machine while not using it is doing
/// something a person would want to know about, and would otherwise never see.
/// The wording states the two observations and stops there — no motive is
/// attributed, because the engine did not observe one.
struct BehaviourRow: View {
    let row: DoctorReport.HarnessBehaviourInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                AccentBar(color: row.ownsIdleServer ? Palette.agentGlow : Palette.inferenceGlow)

                Text(row.name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer(minLength: 8)

                Text(summary)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(row.ownsIdleServer ? Palette.agentGlow : Palette.inkMuted)
                    .lineLimit(1)
            }

            if row.ownsIdleServer {
                Text(Strings.Rows.idleServer(row.serves))
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Palette.inkMuted)
                    .padding(.leading, 18)
            }
        }
    }

    /// The line, built from the observations in the order they matter.
    ///
    /// A port that never answered is reported as a port, never as a server:
    /// "listening on 8888, not answering" is honest, where "serves models on
    /// 8888" was a guess that a real machine proved wrong.
    private var summary: String {
        var parts: [String] = []
        if !row.serves.isEmpty {
            let ports = row.serves.map(String.init).joined(separator: ", ")
            parts.append("serves \(ports)")
            if row.usingOwnServer { parts.append("using it") }
        } else if !row.unconfirmed.isEmpty {
            let ports = row.unconfirmed.map(String.init).joined(separator: ", ")
            parts.append("listening \(ports), not answering")
        }
        if row.reachesOut > 0 {
            parts.append("reaching \(row.reachesOut) outside")
        }
        return parts.isEmpty ? Strings.States.unknown : parts.joined(separator: " · ")
    }
}

/// One undecided thing, with the evidence for it and the two answers available.
///
/// The name is pre-filled from the scan when the scan had one, so answering is a
/// click rather than a typing exercise; it stays editable because the label a
/// person gives a thing is the label they will look for on the graph afterwards.
struct NewCandidateRow: View {
    let candidate: DoctorReport.CandidateInfo
    let isBusy: Bool
    let adopt: (String) -> Void
    let dismiss: () -> Void

    @State private var name: String = ""
    @State private var hasEditedName = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                AccentBar(color: Palette.harnessGlow)

                TextField(candidate.suggestedName ?? candidate.name, text: $name)
                    .textFieldStyle(.plain)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                    .onAppear {
                        if !hasEditedName {
                            name = candidate.suggestedName ?? candidate.name
                        }
                    }
                    .onChange(of: name) { _, _ in hasEditedName = true }

                Spacer(minLength: 8)

                Button(Strings.Actions.itIsAHarness) {
                    adopt(name.isEmpty ? candidate.name : name)
                }
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Palette.harnessGlow)
                .disabled(isBusy)

                Button(Strings.Actions.notAHarness, action: dismiss)
                    .buttonStyle(.plain)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(Palette.inkMuted)
                    .disabled(isBusy)
            }

            // Every line here is something the engine observed, not a guess.
            ForEach(candidate.evidence, id: \.self) { line in
                Text(line)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Palette.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 18)
            }
        }
    }
}
