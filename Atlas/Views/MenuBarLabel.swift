import SwiftUI

/// The status-item content: an icon plus a compact tokens-or-cost figure for
/// the configured period.
struct MenuBarLabel: View {
    @Environment(AppEnvironment.self) private var env
    @State private var now = Date.now
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        let snapshot = MenuBarStatusSnapshot(
            preferences: env.preferences,
            store: env.store,
            now: now
        )
        HStack(spacing: 4) {
            Image(systemName: "chart.bar.xaxis")
            Text(snapshot.displayValue)
                .monospacedDigit()
                .stxNumericValueTransition(value: snapshot.displayValue)
        }
        .id(env.preferences.menuBarDisplayRevision)
        .lineLimit(1)
        .fixedSize()
        .help(snapshot.helpText)
        .accessibilityLabel(snapshot.accessibilityLabel)
        .onReceive(timer) { now = $0 }
        .onReceive(NotificationCenter.default.publisher(for: .menuBarDisplayNeedsRefresh)) { _ in
            now = .now
        }
    }
}

#if DEBUG
// Standalone preview of the status-item content only. The label actually
// lives in the system menu bar via `MenuBarExtra` — a `Scene`, which Xcode's
// Canvas can't render. Run the app (`bash scripts/run-debug.sh`) to see it
// in the real menu bar.
#Preview("Menu bar label") {
    VStack(alignment: .leading, spacing: 14) {
        MenuBarLabel().environment(AppEnvironment.preview())
        MenuBarLabel().environment(AppEnvironment.preview())
            .environment(\.colorScheme, .dark)
            .padding(6)
            .background(.black)
        MenuBarLabel().environment(AppEnvironment.preview(populated: false))
    }
    .padding()
}
#endif
