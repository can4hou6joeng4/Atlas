import Foundation

struct MenuBarStatusSnapshot: Sendable, Hashable {
    let provider: ProviderKind
    let period: MenuBarPeriod
    let metric: MenuBarMetric
    let displayValue: String
    let helpText: String
    let accessibilityLabel: String

    @MainActor
    init(
        preferences: Preferences,
        store: SessionStore,
        now: Date = .now
    ) {
        provider = preferences.selectedProvider
        period = preferences.menuBarPeriod
        metric = preferences.menuBarMetric

        let summary = store.summary(
            for: period,
            provider: provider,
            now: now
        )
        let isLoadingEmptyProvider = store.sessions(for: provider).isEmpty && store.isLoading
        displayValue = Self.valueText(
            summary: summary,
            metric: metric,
            includeCacheRead: preferences.menuBarIncludesCache,
            costMode: preferences.costEstimationMode,
            isLoadingEmptyProvider: isLoadingEmptyProvider
        )
        helpText = "\(provider.displayName) · \(period.displayName) · \(displayValue)"
        accessibilityLabel = "\(provider.shortName) Stats — \(period.displayName)"
    }

    static func valueText(
        summary: UsageSummary,
        metric: MenuBarMetric,
        includeCacheRead: Bool,
        costMode: CostEstimationMode,
        isLoadingEmptyProvider: Bool = false
    ) -> String {
        if isLoadingEmptyProvider { return "…" }
        switch metric {
        case .tokens:
            return Format.tokens(summary.totalTokens(includingCacheRead: includeCacheRead))
        case .cost:
            return Format.cost(summary.totalCost(for: costMode))
        }
    }
}
