# AnimeLog

AnimeLog 是一款面向个人使用的 Android 和 Windows 动漫、漫画记录应用。项目使用 Flutter 构建，界面和业务逻辑共用；记录数据保存在各设备本机的 SQLite 数据库中。

项目起因是把个人记录动漫的习惯从 Notion 延伸成一个可以随手使用的应用。它不需要账号，核心记录可以离线维护；Android 和 Windows 之间不自动同步，可通过 JSON 备份迁移。

当前版本：**1.0.35+36**。发布安装包将在 GitHub Releases 提供；源代码仓库不包含 `dist/` 中的构建产物。

## 功能

- 管理动漫和漫画记录，包括状态、观看或阅读进度、评分和备注。
- 记录单集观看历史、分集备注，并在时间轴和统计页面回顾进度。
- 支持手动录入，也可查询 Bangumi 作品资料。
- 可选使用 OpenAI-compatible AI 接口辅助识别动漫标题。候选资料需要用户确认后才会新建记录。
- 导出与导入 JSON 备份，用于恢复数据或在设备间迁移。
- Android 与 Windows 共用业务规则，并根据屏幕宽度调整布局。

## 数据与联网

- 每个平台的数据保存在本机；应用没有账号、云端数据库或自动同步。
- 手动记录和浏览本地数据可离线使用。查询作品资料和使用 AI 时需要网络。
- AI 接口的 API Key 保存在系统安全存储中，不写入应用数据库。
- 使用 AI 或资料查询时，会向所配置的服务发送完成该请求所需的信息。

## 下载

在本项目的 GitHub 页面打开 **Releases**，下载最新的 Android APK 或 Windows x64 ZIP。Windows 版解压后请保留完整目录结构，包括相邻的 DLL 和 `data` 目录。

## 本地运行与构建

需要 Flutter stable SDK。构建 Android 版需要 Android SDK；构建 Windows 版需要 Visual Studio 的 **Desktop development with C++** 工作负载。

```powershell
flutter pub get
flutter devices
flutter run -d windows
```

连接 Android 设备后，可将 `windows` 替换为 `flutter devices` 列出的设备 ID。构建 release 包：

```powershell
flutter build apk --release
flutter build windows --release
```

更多项目结构和设计说明：

- [开发说明](docs/DEVELOPMENT.md)
- [领域模型](docs/DOMAIN_MODEL.md)
- [AI 录入流程](docs/AI_INTAKE.md)
- [备份与迁移](docs/BACKUP.md)
- [界面说明](docs/UI.md)
