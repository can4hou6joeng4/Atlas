// ConfigurationsComponents.swift
// =====================================================================
// Small, dependency-free presentation leaves extracted verbatim from
// ConfigurationsView.swift to keep that file focused. These are pure
// SwiftUI views with no shared private state, so they live at file scope
// (internal) and are reused across the Configurations UI.
//
// NOTE: extracted as-is (no behavioural change). Access level widened from
// `private` to the module-internal default so call sites in
// ConfigurationsView keep resolving them within the TokenAtlas module.

import SwiftUI

struct APIProviderBadge: View {
    let title: String
    var tint: Color = Color.stxMuted

    var body: some View {
        Text(title)
            .font(.sora(9, weight: .semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(tint.opacity(0.12), in: Capsule())
            .overlay(Capsule().strokeBorder(tint.opacity(0.2), lineWidth: 1))
    }
}

struct CodexStatusMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.sora(10, weight: .medium))
                .foregroundStyle(Color.stxMuted)
            Text(value)
                .font(.sora(13, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct APICLISelectorButton: View {
    let cli: APIProviderCLI
    let isSelected: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            HStack(spacing: 7) {
                Image(cli.assetName)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 15, height: 15)
                    .foregroundStyle(isSelected ? Color.stxAccent : Color.stxMuted)

                Text(cli.shortName)
                    .font(.sora(11, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? Color.primary : Color.stxMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.stxAccent.opacity(0.10) : Color.clear)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isSelected ? Color.stxAccent.opacity(0.38) : Color.clear, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .help(cli.displayName)
        .accessibilityLabel(cli.displayName)
    }
}

struct ClaudeSettingsCandidateRow: View {
    let candidate: ClaudeSettingsCandidate
    let isWorking: Bool
    let importCandidate: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "doc.text")
                .foregroundStyle(Color.stxMuted)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(candidate.title)
                        .font(.sora(12, weight: .semibold))
                        .lineLimit(1)
                    APIProviderBadge(title: candidate.url.lastPathComponent)
                }
                Text(candidate.commandPreview)
                    .font(.sora(10).monospaced())
                    .foregroundStyle(Color.stxMuted)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(candidate.commandPreview)
                HStack(spacing: 6) {
                    if !candidate.baseURL.isEmpty {
                        Text(candidate.baseURL).lineLimit(1)
                    }
                    if !candidate.model.isEmpty {
                        Text("·")
                        Text(candidate.model).lineLimit(1)
                    }
                }
                .font(.sora(10))
                .foregroundStyle(Color.stxMuted)
            }

            Spacer(minLength: 10)

            Button {
                importCandidate()
            } label: {
                Label("导入", systemImage: "square.and.arrow.down")
            }
            .controlSize(.small)
            .disabled(isWorking)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.025), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.stxStroke, lineWidth: 1))
    }
}

struct CodexRecycleBinHeaderRow: View {
    var body: some View {
        HStack(spacing: 8) {
            Text("")
                .frame(width: 22)
            Text("标题")
                .frame(minWidth: 110, maxWidth: .infinity, alignment: .leading)
            Text("来源")
                .frame(width: 88, alignment: .leading)
            Text("最后活跃")
                .frame(width: 72, alignment: .leading)
            Text("删除时间")
                .frame(width: 72, alignment: .leading)
            Text("状态")
                .frame(width: 74, alignment: .leading)
        }
        .font(.sora(9, weight: .semibold))
        .foregroundStyle(Color.stxMuted)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
    }
}

struct CodexRecycleBinRow: View {
    let entry: CodexRecycleBinEntry
    let isSelected: Bool
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isSelected ? Color.stxAccent : Color.stxMuted)
                    .frame(width: 22)
                Text(entry.title?.isEmpty == false ? entry.title! : "未命名会话")
                    .font(.sora(10, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .frame(minWidth: 110, maxWidth: .infinity, alignment: .leading)
                Text(projectLabel(entry.projectCWD))
                    .lineLimit(1)
                    .frame(width: 88, alignment: .leading)
                Text(shortDate(entry.lastActiveAt))
                    .lineLimit(1)
                    .frame(width: 72, alignment: .leading)
                Text(shortDate(entry.deletedAt))
                    .lineLimit(1)
                    .frame(width: 72, alignment: .leading)
                APIProviderBadge(
                    title: entry.status,
                    tint: entry.recoverable ? Color(red: 0.0, green: 0.65, blue: 0.38) : .orange
                )
                .frame(width: 74, alignment: .leading)
            }
            .font(.sora(10).monospacedDigit())
            .foregroundStyle(Color.stxMuted)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .background {
                if isSelected {
                    Rectangle().fill(Color.stxAccent.opacity(0.08))
                }
            }
        }
        .buttonStyle(.plain)
        .help(tooltip)
    }

    private var tooltip: String {
        [
            "标题：\(entry.title ?? "未命名会话")",
            "项目：\(entry.projectCWD ?? "未知")",
            "会话 ID：\(entry.sessionID)",
            "备份：\(entry.backupPath)",
            "类型：\(entry.schema)",
            "状态：\(entry.status)",
        ].joined(separator: "\n")
    }

    private func projectLabel(_ cwd: String?) -> String {
        guard let cwd, !cwd.isEmpty else { return "未知" }
        return URL(fileURLWithPath: cwd).lastPathComponent.isEmpty ? cwd : URL(fileURLWithPath: cwd).lastPathComponent
    }

    private func shortDate(_ date: Date?) -> String {
        guard let date else { return "-" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }
}

