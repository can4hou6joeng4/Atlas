import Testing
import Foundation
@testable import Atlas

@Suite("TranscriptParser")
struct TranscriptParserTests {

    @Test("Extracts title, message count, models, costs, and the hourly timeline")
    func parsesSampleTranscript() async throws {
        let dir = try TempDir.make()
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("session.jsonl")
        try TempDir.write(SampleTranscript.text, to: url)

        let stats = try #require(await TranscriptParser(pricing: TestPricing.table)
            .parse(transcriptAt: url, fallbackTitle: "fallback"))

        #expect(stats.title == SampleTranscript.aiTitle)
        #expect(stats.messageCount == 5) // 2 user + 3 assistant

        // Two models, sorted by total tokens descending.
        #expect(stats.models.map(\.model) == ["model-a", "model-b"])

        let modelA = try #require(stats.models.first { $0.model == "model-a" })
        #expect(modelA.messageCount == 2)
        #expect(modelA.usage.inputTokens == 110)
        #expect(modelA.usage.outputTokens == 205)
        #expect(modelA.usage.cacheReadTokens == 1040)
        #expect(modelA.usage.total == 1355)

        let modelB = try #require(stats.models.first { $0.model == "model-b" })
        #expect(modelB.messageCount == 1)
        #expect(modelB.usage.cacheCreation5mTokens == 300)
        #expect(modelB.usage.total == 425)

        #expect(stats.totalTokens == 1780)
        #expect(abs(modelA.estimatedCost - 0.00624) < 1e-9)
        #expect(abs(modelB.estimatedCost - 0.001) < 1e-9)
        #expect(abs(stats.totalCost - 0.00724) < 1e-9)

        // Three assistant turns ⇒ three (model, hour) buckets across two
        // distinct hours; the token total is timezone-independent.
        #expect(stats.timeline.count == 3)
        #expect(stats.timeline.totalTokens == 1780)
        #expect(Set(stats.timeline.map(\.model)) == ["model-a", "model-b"])
        #expect(Set(stats.timeline.map(\.start)).count == 2)
        #expect(stats.timeline.filter { $0.model == "model-a" }.totalTokens == 1355)

