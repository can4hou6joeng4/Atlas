import SwiftUI

/// "BY TOOL" / "BY SKILL" attribution panel for the main-window Usage page.
///
/// Renders ``ToolUsageBreakdown`` rows — turns, tokens, estimated cost, and
/// share — with the involving-attribution caveat spelled out: a turn's whole
/// usage counts toward every tool it invoked, so multi-tool turns repeat
/// across rows and share is computed against the period total, not the row
/// sum. Callers hide this panel when ``ToolUsageBreakdown/hasToolData`` is
/// false (Codex-only data, stale parses, or pure-chat periods).
struct UsageToolBreakdown: View {
    let breakdown: ToolUsageBreakdown
    let periodTotalUsage: TokenUsage
    let includeCacheInTokens: Bool
    let costEstimationMode: CostEstimationMode
    @State private var cachedSnapshotKey: UsageToolBreakdownSnapshot.Key?
    @State private var cachedSnapshot: UsageToolBreakdownSnapshot?

    var body: some View {
        let key = UsageToolBreakdownSnapshot.Key(
            breakdown: breakdown,
            periodTotalUsage: periodTotalUsage,
            includeCacheInTokens: includeCacheInTokens,
            costEstimationMode: costEstimationMode
        )
        let snapshot = cachedSnapshotKey == key
            ? (cachedSnapshot ?? UsageToolBreakdownSnapshot(key: key))
            : UsageToolBreakdownSnapshot(key: key)

        VStack(alignment: .leading, spacing: 12) {
            section(
                title: L10n.string("usage.tools.by_tool", defaultValue: "BY TOOL"),
                rows: snapshot.toolRows,
                showsColumns: true
            )
            if !snapshot.skillRows.isEmpty {
                StxRule()
                section(
                    title: L10n.string("usage.tools.by_skill", defaultValue: "BY SKILL"),
                    rows: snapshot.skillRows,
                    showsColumns: false
                )
            }
        }
        .mainUsagePanel(padding: 16)
        .onAppear { cacheSnapshotIfNeeded(key) }
        .onChange(of: key) { _, newKey in cacheSnapshotIfNeeded(newKey) }
    }

    @ViewBuilder
    private func section(title: String, rows: [UsageToolBreakdownSnapshot.Row], showsColumns: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.sora(13, weight: .semibold))
                    .tracking(1.0)
                Spacer()
                if showsColumns {
                    Text(L10n.string("usage.tools.columns", defaultValue: "Turns · Tokens · Cost · Share"))
                        .font(.sora(10))
                        .foregroundStyle(Color.stxMuted)
                        .lineLimit(1)
                }
            }
            if showsColumns {
                Text(L10n.string(
                    "usage.tools.involving_note",
                    defaultValue: "Whole-turn usage counts toward every tool the turn invoked; multi-tool turns repeat across rows."
                ))
                .font(.sora(10))
                .foregroundStyle(Color.stxMuted)
                .fixedSize(horizontal: false, vertical: true)
            }
            LazyVStack(spacing: 0) {
                ForEach(rows) { row in
                    UsageToolRow(row: row)
                    if row.id != rows.last?.id {
                        StxRule()
                    }
                }
            }
        }
    }

    private func cacheSnapshotIfNeeded(_ key: UsageToolBreakdownSnapshot.Key) {
        guard cachedSnapshotKey != key else { return }
        cachedSnapshot = UsageToolBreakdownSnapshot(key: key)
        cachedSnapshotKey = key
    }
}

private struct UsageToolRow: View {
    let row: UsageToolBreakdownSnapshot.Row

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(rowColor)
                    .frame(width: 10, height: 10)
                Text(row.label)
                    .font(.sora(12, weight: .medium))
                    .foregroundStyle(row.isNoTools ? Color.stxMuted : .primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 12)
                Text(row.turnsText)
                    .font(.sora(11).monospacedDigit())
                    .stxNumericValueTransition(value: row.turnsText)
                    .foregroundStyle(Color.stxMuted)
                    .frame(minWidth: 40, alignment: .trailing)
                Text(row.tokensText)
                    .font(.sora(12, weight: .semibold).monospacedDigit())
                    .stxNumericValueTransition(value: row.tokensText)
                    .foregroundStyle(.primary)
                    .frame(minWidth: 72, alignment: .trailing)
                Text(row.costText)
                    .font(.sora(12).monospacedDigit())
                    .stxNumericValueTransition(value: row.costText)
                    .foregroundStyle(Color.stxMuted)
                    .frame(minWidth: 70, alignment: .trailing)
                Text(row.shareText)
                    .font(.sora(12, weight: .semibold).monospacedDigit())
                    .stxNumericValueTransition(value: row.shareText)
                    .foregroundStyle(.primary)
                    .frame(minWidth: 50, alignment: .trailing)
            }

            GeometryReader { proxy in
                let width = proxy.size.width * CGFloat(row.totalTokens) / CGFloat(row.maxTokens)
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color.primary.opacity(0.08))
                    if width > 0 {
                        Rectangle()
                            .fill(rowColor)
                            .frame(width: max(2, width))
                            .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                    }
                }
            }
            .frame(height: 5)
        }
        .padding(.vertical, 8)
    }

    private var rowColor: Color {
        guard let colorIndex = row.colorIndex else {
            return Color.primary.opacity(0.28)
        }
        return ModelPalette.color(at: colorIndex)
    }
}