struct CodexConversationMaintenancePanel: View {
    @Bindable var vm: APIProviderSwitcherViewModel
    @Binding var showProviderSyncConfirmation: Bool
    @Binding var showRecycleDeleteConfirmation: Bool
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 14) {
                recycleBinSection
                providerSyncSection

                if let message = vm.maintenanceMessage {
                    Text(message)
                        .font(.sora(10))
                        .foregroundStyle(Color.stxMuted)
                        .lineLimit(2)
                        .textSelection(.enabled)
                }
            }
            .padding(.top, 12)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "wrench.and.screwdriver")
                    .foregroundStyle(Color.stxMuted)
                VStack(alignment: .leading, spacing: 2) {
                    Text("对话维护")
                        .font(.sora(14, weight: .semibold))
                    Text(maintenanceSubtitle)
                        .font(.sora(10))
                        .foregroundStyle(Color.stxMuted)
                }
                Spacer(minLength: 8)
                if isExpanded {
                    Button {
                        Task { await vm.refreshConversationMaintenance() }
                    } label: {
                        Label(vm.isMaintenanceLoading ? "刷新中" : "刷新", systemImage: "arrow.clockwise")
                    }
                    .controlSize(.small)
                    .disabled(vm.isMaintenanceLoading || vm.isProviderSyncRunning || vm.isRecycleBinActionRunning)
                }
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.035), in: RoundedRectangle(cornerRadius: 8))
        .onChange(of: isExpanded) { _, expanded in
            if expanded {
                Task { await vm.loadConversationMaintenanceIfNeeded() }
            }
        }
    }

    private var maintenanceSubtitle: String {
        if vm.providerSyncSnapshot == nil && vm.recycleBinSnapshot.entries.isEmpty {
            return "高级操作，展开后再检查历史归属和回收站。"
        }
        return "已加载维护状态，可预览影响或刷新。"
    }

    private var recycleBinSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                        .foregroundStyle(Color.stxMuted)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("回收站")
                            .font(.sora(13, weight: .semibold))
                        Text("共 \(vm.recycleBinSnapshot.entries.count) 条记录，已选择 \(vm.selectedRecycleBinTokens.count) 条，可恢复 \(vm.recycleBinSnapshot.recoverableCount) 条。")
                            .font(.sora(10))
                            .foregroundStyle(Color.stxMuted)
                    }
                    Spacer(minLength: 8)
                }

                ViewThatFits(in: .horizontal) {
                    recycleBinActionButtons(showLabels: true)
                    recycleBinActionButtons(showLabels: false)
                }
            }

            if vm.recycleBinSnapshot.entries.isEmpty {
                Text("暂无已删除会话备份。")
                    .font(.sora(11))
                    .foregroundStyle(Color.stxMuted)
                    .padding(.vertical, 4)
            } else {
                LazyVStack(alignment: .leading, spacing: 0) {
                    CodexRecycleBinHeaderRow()
                    ForEach(vm.recycleBinSnapshot.entries) { entry in
                        CodexRecycleBinRow(
                            entry: entry,
                            isSelected: vm.selectedRecycleBinTokens.contains(entry.token),
                            toggle: { vm.toggleRecycleBinSelection(entry) }
                        )
                    }
                }
                .background(Color.black.opacity(0.025), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.stxStroke, lineWidth: 1))
            }

            if let result = vm.recycleBinResult, !result.failed.isEmpty {
                Text(result.failed.map(\.message).joined(separator: "；"))
                    .font(.sora(10))
                    .foregroundStyle(.orange)
                    .lineLimit(3)
            }
        }
    }

    private var providerSyncSection: some View {
        let snapshot = vm.providerSyncSnapshot
        let providerOptions = snapshot?.availableProviders ?? [ConfigurationProviderStore.codexManagedProviderKey]

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundStyle(Color.stxMuted)
                VStack(alignment: .leading, spacing: 2) {
                    Text("历史会话归属同步")
                        .font(.sora(13, weight: .semibold))
                    Text(providerSyncStatusText(snapshot))
                        .font(.sora(10))
                        .foregroundStyle(Color.stxMuted)
                }
                Spacer(minLength: 8)
            }

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 10) {
                    providerSyncTargetPicker(providerOptions: providerOptions)
                    Spacer(minLength: 8)
                    providerSyncActionButtons(showLabels: true)
                }
                VStack(alignment: .leading, spacing: 8) {
                    providerSyncTargetPicker(providerOptions: providerOptions)
                    providerSyncActionButtons(showLabels: true)
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), spacing: 8)], alignment: .leading, spacing: 8) {
                CodexStatusMetric(title: "当前配置", value: snapshot?.currentProvider ?? "-")
                CodexStatusMetric(title: "目标归属", value: vm.selectedProviderSyncTarget)
                CodexStatusMetric(title: "原始文件", value: "\(snapshot?.rolloutFiles ?? 0)")
                CodexStatusMetric(title: "待改文件", value: "\(snapshot?.rolloutRewriteNeeded ?? 0)")
                CodexStatusMetric(title: "本地索引", value: "\(snapshot?.sqliteRows ?? 0)")
                CodexStatusMetric(title: "待改索引", value: "\(snapshot?.sqliteProviderRowsNeedingSync ?? 0)")
            }

            if let snapshot {
                DisclosureGroup("查看技术详情") {
                    VStack(alignment: .leading, spacing: 6) {
                        providerCountsLine(title: "原始文件", counts: snapshot.rolloutProviders)
                        providerCountsLine(title: "本地索引", counts: snapshot.sqliteProviders)
                        if let result = vm.providerSyncResult, let backup = result.backupDirectory {
                            Text("最近备份：\(backup.path)")
                                .textSelection(.enabled)
                        }
                    }
                    .font(.sora(10).monospacedDigit())
                    .foregroundStyle(Color.stxMuted)
                    .padding(.top, 4)
                }
                .font(.sora(10, weight: .medium))
            }
        }
    }

    private func recycleBinActionButtons(showLabels: Bool) -> some View {
        HStack(spacing: 8) {
            Button {
                vm.toggleAllRecycleBinEntries()
            } label: {
                actionLabel(vm.allRecycleBinEntriesSelected ? "取消全选" : "全选", systemImage: "checklist", showLabels: showLabels)
            }
            .fixedSize(horizontal: showLabels, vertical: false)
            .disabled(vm.recycleBinSnapshot.entries.isEmpty || vm.isRecycleBinActionRunning)

            Button {
                Task { await vm.restoreSelectedRecycleBinEntries() }
            } label: {
                actionLabel(vm.isRecycleBinActionRunning ? "处理中" : "恢复可恢复项", systemImage: "arrow.uturn.backward", showLabels: showLabels)
            }
            .fixedSize(horizontal: showLabels, vertical: false)
            .disabled(vm.selectedRecoverableRecycleBinTokens.isEmpty || vm.isRecycleBinActionRunning)

            Button(role: .destructive) {
                showRecycleDeleteConfirmation = true
            } label: {
                actionLabel("永久删除", systemImage: "trash.fill", showLabels: showLabels)
            }
            .fixedSize(horizontal: showLabels, vertical: false)
            .disabled(vm.selectedRecycleBinTokens.isEmpty || vm.isRecycleBinActionRunning)
        }
        .controlSize(.small)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func providerSyncTargetPicker(providerOptions: [String]) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Text("目标归属")
                .font(.sora(10, weight: .medium))
                .foregroundStyle(Color.stxMuted)
                .frame(width: 62, alignment: .leading)
            Picker("", selection: $vm.providerSyncTarget) {
                ForEach(providerOptions, id: \.self) { provider in
                    Text(provider).tag(provider)
                }
                Text("自定义").tag("__custom")
            }
            .labelsHidden()
            .frame(width: 148)
            .onChange(of: vm.providerSyncTarget) { _, newValue in
                vm.selectProviderSyncTarget(newValue)
            }
            if vm.useCustomProviderSyncTarget {
                TextField("Provider 名称", text: $vm.customProviderSyncTarget)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 160)
            }
        }
    }

    private func providerSyncActionButtons(showLabels: Bool) -> some View {
        HStack(spacing: 8) {
            Button {
                Task { await vm.previewProviderSync() }
            } label: {
                actionLabel(vm.isProviderSyncRunning ? "检查中" : "预览影响", systemImage: "eye", showLabels: showLabels)
            }
            .fixedSize(horizontal: showLabels, vertical: false)
            .disabled(vm.isProviderSyncRunning)

            Button {
                showProviderSyncConfirmation = true
            } label: {
                actionLabel("同步", systemImage: "checkmark.arrow.trianglehead.2.clockwise.rotate.90", showLabels: showLabels)
            }
            .fixedSize(horizontal: showLabels, vertical: false)
            .buttonStyle(.borderedProminent)
            .disabled(!vm.canRunProviderSync)
        }
        .controlSize(.small)
    }

    private func providerSyncStatusText(_ snapshot: CodexProviderSyncSnapshot?) -> String {
        guard let snapshot else { return "选择目标归属后预览影响，再决定是否同步。" }
        if snapshot.totalPendingUpdates > 0 {
            return "预计更新 \(snapshot.rolloutRewriteNeeded) 个原始会话文件、\(snapshot.sqliteProviderRowsNeedingSync) 条本地索引记录。"
        }
        return "\(snapshot.rolloutFiles) 个原始会话文件、\(snapshot.sqliteRows) 条本地索引记录已对齐。"
    }

    private func providerCountsLine(title: String, counts: [CodexProviderCount]) -> some View {
        let text = counts.isEmpty
            ? "\(title)：无"
            : "\(title)：\(counts.map { "\($0.provider) \($0.count)" }.joined(separator: " · "))"
        return Text(text)
    }

    @ViewBuilder
    private func actionLabel(_ title: String, systemImage: String, showLabels: Bool) -> some View {
        if showLabels {
            Label(title, systemImage: systemImage)
        } else {
            Image(systemName: systemImage)
                .frame(width: 22, height: 18)
        }
    }
}

