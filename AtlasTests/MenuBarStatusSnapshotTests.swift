import Foundation
import Testing
@testable import Atlas

@MainActor
@Suite("Menu bar status snapshot")
struct MenuBarStatusSnapshotTests {
    @Test("Period changes update the displayed token value immediately")
    func periodChangesUpdateDisplayedTokenValue() async {
        let now = Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 3, hour: 12))!
        let provider = StaticSessionProvider(sessions: [
            Self.session(id: "today", daysAgo: 0, tokens: 100, now: now),
            Self.session(id: "recent", daysAgo: 3, tokens: 200, now: now),
            Self.session(id: "old", daysAgo: 20, tokens: 300, now: now),
        ])
        let store = SessionStore(
            registry: ProviderRegistry(providers: [provider]),
            pricing: TestPricing.table
        )
        await store.refresh()
        let prefs = Preferences(defaults: Self.makeDefaults())
        prefs.selectedProvider = .claude
        prefs.menuBarMetric = .tokens
        prefs.menuBarIncludesCache = true

        prefs.menuBarPeriod = .today
        let today = MenuBarStatusSnapshot(preferences: prefs, store: store, now: now)

        prefs.menuBarPeriod = .last7Days
        let last7Days = MenuBarStatusSnapshot(preferences: prefs, store: store, now: now)

        prefs.menuBarPeriod = .allTime
        let allTime = MenuBarStatusSnapshot(preferences: prefs, store: store, now: now)

        #expect(today.displayValue == "100")
        #expect(last7Days.displayValue == "300")
        #expect(allTime.displayValue == "600")
        #expect(today.helpText.contains(MenuBarPeriod.today.displayName))
        #expect(last7Days.helpText.contains(MenuBarPeriod.last7Days.displayName))
        #expect(allTime.helpText.contains(MenuBarPeriod.allTime.displayName))
    }

    private static func session(id: String, daysAgo: Int, tokens: Int, now: Date) -> Session {
        let calendar = Calendar.current
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
        let usage = TokenUsage(inputTokens: tokens, outputTokens: 0)
        let stats = SessionStats(
            title: id,
            messageCount: 1,
            firstActivity: day,
            lastActivity: day,
            models: [
                ModelUsage(
                    model: "model-a",
                    messageCount: 1,
                    usage: usage,
                    pricing: TestPricing.table
                ),
            ],
            timeline: [
                ModelBucket(model: "model-a", start: day, usage: usage),
            ]
        )

        return Session(
            id: id,
            externalID: id,
            provider: .claude,
            projectDirectoryName: "-p",
            filePath: "/tmp/\(id).jsonl",
            cwd: "/tmp/project",
            lastModified: day,
            fileSize: 1,
            stats: stats
        )
    }

    private static func makeDefaults() -> UserDefaults {
        let suiteName = "AtlasTests.MenuBarStatusSnapshot.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

private final class StaticSessionProvider: Provider, @unchecked Sendable {
    let kind: ProviderKind = .claude
    var dataDirectoryExists: Bool { true }

    private let sessions: [Session]

    init(sessions: [Session]) {
        self.sessions = sessions
    }

    func discoverSessions() async -> [Session] {
        sessions.map {
            Session(
                id: $0.id,
                externalID: $0.externalID,
                provider: $0.provider,
                projectDirectoryName: $0.projectDirectoryName,
                filePath: $0.filePath,
                cwd: $0.cwd,
                lastModified: $0.lastModified,
                fileSize: $0.fileSize,
                stats: nil
            )
        }
    }

    func parse(_ session: Session) async -> SessionStats? {
        sessions.first { $0.id == session.id }?.stats
    }
}
