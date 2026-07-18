import AppKit
import SwiftUI

struct ConfigurationsView: View {
    @Environment(AppEnvironment.self) private var env

    private let workspaceMaxWidth: CGFloat = 1100
    private let providerColumnWidth: CGFloat = 330
    private let columnSpacing: CGFloat = 14
    private let railMinimumHeight: CGFloat = 144
    private let editorModeContentHeight: CGFloat = 176

    @State private var editorMode: APIProviderEditorMode = .fields
    @State private var cursorLine = 1
    @State private var cursorColumn = 1
    @State private var showEnvironmentCleanupConfirmation = false
    @State private var showProviderSyncConfirmation = false
    @State private var showRecycleDeleteConfirmation = false

    var body: some View {
        @Bindable var vm = env.apiProviders
        let environmentVM = env.cliEnvironment

        CenteredPaneContainer(maxWidth: workspaceMaxWidth, topPadding: 36) {
            VStack(alignment: .leading, spacing: 18) {
                header(vm: vm)
                configurationWorkspace(vm: vm)

                CLIEnvironmentSection(
                    vm: environmentVM,
                    requestDelete: { showEnvironmentCleanupConfirmation = true },
                    copyText: copyToClipboard,
                    openURL: openExternalURL
                )
            }
        }
        .task {
            NSApp.activate(ignoringOtherApps: true)
            await environmentVM.loadIfNeeded()
            await vm.loadIfNeeded(keyStorageMode: env.preferences.apiProviderKeyStorageMode)
            await vm.loadConversationMaintenanceIfNeeded()
            NSApp.activate(ignoringOtherApps: true)
        }
        .onChange(of: env.preferences.apiProviderKeyStorageMode) { _, newMode in
            Task { await vm.reload(keyStorageMode: newMode) }
        }
        .alert("Configuration Error", isPresented: errorBinding) {
            Button("OK") { vm.clearError() }
        } message: {
            Text(vm.lastError ?? "")
        }
        .alert("Delete Environment Variables?", isPresented: $showEnvironmentCleanupConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task { await env.cliEnvironment.deleteSelectedConflicts() }
            }
        } message: {
            Text("Selected shell config lines will be backed up first, then removed. Process environment variables and read-only files are skipped.")
        }
        .alert("同步历史会话归属？", isPresented: $showProviderSyncConfirmation) {
            Button("取消", role: .cancel) {}
            Button("同步", role: .destructive) {
                Task { await env.apiProviders.runProviderSync() }
            }
        } message: {
            let snapshot = env.apiProviders.providerSyncSnapshot
            Text("将历史对话归属同步为“\(env.apiProviders.selectedProviderSyncTarget)”，预计影响 \(snapshot?.totalPendingUpdates ?? 0) 项。")
        }
        .alert("永久删除回收站记录？", isPresented: $showRecycleDeleteConfirmation) {
            Button("取消", role: .cancel) {}
            Button("永久删除", role: .destructive) {
                Task { await env.apiProviders.deleteSelectedRecycleBinEntries() }
            }
        } message: {
            Text("将永久删除选中的 \(env.apiProviders.selectedRecycleBinTokens.count) 条恢复备份。删除后不能恢复。")
        }
    }

    private func header(vm: APIProviderSwitcherViewModel) -> some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("API Provider Switcher")
                    .font(.sora(28, weight: .semibold))
                HStack(spacing: 8) {
                    Text(vm.selectedCLI.displayName)
                    Text("·")
                    Text(env.preferences.apiProviderKeyStorageMode.displayName)
                }
                .font(.sora(11))
                .foregroundStyle(Color.stxMuted)
            }
            Spacer(minLength: 12)
            if vm.isWorking {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    private func cliSelectorStrip(vm: APIProviderSwitcherViewModel) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Text("工具类型")
                .font(.sora(11, weight: .semibold))
                .foregroundStyle(Color.stxMuted)
                .frame(width: 58, alignment: .leading)

            HStack(spacing: 6) {
                ForEach(APIProviderCLI.allCases) { cli in
                    APICLISelectorButton(
                        cli: cli,
                        isSelected: vm.selectedCLI == cli
                    ) {
                        editorMode = .fields
                        vm.selectCLI(cli, keyStorageMode: env.preferences.apiProviderKeyStorageMode)
                    }
                }
            }

            Spacer(minLength: 8)
        }
        .padding(6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.025), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.stxStroke.opacity(0.7), lineWidth: 1))
    }

    @ViewBuilder
    private func configurationWorkspace(vm: APIProviderSwitcherViewModel) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            cliSelectorStrip(vm: vm)

            if vm.selectedCLI == .codex {
                codexWorkspace(vm: vm)
            } else {
                claudeWorkspace(vm: vm)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func codexWorkspace(vm: APIProviderSwitcherViewModel) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            codexChannelPanel(vm: vm)
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)
    }

    private func claudeWorkspace(vm: APIProviderSwitcherViewModel) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            claudeModePanel(vm: vm)
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)
    }

    private func claudeModePanel(vm: APIProviderSwitcherViewModel) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            claudeModePicker(vm: vm)
            if vm.selectedClaudeMode == .customSettings {
                claudeSettingsCandidatesPanel(vm: vm)
                claudeProfileStrip(vm: vm)
                if vm.draftProviderID == nil {
                    claudeEmptyEditorPanel(vm: vm)
                } else {
                    editorPanel(vm: vm)
                }
            } else {
                claudeOfficialPanel(vm: vm)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: railMinimumHeight, alignment: .topLeading)
        .appSurface(.compactCard(radius: 8, cornerStyle: .circular, maxWidth: nil))
        .task {
            await vm.loadClaudeSettingsCandidates()
        }
    }

    private func claudeModePicker(vm: APIProviderSwitcherViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(Color.stxMuted)
                Text("选择 Claude 配置方式")
                    .font(.sora(14, weight: .semibold))
                Spacer(minLength: 8)
                Text("claude --settings <file>")
                    .font(.sora(10).monospaced())
                    .foregroundStyle(Color.stxMuted)
                    .lineLimit(1)
            }

            HStack(spacing: 10) {
                ForEach(ClaudeProviderMode.allCases) { mode in
                    ClaudeModeCard(
                        mode: mode,
                        isSelected: vm.selectedClaudeMode == mode,
                        isDisabled: vm.isWorking
                    ) {
                        editorMode = .fields
                        vm.selectClaudeMode(mode, keyStorageMode: env.preferences.apiProviderKeyStorageMode)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.035), in: RoundedRectangle(cornerRadius: 8))
    }

    private func claudeOfficialPanel(vm: APIProviderSwitcherViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal")
                    .foregroundStyle(Color.stxMuted)
                Text("官方配置")
                    .font(.sora(14, weight: .semibold))
            }
            VStack(alignment: .leading, spacing: 5) {
                Text("使用 Claude Code 默认 settings.json")
                    .font(.sora(13, weight: .semibold))
                Text("保持 Claude 官方配置路径，不挂载中转配置列表和编辑器。需要维护 settings.<name>.json 时再切换到自定义 settings。")
                    .font(.sora(11))
                    .foregroundStyle(Color.stxMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack {
                Spacer(minLength: 8)
                Button {
                    vm.selectClaudeMode(.customSettings, keyStorageMode: env.preferences.apiProviderKeyStorageMode)
                } label: {
                    Label("管理自定义 settings", systemImage: "slider.horizontal.3")
                }
                .controlSize(.small)
                .disabled(vm.isWorking)
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.035), in: RoundedRectangle(cornerRadius: 8))
    }

    private func claudeSettingsCandidatesPanel(vm: APIProviderSwitcherViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "doc.badge.gearshape")
                    .foregroundStyle(Color.stxMuted)
                Text("可导入 settings 文件")
                    .font(.sora(14, weight: .semibold))
                Spacer(minLength: 8)
                if vm.isLoadingClaudeSettingsCandidates {
                    ProgressView().controlSize(.small)
                }
            }

            if vm.claudeSettingsCandidates.isEmpty {
                Text("未发现 settings.<name>.json。")
                    .font(.sora(11))
                    .foregroundStyle(Color.stxMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(vm.claudeSettingsCandidates) { candidate in
                        ClaudeSettingsCandidateRow(candidate: candidate, isWorking: vm.isWorking) {
                            Task {
                                await vm.importClaudeSettingsCandidate(
                                    candidate,
                                    keyStorageMode: env.preferences.apiProviderKeyStorageMode
                                )
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.035), in: RoundedRectangle(cornerRadius: 8))
    }

    private func claudeProfileStrip(vm: APIProviderSwitcherViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("配置档")
                    .font(.sora(15, weight: .semibold))
                Spacer(minLength: 8)
                Button {
                    Task {
                        await vm.importCurrent(keyStorageMode: env.preferences.apiProviderKeyStorageMode)
                        reactivateAtlas()
                    }
                } label: {
                    Label("导入默认", systemImage: "square.and.arrow.down")
                }
                .controlSize(.small)
                .disabled(vm.isWorking)
                Button {
                    Task {
                        await vm.addProvider(keyStorageMode: env.preferences.apiProviderKeyStorageMode)
                        reactivateAtlas()
                    }
                } label: {
                    Label("新增", systemImage: "plus")
                }
                .controlSize(.small)
                .disabled(vm.isWorking)
            }

            if vm.claudeProfiles.isEmpty {
                Text("暂无 Claude 自定义配置档。可从 settings.<name>.json 导入，或手动新增。")
                    .font(.sora(11))
                    .foregroundStyle(Color.stxMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(vm.claudeProfiles) { provider in
                            CodexProfileChip(
                                provider: provider,
                                isSelected: vm.selectedProviderID == provider.id,
                                isActive: vm.isActive(provider)
                            ) {
                                editorMode = .fields
                                vm.selectProvider(provider, keyStorageMode: env.preferences.apiProviderKeyStorageMode)
                            }
                        }
                    }
                    .padding(.vertical, 1)
                    .padding(.trailing, 2)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color.black.opacity(0.035), in: RoundedRectangle(cornerRadius: 8))
    }

    private func claudeEmptyEditorPanel(vm: APIProviderSwitcherViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("请选择或导入 Claude 配置档")
                .font(.sora(13, weight: .semibold))
            Text("选择配置档后才会加载 fields/raw 编辑器，避免进入 Claude 标签时进行重型渲染。")
                .font(.sora(11))
                .foregroundStyle(Color.stxMuted)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                Task {
                    await vm.addProvider(keyStorageMode: env.preferences.apiProviderKeyStorageMode)
                    reactivateAtlas()
                }
            } label: {
                Label("新增配置", systemImage: "plus")
            }
            .controlSize(.small)
            .disabled(vm.isWorking)
        }
        .padding(12)
        .background(Color.black.opacity(0.035), in: RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func providersColumn(vm: APIProviderSwitcherViewModel) -> some View {
        if vm.selectedCLI == .codex {
            codexProfilesColumn(vm: vm)
        } else {
            legacyProvidersColumn(vm: vm)
        }
    }

    private func legacyProvidersColumn(vm: APIProviderSwitcherViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("Providers")
                    .font(.sora(15, weight: .semibold))
                Spacer(minLength: 8)
                Button {
                    Task {
                        await vm.importCurrent(keyStorageMode: env.preferences.apiProviderKeyStorageMode)
                        reactivateAtlas()
                    }
                } label: {
                    Label("Import Current", systemImage: "square.and.arrow.down")
                }
                .controlSize(.small)
                .disabled(vm.isWorking)
                Menu {
                    Button {
                        Task {
                            await vm.addProvider(keyStorageMode: env.preferences.apiProviderKeyStorageMode)
                            reactivateAtlas()
                        }
                    } label: {
                        Label("Provider", systemImage: "plus")
                    }
                    Button {
                        Task { await vm.addUniversalProvider(keyStorageMode: env.preferences.apiProviderKeyStorageMode) }
                    } label: {
                        Label("Universal Provider", systemImage: "point.3.connected.trianglepath.dotted")
                    }
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 22, height: 22)
                }
                .menuStyle(.button)
                .controlSize(.small)
                .disabled(vm.isWorking)
                .help("New provider")
            }

            AppScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(spacing: 0) {
                        let providers = vm.providers(for: vm.selectedCLI)
                        if providers.isEmpty {
                            Text("No providers")
                                .font(.sora(12))
                                .foregroundStyle(Color.stxMuted)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            ForEach(providers) { provider in
                                APIProviderListRow(
                                    provider: provider,
                                    isSelected: vm.selectedProviderID == provider.id,
                                    isActive: vm.isActive(provider),
                                    localizedBadges: vm.selectedCLI == .codex
                                ) {
                                    editorMode = .fields
                                    vm.selectProvider(provider, keyStorageMode: env.preferences.apiProviderKeyStorageMode)
                                }
                                if provider.id != providers.last?.id {
                                    StxRule().padding(.leading, 12)
                                }
                            }
                        }
                    }
                    .appSurface(.compactCard(radius: 8, cornerStyle: .circular))

                    if let result = vm.latestApplyResult {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Last backup")
                                .font(.sora(10, weight: .semibold))
                                .foregroundStyle(Color.stxMuted)
                            Text(result.backupDirectory.path)
                                .font(.sora(10).monospaced())
                                .foregroundStyle(Color.stxMuted)
                                .lineLimit(2)
                                .textSelection(.enabled)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .appSurface(.compactCard(radius: 8, fillOpacity: 0.55, cornerStyle: .circular), padding: nil)
                    }
                }
                .padding(.trailing, 2)
            }
        }
        .frame(minWidth: providerColumnWidth, maxWidth: .infinity, alignment: .top)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private func editorColumn(vm: APIProviderSwitcherViewModel) -> some View {
        editorPanel(vm: vm)
            .frame(minWidth: providerColumnWidth, maxWidth: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func editorPanel(vm: APIProviderSwitcherViewModel) -> some View {
        if vm.selectedCLI == .codex {
            codexChannelPanel(vm: vm)
        } else if vm.draftProviderID == nil {
            VStack(alignment: .leading, spacing: 8) {
                Text("No provider selected")
                    .font(.sora(16, weight: .semibold))
                Text("Create or import a provider.")
                    .font(.sora(12))
                    .foregroundStyle(Color.stxMuted)
            }
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: railMinimumHeight, alignment: .topLeading)
            .appSurface(.compactCard(radius: 8, cornerStyle: .circular, maxWidth: nil))
        } else {
            VStack(alignment: .leading, spacing: 14) {
                editorHeader(vm: vm)
                Picker("", selection: $editorMode) {
                    ForEach(APIProviderEditorMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 190)

                if editorMode == .fields {
                    providerFields(vm: vm)
                        .frame(height: editorModeContentHeight, alignment: .top)
                } else {
                    rawEditor(vm: vm)
                        .frame(height: editorModeContentHeight, alignment: .top)
                }

                editorActions(vm: vm)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: railMinimumHeight, alignment: .topLeading)
            .appSurface(.compactCard(radius: 8, cornerStyle: .circular, maxWidth: nil))
            .task(id: vm.draftProviderID) {
                await vm.loadSelectedDraftDetailsIfNeeded()
            }
        }
    }

    private func codexProfilesColumn(vm: APIProviderSwitcherViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("配置档")
                    .font(.sora(15, weight: .semibold))
                Spacer(minLength: 8)
                Button {
                    Task {
                        await vm.importCurrent(keyStorageMode: env.preferences.apiProviderKeyStorageMode)
                        reactivateAtlas()
                    }
                } label: {
                    Label("导入当前", systemImage: "square.and.arrow.down")
                }
                .controlSize(.small)
                .disabled(vm.isWorking)
                Button {
                    Task {
                        await vm.addCodexProfile(keyStorageMode: env.preferences.apiProviderKeyStorageMode)
                        reactivateAtlas()
                    }
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 22, height: 22)
                }
                .controlSize(.small)
                .disabled(vm.isWorking)
                .help("新增配置")
            }

            AppScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(spacing: 0) {
                        let profiles = vm.codexProfiles
                        if profiles.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("暂无混合中转配置")
                                    .font(.sora(12, weight: .semibold))
                                Text("新增配置后填写 Base URL 和 API Key。")
                                    .font(.sora(11))
                                    .foregroundStyle(Color.stxMuted)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            ForEach(profiles) { provider in
                                APIProviderListRow(
                                    provider: provider,
                                    isSelected: vm.selectedProviderID == provider.id,
                                    isActive: vm.isActive(provider),
                                    localizedBadges: true
                                ) {
                                    vm.selectProvider(provider, keyStorageMode: env.preferences.apiProviderKeyStorageMode)
                                }
                                if provider.id != profiles.last?.id {
                                    StxRule().padding(.leading, 12)
                                }
                            }
                        }
                    }
                    .appSurface(.compactCard(radius: 8, cornerStyle: .circular))

                    if let result = vm.latestApplyResult {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("最近备份")
                                .font(.sora(10, weight: .semibold))
                                .foregroundStyle(Color.stxMuted)
                            Text(result.backupDirectory.path)
                                .font(.sora(10).monospaced())
                                .foregroundStyle(Color.stxMuted)
                                .lineLimit(2)
                                .textSelection(.enabled)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .appSurface(.compactCard(radius: 8, fillOpacity: 0.55, cornerStyle: .circular), padding: nil)
                    }
                }
                .padding(.trailing, 2)
            }
        }
        .frame(minWidth: providerColumnWidth, maxWidth: .infinity, alignment: .top)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func codexProfileStrip(vm: APIProviderSwitcherViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("配置档")
                    .font(.sora(15, weight: .semibold))
                Spacer(minLength: 8)
                Button {
                    Task {
                        await vm.importCurrent(keyStorageMode: env.preferences.apiProviderKeyStorageMode)
                        reactivateAtlas()
                    }
                } label: {
                    Label("导入当前", systemImage: "square.and.arrow.down")
                }
                .controlSize(.small)
                .disabled(vm.isWorking)
                Button {
                    Task {
                        await vm.addCodexProfile(keyStorageMode: env.preferences.apiProviderKeyStorageMode)
                        reactivateAtlas()
                    }
                } label: {
                    Label("新增", systemImage: "plus")
                }
                .controlSize(.small)
                .disabled(vm.isWorking)
            }

            if vm.codexProfiles.isEmpty {
                Text("暂无混合中转配置。")
                    .font(.sora(11))
                    .foregroundStyle(Color.stxMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(vm.codexProfiles) { provider in
                            CodexProfileChip(
                                provider: provider,
                                isSelected: vm.selectedProviderID == provider.id,
                                isActive: vm.isActive(provider)
                            ) {
                                vm.selectProvider(provider, keyStorageMode: env.preferences.apiProviderKeyStorageMode)
                            }
                        }
                    }
                    .padding(.vertical, 1)
                    .padding(.trailing, 2)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color.black.opacity(0.035), in: RoundedRectangle(cornerRadius: 8))
    }

    private func codexChannelPanel(vm: APIProviderSwitcherViewModel) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            codexStatusPanel(vm: vm)
            codexChannelPicker(vm: vm)
            if vm.selectedCodexChannel == .hybridRelay {
                codexProfileStrip(vm: vm)
                CodexProfileEditorPanel(
                    vm: vm,
                    keyStorageMode: env.preferences.apiProviderKeyStorageMode,
                    reactivateAtlas: reactivateAtlas
                )
            } else {
                codexOfficialPanel(vm: vm)
            }
            CodexConversationMaintenancePanel(
                vm: vm,
                showProviderSyncConfirmation: $showProviderSyncConfirmation,
                showRecycleDeleteConfirmation: $showRecycleDeleteConfirmation
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: railMinimumHeight, alignment: .topLeading)
        .appSurface(.compactCard(radius: 8, cornerStyle: .circular, maxWidth: nil))
        .task {
            await vm.refreshCodexChannelStatus()
        }
    }

    private func codexStatusPanel(vm: APIProviderSwitcherViewModel) -> some View {
        let status = vm.codexChannelStatus
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "checkmark.circle")
                    .foregroundStyle(status.configured || status.channel == .official ? Color.stxAccent : .orange)
                Text("当前状态")
                    .font(.sora(14, weight: .semibold))
                Spacer(minLength: 8)
                Text(status.configPath)
                    .font(.sora(10).monospaced())
                    .foregroundStyle(Color.stxMuted)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(status.configPath)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 10)], alignment: .leading, spacing: 10) {
                CodexStatusMetric(title: "官方登录", value: status.authenticated ? "已检测" : "未检测")
                CodexStatusMetric(title: "当前通道", value: status.channel.displayName)
                CodexStatusMetric(title: "配置档", value: status.activeProfileName)
                CodexStatusMetric(title: "已配置", value: status.configured || status.channel == .official ? "是" : "否")
            }

            HStack(spacing: 8) {
                Circle()
                    .fill(status.authenticated ? Color(red: 0.0, green: 0.65, blue: 0.38) : .orange)
                    .frame(width: 7, height: 7)
                Text("登录账号")
                    .foregroundStyle(Color.stxMuted)
                Text(status.accountLabel ?? "未读取到账号信息")
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 8)
            }
            .font(.sora(11))
        }
        .padding(12)
        .background(Color.black.opacity(0.035), in: RoundedRectangle(cornerRadius: 8))
    }

    private func codexChannelPicker(vm: APIProviderSwitcherViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "point.3.connected.trianglepath.dotted")
                    .foregroundStyle(Color.stxMuted)
                Text("选择通道")
                    .font(.sora(14, weight: .semibold))
                Spacer(minLength: 8)
                Text(vm.codexChannelStatus.authPath)
                    .font(.sora(10).monospaced())
                    .foregroundStyle(Color.stxMuted)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(vm.codexChannelStatus.authPath)
            }

            HStack(spacing: 10) {
                ForEach(CodexModelChannel.allCases) { channel in
                    CodexChannelCard(
                        channel: channel,
                        isSelected: vm.selectedCodexChannel == channel,
                        isDisabled: vm.isWorking
                    ) {
                        vm.selectCodexChannel(channel, keyStorageMode: env.preferences.apiProviderKeyStorageMode)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.035), in: RoundedRectangle(cornerRadius: 8))
    }

    private func codexOfficialPanel(vm: APIProviderSwitcherViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal")
                    .foregroundStyle(Color.stxMuted)
                Text("官方通道")
                    .font(.sora(14, weight: .semibold))
            }
            VStack(alignment: .leading, spacing: 5) {
                Text("使用 Codex/ChatGPT 官方登录")
                    .font(.sora(13, weight: .semibold))
                Text(CodexModelChannel.official.description)
                    .font(.sora(11))
                    .foregroundStyle(Color.stxMuted)
            }
            HStack {
                Spacer(minLength: 8)
                Button {
                    Task {
                        await vm.applyOfficialCodexChannel(keyStorageMode: env.preferences.apiProviderKeyStorageMode)
                        reactivateAtlas()
                    }
                } label: {
                    Label("保存官方通道", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(vm.isWorking)
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.035), in: RoundedRectangle(cornerRadius: 8))
    }

    private func editorHeader(vm: APIProviderSwitcherViewModel) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(vm.draftCLI.assetName)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundStyle(Color.stxAccent)
            VStack(alignment: .leading, spacing: 7) {
                Text(vm.draftName.isEmpty ? "Provider" : vm.draftName)
                    .font(.sora(18, weight: .semibold))
                    .lineLimit(1)
                HStack(spacing: 6) {
                    APIProviderBadge(title: vm.draftOrigin?.displayName ?? "Provider")
                    APIProviderBadge(title: vm.draftCategory.displayName)
                    if let provider = vm.selectedProvider, vm.isActive(provider) {
                        APIProviderBadge(title: "Active", tint: Color.stxAccent)
                    }
                    if vm.draftIsDirty {
                        APIProviderBadge(title: "Unsaved", tint: .orange)
                    }
                    if vm.isDraftDetailLoading {
                        APIProviderBadge(title: "Loading", tint: Color.stxAccent)
                    }
                }
            }
            Spacer(minLength: 12)
        }
    }

    private func providerFields(vm: APIProviderSwitcherViewModel) -> some View {
        @Bindable var bindableVM = vm
        let isOfficial = bindableVM.draftOrigin?.kind == .official
        let isUniversal = bindableVM.draftOrigin?.kind == .universal

        return VStack(alignment: .leading, spacing: 12) {
            APIProviderFieldRow(title: "Name") {
                TextField("Provider name", text: $bindableVM.draftName)
                    .textFieldStyle(.roundedBorder)
            }
            APIProviderFieldRow(title: "Category") {
                Picker("", selection: $bindableVM.draftCategory) {
                    ForEach(APIProviderCategory.allCases) { category in
                        Text(category.displayName).tag(category)
                    }
                }
                .labelsHidden()
                .disabled(isUniversal)
            }
            APIProviderFieldRow(title: "Base URL") {
                TextField("https://api.example.com", text: $bindableVM.draftBaseURL)
                    .textFieldStyle(.roundedBorder)
            }
            APIProviderFieldRow(title: "API Key") {
                SecureField("API key", text: $bindableVM.draftAPIKey)
                    .textFieldStyle(.roundedBorder)
            }
            APIProviderFieldRow(title: "Model") {
                TextField(bindableVM.draftCLI == .claude ? "claude-compatible model" : "gpt-compatible model", text: $bindableVM.draftModel)
                    .textFieldStyle(.roundedBorder)
            }
        }
            .disabled(isOfficial || bindableVM.isWorking)
    }

    private func rawEditor(vm: APIProviderSwitcherViewModel) -> some View {
        @Bindable var bindableVM = vm
        let isEditable = bindableVM.canSaveSelectedProvider && !bindableVM.isWorking

        return VStack(alignment: .leading, spacing: 8) {
            ConfigurationTextEditor(
                text: $bindableVM.draftRawConfig,
                fileKind: bindableVM.draftCLI == .claude ? .json : .toml,
                isEditable: isEditable
            ) { line, column in
                cursorLine = line
                cursorColumn = column
            }
            .frame(maxHeight: .infinity)
            .background(Color.black.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.stxStroke, lineWidth: 1))

            HStack(spacing: 8) {
                Text(bindableVM.draftCLI == .claude ? "settings.json" : "config.toml")
                Text("·")
                Text("\(cursorLine):\(cursorColumn)")
                Spacer(minLength: 8)
            }
            .font(.sora(10).monospacedDigit())
            .foregroundStyle(Color.stxMuted)
        }
    }

    private func editorActions(vm: APIProviderSwitcherViewModel) -> some View {
        ViewThatFits(in: .horizontal) {
            editorActionButtons(vm: vm, showLabels: true)
            editorActionButtons(vm: vm, showLabels: false)
        }
        .controlSize(.small)
    }

    private func editorActionButtons(vm: APIProviderSwitcherViewModel, showLabels: Bool) -> some View {
        HStack(spacing: 10) {
            Button(role: .destructive) {
                Task {
                    await vm.deleteSelectedProvider(keyStorageMode: env.preferences.apiProviderKeyStorageMode)
                    reactivateAtlas()
                }
            } label: {
                actionLabel("Delete", systemImage: "trash", showLabels: showLabels)
            }
            .fixedSize(horizontal: showLabels, vertical: false)
            .disabled(!vm.canDeleteSelectedProvider || vm.isWorking)
            .help("Delete")

            Spacer(minLength: 12)

            Button {
                vm.resetDraft(keyStorageMode: env.preferences.apiProviderKeyStorageMode)
            } label: {
                actionLabel("Revert", systemImage: "arrow.uturn.backward", showLabels: showLabels)
            }
            .fixedSize(horizontal: showLabels, vertical: false)
            .disabled(!vm.draftIsDirty || vm.isWorking)
            .help("Revert")

            Button {
                Task {
                    await vm.saveDraft(rawMode: editorMode == .raw, keyStorageMode: env.preferences.apiProviderKeyStorageMode)
                    reactivateAtlas()
                }
            } label: {
                actionLabel("Save Provider", systemImage: "square.and.arrow.down", showLabels: showLabels)
            }
            .fixedSize(horizontal: showLabels, vertical: false)
            .disabled(!vm.canSaveSelectedProvider || !vm.draftIsDirty || vm.isWorking)
            .help("Save Provider")

            Button {
                Task {
                    await vm.enableSelectedProvider(rawMode: editorMode == .raw, keyStorageMode: env.preferences.apiProviderKeyStorageMode)
                    reactivateAtlas()
                }
            } label: {
                actionLabel("Enable Provider", systemImage: "bolt.fill", showLabels: showLabels)
            }
            .fixedSize(horizontal: showLabels, vertical: false)
            .buttonStyle(.borderedProminent)
            .disabled(vm.selectedProvider == nil || vm.isWorking)
            .help("Enable Provider")
        }
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

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { env.apiProviders.lastError != nil },
            set: { newValue in
                if !newValue { env.apiProviders.clearError() }
            }
        )
    }

    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    private func openExternalURL(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    @MainActor
    private func reactivateAtlas() {
        DockVisibilityCoordinator.shared.bringVisibleWindowsForward()
    }
}

#if DEBUG
#Preview {
    ConfigurationsView()
        .environment(AppEnvironment.preview())
        .frame(width: 1180, height: 780)
}
#endif