enum APIProviderEditorMode: String, CaseIterable, Identifiable {
    case fields
    case raw

    var id: String { rawValue }
    var title: String {
        switch self {
        case .fields: "Fields"
        case .raw: "Raw"
        }
    }
}

struct APIProviderListRow: View {
    let provider: CLIAPIProvider
    let isSelected: Bool
    let isActive: Bool
    var localizedBadges = false
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 8) {
                    Image(provider.cli.assetName)
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 15, height: 15)
                        .foregroundStyle(isSelected ? Color.stxAccent : Color.stxMuted)
                    Text(provider.name)
                        .font(.sora(12, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    if isActive {
                        Circle()
                            .fill(Color.stxAccent)
                            .frame(width: 7, height: 7)
                    }
                }

                HStack(spacing: 6) {
                    APIProviderBadge(title: localizedBadges ? localizedOriginName(provider.origin) : provider.origin.displayName)
                    if provider.category != .official && provider.category != .imported {
                        APIProviderBadge(title: localizedBadges ? localizedCategoryName(provider.category) : provider.category.displayName)
                    }
                    Spacer(minLength: 6)
                }

                HStack(spacing: 6) {
                    Text(provider.baseURL.isEmpty ? (localizedBadges ? "官方端点" : "Official endpoint") : provider.baseURL)
                        .lineLimit(1)
                    if !provider.model.isEmpty {
                        Text("·")
                        Text(provider.model).lineLimit(1)
                    }
                }
                .font(.sora(10))
                .foregroundStyle(Color.stxMuted)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 7).fill(Color.stxAccent.opacity(0.10))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func localizedOriginName(_ origin: APIProviderOrigin) -> String {
        switch origin.kind {
        case .official: "官方"
        case .importedDefault: "导入"
        case .appSpecific: "配置档"
        case .universal: "通用"
        }
    }

    private func localizedCategoryName(_ category: APIProviderCategory) -> String {
        switch category {
        case .official: "官方"
        case .imported: "导入"
        case .aggregator: "聚合"
        case .thirdParty: "第三方"
        case .custom: "自定义"
        case .universal: "通用"
        }
    }
}

