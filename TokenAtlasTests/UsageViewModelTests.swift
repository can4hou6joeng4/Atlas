import Foundation
import Testing
@testable import TokenAtlas

@MainActor
@Suite("Usage view model")
struct UsageViewModelTests {
    @Test("Selecting a usage period syncs the menu bar period")
    func selectingPeriodSyncsMenuBarPeriod() {
        let prefs = Preferences(defaults: makeDefaults())
        let vm = UsageViewModel()

        vm.selectPeriod(.last7Days, syncingMenuBarPeriodIn: prefs)
        #expect(vm.period == .last7Days)
        #expect(prefs.menuBarPeriod == .last7Days)

        vm.selectPeriod(.allTime, syncingMenuBarPeriodIn: prefs)
        #expect(vm.period == .allTime)
        #expect(prefs.menuBarPeriod == .allTime)
    }

    @Test("Current session menu bar period does not overwrite usage period")
    func currentSessionDoesNotOverwriteUsagePeriod() {
        let vm = UsageViewModel()
        vm.period = .last30Days

        vm.syncPeriodFromMenuBar(.currentSession)

        #expect(vm.period == .last30Days)
    }

    @Test("Usage period can sync from supported menu bar period")
    func syncsFromSupportedMenuBarPeriod() {
        let vm = UsageViewModel()
        vm.period = .today

        vm.syncPeriodFromMenuBar(.last30Days)

        #expect(vm.period == .last30Days)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "TokenAtlasTests.UsageViewModel.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