struct UsageToolBreakdownSnapshot: Equatable {
    struct Key: Equatable {
        let breakdown: ToolUsageBreakdown
        let periodTotalUsage: TokenUsage
        let includeCacheInTokens: Bool
        let costEstimationMode: CostEstimationMode
    }

    struct Row: Identifiable, Equatable {
        let id: String
        let label: String
        let isNoTools: Bool
        /// Palette index for the leading swatch and bar; `nil` renders the
        /// muted residual style used by the "No tools" bucket.
        let colorIndex: Int?
        let turnsText: String
        let tokensText: String
        let costText: String
        let shareText: String
        let totalTokens: Int
        let maxTokens: Int
    }

    let key: Key
    let toolRows: [Row]
    let skillRows: [Row]

    init(key: Key) {
        self.key = key
        // Involving attribution: rows overlap, so the share denominator is
        // the period's total usage — never the sum of rows.
        let denominator = max(1, key.periodTotalUsage.total(includingCacheRead: key.includeCacheInTokens))
        toolRows = Self.rows(
            from: key.breakdown.byTool,
            denominator: denominator,
            includeCacheInTokens: key.includeCacheInTokens,
            costEstimationMode: key.costEstimationMode
        )
        skillRows = Self.rows(
            from: key.breakdown.bySkill,
            denominator: denominator,
            includeCacheInTokens: key.includeCacheInTokens,
            costEstimationMode: key.costEstimationMode
        )
    }

    private static func rows(
        from rows: [ToolUsageBreakdown.Row],
        denominator: Int,
        includeCacheInTokens: Bool,
        costEstimationMode: CostEstimationMode
    ) -> [Row] {
        let totals = rows.map { $0.usage.total(includingCacheRead: includeCacheInTokens) }
        let maxTokens = max(1, totals.max() ?? 1)
        var paletteIndex = 0
        return zip(rows, totals).map { row, total in
            let colorIndex: Int?
            if row.isNoToolsBucket {
                colorIndex = nil
            } else {
                colorIndex = paletteIndex
                paletteIndex += 1
            }
            return Row(
                id: row.id,
                label: row.name ?? L10n.string("usage.tools.no_tools", defaultValue: "No tools"),
                isNoTools: row.isNoToolsBucket,
                colorIndex: colorIndex,
                turnsText: "\(row.turnCount)",
                tokensText: Format.tokens(total),
                costText: Format.cost(row.cost.value(for: costEstimationMode)),
                shareText: Format.percent(Double(total) / Double(denominator)),
                totalTokens: total,
                maxTokens: maxTokens
            )
        }
    }
}

#if DEBUG
#Preview {
    UsageToolBreakdown(
        breakdown: ToolUsageBreakdown(
            byTool: [
                ToolUsageBreakdown.Row(
                    name: "Bash",
                    turnCount: 42,
                    usage: TokenUsage(inputTokens: 40_000, outputTokens: 12_000, cacheReadTokens: 700_000),
                    cost: CostEstimate(standardAPI: 1.85)
                ),
                ToolUsageBreakdown.Row(
                    name: "Skill",
                    turnCount: 6,
                    usage: TokenUsage(inputTokens: 9_000, outputTokens: 4_000, cacheReadTokens: 120_000),
                    cost: CostEstimate(standardAPI: 0.42)
                ),
                ToolUsageBreakdown.Row(
                    name: nil,
                    turnCount: 18,
                    usage: TokenUsage(inputTokens: 12_000, outputTokens: 22_000, cacheReadTokens: 90_000),
                    cost: CostEstimate(standardAPI: 0.66)
                ),
            ],
            bySkill: [
                ToolUsageBreakdown.Row(
                    name: "code-review",
                    turnCount: 6,
                    usage: TokenUsage(inputTokens: 9_000, outputTokens: 4_000, cacheReadTokens: 120_000),
                    cost: CostEstimate(standardAPI: 0.42)
                ),
            ]
        ),
        periodTotalUsage: TokenUsage(inputTokens: 80_000, outputTokens: 50_000, cacheReadTokens: 1_000_000),
        includeCacheInTokens: true,
        costEstimationMode: .standardAPI
    )
    .padding(24)
    .frame(width: 720)
    .background(Color.stxBackground)
}
#endif