struct ClaudeModeCard: View {
    let mode: ClaudeProviderMode
    let isSelected: Bool
    let isDisabled: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: mode == .official ? "checkmark.seal" : "doc.badge.gearshape")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.stxAccent : Color.stxMuted)
                    .frame(width: 28, height: 28)
                    .background((isSelected ? Color.stxAccent : Color.stxMuted).opacity(0.12), in: RoundedRectangle(cornerRadius: 7))
                Text(mode.displayName)
                    .font(.sora(13, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(mode.description)
                    .font(.sora(10))
                    .foregroundStyle(Color.stxMuted)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 116, alignment: .topLeading)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.stxAccent.opacity(0.10) : Color.black.opacity(0.025))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isSelected ? Color.stxAccent.opacity(0.55) : Color.stxStroke, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

struct CodexProfileChip: View {
    let provider: CLIAPIProvider
    let isSelected: Bool
    let isActive: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            HStack(alignment: .center, spacing: 9) {
                Image(provider.cli.assetName)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 15, height: 15)
                    .foregroundStyle(isSelected ? Color.stxAccent : Color.stxMuted)

                VStack(alignment: .leading, spacing: 5) {
                    Text(provider.name)
                        .font(.sora(11, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(spacing: 5) {
                        APIProviderBadge(title: originName)
                        if isActive {
                            APIProviderBadge(title: "当前", tint: Color.stxAccent)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .frame(width: 178, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.stxAccent.opacity(0.10) : Color.black.opacity(0.025))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isSelected ? Color.stxAccent.opacity(0.45) : Color.stxStroke, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .help(provider.name)
    }

    private var originName: String {
        switch provider.origin.kind {
        case .official: "官方"
        case .importedDefault: "导入"
        case .appSpecific: "配置档"
        case .universal: "通用"
        }
    }
}

struct CodexChannelCard: View {
    let channel: CodexModelChannel
    let isSelected: Bool
    let isDisabled: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: channel == .official ? "checkmark.seal" : "network")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.stxAccent : Color.stxMuted)
                    .frame(width: 28, height: 28)
                    .background((isSelected ? Color.stxAccent : Color.stxMuted).opacity(0.12), in: RoundedRectangle(cornerRadius: 7))
                Text(channel.displayName)
                    .font(.sora(13, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(channel.description)
                    .font(.sora(10))
                    .foregroundStyle(Color.stxMuted)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 116, alignment: .topLeading)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.stxAccent.opacity(0.10) : Color.black.opacity(0.025))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isSelected ? Color.stxAccent.opacity(0.55) : Color.stxStroke, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

struct CodexProfileEditorPanel: View {
    var vm: APIProviderSwitcherViewModel
    let keyStorageMode: APIProviderKeyStorageMode
    let reactivateTokenAtlas: @MainActor () -> Void
    @State private var localName = ""
    @State private var localBaseURL = ""
    @State private var localAPIKey = ""
    @State private var pendingDraftSync: Task<Void, Never>?
    @FocusState private var focusedDraftField: DraftField?

    private enum DraftField: Hashable {
        case name
        case baseURL
        case apiKey
    }

    private var localDraftIsDirty: Bool {
        localName != vm.draftName
            || localBaseURL != vm.draftBaseURL
            || localAPIKey != vm.draftAPIKey
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "network")
                    .foregroundStyle(Color.stxMuted)
                Text("混合中转配置")
                    .font(.sora(14, weight: .semibold))
                Spacer(minLength: 8)
                if vm.draftIsDirty || localDraftIsDirty {
                    APIProviderBadge(title: "未保存", tint: .orange)
                }
            }

            if vm.draftProviderID == nil {
                VStack(alignment: .leading, spacing: 8) {
                    Text("请选择或新增配置档")
                        .font(.sora(13, weight: .semibold))
                    Text("混合中转需要配置名称、Base URL 和 API Key。")
                        .font(.sora(11))
                        .foregroundStyle(Color.stxMuted)
                    Button {
                        Task { await vm.addCodexProfile(keyStorageMode: keyStorageMode) }
                    } label: {
                        Label("新增配置", systemImage: "plus")
                    }
                    .controlSize(.small)
                    .disabled(vm.isWorking)
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    APIProviderFieldRow(title: "配置名称") {
                        TextField("默认中转", text: $localName)
                            .textFieldStyle(.roundedBorder)
                            .focused($focusedDraftField, equals: .name)
                            .onSubmit { flushLocalDraftToViewModel() }
                    }
                    APIProviderFieldRow(title: "Base URL") {
                        TextField("https://example.com/v1", text: $localBaseURL)
                            .textFieldStyle(.roundedBorder)
                            .focused($focusedDraftField, equals: .baseURL)
                            .onSubmit { flushLocalDraftToViewModel() }
                    }
                    APIProviderFieldRow(title: "API Key") {
                        SecureField("sk-...", text: $localAPIKey)
                            .textFieldStyle(.roundedBorder)
                            .focused($focusedDraftField, equals: .apiKey)
                            .onSubmit { flushLocalDraftToViewModel() }
                    }
                    Text("应用混合中转时，TokenAtlas 会把该 Key 写入 Codex config.toml 的 experimental_bearer_token，供 Codex 运行时读取。")
                        .font(.sora(10))
                        .foregroundStyle(Color.stxMuted)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 10) {
                        Button(role: .destructive) {
                            Task {
                                await vm.deleteSelectedCodexProfile(keyStorageMode: keyStorageMode)
                                reactivateTokenAtlas()
                            }
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                        .disabled(vm.codexProfiles.count <= 1 || vm.isWorking || vm.selectedCodexProfile?.isSystemProvider != false)

                        Spacer(minLength: 12)

                        Button {
                            cancelPendingDraftSync()
                            vm.resetDraft(keyStorageMode: keyStorageMode)
                            syncLocalDraftFromViewModel()
                        } label: {
                            Label("还原", systemImage: "arrow.uturn.backward")
                        }
                        .disabled((!vm.draftIsDirty && !localDraftIsDirty) || vm.isWorking)

                        Button {
                            flushLocalDraftToViewModel()
                            Task {
                                await vm.saveAndApplyCodexProfile(keyStorageMode: keyStorageMode)
                                syncLocalDraftFromViewModel()
                                reactivateTokenAtlas()
                            }
                        } label: {
                            Label("保存并应用", systemImage: "bolt.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(
                            vm.isWorking
                                || localName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                || localBaseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                || localAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        )
                    }
                    .controlSize(.small)
                }
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.035), in: RoundedRectangle(cornerRadius: 8))
        .disabled(vm.isWorking)
        .onAppear { syncLocalDraftFromViewModel() }
        .onDisappear { cancelPendingDraftSync() }
        .onChange(of: vm.draftProviderID) { _, _ in syncLocalDraftFromViewModel() }
        .onChange(of: vm.draftName) { _, _ in syncLocalDraftFromViewModelIfNeeded() }
        .onChange(of: vm.draftBaseURL) { _, _ in syncLocalDraftFromViewModelIfNeeded() }
        .onChange(of: vm.draftAPIKey) { _, _ in syncLocalDraftFromViewModelIfNeeded() }
        .onChange(of: localName) { _, _ in scheduleLocalDraftSync() }
        .onChange(of: localBaseURL) { _, _ in scheduleLocalDraftSync() }
        .onChange(of: localAPIKey) { _, _ in scheduleLocalDraftSync() }
        .onChange(of: focusedDraftField) { _, field in
            if field == nil {
                flushLocalDraftToViewModel()
            }
        }
    }

    private func syncLocalDraftFromViewModelIfNeeded() {
        guard vm.draftProviderID != nil else { return }
        if !localDraftIsDirty {
            syncLocalDraftFromViewModel()
        }
    }

    private func syncLocalDraftFromViewModel() {
        cancelPendingDraftSync()
        localName = vm.draftName
        localBaseURL = vm.draftBaseURL
        localAPIKey = vm.draftAPIKey
    }

    private func scheduleLocalDraftSync() {
        guard localDraftIsDirty else { return }
        let providerID = vm.draftProviderID
        let name = localName
        let baseURL = localBaseURL
        let apiKey = localAPIKey

        pendingDraftSync?.cancel()
        pendingDraftSync = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            writeDraftToViewModel(providerID: providerID, name: name, baseURL: baseURL, apiKey: apiKey)
        }
    }

