import Foundation
import Testing
@testable import Atlas

@Suite("Legacy feature data cleaner")
struct LegacyFeatureDataCleanerTests {
    @Test("Removes legacy defaults")
    func removesLegacyDefaults() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("LegacyFeatureDataCleanerTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let suiteName = "LegacyFeatureDataCleanerTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let legacyDefaultsKeys = [
            "leaderboardsEnabled",
            "leaderboardNickname",
            "leaderboardAvatarSeed",
            "leaderboardProfileUserHash",
            "leaderboardLastSyncedAt",
            "leaderboardLastSyncError",
        ]
        for key in legacyDefaultsKeys {
            defaults.set("legacy", forKey: key)
        }

        let cleaner = LegacyFeatureDataCleaner(applicationSupportDirectory: root, defaults: defaults)
        cleaner.cleanRemovedFeatureData()

        for key in legacyDefaultsKeys {
            #expect(defaults.object(forKey: key) == nil)
        }

        cleaner.cleanRemovedFeatureData()
        for key in legacyDefaultsKeys {
            #expect(defaults.object(forKey: key) == nil)
        }
    }

    @Test("Removed town page raw value falls back at navigation normalization")
    func townPageRawValueIsRemoved() {
        #expect(MainPage(rawValue: "town") == nil)
    }

    @Test("Removed local insights page raw value falls back at navigation normalization")
    func localInsightsPageRawValueIsRemoved() {
        #expect(MainPage(rawValue: "leaderboards") == nil)
        #expect(SettingsSection(rawValue: "leaderboards") == nil)
    }
}