        let first = try #require(stats.firstActivity)
        let last = try #require(stats.lastActivity)
        #expect(first < last)
        let expectedFirst = try Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse("2026-01-10T09:00:01.000Z")
        let expectedLast = try Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse("2026-01-11T10:00:20.000Z")
        #expect(first == expectedFirst)
        #expect(last == expectedLast)
    }

    @Test("Falls back to a sanitized first user message when there is no ai-title")
    func usesFirstUserMessageAsFallbackTitle() async throws {
        let dir = try TempDir.make()
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("session.jsonl")
        let text = """
        {"type":"user","timestamp":"2026-02-01T00:00:00.000Z","message":{"role":"user","content":"  Build  the  thing  "}}
        {"type":"assistant","timestamp":"2026-02-01T00:00:01.000Z","message":{"model":"model-a","usage":{"input_tokens":1,"output_tokens":1}}}
        """
        try TempDir.write(text, to: url)

        let stats = try #require(await TranscriptParser(pricing: TestPricing.table)
            .parse(transcriptAt: url, fallbackTitle: "demo"))
        #expect(stats.title == "Build the thing")
    }

    @Test("Extracts displayable conversation messages")
    func displayMessages() async throws {
        let dir = try TempDir.make()
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("session.jsonl")
        try TempDir.write(SampleTranscript.text, to: url)

        let messages = await TranscriptParser(pricing: TestPricing.table)
            .messages(transcriptAt: url)

        #expect(messages.map(\.role) == [.user, .assistant, .tool, .assistant, .assistant])
        #expect(messages.map(\.text) == [
            "please refactor the parser",
            "on it",
            "Tool result:\nok",
            "done",
            "more",
        ])
        #expect(messages[1].model == "model-a")
    }

    @Test("Returns nil for a transcript with no real messages")
    func returnsNilForEmptyTranscript() async throws {
        let dir = try TempDir.make()
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("session.jsonl")
        try TempDir.write(#"{"type":"queue-operation","operation":"enqueue","timestamp":"2026-01-01T00:00:00.000Z"}"# + "\n", to: url)

        let stats = await TranscriptParser(pricing: TestPricing.table)
            .parse(transcriptAt: url, fallbackTitle: "demo")
        #expect(stats == nil)
    }

    @Test("Hides zero-token synthetic model rows while preserving activity")
    func hidesZeroTokenSyntheticRows() async throws {
        let dir = try TempDir.make()
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("session.jsonl")
        let text = """
        {"type":"user","timestamp":"2026-02-01T00:00:00.000Z","message":{"role":"user","content":"hello"}}
        {"type":"assistant","timestamp":"2026-02-01T00:00:01.000Z","message":{"model":"model-a","usage":{"input_tokens":10,"output_tokens":5}}}
        {"type":"assistant","timestamp":"2026-02-01T00:02:00.000Z","message":{"model":"<synthetic>","usage":{"input_tokens":0,"output_tokens":0,"cache_creation_input_tokens":0,"cache_read_input_tokens":0}}}
        """
        try TempDir.write(text, to: url)

        let stats = try #require(await TranscriptParser(pricing: TestPricing.table)
            .parse(transcriptAt: url, fallbackTitle: "demo"))

        #expect(stats.messageCount == 3)
        #expect(stats.models.map(\.model) == ["model-a"])
        #expect(stats.timeline.map(\.model) == ["model-a"])
        let expectedLast = try Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse("2026-02-01T00:02:00.000Z")
        #expect(stats.lastActivity == expectedLast)
    }

    @Test("Keeps non-zero synthetic model rows and labels them as internal")
    func keepsNonZeroSyntheticRows() async throws {
        let dir = try TempDir.make()
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("session.jsonl")
        let text = """
        {"type":"assistant","timestamp":"2026-02-01T00:00:01.000Z","message":{"model":"<synthetic>","usage":{"input_tokens":10,"output_tokens":5}}}
        """
        try TempDir.write(text, to: url)

        let stats = try #require(await TranscriptParser(pricing: TestPricing.table)
            .parse(transcriptAt: url, fallbackTitle: "demo"))

        #expect(stats.models.map(\.model) == ["<synthetic>"])
        #expect(stats.models.first?.usage.total == 15)
        #expect(ClaudeProvider.prettyName(for: "<synthetic>") == "Claude internal")
    }

    @Test("Detailed Claude billing applies fast mode and web search charges")
    func detailedClaudeBillingAddsVisibleCharges() async throws {
        let dir = try TempDir.make()
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("session.jsonl")
        let text = """
        {"type":"assistant","timestamp":"2026-02-01T00:00:01.000Z","message":{"model":"claude-opus-4-7","usage":{"input_tokens":1000000,"output_tokens":1000000,"speed":"fast","server_tool_use":{"web_search_requests":2}}}}
        """
        try TempDir.write(text, to: url)

        let pricing = ModelPricing(
            rates: ["claude-opus-4-7": ModelPricing.Rates.derived(input: 5, output: 25)],
            defaultRate: TestPricing.table.defaultRate
        )
        let stats = try #require(await TranscriptParser(pricing: pricing)
            .parse(transcriptAt: url, fallbackTitle: "demo"))
        let model = try #require(stats.models.first)

        #expect(abs(model.estimatedCost(for: .standardAPI) - 30) < 1e-9)
        #expect(abs(model.estimatedCost(for: .detailedBilling) - 180.02) < 1e-9)
        #expect(abs(stats.totalCost(for: .detailedBilling) - 180.02) < 1e-9)
    }

    @Test("Collects tool and skill names per assistant turn on billable messages")
    func collectsToolAndSkillNamesPerTurn() async throws {
        let dir = try TempDir.make()
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("session.jsonl")
        let text = """
        {"type":"assistant","timestamp":"2026-02-01T00:00:01.000Z","requestId":"r1","message":{"id":"m1","model":"model-a","content":[{"type":"text","text":"just thinking"}],"usage":{"input_tokens":10,"output_tokens":5}}}
        {"type":"assistant","timestamp":"2026-02-01T00:00:02.000Z","requestId":"r2","message":{"id":"m2","model":"model-a","content":[{"type":"tool_use","id":"t1","name":"Bash","input":{"command":"ls"}},{"type":"tool_use","id":"t2","name":"Read","input":{"file_path":"/tmp/a"}},{"type":"tool_use","id":"t3","name":"Bash","input":{"command":"pwd"}}],"usage":{"input_tokens":20,"output_tokens":10}}}
        {"type":"assistant","timestamp":"2026-02-01T00:00:03.000Z","requestId":"r3","message":{"id":"m3","model":"model-a","content":[{"type":"text","text":"running the skill"},{"type":"tool_use","id":"t4","name":"Skill","input":{"skill":"code-review","args":"--effort high HEAD"}}],"usage":{"input_tokens":30,"output_tokens":15}}}
        """
        try TempDir.write(text, to: url)

        let stats = try #require(await TranscriptParser(pricing: TestPricing.table)
            .parse(transcriptAt: url, fallbackTitle: "demo"))

        #expect(stats.billableMessages.count == 3)
        // Pure-reasoning turn: no tool or skill attribution.
        #expect(stats.billableMessages[0].toolNames.isEmpty)
        #expect(stats.billableMessages[0].skillNames.isEmpty)
        // Duplicate Bash collapses; order is first appearance.
        #expect(stats.billableMessages[1].toolNames == ["Bash", "Read"])
        #expect(stats.billableMessages[1].skillNames.isEmpty)
        // Skill invocations land in the tool list AND surface the skill name.
        #expect(stats.billableMessages[2].toolNames == ["Skill"])
        #expect(stats.billableMessages[2].skillNames == ["code-review"])
    }

    @Test("Skill blocks without a decodable skill input keep tool attribution only")
    func skillBlockWithoutSkillFieldKeepsToolAttribution() async throws {
        let dir = try TempDir.make()
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("session.jsonl")
        let text = """
        {"type":"assistant","timestamp":"2026-02-01T00:00:01.000Z","requestId":"r1","message":{"id":"m1","model":"model-a","content":[{"type":"tool_use","id":"t1","name":"Skill","input":{"args":"no skill field"}}],"usage":{"input_tokens":10,"output_tokens":5}}}
        {"type":"assistant","timestamp":"2026-02-01T00:00:02.000Z","requestId":"r2","message":{"id":"m2","model":"model-a","content":[{"type":"tool_use","id":"t2","name":"Skill","input":"not-an-object"}],"usage":{"input_tokens":10,"output_tokens":5}}}
        """
        try TempDir.write(text, to: url)

        let stats = try #require(await TranscriptParser(pricing: TestPricing.table)
            .parse(transcriptAt: url, fallbackTitle: "demo"))

        #expect(stats.billableMessages.count == 2)
        #expect(stats.billableMessages[0].toolNames == ["Skill"])
        #expect(stats.billableMessages[0].skillNames.isEmpty)
        #expect(stats.billableMessages[1].toolNames == ["Skill"])
        #expect(stats.billableMessages[1].skillNames.isEmpty)
    }
}