    private func flushLocalDraftToViewModel() {
        let providerID = vm.draftProviderID
        cancelPendingDraftSync()
        writeDraftToViewModel(providerID: providerID, name: localName, baseURL: localBaseURL, apiKey: localAPIKey)
    }

    private func writeDraftToViewModel(providerID: String?, name: String, baseURL: String, apiKey: String) {
        guard providerID != nil, vm.draftProviderID == providerID else { return }
        if vm.draftName != name {
            vm.draftName = name
        }
        if vm.draftBaseURL != baseURL {
            vm.draftBaseURL = baseURL
        }
        if vm.draftAPIKey != apiKey {
            vm.draftAPIKey = apiKey
        }
    }

    private func cancelPendingDraftSync() {
        pendingDraftSync?.cancel()
        pendingDraftSync = nil
    }
}

struct APIProviderFieldRow<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(title)
                .font(.sora(11, weight: .medium))
                .foregroundStyle(Color.stxMuted)
                .frame(width: 86, alignment: .leading)
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct CLIEnvironmentSection: View {
    private static let cardSpacing: CGFloat = 12
    private static let minimumCardWidth: CGFloat = 280

    @Bindable var vm: CLIEnvironmentViewModel
    let requestDelete: () -> Void
    let copyText: (String) -> Void
    let openURL: (URL) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text("Local environment check")
                    .font(.sora(15, weight: .semibold))
                if vm.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
                Spacer(minLength: 0)
            }

            if !vm.isLoaded {
                automaticCheckPrompt
            }

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: Self.minimumCardWidth), spacing: Self.cardSpacing)],
                alignment: .leading,
                spacing: Self.cardSpacing
            ) {
                ForEach(APIProviderCLI.allCases) { cli in
                    CLIEnvironmentStatusCard(
                        cli: cli,
                        status: vm.status(for: cli),
                        hasChecked: vm.isLoaded,
                        isLoading: vm.isLoading,
                        copyText: copyText,
                        openURL: openURL
                    )
                }
            }

            CLIEnvironmentConflictPanel(
                vm: vm,
                requestDelete: requestDelete,
                copyText: copyText
            )

            if let lastError = vm.lastError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                    Text(lastError)
                        .lineLimit(2)
                    Spacer(minLength: 8)
                    Button("Dismiss") {
                        vm.clearError()
                    }
                    .controlSize(.small)
                }
                .font(.sora(11))
                .foregroundStyle(.orange)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.orange.opacity(0.25), lineWidth: 1))
            }
        }
        .padding(.top, 2)
    }

    private var automaticCheckPrompt: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: vm.isLoading ? "hourglass" : "checkmark.shield")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.stxMuted)
                .frame(width: 20, height: 20)
            VStack(alignment: .leading, spacing: 4) {
                Text(vm.isLoading ? "正在检查本地 CLI 环境" : "本地 CLI 环境将自动检查")
                    .font(.sora(13, weight: .semibold))
                Text("TokenAtlas 会在进入配置页时读取 shell 配置文件并运行 CLI 版本检查；需要 macOS 授权时会直接弹出系统窗口。")
                    .font(.sora(11))
                    .foregroundStyle(Color.stxMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurface(.compactCard(radius: 8, fillOpacity: 0.65, cornerStyle: .circular), padding: nil)
    }
}

