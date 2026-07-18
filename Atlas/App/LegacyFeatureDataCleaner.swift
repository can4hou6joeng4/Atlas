import Foundation

struct LegacyFeatureDataCleaner {
    private let applicationSupportDirectory: URL
    private let defaults: UserDefaults
    private let fileManager: FileManager

    init(
        applicationSupportDirectory: URL? = nil,
        defaults: UserDefaults = .standard,
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager
        self.defaults = defaults
        self.applicationSupportDirectory = applicationSupportDirectory
            ?? fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support", isDirectory: true)
    }

    func cleanRemovedFeatureData() {
        removeLegacyLeaderboardDefaults()
    }

    private func removeLegacyLeaderboardDefaults() {
        for key in Self.legacyLeaderboardDefaultsKeys {
            defaults.removeObject(forKey: key)
        }
    }

    private static let legacyLeaderboardDefaultsKeys = [
        "leaderboardsEnabled",
        "leaderboardNickname",
        "leaderboardAvatarSeed",
        "leaderboardProfileUserHash",
        "leaderboardLastSyncedAt",
        "leaderboardLastSyncError",
    ]
}
