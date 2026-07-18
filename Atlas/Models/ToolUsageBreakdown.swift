import Foundation

/// Approximate token attribution by tool / skill for one aggregation scope.
///
/// Built from ``BillableMessage`` turns *after* cross-session dedup, so a
/// subagent turn mirrored into its parent transcript is attributed once.
///
/// Attribution is "involving": a turn's full usage counts toward **every**
/// tool that turn invoked, so multi-tool turns appear in several rows and row
/// totals can exceed the period total. Share must therefore be computed
/// against the period's total usage, never the sum of rows. Exact
/// per-tool-call tokens do not exist in Claude Code transcripts — usage is
/// reported per assistant message, and `tool_use` is a content block inside
/// it — so this is the honest approximation, and the UI labels it as such.
struct ToolUsageBreakdown: Sendable, Hashable {
    struct Row: Sendable, Hashable, Identifiable {
        /// Raw tool or skill name; `nil` marks the fixed "No tools" bucket
        /// (turns that invoked no tool at all — pure reasoning/chat).
        let name: String?
        /// Number of deduped assistant turns involving this tool/skill.
        let turnCount: Int
        let usage: TokenUsage
        let cost: CostEstimate

        var id: String { name ?? Self.noToolsID }
        var isNoToolsBucket: Bool { name == nil }

        /// Sentinel id for the "No tools" bucket; starts with NUL so it can
        /// never collide with a real tool name.
        static let noToolsID = "\u{0}no-tools"
    }

    /// Tool rows sorted by total tokens descending; the "No tools" bucket,
    /// when any toolless turn exists, is pinned last as the residual bucket.
    let byTool: [Row]
    /// Skill rows (from `Skill` tool invocations), total tokens descending.
    let bySkill: [Row]

    static let empty = ToolUsageBreakdown(byTool: [], bySkill: [])

    /// True when at least one turn invoked a real tool. False for providers
    /// that don't populate billable messages (e.g. Codex), for stale parses
    /// predating tool attribution, and for pure-chat scopes — the UI hides
    /// the breakdown in all of those cases.
    var hasToolData: Bool { byTool.contains { !$0.isNoToolsBucket } }
}

extension ToolUsageBreakdown {
    /// Streaming accumulator used by ``UsageSummary``'s aggregation pass.
    /// Feed every deduped, in-scope billable turn, then `build()` once.
    struct Builder {
        private var perTool: [String: Accumulated] = [:]
        private var perSkill: [String: Accumulated] = [:]
        private var noTools = Accumulated()

        init() {}

        mutating func add(_ bill: BillableMessage) {
            if bill.toolNames.isEmpty {
                noTools.add(bill)
            } else {
                for tool in bill.toolNames {
                    perTool[tool, default: Accumulated()].add(bill)
                }
            }
            for skill in bill.skillNames {
                perSkill[skill, default: Accumulated()].add(bill)
            }
        }

        func build() -> ToolUsageBreakdown {
            var toolRows = rows(from: perTool)
            if noTools.turns > 0 {
                toolRows.append(Row(name: nil, turnCount: noTools.turns, usage: noTools.usage, cost: noTools.cost))
            }
            return ToolUsageBreakdown(byTool: toolRows, bySkill: rows(from: perSkill))
        }

        private func rows(from accumulated: [String: Accumulated]) -> [Row] {
            accumulated
                .map { Row(name: $0.key, turnCount: $0.value.turns, usage: $0.value.usage, cost: $0.value.cost) }
                .sorted {
                    if $0.usage.total != $1.usage.total { return $0.usage.total > $1.usage.total }
                    return ($0.name ?? "") < ($1.name ?? "")
                }
        }

        private struct Accumulated {
            var turns = 0
            var usage = TokenUsage.zero
            var cost = CostEstimate.zero

            mutating func add(_ bill: BillableMessage) {
                turns += 1
                usage += bill.usage
                cost += bill.cost
            }
        }
    }
}