struct CLIEnvironmentStatusCard: View {
    let cli: APIProviderCLI
    let status: CLIToolStatus?
    let hasChecked: Bool
    let isLoading: Bool
    let copyText: (String) -> Void
    let openURL: (URL) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "terminal")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.stxMuted)
                Text(cli.shortName)
                    .font(.sora(18, weight: .semibold))
                    .lineLimit(1)
                APIProviderBadge(title: CLIEnvironmentType.macOS.displayName)
                Spacer(minLength: 8)
                statusAccessory
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(detailText)
                    .font(.sora(14).monospaced())
                    .foregroundStyle(Color.stxMuted)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(status?.diagnostic ?? status?.displayValue ?? "")

                cardFooter
            }
            .frame(maxWidth: .infinity, minHeight: 54, alignment: .topLeading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 144, alignment: .topLeading)
        .appSurface(.compactCard(radius: 8, cornerStyle: .circular, maxWidth: nil), padding: nil)
    }

    private var cardFooter: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if let status, status.isOutdated, let latestVersion = status.latestVersion {
                APIProviderBadge(title: "Latest \(latestVersion)", tint: .orange)
                    .layoutPriority(1)
            }
            Spacer(minLength: 8)
            if needsInstallActions {
                installActions
            }
        }
        .frame(maxWidth: .infinity, minHeight: 24, alignment: .bottomLeading)
    }

    private var installActions: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                Button {
                    copyText(cli.installCommand)
                } label: {
                    Label("Copy Install", systemImage: "doc.on.doc")
                }
                Button {
                    openURL(cli.installURL)
                } label: {
                    Label("Install Page", systemImage: "arrow.up.right.square")
                }
            }
            HStack(spacing: 8) {
                Button {
                    copyText(cli.installCommand)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .frame(width: 22, height: 18)
                }
                .help("Copy Install")
                Button {
                    openURL(cli.installURL)
                } label: {
                    Image(systemName: "arrow.up.right.square")
                        .frame(width: 22, height: 18)
                }
                .help("Install Page")
            }
        }
        .controlSize(.small)
    }

    @ViewBuilder
    private var statusAccessory: some View {
        if isLoading && status == nil {
            ProgressView()
                .controlSize(.small)
        } else if !hasChecked {
            Image(systemName: "clock")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.stxMuted)
        } else if status?.isInstalled == true {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(status?.isOutdated == true ? .orange : Color(red: 0.0, green: 0.65, blue: 0.38))
        } else {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.orange)
        }
    }

    private var detailText: String {
        if isLoading && status == nil {
            return "检查中..."
        }
        if !hasChecked {
            return "尚未检查"
        }
        return status?.displayValue ?? "not installed or not executable"
    }

    private var needsInstallActions: Bool {
        guard hasChecked else { return false }
        guard !isLoading else { return false }
        guard let status else { return true }
        return !status.isInstalled || status.isOutdated
    }

}

