# Changelog

All notable changes to TokenAtlas are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

This file is generated from the same source of truth as the in-app release history:
Conventional Commit messages (grouped by `scripts/release_notes_lib.py`) and the
per-release overrides in `release-notes/history/v*.json`. Regenerate it with:

```bash
python3 scripts/generate-changelog.py
```

## [Unreleased]

### 修复

- 清理旧应用名称与状态刷新
- 重新探测活动权限状态
- 修复状态栏周期刷新复发
- 修复授权失败误清令牌
- 修复状态栏周期刷新

### 工程与发布

- 引入 SwiftLint 静态检查与 CI 门禁

## [1.0.0] - 2026-06-01

_重新定位为精简后的新产品起点_

- 以精简后的应用形态作为新的版本基线
- 版本号从 1.0.0 重新开始，构建号重置为 1
- 移除旧发布历史中已经下线的功能叙事
- 后续 Git 历史等待重新初始化后再按新基线提交

[Unreleased]: https://github.com/can4hou6joeng4/TokenAtlas/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/can4hou6joeng4/TokenAtlas/releases/tag/v1.0.0
