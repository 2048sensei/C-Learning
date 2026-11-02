# 更新日志

本项目的所有重要变更都会记录在此。
格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### Added

- 仓库门面：`README.md`、`LICENSE`、`CONTRIBUTING.md`、本更新日志
- `.github/workflows/pages.yml`：合并到 `main` 后自动发布 GitHub Pages
- `.github/workflows/verify.yml`：提交与 PR 自动核对清单哈希、检查内部链接
- `scripts/verify-release.ps1`、`scripts/update-release-info.ps1`、`scripts/check-links.mjs`
- Issue 模板（问题反馈 / 内容建议）与 PR 模板、`.editorconfig`

### Changed

- 将根目录的 `使用说明.txt` 移入 `学习资源/`，与发布清单记录的路径保持一致

### Fixed

- `release-info.json` 指向的 `学习资源/使用说明.txt` 不存在，导致完整性校验不通过

## [1.1.0] - 2026-09-19

首个对外版本，对应 `学习资源/release-info.json` 中的 1.1.0。

### Added

- 17 章主线课程：入门基础、流程与数据、进阶与实战三个模块
- 5 个附录页面（例题库、易错库、术语表、速查表、工具箱）与单片机实践页（12 个场景）
- 全局搜索、明暗主题、章节进度、章末小测与错题复习
- 学习记录本地保存，支持导出备份、合并导入与覆盖导入
- Windows 便携启动器与离线静态站点