struct CLIEnvironmentConflictPanel: View {
    @Bindable var vm: CLIEnvironmentViewModel
    let requestDelete: () -> Void
    let copyText: (String) -> Void

    var body: some View {
        if !vm.isLoaded {
            automaticScanPanel
        } else if vm.conflicts.isEmpty {
            cleanPanel
        } else {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Environment variable conflicts")
                            .font(.sora(13, weight: .semibold))
                        Text("\(vm.conflicts.count) ANTHROPIC / OPENAI variable\(vm.conflicts.count == 1 ? "" : "s") found in your local environment.")
                            .font(.sora(11))
                            .foregroundStyle(Color.stxMuted)
                    }
                    Spacer(minLength: 8)
                    Button {
                        vm.selectAllDeletableConflicts()
                    } label: {
                        Label("Select All", systemImage: "checklist")
                    }
                    .controlSize(.small)
                    .disabled(vm.isCleaning || vm.conflicts.allSatisfy { !$0.isDeletable })

                    Button(role: .destructive) {
                        requestDelete()
                    } label: {
                        Label("Delete Selected", systemImage: "trash")
                    }
                    .controlSize(.small)
                    .disabled(vm.selectedDeletableCount == 0 || vm.isCleaning)
                }

                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(vm.conflicts) { conflict in
                        CLIEnvironmentConflictRow(
                            conflict: conflict,
                            isSelected: vm.isSelected(conflict),
                            isRevealed: vm.isRevealed(conflict),
                            toggleSelection: { vm.toggleSelection(conflict) },
                            toggleReveal: { vm.toggleReveal(conflict) },
                            copyText: copyText
                        )
                    }
                }

                if let result = vm.latestCleanupResult {
                    cleanupResult(result)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.09), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.orange.opacity(0.25), lineWidth: 1))
        }
    }

    private var automaticScanPanel: some View {
        HStack(spacing: 10) {
            Image(systemName: vm.isLoading ? "hourglass" : "shield.lefthalf.filled")
                .foregroundStyle(Color.stxMuted)
            VStack(alignment: .leading, spacing: 2) {
                Text(vm.isLoading ? "正在扫描环境变量冲突" : "环境变量冲突将自动扫描")
                    .font(.sora(13, weight: .semibold))
                Text("TokenAtlas 会检查进程和 shell 配置中的 ANTHROPIC / OPENAI 覆盖变量。")
                    .font(.sora(11))
                    .foregroundStyle(Color.stxMuted)
                    .lineLimit(2)
            }
            Spacer(minLength: 8)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurface(.compactCard(radius: 8, fillOpacity: 0.65, cornerStyle: .circular), padding: nil)
    }

    private var cleanPanel: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle")
                .foregroundStyle(Color(red: 0.0, green: 0.65, blue: 0.38))
            VStack(alignment: .leading, spacing: 2) {
                Text("No environment conflicts")
                    .font(.sora(13, weight: .semibold))
                Text("No ANTHROPIC or OPENAI overrides were found in process or shell config files.")
                    .font(.sora(11))
                    .foregroundStyle(Color.stxMuted)
                    .lineLimit(2)
            }
            Spacer(minLength: 8)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurface(.compactCard(radius: 8, fillOpacity: 0.65, cornerStyle: .circular), padding: nil)
    }

    private func cleanupResult(_ result: CLIEnvironmentCleanupResult) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Last cleanup backup")
                .font(.sora(10, weight: .semibold))
                .foregroundStyle(Color.stxMuted)
            Text(result.backupDirectory.path)
                .font(.sora(10).monospaced())
                .foregroundStyle(Color.stxMuted)
                .lineLimit(2)
                .truncationMode(.middle)
                .textSelection(.enabled)
            if !result.skippedConflicts.isEmpty {
                Text("\(result.skippedConflicts.count) item\(result.skippedConflicts.count == 1 ? "" : "s") skipped")
                    .font(.sora(10))
                    .foregroundStyle(.orange)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurface(.compactCard(radius: 8, fillOpacity: 0.55, cornerStyle: .circular), padding: nil)
    }
}

