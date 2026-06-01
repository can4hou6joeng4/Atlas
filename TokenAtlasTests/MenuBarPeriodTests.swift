import Testing
@testable import TokenAtlas

@Suite("Menu bar period")
struct MenuBarPeriodTests {
    @Test("Stats periods map to menu bar periods")
    func statsPeriodMapping() {
        #expect(MenuBarPeriod(statsPeriod: .today) == .today)
        #expect(MenuBarPeriod(statsPeriod: .last7Days) == .last7Days)
        #expect(MenuBarPeriod(statsPeriod: .last30Days) == .last30Days)
        #expect(MenuBarPeriod(statsPeriod: .allTime) == .allTime)
    }

    @Test("Stats period round trips for supported menu bar ranges")
    func statsPeriodRoundTrip() {
        for period in StatsPeriod.allCases {
            #expect(MenuBarPeriod(statsPeriod: period).statsPeriod == period)
        }
    }
}