struct CLIEnvironmentConflictRow: View {
    let conflict: CLIEnvironmentConflict
    let isSelected: Bool
    let isRevealed: Bool
    let toggleSelection: () -> Void
    let toggleReveal: () -> Void
    let copyText: (String) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button(action: toggleSelection) {
                Image(systemName: conflict.isDeletable ? (isSelected ? "checkmark.square.fill" : "square") : "lock")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(conflict.isDeletable ? Color.stxAccent : Color.stxMuted)
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.plain)
            .disabled(!conflict.isDeletable)
            .help(conflict.isDeletable ? "Select for deletion" : "This source cannot be edited from here")

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 7) {
                    Image(conflict.cli.assetName)
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundStyle(Color.stxMuted)
                    Text(conflict.varName)
                        .font(.sora(12, weight: .semibold))
                        .lineLimit(1)
                    APIProviderBadge(title: conflict.cli.shortName)
                    Spacer(minLength: 8)
                }

                HStack(spacing: 6) {
                    Text("Value:")
                    Text(isRevealed ? conflict.varValue : conflict.maskedValue)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Button {
                        toggleReveal()
                    } label: {
                        Image(systemName: isRevealed ? "eye.slash" : "eye")
                            .frame(width: 18, height: 16)
                    }
                    .buttonStyle(.plain)
                    .help(isRevealed ? "Hide value" : "Reveal value")
                }
                .font(.sora(10).monospaced())
                .foregroundStyle(Color.stxMuted)

                HStack(spacing: 6) {
                    Text(conflict.sourceDescription)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer(minLength: 8)
                    Button {
                        copyText(conflict.varName)
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .frame(width: 18, height: 16)
                    }
                    .buttonStyle(.plain)
                    .help("Copy variable")
                    Button {
                        copyText(conflict.sourceDescription)
                    } label: {
                        Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                            .frame(width: 18, height: 16)
                    }
                    .buttonStyle(.plain)
                    .help("Copy source")
                }
                .font(.sora(10))
                .foregroundStyle(Color.stxMuted)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurface(.compactCard(radius: 8, fillOpacity: 0.75, cornerStyle: .circular), padding: nil)
    }
}
