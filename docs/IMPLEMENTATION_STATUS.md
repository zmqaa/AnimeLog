# 实现状态与实际检查

更新：2026-10-12。应用版本为 1.0.35+36，Flutter 3.47.7 / Dart 3.13.5，SDK 使用 D:/dev/flutter。当前源码为 schema v3，本次没有修改数据库 schema 或应用身份，没有重新执行 flutter create，没有修改 D:/Projects/AnimeTrack。以下区分最新打包、源码调整、此前打包和历史阶段的实际结果。

## 本次 1.0.35+36 撤销历史同步回退进度

- 修复数据管理及番剧详情页删除历史后进度仍保留的问题。撤销第 N 集会将进度回退到 `min(当前进度, N−1)`，并在同一事务删除高于新进度的历史；例如进度为 4 时撤销第 3 集，进度变为 2，第 3、4 集历史一并删除。完成状态会按需退回在看，完成日期清除；历史来源的开始日期重算，手动日期保留。
- 确认框在操作前显示进度变化及清理范围；提交时事务重新验证预览，期间记录变化会拒绝过期确认。两个入口共用 repository 操作。
- 格式化相关 Dart 文件；`flutter analyze --no-pub` 输出 `No issues found!`。未运行自动化测试，也未启动应用或操作界面。
- Windows release 构建成功，独立输出为 `build/package/1.0.35/windows`，ZIP 为 15.02 MiB；固定使用目录与发布目录各 24 个文件，SHA-256 逐项一致。exe 文件／产品版本均为 1.0.35+36。
- Android release 离线构建成功，Gradle 最终为 258 个任务（30 个执行、228 个复用）。APK 为 64.54 MiB，包名 `app.animelog.offline`、versionName 1.0.35、versionCode 36、MainActivity 与 arm64-v8a／armeabi-v7a／x86_64 ABI 已核验；签名证书 SHA-256 与旧版一致，为 `d3d4d96f6a1a67037e7f50f6af3a1e883ce6d6cd606d91340b41e261117118f0`，未包含 debug kernel。交付 APK 与构建输出 SHA-256 一致。
- 新 Windows ZIP SHA-256：`D195F84C27F20562B40162DDFBAA1278216D071EFE5C879F8FB2FF56ED50FDCC`；Android APK：`8E8B8C72A955984EA8052630DBF88802274A3503BB84A57B8088A69D5A9D133A`。校验值已追加到 `dist/SHA256SUMS.txt`，旧包保留。
- 两端 release 构建及包身份核验通过；未验证真机安装、覆盖升级或实际界面交互。

## 本次 1.0.34+35 进度减一同步历史

- 对照 AnimeTrack 修正动漫库和详情页的进度减一：事务内将进度减 1，并删除集数高于新进度的观看历史；若删掉历史，则重算由历史推导的开始日期。手动开始日期仍受保护。历史低于新进度时不会被删除。
- 更新两个页面的减一提示；没有新增或运行自动化测试。
- 3 个 Dart 源码文件完成格式化；`flutter analyze --no-pub` 输出 `No issues found!`。
- Windows release 构建成功，输出 `build/package/1.0.34/windows`，ZIP 为 15.02 MiB；固定使用目录与发布目录各 24 个文件，SHA-256 逐项一致。exe 文件／产品版本均为 1.0.34+35。
- Android release 使用已有 JBR、临时 socket 路径和仓库 init script 离线构建成功；最终 Gradle 为 258 个任务（30 个执行、228 个复用）。APK 为 64.56 MiB，包名 `app.animelog.offline`、versionName 1.0.34、versionCode 35、MainActivity 与 arm64-v8a／armeabi-v7a／x86_64 ABI 已核验；签名证书 SHA-256 与旧版一致，为 `d3d4d96f6a1a67037e7f50f6af3a1e883ce6d6cd606d91340b41e261117118f0`，未包含 debug kernel。交付 APK 与构建输出 SHA-256 一致。
- 新 Windows ZIP SHA-256：`E2D608B95BA2CAC501E08E6DEFFC317A9B6A9C9CDFF37DE2742E081E8BD83FEA`；Android APK：`110EE44B772BD9A091DFDFA7FAF5862EEBB71B5EF44221F995FB9C58FB4E6C70`。校验值已追加到 `dist/SHA256SUMS.txt`，旧包保留。
- 普通 Flutter Android 构建首次遇到已记录的 JDK loopback 错误；改用项目既有 socket 配置后成功。未启动应用、运行自动化测试或验证真机安装／覆盖升级。

## 本次 1.0.33+34 漫画独立详情页

- 漫画卡片和列表点击由底部详情弹层改为独立 `MangaDetailPage` 路由，结构参考现有动漫详情页：响应式显示封面、作品概览、阅读状态、卷话进度、完成度、简介、出版／连载日期、作者／作画／出版社／连载杂志、个人备注和更多资料。
- 详情页复用现有漫画编辑表单和本地 `MangaRepository`，支持编辑后重新读取当前记录，也支持确认删除；没有修改数据库 schema、应用身份、数据目录、Key、草稿或 Android 签名。通过独立路由打开后，安卓返回手势先返回漫画库，详情页不会被顶层页面历史拦截。
- `lib/features/manga/manga_page.dart` 与新增 `lib/features/manga/manga_detail_page.dart` 已完成格式化；本次执行完整 `flutter analyze --no-pub`，输出 `No issues found!`。没有运行自动化测试、启动应用、操作界面、生成界面预览、真实接口联调或验证真机安装／覆盖升级。
- Windows release 构建成功，独立输出为 `build/package/1.0.33/windows`；补入已有 VC 运行库后生成约 15.02 MiB ZIP。ZIP 与固定目录 `build/windows/x64/runner/Release` 均为 24 个文件，文件哈希逐项一致，exe 版本为 1.0.33+34。
- Android release 构建成功，Gradle 为 258 个任务（47 个执行、211 个复用）；APK 约 64.56 MiB，包名 `app.animelog.offline`、versionName 1.0.33、versionCode 34、MainActivity、旧签名证书和 arm64-v8a／armeabi-v7a／x86_64 三种 ABI 已核验，未包含 debug kernel。交付副本与构建 APK 哈希一致；没有验证真机安装、覆盖升级或详情页实际交互。

## 本次 1.0.32+33 漫画 AI 候选录入

- 漫画新增流程参考 AnimeTrack：先输入标题查询 Bangumi 的 type=1 漫画候选，前五个候选会读取详情；唯一标题／别名命中时给出推荐，否则在 AI 已配置时让 AI 只从真实候选中辅助选择。候选仍必须由用户点击确认，再进入原有漫画编辑表单；也保留「仅用标题手动添加」路径。
- 新增漫画候选模型、Bangumi 漫画资料适配、候选选择提示和查询面板；卷数、章节数、连载状态、作者、出版社、简介及封面均来自来源资料并作为可修改预填值，不由 AI 猜测，也没有修改漫画数据库 schema。`lib/features/manga/manga_page.dart`、`lib/features/manga/manga_intake_page.dart` 及相关 Dart 文件已完成格式化；针对本次 9 个相关文件执行 `flutter analyze --no-pub`，输出 `No issues found!`。
- Windows release 构建成功，独立输出为 `build/package/1.0.32/windows`，补入已有 VC 运行库后生成约 15.01 MiB ZIP；ZIP 与固定目录 `build/windows/x64/runner/Release` 均为 24 个文件，内容逐项核对一致，exe 版本为 1.0.32+33。
- Android release 构建成功，Gradle 为 258 个任务（42 个执行、216 个复用）；APK 约 64.52 MiB，包名 `app.animelog.offline`、versionName 1.0.32、versionCode 33、MainActivity、旧签名证书、三种 ABI 和无 debug kernel 均已核验。交付副本与构建输出哈希一致，旧包保留；没有验证真机安装、覆盖升级或实际漫画查询交互。

## 本次 1.0.31+32 Android 顶层页面返回手势

- 窄屏顶层页面加入轻量导航历史。切换总览、动漫库、时间轴或右上角菜单中的其他页面后，安卓系统返回手势会回到上一个顶层页面；历史为空时仍按原行为退出应用。详情、编辑、录入等通过 `Navigator.push` 打开的页面继续使用各自原有的返回和未保存提示逻辑；宽屏桌面侧栏行为不变。
- `lib/features/library/library_page.dart` 已完成格式化；针对该文件执行 `flutter analyze --no-pub`，输出 `No issues found!`。没有运行自动化测试、启动应用、操作界面、生成界面预览或真实接口联调。
- Windows release 构建成功，独立输出为 `build/package/1.0.31/windows`，补入已有 VC 运行库后生成约 15.00 MiB ZIP；ZIP 与固定目录 `build/windows/x64/runner/Release` 均为 24 个文件，内容逐项核对一致，exe 版本为 1.0.31+32。
- Android release 构建成功，Gradle 为 258 个任务（42 个执行、216 个复用）；APK 约 64.42 MiB，包名 `app.animelog.offline`、versionName 1.0.31、versionCode 32、MainActivity、旧签名证书、三种 ABI 和无 debug kernel 均已核验。交付副本与构建输出哈希一致，旧包保留；没有验证真机安装、覆盖升级或实际返回手势交互。

## 本次 1.0.30+31 Android 窄屏顶部导航调整

- Android 窄屏 AppBar 移除 AnimeLog 标题，改为顶部三个常用入口「总览／动漫库／时间轴」；右上角菜单继续列出全部页面，包括漫画库、数据管理和设置。桌面宽屏侧栏保持不变。
- 总览页窄屏在已有记录时移除重复的「添加动漫」按钮；空数据状态仍保留首次添加引导，桌面总览操作保持不变。
- `lib/features/library/library_page.dart`、`lib/features/overview/overview_page.dart` 已完成格式化；针对两个文件执行 `flutter analyze --no-pub`，输出 `No issues found!`。没有运行自动化测试、启动应用、操作界面、生成界面预览或真实接口联调。
- Windows release 构建成功，独立输出为 `build/package/1.0.30/windows`，补入已有 VC 运行库后生成约 15.00 MiB ZIP；ZIP 与固定目录 `build/windows/x64/runner/Release` 均为 24 个文件，exe 产品／文件版本为 1.0.30+31，固定目录更新时已关闭旧版进程。
- Android release 构建成功，Gradle 为 258 个任务（42 个执行、216 个复用）；APK 约 64.42 MiB，包名 `app.animelog.offline`、versionName 1.0.30、versionCode 31、MainActivity、旧签名证书、三种 ABI 和无 debug kernel 均已核验。交付副本与构建输出哈希一致，旧包保留；没有验证真机安装、覆盖升级或实际导航交互。

## 本次 1.0.29+30 Android 图表提示关闭修复

- 修复 `ChartHoverRegion` 在 Android 点按图表后，继续点按其他图表或页面位置仍保留旧提示的问题。共用协调器确保同一时间只有一个图表提示；全局指针按下事件在命中其他位置时立即关闭当前提示，桌面鼠标悬停仍沿用原有行为。
- `lib/features/shared/chart_tooltip.dart` 已完成 Dart 格式化；针对该文件执行 `flutter analyze --no-pub`，输出 `No issues found!`。没有运行自动化测试、启动应用、操作界面、生成界面预览或真实接口联调。
- Windows release 构建成功，独立输出为 `build/package/1.0.29/windows`，补入已有 VC 运行库后生成 14.99 MiB ZIP；ZIP 与固定目录 `build/windows/x64/runner/Release` 均为 24 个文件，exe 产品／文件版本为 1.0.29+30，固定目录更新时已正常关闭旧版进程。
- Android release 构建成功，Gradle 为 258 个任务（47 个执行、211 个复用）；APK 约 64.41 MiB，包名 `app.animelog.offline`、versionName 1.0.29、versionCode 30、MainActivity、不可调试状态、旧签名证书、三种 ABI 和无 debug kernel 均已核验。交付副本与构建输出哈希一致，旧包保留；没有验证真机安装、覆盖升级或实际提示交互。

## 本次 1.0.28+29 简洁操作提示

- 全部页面的临时操作反馈统一为底部居中的小浮条，普通字号下宽度最多 440，手机保留两侧安全留白；文字放大时适当增加宽度并允许换行。跟随明暗模式和主题色，采用柔和表面底色、细边框、圆角与轻阴影，避免深色模式下出现贯穿窗口的亮色横条。
- 成功与失败分别显示完成／错误图标；缩短观看进度提示，保留原有撤销、管理历史及业务处理。普通提示默认 3 秒，错误与带操作的提示保留 6 秒；沿用 Flutter 原生提示的无障碍播报、动画、手势关闭与操作生命周期。
- 11 个 Dart 文件完成格式化，针对这些文件的 `dart analyze` 输出 `No issues found!`。没有新增依赖或修改数据规则；没有运行自动化测试、启动应用、操作界面、生成界面预览或真实接口联调。界面体验仍待用户日常使用时确认。
- Windows release 复用独立 CMake／ATL 缓存，输出 `build/package/1.0.28/windows`，补入已有 VC 运行库，生成 14.99 MiB ZIP；压缩包及固定使用目录 `build/windows/x64/runner/Release` 的 24 个文件分别逐项 SHA-256 核对一致，exe 文件／产品版本均为 1.0.28+29。更新时没有运行中的固定目录 AnimeLog 进程。
- Android release 离线构建成功，Gradle 耗时 50 秒，258 个任务中 42 个执行、216 个复用。APK 为 64.42 MiB，包名 `app.animelog.offline`、versionName 1.0.28／versionCode 29、MainActivity 与不可调试状态核验完成，三种 ABI 的九个 AOT／Flutter／SQLite 库齐全且没有 debug kernel。新旧 APK 签名验证有效，证书 SHA-256 仍为 `d3d4d96f6a1a67037e7f50f6af3a1e883ce6d6cd606d91340b41e261117118f0`；交付副本与构建输出哈希一致，两份新包校验值追加至 `dist/SHA256SUMS.txt`，旧包保留。本次没有验证真机安装、覆盖升级或实际提示交互。

## 本次 1.0.27+28 应用图标与 Android release 交付（此前版本）

- 用户反馈 1.0.26 Android 的主要功能已基本可用；这是用户实际体验反馈，没有将其计作本次新图标与 release 包的真机验收。按后续日常使用需求，将 AGENTS.md 的 Android 默认交付改为 release，并保持既有 APK 输出目录。
- 当前 Android 图标与 Flutter 模板 SHA-256 一致；按用户要求复制 AnimeTrack 的 `app/icon.png` 月夜海面原图，原图 SHA-256 为 `027708a18b6614196d4e4d7f0762da06f91019d61d3d00de6cf146e144bf557d`。AnimeTrack 的 Android 资源仍是 Capacitor 占位图标，因此没有采用它们。原图保存在 `assets/branding/app_icon.png`，本地生成五种传统 Android 图标、自适应前景及七种尺寸 Windows ICO；没有修改 AnimeTrack 文件、使用 AI 重新绘图或下载额外图标依赖。
- Android release 明确关闭 debuggable，继续使用原安装的签名证书，未生成新签名身份；保留 applicationId、schema v3、数据目录、Key、草稿和既有数据规则。准备脚本支持 release／debug，默认 release；先离线刷新依赖，再由 Flutter 官方 `build apk --release --config-only` 按模式生成注册表，并保留安全存储／文件选择插件校验和 release 排除测试插件的检查。
- 首轮 Android release 构建约 48 秒后因注册表引用仅供调试的 IntegrationTestPlugin 失败。定位当前 SDK 的 `--no-pub` 同时会跳过按模式重新生成插件注册，因此 config-only 步骤保留默认 pub 检查，复用刚刷新的依赖。没有手工修改 GeneratedPluginRegistrant、Flutter SDK、Pub 插件源码或删除测试依赖；最终注册表不含 IntegrationTestPlugin，仍包含文件选择与安全存储插件。
- 两个 PowerShell 脚本的语法、Android manifest／自适应图标／背景 XML、十份 PNG 尺寸和七层 Windows ICO 结构检查通过。没有改动 Dart 业务源码，本轮未重复运行 Dart 分析；没有运行自动化测试、启动应用、操作界面、生成界面预览或真实接口联调。
- Windows release 配置及构建耗时 29.03 秒，输出 `build/package/1.0.27/windows`；以只读 PE 资源方式核对 exe 中七个图标图层与新 ICO 的哈希一致，没有执行 exe。补入已有 VC 运行库后生成 14.99 MiB ZIP，24 个文件逐项哈希一致，完整更新固定使用目录 `build/windows/x64/runner/Release`；exe 文件／产品版本为 1.0.27+28。更新时没有运行中的固定目录 AnimeLog 进程。
- 修正准备流程后 Android release 离线构建耗时 38.19 秒，258 个任务中 33 个执行、225 个复用；输出 `build/app/outputs/flutter-apk/app-release.apk`，另存 `dist/AnimeLog-1.0.27-android.apk`，约 64.42 MiB。aapt 核验 `app.animelog.offline`、1.0.27／versionCode 28、MainActivity 和不可调试状态；APK 不含 debug kernel，三种 ABI 的 AOT／Flutter／SQLite 共九个原生库与本次 release 输出逐项哈希一致，十份打包后的传统图标／前景逐像素与本次资源一致，自适应图标 XML 和圆形图标引用正常。
- 新旧 APK 签名有效且证书 SHA-256 与 1.0.26 一致（`d3d4d96f6a1a67037e7f50f6af3a1e883ce6d6cd606d91340b41e261117118f0`）；构建输出与 dist 副本哈希一致，校验值追加至 `dist/SHA256SUMS.txt`。保留旧 debug 与 dist 包，原输出目录的旧 1.0.5 release 包已归档到 `build/package/android-archive`。两端成功构建合计 67.22 秒，首轮失败耗时另计；本次没有验证新图标的实际系统显示、release 真机安装、覆盖升级或运行体验。

## 本次 1.0.26+27 手机菜单导航与五个识别候选（此前版本）

- 窄屏移除六入口底部导航，顶部仅保留 AnimeLog 名称和右上角菜单按钮；全部页面按总览、动漫库、漫画库、时间轴、数据管理、设置排列，当前页以主题底色与加粗文字标记，管理入口前增加分隔。菜单在加载、错误和空状态下仍可打开，选中即关闭；宽屏侧栏及 IndexedStack 的搜索、筛选与滚动状态保留，不增加顶部标签栏。
- 添加动漫时最多返回五个去重候选，推荐置于首位，其余按来源搜索顺序补齐；不足五个时显示实际数量。原来的最多两次搜索、40 个去重结果判断、候选 AI 最多看前 20 个、严格标题匹配及季度／形式校验保留，仍需用户选取并确认详情才能填写新记录。
- 5 个修改 Dart 文件完成格式化；针对这些文件的 `dart analyze` 最终输出 `No issues found!`。同步调整已有导航断言，以及推荐位于来源前五名之外时仍须展示的候选断言；按约定未运行自动化测试、启动新版本、操作界面、生成截图／预览或真实接口联调。未修改 schema v3、应用身份、数据目录、Key、草稿、依赖版本或 Android 签名。
- Windows release 复用已有 ATL 与独立 CMake 缓存，配置及构建耗时 29.46 秒，输出 `build/package/1.0.26/windows`。补入已有官方 VC 运行库后生成 14.83 MiB ZIP，24 个文件逐项 SHA-256 一致；按既有授权正常关闭固定目录中的一个旧版 AnimeLog 进程，再完整更新 `build/windows/x64/runner/Release` 并逐项核验，exe 文件／产品版本为 1.0.26+27。
- Android debug 离线构建耗时 19.02 秒，213 个任务中 32 个执行、181 个复用。APK 约 162.87 MiB，aapt 核验 `app.animelog.offline`、1.0.26 / versionCode 27 与 MainActivity；三种 ABI 的 Flutter／SQLite 原生库齐全。新旧 APK 签名有效且证书与 1.0.25 一致（SHA-256 `d3d4d96f6a1a67037e7f50f6af3a1e883ce6d6cd606d91340b41e261117118f0`）；kernel 与本次 Flutter debug 编译结果、交付 APK 与构建 APK 的哈希均一致。
- 两端成功构建合计 48.48 秒，依赖／插件仅离线刷新；两份新包校验值追加至 `dist/SHA256SUMS.txt`，旧包保留。没有验证实际菜单布局、切换交互、候选选择与真实查询效果、真机安装或覆盖升级；静态分析、构建和包校验不作为这些体验的验收证据。

## 本次 1.0.25+26 点击控件统一手形光标（此前版本）

- 对照当前 SDK 源码确认 adaptiveClickable 在原生平台默认使用箭头，既有按钮主题没有覆盖所有内置下拉、菜单和日期／时间选择器。新增 AppClickCursor，置于 Navigator 上方及启动失败页面，按实际命中目标的可用点击／长按动作补齐默认箭头或未指定的光标，弹出菜单主题同时明确可用／禁用项的光标。
- 保留输入与选择文字的文本光标，以及已经明确指定的调整、拖动和图表精确查看光标；按最近的命中控件识别禁用状态，避免继承外层卡片的可点击状态。只添加光标注解，不修改原有子级命中坐标、点击回调、布局和手势处理；Android 触摸交互、库页卡片与数据规则不变。
- 3 个修改／新增 Dart 文件完成格式化；`dart analyze lib/features/shared/app_click_cursor.dart lib/features/shared/app_theme.dart lib/main.dart` 输出 `No issues found!`。未运行自动化测试、启动新版本、操作界面、生成截图／预览或业务接口联调；未修改 schema v3、应用身份、数据目录、Key 存储格式、草稿、依赖或 Android 签名。
- Windows release 复用已有 ATL 与独立 CMake 缓存，配置及构建耗时 31.18 秒，输出 `build/package/1.0.25/windows`。补入已有官方 VC 运行库后生成 14.83 MiB ZIP，24 个文件逐项 SHA-256 一致；完整更新 `build/windows/x64/runner/Release` 并逐项核验，exe 文件／产品版本为 1.0.25+26。更新时没有运行中的固定目录 AnimeLog 进程。
- Android debug 离线构建耗时 19.91 秒，213 个任务中 32 个执行、181 个复用。APK 约 162.87 MiB，aapt 核验 `app.animelog.offline`、1.0.25 / versionCode 26 与 MainActivity；三种 ABI 的 Flutter／SQLite 原生库齐全。新旧 APK 签名有效且证书与 1.0.24 一致（SHA-256 `d3d4d96f6a1a67037e7f50f6af3a1e883ce6d6cd606d91340b41e261117118f0`）；kernel 与本次 Flutter debug 编译结果、交付 APK 与构建 APK 的哈希均一致。
- 两端成功构建合计 51.09 秒，依赖／插件仅离线刷新；两份新包校验值追加至 `dist/SHA256SUMS.txt`，旧包保留。没有验证实际鼠标悬停、输入／禁用状态、弹出菜单、日期／时间选择器的界面体验、真机安装或覆盖升级；静态分析、构建和包校验不作为这些体验的验收证据。

## 本次 1.0.24+25 设置卡片与 AI 预设（此前版本）

- 导航统一为总览、动漫库、漫画库、时间轴、数据管理、设置，时间轴位于漫画库之后；同步修改 IndexedStack 页面顺序及总览／数据管理进入动漫库的目标位置。库页每页十部、宽屏两行五列与纵向卡片规则保留。
- 设置页提取为独立 SettingsPage 和共用 SettingsPanel：外观提供浅色／深色样式选择与带名称的主题色，AI 和备份在宽屏并排，底部仅显示本机收藏简要信息。原侧栏外观控件保持紧凑，本地外观保存方式不变；配置摘要只读地址／模型，不读取或展示 Key。
- AI 设置增加 DeepSeek、Qwen 与自定义服务，预设自动填写地址和默认模型；模型可下拉选择或填写自定义 ID，读取已有配置不迁移地址／模型。接口地址、Qwen 地域和删除 Key 放入高级设置；相同 endpoint 的已保存 Key 可以留空保留，切换服务／地域或修改 endpoint 会清空未保存的 Key，已保存 Key 继续按 endpoint 隔离。
- 按本轮核对的官方文档提供 DeepSeek Flash／Pro、Qwen Plus／Flash／3.5 Plus，Qwen 默认北京，可选新加坡与美国弗吉尼亚。仅在已知官方 HTTPS endpoint 和列出的模型上添加非思考扩展参数，其他自定义接口沿用标准兼容请求体。详细地址、模型和官方来源见 AI_INTAKE.md；没有进行真实模型服务联调，服务账号的 Key、地域与模型权限仍需匹配。
- 7 个修改／新增 Dart 文件完成格式化；针对这些文件的 `dart analyze` 输出 `No issues found!`。未运行自动化测试、启动新版本、操作界面、生成截图／预览或业务接口联调；未修改 schema v3、应用身份、数据目录、Key 存储格式、草稿、依赖或 Android 签名。
- Windows release 复用已有 ATL 与独立 CMake 缓存，配置及构建耗时 31.49 秒，输出 `build/package/1.0.24/windows`。补入已有官方 VC 运行库后生成 14.83 MiB ZIP，24 个文件逐项 SHA-256 一致；完整更新 `build/windows/x64/runner/Release` 并逐项核验，exe 文件／产品版本为 1.0.24+25。更新时没有运行中的固定目录 AnimeLog 进程。
- Android debug 离线构建耗时 20.23 秒，213 个任务中 32 个执行、181 个复用。APK 约 162.87 MiB，aapt 核验 `app.animelog.offline`、1.0.24 / versionCode 25 与 MainActivity；三种 ABI 的 Flutter／SQLite 原生库齐全。新旧 APK 签名有效且证书与 1.0.23 一致（SHA-256 `d3d4d96f6a1a67037e7f50f6af3a1e883ce6d6cd606d91340b41e261117118f0`）；kernel 与本次 Flutter debug 编译结果、交付 APK 与构建 APK 的哈希均一致。
- 两端成功构建合计 51.72 秒，依赖／插件仅离线刷新；两份新包校验值追加至 `dist/SHA256SUMS.txt`，旧包保留。没有验证实际布局、界面交互、真实服务连接、真机安装或覆盖升级，构建与包核验不作为这些功能体验的验收证据。

## 本次 1.0.23+24 纵向封面与两行简介（此前版本）

- 只读参考本机 AnimeTrack 的 AnimeCard.tsx，将动漫／漫画库的封面模式改成上方封面、状态与渐变标题，下方进度、两行简介和底部操作的纵向结构。缺少简介明确显示「暂无简介」，未知总数不推算；卡片保留整体点击、手形指针、悬停反馈、主题色与明暗模式，没有修改 AnimeTrack 源码或用户资料。
- 每页仍为 10 条，正常宽屏五列、两行；卡片总高度按头部之后的实际剩余空间计算，预留底部分页，默认文字下目标范围 224–420。先布局下方内容，再用剩余高度安排封面；紧凑封面使用一行标题，更高封面最多两行，并按空间显示原名和第二状态。空间不足或文字明显放大时使用自然高度与必要滚动，避免截断操作。
- 新增共用搜索／筛选布局，在作品区域至少 900 宽且文字缩放不超过 1.3 时并排显示，其他情况纵向排列。库页标题通过可选 compact 参数收紧，其他页面默认样式保持原有规则；同步缩小头部、网格和分页留白。
- 动漫底部为减一与「+ 看一集」，到顶显示禁用「已看完」，忙碌期间禁用重复操作；漫画保留卷／话进度，增加比例展示并提供编辑与更多菜单。今天历史、撤销、进度校验、编辑和删除确认规则保持原样。右侧资料标签过滤和统计面板沿用 1.0.22，记录标签与备份保留。
- 4 个修改 Dart 文件完成格式化；`dart analyze lib/features/shared/collection_card.dart lib/features/shared/app_theme.dart lib/features/library/library_page.dart lib/features/manga/manga_page.dart` 输出 `No issues found!`。未运行自动化测试、启动新版本、操作界面、生成截图／预览或业务接口联调；未更改应用身份、schema v3、数据目录、Key、草稿、依赖或 Android 签名。
- Windows release 复用已有 ATL 与独立 CMake 缓存，配置及构建耗时 34.99 秒，输出 `build/package/1.0.23/windows`。补入已有官方 VC 运行库后生成 14.79 MiB ZIP，24 个文件逐项 SHA-256 一致；完整更新 `build/windows/x64/runner/Release` 并逐项校验，exe 文件／产品版本为 1.0.23+24。更新时没有运行中的固定目录 AnimeLog 进程。
- Android debug 离线构建耗时 20.17 秒，213 个任务中 32 个执行、181 个复用。APK 约 162.85 MiB，aapt 核验 `app.animelog.offline`、1.0.23 / versionCode 24 与 MainActivity；三种 ABI 的 Flutter／SQLite 原生库齐全。新旧 APK 签名有效且证书与 1.0.22 一致（SHA-256 `d3d4d96f6a1a67037e7f50f6af3a1e883ce6d6cd606d91340b41e261117118f0`）；kernel 与本次 Flutter debug 编译结果、交付 APK 与构建 APK 的哈希均一致。
- 两端成功构建合计 55.16 秒，依赖／插件仅离线刷新；两份新包校验值追加至 `dist/SHA256SUMS.txt`，旧包保留。没有验证实际窗口中的整页显示、界面交互、真机安装或覆盖升级；构建与包校验不作为功能体验验收证据。

## 本次 1.0.22+23 两行五列与类型标签（此前版本）

- 按用户给出的两行五列限制，动漫／漫画库统一每页 10 条，宽屏五列形成两行。共用卡片高度计算读取搜索／筛选头部之后的实际剩余空间，预留底部分页；默认文字下目标高度 232–280，横向卡片保留原有信息和操作，放高封面与内边距，较高卡片标题最多三行。
- 五列卡片宽度不足 220、剩余高度不足或文字明显放大时采用自然高度，窄屏继续减少列数；目标高度作为最小高度，长内容可自然增长而不被裁切。没有新增简介或纵向大封面，底部分页、搜索、筛选、排序、列表和右侧统计继续保留。
- 侧栏统一过滤漫画改／漫改／漫画改编、TV／OVA／ONA／剧场版等形式标签和独立年份／年月／季度／季节标签；忽略大小写、空格和开头的 #，不隐藏包含年份的任意故事标签。过滤后取前 20 个可见标签，声优仍为前 10 名；缩小统计行、面板和筛选标签的留白。只改变侧栏展示，未修改记录标签、核心统计、搜索规则或 JSON 备份。
- 5 个修改 Dart 文件完成格式化；`dart analyze lib/features/shared/collection_card.dart lib/features/shared/collection_sidebar.dart lib/features/shared/pagination.dart lib/features/library/library_page.dart lib/features/manga/manga_page.dart` 输出 `No issues found!`。没有运行自动化测试、启动新版本、操作界面、生成截图／预览或业务接口联调；未更改应用身份、schema v3、数据目录、Key、草稿、依赖或 Android 签名。
- Windows release 复用已有 ATL 与独立 CMake 缓存，配置及构建耗时 30.86 秒，输出到 `build/package/1.0.22/windows`。补入已有官方 VC 运行库，生成 14.79 MiB ZIP，24 个文件逐项 SHA-256 一致；正常关闭固定目录中运行的旧版后，完整更新 `build/windows/x64/runner/Release` 并逐项校验，exe 文件／产品版本为 1.0.22+23。
- Android debug 离线构建耗时 19.33 秒，213 个任务中 32 个执行、181 个复用。APK 约 162.84 MiB，aapt 核验 `app.animelog.offline`、1.0.22 / versionCode 23 与 MainActivity；三种 ABI 的 Flutter／SQLite 原生库齐全。新旧 APK 签名有效且证书与 1.0.21 一致（SHA-256 `d3d4d96f6a1a67037e7f50f6af3a1e883ce6d6cd606d91340b41e261117118f0`）；kernel 与本次 Flutter debug 编译结果、交付 APK 与构建 APK 的哈希均一致。
- 两端成功构建合计 50.19 秒，依赖／插件仅离线刷新；两份新包校验值追加至 `dist/SHA256SUMS.txt`，旧包保留。未验证实际窗口中的整页显示、界面交互、真机安装或覆盖升级；构建与包校验不作为功能体验验收证据。

## 本次 1.0.21+22 恢复紧凑整页布局（此前版本）

- 根据用户关于「卡片太大，希望进页面直接看完、不用下拉」的反馈，将动漫／漫画库恢复到 1.0.19 的横向紧凑布局：小封面在左，状态、标题与进度在右，16 间距、12 内边距、原有封面尺寸和标题字号。两个库页恢复每页 15 条、宽屏最多 5 列，正常宽屏按三行整页浏览。
- 移除 1.0.20 新增的纵向大封面、渐变标题、完结／普通标签、简介占位、漫画比例条和大操作按钮；动漫恢复紧凑加一／减一，漫画恢复原名、作者、卷／话进度与更多菜单。搜索、筛选、列表、右侧统计栏和底部分页保留；窄屏与放大文字时仍保留必要滚动，不裁切记录或操作。
- 4 个 Dart 文件完成格式化；`dart analyze lib/features/shared/collection_card.dart lib/features/shared/pagination.dart lib/features/library/library_page.dart lib/features/manga/manga_page.dart` 输出 `No issues found!`。没有运行自动化测试、启动新版本、操作界面、生成截图／预览或业务接口联调；没有修改数据库 schema、应用身份、数据目录、Key、草稿或 Android 签名。
- Windows release 复用已有 ATL 与独立 CMake 缓存，配置及构建耗时 31.93 秒，输出 `build/package/1.0.21/windows`。补入已有官方 VC 运行库，生成 14.78 MiB ZIP，24 个文件逐项 SHA-256 一致；正常关闭固定目录中运行的旧版后，完整更新 `build/windows/x64/runner/Release` 并逐项核对，exe 文件／产品版本为 1.0.21+22。
- Android debug 离线构建耗时 21.41 秒，213 个任务中 32 个执行、181 个复用。APK 约 162.84 MiB，aapt 核验 `app.animelog.offline`、1.0.21 / versionCode 22 和 MainActivity；三种 ABI 的 Flutter／SQLite 原生库齐全。签名有效且证书与 1.0.20 一致（SHA-256 `d3d4d96f6a1a67037e7f50f6af3a1e883ce6d6cd606d91340b41e261117118f0`）；kernel 与本次 Flutter debug 编译结果、交付 APK 与构建 APK 的哈希均一致。
- 两端成功构建合计 53.34 秒，依赖／插件仅离线刷新；新包校验值追加至 `dist/SHA256SUMS.txt`，旧包保留。没有验证实际窗口中的整页显示、界面交互、真机安装或升级运行，构建与文件校验不作为功能体验验收证据。

## 本次 1.0.20+21 大封面卡片与八条分页（此前版本）

- 根据用户提供的 AnimeTrack 截图，将动漫／漫画库的封面模式改为大封面纵向卡片；两个库页每页从 15 条减少到 8 条，最大列数从 5 列减少到 4 列，最小卡片宽度改为 232、间距改为 24。窗口变窄或字体放大时继续减少列数，作品区域不足 600 时保持单列，自然行高避免固定网格裁切文字。
- 封面下沿渐变承载标题与原名，上沿展示个人状态、已知完结／连载情况和第一个普通标签；卡片下方保留类型／季度或作者、进度，增加两行简介。缺失简介明确显示「暂无简介」，未知总数不推算；漫画进度条优先采用已知话数比例，否则采用已知卷数比例，不改写当前进度。
- 动漫主操作改为「+ 看一集」，到顶显示禁用「已看完」，保留减一、忙碌防重复、今天观看历史和撤销；漫画增加明确的「编辑记录」，更多菜单保留编辑与确认删除。搜索、筛选、排序、列表模式、底部分页和右侧统计继续保留；兼容明暗模式与当前主题色，没有新增数据字段或依赖。
- 4 个 Dart 文件完成格式化；`dart analyze lib/features/shared/collection_card.dart lib/features/shared/pagination.dart lib/features/library/library_page.dart lib/features/manga/manga_page.dart` 输出 `No issues found!`。本轮没有运行自动化测试、启动应用、操作界面、生成截图／预览或联网联调；本地数据、Key 和草稿保持原有兼容。
- Windows release 沿用已有 ATL 与独立 CMake 缓存，配置及构建耗时 31.72 秒，输出到 `build/package/1.0.20/windows`。补入已有官方 VC 运行库后生成 14.79 MiB ZIP，24 个文件逐项 SHA-256 核对一致；完整更新 `build/windows/x64/runner/Release` 并逐项校验，exe 文件／产品版本为 1.0.20+21。更新时没有运行中的固定目录 AnimeLog 进程。
- Android debug 离线构建耗时 20.23 秒，213 个任务中 32 个执行、181 个复用。APK 约 162.84 MiB，aapt 核验包名 `app.animelog.offline`、1.0.20 / versionCode 21 和 MainActivity 入口；三种 ABI 的 Flutter／SQLite 原生库齐全。新旧 APK 签名有效且证书与 1.0.19 一致（SHA-256 `d3d4d96f6a1a67037e7f50f6af3a1e883ce6d6cd606d91340b41e261117118f0`）；kernel 与本次 Flutter debug 编译结果、交付 APK 与构建 APK 的哈希均一致。
- 两端成功构建合计 51.95 秒，依赖／插件仅离线刷新；新包校验值已追加至 `dist/SHA256SUMS.txt`，旧包与校验值保留。没有验证界面交互、真机安装或升级运行，构建与文件校验不作为功能体验验收证据。

## 本次 1.0.19+20 图表提示与四条分页（此前版本）

- 动漫／漫画紧凑卡片与数据管理记录移除进入箭头，保留整卡／整行点击、鼠标与焦点反馈；功能性排序／下拉箭头保留。总览继续观看去掉残留的独立刷次文字。
- 新增共用图表浮层：鼠标进入即显示、跟随位置、限制在窗口范围内，悬停区域高亮；手机点按或长按查看，触摸提示 4 秒后关闭。浮层不接收鼠标事件，不遮断底层图表命中，也不受卡片／滚动区域裁切。
- 热力图显示完整日期／星期、作品数和观看集数，包括零记录日期，范围外占位不响应；读取中或失败时不展示零值热图。总览柱状趋势和时间轴折线提示完整日期或年份／月份、作品数及集数。折线按横坐标选择最近点，增加选中点与竖向参考线，并按宽度／文字缩放减少轴标签密度。状态饼图与类型排行增加数量、占比提示。
- 作品数按每个日期／月份的 animeUuid 去重，同一记录多集只计一部，不合并同名记录；计数仍用 watchedOn，排除未来、无效及范围外日期。新增 2 项跨年日期、作品去重与月统计回归用例，按约定未运行。
- 时间轴左侧时间线／列表统一每页 4 条，分页范围、页码夹紧及筛选重置共用新大小；跨页分组保留总数提示。右侧最近作品继续每页 10 部并独立翻页，手机沿用四条分页与顺序堆叠。
- 7 个修改／新增 Dart 文件完成格式化；`dart analyze lib/features lib/core/domain/library_statistics.dart test/core/library_statistics_test.dart` 输出 `No issues found!`。依赖／插件仅离线刷新，无新增依赖、schema 或用户数据改写；没有运行自动化测试、启动新版本、操作界面、生成截图／预览或联网联调。
- Windows release 使用已有独立 CMake 缓存，配置与构建耗时 30.84 秒，输出 `build/package/1.0.19/windows`。补入已有官方 VC 运行库，ZIP 14.78 MiB；24 个文件逐项哈希一致。正常关闭运行中的旧版后，完整更新 `build/windows/x64/runner/Release`，24 个发布文件逐项校验，exe 文件／产品版本为 1.0.19+20。
- Android debug 离线构建耗时 19.73 秒，213 个任务中 32 个执行、181 个复用。APK 约 162.84 MiB，aapt 核验 `app.animelog.offline`、1.0.19 / versionCode 20 和三种 ABI；三种 Flutter／SQLite 原生库齐全。签名验证有效且与 1.0.18 一致（证书 SHA-256 `d3d4d96f6a1a67037e7f50f6af3a1e883ce6d6cd606d91340b41e261117118f0`）；kernel 与本次编译结果及交付 APK 与构建 APK 的哈希一致。
- 两端成功构建合计 50.57 秒。新包校验值追加到 `dist/SHA256SUMS.txt`，旧版包与校验值保留；应用身份、数据目录、Key、草稿和 Android 签名保持兼容，未验证界面交互或真机覆盖安装。

## 本次 1.0.18+19 详情、管理与观看时刻（此前版本）

- 根据用户三张截图，只读参考本机 AnimeTrack 的 AnimeDetailMain、AnimeDetailSidebar 和 AdminPageClient，重组 AnimeLog 详情与管理页；未修改 AnimeTrack 源码或数据。
- 详情宽屏采用大封面侧栏与作品概览，分区展示进度、简介、日期、声优、个人备注及历史；窄屏顺序堆叠。管理页宽屏采用可选中记录列表与固定详情栏，手机采用详情底部面板，保留编辑、补记、资料补全、进度加减及确认删除。管理搜索支持时分，分页位于列表底部，每页 24 条。
- 详情、管理和动漫库不再单独显示「第几刷」，已有重刷标签与普通标签同样呈现；保留原有字段、标签、创建规则与备份兼容，不改写旧记录。
- 修复进度加一未写 watchedAt、纠正历史直接清空时刻的问题。今天的 +1 写入真实 UTC 时刻，日期外的底层调用仍保留未知；手动补记／纠正新增 24 小时时分选择、当前时分与清空。未确认时分的新补记改为过去日期时清空当前时间默认值。已有精确时刻仅改集数时保留，日期调整但时分未改时保留秒数；显式清空移除时刻。日期／时间不匹配或格式无效会在事务写入前拒绝。同日历史按已知时刻排序，日期统计仍用 watchedOn。
- 历史展示统一使用日期和本机时区 HH:mm，未知时刻显示「时间未记录」，不以 createdAt 或 00:00 补造。沿用 watchedAt、schema v3、目录、Key、草稿与原有备份字段，未读取或修改用户实际数据库。
- 10 个修改／新增 Dart 文件完成格式化；`dart analyze lib/features lib/core/api/library_repository.dart lib/data/local/sqlite_library_repository.dart test/data/sqlite_library_repository_test.dart` 输出 `No issues found!`。新增 5 项时间写入／撤销、同日排序／保留精度、纠正／清空、非法时间事务回滚、未知时间不推导的回归用例，按约定未运行。没有启动应用、操作界面、生成截图／预览或联网联调。
- Windows release 使用已有 ATL 与独立 CMake 缓存，配置及构建耗时 36.00 秒，输出到 `build/package/1.0.18/windows`。补入已有官方 VC 运行库后生成 14.78 MiB ZIP；24 个文件逐项核对 SHA-256。完整更新 `build/windows/x64/runner/Release` 并逐项核对，exe 文件／产品版本为 1.0.18+19。更新时没有运行中的项目进程。
- Android debug 离线构建耗时 23.22 秒，213 个任务中 32 个执行、181 个复用。APK 约 162.83 MiB，包名 `app.animelog.offline`，1.0.18 / versionCode 19，三种 ABI 的 Flutter／SQLite 库齐全；签名验证有效，证书与 1.0.17 一致（SHA-256 `d3d4d96f6a1a67037e7f50f6af3a1e883ce6d6cd606d91340b41e261117118f0`）。Flutter kernel 与本次 debug 编译输出、交付 APK 与构建 APK 的哈希均一致。
- 两端成功构建合计 59.22 秒。新包 SHA-256 追加到 `dist/SHA256SUMS.txt`，旧包与校验值保留。未验证真机覆盖安装、升级运行或界面功能体验。

## 本次 1.0.17+18 桌面交互与移动表单（此前版本）

- 统一按钮、图标按钮、导航、分段选择、筛选标签及可点击内容的手形指针、悬停／按下／焦点反馈。总览状态图悬停时突出对应扇区和数量，并限制点击至环形区域。
- 新增共用状态选择、整数加减、可删除标签和自适应表单面板。标签未按回车的输入也同步至原有草稿或保存值；动漫进度加减受已知总集数约束，直接输入仍保留业务校验。
- 重组动漫／漫画表单，次要资料默认折叠；标题、评分、集数和日期提供字段内错误提示。手机漫画编辑、备注和观看历史使用底部面板，桌面使用弹窗，固定操作区并避让键盘，支持 Ctrl+Enter 保存。手机日期优先日历并保留手动输入，备注／历史增加今天、昨天快捷选项。
- 手机封面列表采用单列，避免小卡片挤压操作；宽屏仍保留紧凑网格、每页 15 条及已有分页。AI 设置操作区随页面避让键盘，表单可拖动收起键盘。编辑漫画保留原 Bangumi ID，沿用业务逻辑与 schema v3。
- 修改的 17 个 Dart 文件完成格式化，`dart analyze lib/features` 输出 `No issues found!`。依赖与插件仅作离线刷新，没有新增包。没有运行自动化测试、启动应用、操作界面、生成截图／预览或进行真实接口联调；布局与设备操作仍未进行运行验收。
- Windows release 使用已有 ATL 和独立 CMake 缓存，配置与构建合计 35.90 秒，输出 `build/package/1.0.17/windows`。补入已有官方 VC 运行库后生成 14.67 MiB 的 ZIP，24 个文件逐项核对 SHA-256。完整更新固定使用目录 `build/windows/x64/runner/Release`，24 个发布文件逐项哈希一致，exe 的文件／产品版本均为 1.0.17+18；更新时没有运行中的项目进程，无需关闭应用。
- Android debug 离线构建耗时 21.84 秒，213 个任务中 32 个执行、181 个复用。APK 约 162.81 MiB；aapt 核验包名 `app.animelog.offline`、1.0.17 / versionCode 18 和三种 ABI；apksigner 验证有效，新旧证书 SHA-256 均为 `d3d4d96f6a1a67037e7f50f6af3a1e883ce6d6cd606d91340b41e261117118f0`。核对每种 ABI 的 Flutter／SQLite 库、APK Flutter kernel 与本次编译输出，以及交付 APK 与构建 APK 的哈希。
- 两端成功构建合计 57.74 秒，新包校验值追加到 `dist/SHA256SUMS.txt`，旧版包与校验值保留。没有读写或清空用户数据库、Key、草稿；应用身份、目录、备份格式和 Android 签名保持兼容，未验证真机覆盖安装。

## 本次 1.0.16+17 时间轴调整与打包（此前版本）

- 只读参考本机 AnimeTrack 的 TimelineEnhancedList、TimelineTable、TimelineAnimeSummary 与用户截图，将时间轴改成连续竖线、日期节点、具体时刻和封面进度卡片，列表改成独立的时间／番剧／集数／进度表格，不再复用缩小卡片。
- 历史记录与最近观看作品各自每页 10 条；最近作品不再截断为前 10，后续可分页查看。日期和关键词可组合筛选，条件切换回到第一页，数据变化时夹紧有效页码；时间线跨页分组显示本页与分组总集数，按周从周一开始。
- 热力图根据容器宽度计算格子大小并填满宽屏；窄屏保持最小格子和横向滚动。修正月份重复／截断、星期对齐与 365 天范围外格子，增加日期／集数提示。观看时刻转本地时间显示，未知时刻显示「时间未记录」，不补造时刻；日期分组仍采用保存的观看日。
- 修改文件完成 Dart 格式化与针对性静态分析，输出 No issues found；没有运行自动化测试、启动新应用、操作界面、生成截图／预览或进行真实接口联调。
- Windows release 构建成功，输出到 `build/package/1.0.16/windows`，补入已有官方 x64 VC 运行库。ZIP 约 14.63 MiB，共 24 个文件，逐项与构建输出核对 SHA-256；向旧版发送正常关闭请求并确认退出后，完整更新固定使用目录 `build/windows/x64/runner/Release`，24 个发布文件逐项哈希一致，exe 版本为 1.0.16+17。旧版包保留。

- Android debug 离线构建成功，213 个任务中 32 个执行、181 个复用，交付 `dist/AnimeLog-1.0.16-android.apk`，约 162.78 MiB。aapt 核验 `app.animelog.offline`、MainActivity、1.0.16 / versionCode 17 与三种 ABI；apksigner 验证签名有效，证书 SHA-256 与旧版记录一致（d3d4d96f6a1a67037e7f50f6af3a1e883ce6d6cd606d91340b41e261117118f0）。交付 APK 哈希与构建 APK 一致，Flutter kernel 与本次 debug 编译输出一致，三种 ABI 的 Flutter／SQLite 原生库均保留。
- 新两端包 SHA-256 已追加到 `dist/SHA256SUMS.txt`，此前包及校验值保留；应用身份、schema v3、数据目录、Key、草稿目录和签名沿用，没有读写或清空用户数据，没有验证真机覆盖安装或运行功能。

## 本次 1.0.15+16 打包（此前版本）

- 本轮源码：新增独立「时间轴」导航页；总览保留轻量观看趋势，观看热力图迁移到时间轴；新增观看统计卡、周／月／年趋势折线、过去 12 个月热力图、按天／周／月分组、搜索排序、时间线／列表切换和最近观看作品前 10。
- Windows release：独立构建输出到 `build/package/1.0.15/windows`，补入已有官方 x64 VC 运行库并生成 `dist/AnimeLog-1.0.15-windows-x64.zip`，约 14.59 MiB；固定使用目录 `build/windows/x64/runner/Release` 已覆盖当前 24 个发布文件，固定目录 exe 版本为 1.0.15+16。
- Android debug：沿用离线 Gradle 流程构建成功，213 个任务中 25 个执行、188 个增量复用，versionName 为 1.0.15、versionCode 为 16，交付 `dist/AnimeLog-1.0.15-android.apk`，约 162.77 MiB；应用身份、旧签名、三种 ABI、数据库 schema、Key 和草稿目录保持兼容。
- 本轮完成源码静态分析、两端构建、Windows 固定目录覆盖和包文件核对；未启动新版本应用、操作界面、生成截图／预览、运行自动化测试、进行真实接口联调或验证真机覆盖安装。旧版本包保留。

## 本次 1.0.14+15 打包

- 本轮源码：总览删除评分、资料完整度、最近观看和首播年份板块；观看状态改为可点击饼图，常用标签改为类型排行；观看趋势增加过去一年观看热力图，继续观看移动到观看趋势之后。
- Windows release：输出到 `build/package/1.0.14/windows`，补入已有官方 x64 VC 运行库并生成 `dist/AnimeLog-1.0.14-windows-x64.zip`；固定使用目录 `build/windows/x64/runner/Release` 已覆盖当前 24 个发布文件，逐项 SHA-256 与独立构建输出一致，exe 版本为 1.0.14+15。
- Android debug：沿用离线 Gradle 流程，213 个任务构建成功，versionName 为 1.0.14、versionCode 为 15，应用身份、旧签名、三种 ABI、数据库 schema、Key 和草稿目录保持兼容；交付 `dist/AnimeLog-1.0.14-android.apk`。
- 本轮完成源码静态分析、两端构建、关闭运行中的旧版 AnimeLog、固定目录覆盖和包文件核对；未启动新版本应用、操作界面、生成截图／预览、运行自动化测试、进行真实接口联调或验证真机覆盖安装。旧版本包保留。

## 本次 1.0.13+14 打包（此前版本）

- 本轮源码：移除动漫／漫画库顶部重复分页，底部分页靠右；宽窄屏库页隐藏可见滚动条但保留必要的滚轮／触摸滚动；Android 沿用紧凑卡片和底部分页，宽屏右侧统计栏不显示在窄屏布局中。
- Windows release：输出到 `build/package/1.0.13/windows`，补入已有官方 x64 VC 运行库并生成 `dist/AnimeLog-1.0.13-windows-x64.zip`；固定使用目录 `build/windows/x64/runner/Release` 已覆盖当前 24 个发布文件，逐项 SHA-256 与独立构建输出一致，exe 版本为 1.0.13+14。
- Android debug：沿用离线 Gradle 流程，213 个任务构建成功，versionName 为 1.0.13、versionCode 为 14，应用身份、旧签名、三种 ABI、数据库 schema、Key 和草稿目录保持兼容；交付 `dist/AnimeLog-1.0.13-android.apk`。
- 本轮完成源码静态分析、两端构建、固定目录覆盖和包文件核对；未启动应用、操作界面、生成截图／预览、运行自动化测试、进行真实接口联调或验证真机覆盖安装。旧版本包保留。

## 本次 1.0.12+13 打包（此前版本）

- Windows release：输出到 `build/package/1.0.12/windows`，补入已有官方 x64 VC 运行库并生成 `dist/AnimeLog-1.0.12-windows-x64.zip`；固定使用目录 `build/windows/x64/runner/Release` 已覆盖当前 24 个发布文件，逐项 SHA-256 与独立构建输出一致，exe 版本为 1.0.12+13。
- Android debug：沿用离线 Gradle 流程，213 个任务构建成功，versionName 为 1.0.12、versionCode 为 13，应用身份、旧签名、三种 ABI、数据库 schema、Key 和草稿目录保持兼容；交付 `dist/AnimeLog-1.0.12-android.apk`。
- 本轮完成源码静态分析、两端构建和包文件核对；未启动应用、操作界面、生成截图／预览、运行自动化测试、进行真实接口联调或验证真机覆盖安装。旧版本包保留。

## 本次 1.0.11+12 打包（此前版本）

- Windows release：输出到 `build/package/1.0.11/windows`，补入已有官方 x64 VC 运行库并生成 `dist/AnimeLog-1.0.11-windows-x64.zip`；应用退出后已将当前 24 个发布文件覆盖到固定使用目录 `build/windows/x64/runner/Release`，逐项 SHA-256 与独立构建输出一致，exe 版本为 1.0.11+12。
- Android debug：沿用离线 Gradle 流程，213 个任务构建成功，versionName 为 1.0.11、versionCode 为 12，应用身份、旧签名、三种 ABI、数据库 schema、Key 和草稿目录保持兼容；交付 `dist/AnimeLog-1.0.11-android.apk`。
- 本轮完成源码静态分析、两端构建和包文件核对；未启动应用、操作界面、生成截图／预览、运行自动化测试、进行真实接口联调或验证真机覆盖安装。旧版本包保留。

## 本次 1.0.10+11 打包（此前版本）

- Windows release：输出到 `build/package/1.0.10/windows`，补入已有官方 x64 VC 运行库并生成 `dist/AnimeLog-1.0.10-windows-x64.zip`；应用退出后已将当前 24 个发布文件覆盖到固定使用目录 `build/windows/x64/runner/Release`，逐项 SHA-256 与独立构建输出一致，exe 版本为 1.0.10+11。
- Android debug：沿用离线 Gradle 流程，213 个任务构建成功，versionName 为 1.0.10、versionCode 为 11，应用身份、旧签名、三种 ABI、数据库 schema、Key 和草稿目录保持兼容；交付 `dist/AnimeLog-1.0.10-android.apk`。
- 本轮完成源码静态分析、两端构建和包文件核对；未启动应用、操作界面、生成截图／预览、运行自动化测试、进行真实接口联调或验证真机覆盖安装。旧版本包保留。

## 本次 1.0.9+10 打包（此前版本）

- Windows release：沿用上一轮独立目录流程，输出到 `build/package/1.0.9/windows` 并生成 Windows ZIP；应用退出后已将当前 24 个发布文件覆盖到固定使用目录 `build/windows/x64/runner/Release`，逐项 SHA-256 与独立构建输出一致，exe 版本为 1.0.9+10。Windows ZIP 和 Android APK 文件及 SHA-256 已写入 dist。
- Android debug：沿用离线 Gradle 流程，versionName 为 1.0.9、versionCode 为 10，应用身份、旧签名、三种 ABI、数据库 schema、Key 和草稿目录保持兼容。
- 本轮只进行源码静态分析、构建和包文件核对；没有启动应用、操作界面、生成截图／预览、运行自动化测试、进行真实接口联调或验证真机覆盖安装。1.0.8 及更早版本包保留。

## 本次 1.0.8+9 打包（此前版本）

- Windows release：在独立 `build/windows-package/x64` 目录完成配置和 Release 构建，安装输出到 `build/package/1.0.8/windows`，随后补入已有官方 x64 VC 运行库并生成 `dist/AnimeLog-1.0.8-windows-x64.zip`。ZIP 有 24 个文件，exe 产品／文件版本均为 1.0.8+9；新完整输出已更新到固定使用目录 `build/windows/x64/runner/Release`。构建时没有运行中的 AnimeLog 进程，也没有关闭用户应用。
- Android debug：执行 `scripts/prepare_android.ps1` 后，以既有 JBR、临时 socket 配置和仓库 init script 离线运行 `assembleDebug` 成功；沿用 `app.animelog.offline`、旧签名及三种 ABI，versionName 为 1.0.8、versionCode 为 9。交付 `dist/AnimeLog-1.0.8-android.apk`，校验值已追加到 `dist/SHA256SUMS.txt`。
- 本次只进行源码静态分析、构建和包文件核对；没有启动应用、操作界面、生成截图／预览、运行自动化测试、进行真实接口联调或验证真机覆盖安装。旧版 1.0.5／1.0.6／1.0.7 包保留。

## 本次 1.0.7+8 打包与后续默认约定（此前版本）

- 用户明确要求打包，并授权在耗时较短、流程简单时以后默认打包。版本从 1.0.6+7 提升为 1.0.7+8，包含第五轮文字导航、分页、直接管理历史、进度减一和主题色设置。已更新 AGENTS.md：每轮修改收尾时，现有缓存可用则默认两端打包；明显费时的依赖下载、清理重建或环境修复等用户明确要求再做。
- Windows 初次常规构建约 30 秒，在链接阶段因用户正在运行 build/windows/x64/runner/Release/animelog.exe 而报 LNK1104。没有关闭该进程。改用独立 build/windows-package/x64 构建目录及 build/package/1.0.7/windows 输出目录，CMake 配置、Release 构建和安装合计 18.61 秒成功。exe 的产品／文件版本均为 1.0.7+8，AOT 程序与本次编译结果哈希一致。
- Windows ZIP 为 dist/AnimeLog-1.0.7-windows-x64.zip，14.54 MiB，压缩约 0.44 秒；24 个文件逐个与新输出目录核对 SHA-256，数量与内容一致。包含 Flutter、SQLite、安全存储插件、程序资源及沿用的官方 x64 VC 运行库。新包使用当前 Release 的 NativeAssetsManifest.json，相对引用 sqlite3.dll；没有带入旧构建目录遗留的 native_assets.json。
- 用户随后正常退出旧版，已将完整新包更新至固定使用目录 build/windows/x64/runner/Release。exe 产品／文件版本均核对为 1.0.7+8，24 个新版文件逐项与新包核对 SHA-256，一致。额外清理该目录旧 native_assets.json 的操作被自动审批拦截（仅返回 blocked by policy），该旧生成文件保留；本次 Release 程序使用的新版 NativeAssetsManifest.json 已正常更新。没有启动应用，没有访问或修改本机数据库、Key 或草稿。
- Android 先执行 prepare_android.ps1，离线刷新插件注册和 1.0.7 / versionCode 8；沿用 JBR 和 socket 临时目录配置，Gradle assembleDebug --offline 成功，24.71 秒，213 个任务。aapt 核对 app.animelog.offline、MainActivity 及 arm64-v8a／armeabi-v7a／x86_64 三种 ABI。apksigner 核对新旧签名有效且证书一致，javap 核对本次插件注册包含 FilePickerPlugin 和 FlutterSecureStoragePlugin。
- Android 交付 dist/AnimeLog-1.0.7-android.apk，162.71 MiB，仍是 debug 测试包，复制后哈希与本次构建 APK 一致。两份新包校验值已追加到 dist/SHA256SUMS.txt，1.0.5／1.0.6 旧包保留。两端成功构建合计约 43 秒；本次额外花时间排查并绕开正在运行的 exe。
- 没有启动应用、操作界面、生成预览、运行自动化测试或进行真实接口联调；没有执行数据库升级或真机覆盖安装。构建／包校验不等于功能体验验收，也不使用此前测试结果作为本次证据。

当前机器可复用以下独立 Windows 构建流程（先刷新依赖／插件；不清理已有缓存）：

~~~powershell
./scripts/prepare_android.ps1
./scripts/prepare_windows_links.ps1
$env:CL = '/I"D:\Projects\AnimeLog\build\windows-atl\Contents\VC\Tools\MSVC\14.44.35207\atlmfc\include"'
$env:LINK = '/LIBPATH:"D:\Projects\AnimeLog\build\windows-atl\Contents\VC\Tools\MSVC\14.44.35207\atlmfc\lib\x64"'
# 下一轮按 pubspec 的版本更新输出目录。此命令只刷新 Flutter 配置，不构建原目录的 exe。
& 'D:\dev\flutter\bin\flutter.bat' build windows --release --no-pub --config-only
$taskCmake = 'C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe'
& $taskCmake -S windows -B build/windows-package/x64 -G 'Visual Studio 17 2022' -A x64 -DFLUTTER_TARGET_PLATFORM=windows-x64 -DCMAKE_INSTALL_PREFIX=D:/Projects/AnimeLog/build/package/1.0.7/windows
& $taskCmake --build build/windows-package/x64 --config Release --target INSTALL -- /verbosity:minimal
~~~

随后补入已有官方 VC 运行库并压缩、核对新输出目录。Android 使用下文既有 JBR／socket 配置，命令增加 --offline 以复用缓存；两端构建顺序执行。缓存或工具链缺失时不为默认打包自动展开长时间环境修复。

## 最新源码调整：导航顺序与紧凑分页封面

- 2026-10-11 按用户反馈将桌面侧栏和手机底部导航统一为「总览、动漫库、漫画库、数据管理、设置」，并将原「本机」页面标题改为「设置」；同时不改变本地数据、备份、Key 或草稿目录。
- 动漫库和漫画库封面模式改用横向紧凑卡片，每页 15 条、宽屏按 5 列三行排列；移除库页面卡片／列表中的评分展示，保留详情和编辑页的评分数据；同时增大封面并补充手形指针、悬停、点击缩放、涟漪和箭头反馈，不再弹出悬停文字提示。
- 宽屏库页增加右侧库统计和标签统计；标签点击后作为筛选条件与搜索、状态筛选叠加，再次点击当前标签取消，窄屏不显示侧栏。
- 标签统计限制为前 20；动漫库增加前 10 声优统计，点击声优后作为筛选条件，并同时匹配声优别名。
- 本轮完成源码修改、文档更新、格式化、针对修改文件的静态分析、两端构建和发布包核对；未启动应用、操作界面、运行自动化测试、进行真实接口联调或验证真机覆盖安装。

## 此前源码调整：简洁界面与记录管理

- 2026-10-11 完成纯文字导航、移除装饰图标、详情分组与日期留白，以及动漫／漫画／数据管理每页 24 条的分页。数据管理改成「番剧记录／观看历史」，支持直接编辑番剧、补记、纠正历史和确认删除。
- 动漫库与详情新增事务式进度 −1，保留历史和备注，从看完返回在看；+1 撤销保持原规则。侧栏底部改成主题色与浅色／深色选择，主题色写入现有设置表，不改 schema 或备份格式。
- 开发阶段相关源码和测试文件完成格式化，针对 features、main.dart、Repository 接口／实现、外观存储及修改的测试文件运行 dart analyze，最终无问题。新增／调整的回归用例未运行，开发阶段没有启动应用、生成截图／预览、进行真实接口联调或打包。后续用户授权后已纳入 1.0.7 两端包，见上节。详细界面规则见 [界面说明第五轮](UI.md)。

## 本次 1.0.6+7 打包

- 用户明确授权后将应用版本由 1.0.5+6 提升至 1.0.6+7，包含本次现代化视觉和交互两轮改动，以及当前源码已有的漫画／数据管理功能。应用身份、数据库目录、Key namespace、草稿路径和 Android 签名保持兼容；没有运行或清空用户数据。
- Windows release：使用既有 ATL 缓存与插件目录连接，执行 `flutter build windows --release --no-pub` 成功。animelog.exe 的文件／产品版本均为 1.0.6+7。生成 `dist/AnimeLog-1.0.6-windows-x64.zip`，14.56 MiB；包含所需 Flutter／SQLite／安全存储 DLL、data 和 VC 运行库。ZIP 内 25 个文件逐个与本次构建目录核对 SHA-256，全部一致。
- Android debug：执行 `scripts/prepare_android.ps1` 离线刷新插件注册和版本，随后使用既有 JBR／临时 socket 路径／仓库 init script 运行 `assembleDebug`，213 个任务，构建成功。aapt 核验 app.animelog.offline / 1.0.6 / versionCode 7 / MainActivity，包含 arm64-v8a、armeabi-v7a、x86_64 三种 ABI 的 Flutter 与 SQLite 库。
- apksigner 验证新旧 APK 签名有效且证书一致，SHA-256 为 d3d4d96f6a1a67037e7f50f6af3a1e883ce6d6cd606d91340b41e261117118f0。javap 核对本次编译的 GeneratedPluginRegistrant.class，保留 FilePickerPlugin 与 FlutterSecureStoragePlugin 的构造／注册。
- 交付 `dist/AnimeLog-1.0.6-android.apk`，162.70 MiB，仍为 debug 测试包。复制后与原构建 APK 核对 SHA-256，包内 kernel_blob.bin 与本次 Flutter debug 编译结果一致。新包校验值加入 `dist/SHA256SUMS.txt`，1.0.5 旧包和校验值保留。
- 当前源码已为 schema v3，沿用既有 v1→v2→v3 迁移，包括声优字段和漫画表；此次打包没有改 schema，也没有运行升级迁移。本次没有启动应用／浏览器、生成截图／预览、运行自动化测试、联网业务联调或验证真实设备安装／运行。构建和包校验不作为界面、插件和数据升级运行验收证据。

## 现代化界面开发阶段（后续已纳入 1.0.6）

- 后续继续优化：手机总览前置继续观看、折叠次要统计；动漫／漫画库增加保留当前搜索条件的封面／列表切换；详情前置感想、标签按需查看、备注／历史逐步展开、删除收进菜单；统一页面状态并增加只读重试。具体交互见 [界面说明第四轮](UI.md)。
- 本次继续优化实际检查：10 个修改／新增 Dart 文件完成格式化，针对这些文件的 `dart analyze` 最终输出 `No issues found!`。没有运行应用、界面验收、自动化测试、联网联调或重新构建安装包；显示模式只在当前应用会话中保留。
- 根据用户界面反馈，调整青绿色主题、字体与表面层级、导航、总览头部及独立统计卡片、继续观看、动漫与漫画封面卡片、搜索筛选、数据管理标签、详情头部和外观选择。录入、AI 设置、备份等页面共享新的基础控件样式。
- 新增共享 CollectionCard，宽度和字体缩放决定一至五列；内容保持自然高度，桌面悬停提供边框／阴影反馈。保留现有页面状态、业务操作、统计规则及存储兼容，没有修改应用身份、数据库、Key 或草稿目录。
- 实际检查：8 个修改／新增 Dart 文件完成格式化；使用现有 SDK 的 `dart analyze` 检查这些文件，最终输出 `No issues found!`。
- 开发阶段未启动应用、操作界面、生成截图或预览、运行自动化测试、联网业务接口联调、编译或打包。当时版本为 1.0.5+6；后续用户授权后已生成包含这些改动的 1.0.6+7 两端包，见上节。细节见 [界面说明](UI.md)。

## 此前 1.0.5+6 打包

- 用户明确授权打包后，将版本从 1.0.4+5 提升至 1.0.5+6。应用身份、数据库 schema、私有目录、Key namespace、草稿路径和 Android 签名保持兼容，没有启动或清空应用数据。
- Windows release：flutter build windows --release --no-pub 成功；animelog.exe 的产品版本为 1.0.5+6。生成 dist/AnimeLog-1.0.5-windows-x64.zip，包含 Flutter、SQLite、安全存储插件、data 目录及官方 x64 VC 运行库，核对 27 个文件／目录条目与必需文件，约 14.4 MiB。
- Windows 首次构建因缺少 atlstr.h 失败。Visual Studio 未安装 ATL，安装器在非提权进程下返回 5007，没有完成组件安装。随后从已安装 VS 目录的 catalog.json 选取与 MSVC 14.44 配套的官方 ATL Headers.base／X64.base 两个 VSIX，校验 SHA-256 后解压到 build/windows-atl。通过本次构建进程的 CL /I 与 LINK /LIBPATH 使用它们，第二次构建成功；没有修改 Flutter SDK、Pub 包源码或系统 VS 安装。
- ATL 头文件包 SHA-256：f8d375a254b6cfdbe0e7dc4fe7342d6212052068eb6394070dd932c815adb500；x64 库包：6dd0b7f8079c654db2b8fdaebc74900e8418b5204914a77bde93a5b01ac0998c。来源为已安装 VS 的微软官方 catalog，下载域名为 download.visualstudio.microsoft.com。
- Android debug：先执行 scripts/prepare_android.ps1 刷新插件和版本，再使用既有 JBR／临时 socket 路径／仓库 init script 运行 assembleDebug，213 个任务，构建成功。aapt 核验 app.animelog.offline / 1.0.5 / versionCode 6 / MainActivity，包含 arm64-v8a、armeabi-v7a、x86_64 三种 ABI。
- apksigner 验证新 APK 签名有效，证书 SHA-256 与旧包均为 d3d4d96f6a1a67037e7f50f6af3a1e883ce6d6cd606d91340b41e261117118f0。javap 检查本次 GeneratedPluginRegistrant.class，确认构造并注册 FilePickerPlugin 与 FlutterSecureStoragePlugin，先前修复已进入新包；不据此声称真机操作已通过。
- Android 交付文件 dist/AnimeLog-1.0.5-android.apk，约 162.5 MiB，为沿用旧签名的 debug 测试包；没有生成正式签名 release 包。两份交付文件的 SHA-256 存在 dist/SHA256SUMS.txt，说明见 dist/README.md。
- 本次只执行构建与包核验，没有启动应用／浏览器、生成截图、运行自动化测试或联网业务接口验收。总览、深浅色及插件修复仍需真实使用检查，历史测试结果不作为本次运行证据。

当前机器 ATL 缓存保留时，Windows 构建可按以下方式复现；缓存清理后需重新取得上述官方文件，或正式安装 VS 的 ATL 组件：

~~~powershell
$env:CL = '/I"D:\Projects\AnimeLog\build\windows-atl\Contents\VC\Tools\MSVC\14.44.35207\atlmfc\include"'
$env:LINK = '/LIBPATH:"D:\Projects\AnimeLog\build\windows-atl\Contents\VC\Tools\MSVC\14.44.35207\atlmfc\lib\x64"'
& 'D:\dev\flutter\bin\flutter.bat' build windows --release --no-pub
~~~

## 总览与外观开发阶段（后续已纳入 1.0.5）

- 参考本机 AnimeTrack 的 Dashboard、Hero、观看趋势和右侧统计源码，先完成 docs/UI_REDESIGN.md，再实现 AnimeLog 的总览。AnimeTrack 仅作只读参考，没有修改。
- 新增「总览」导航：记录／看完／重刷数量、累计进度、已知时长、继续观看、近 7 日／近 30 日／今年历史趋势、最近历史逐步展开、状态／评分／标签／首播年份分布及资料完整度。所有查询只读，使用 SQLite 动漫和历史监听，复用既有详情与筛选。
- 统计明确采用独立 UUID 记录，不按标题合并；进度与历史不重复相加，未知时长不默认 24 分钟，缺失日期不补造历史，评分 0 有效。新增 6 项统计回归用例，覆盖这些口径、日期边界、跨年和闰日；本轮未运行。
- 只提供「浅色」「深色」，写入现有 app_settings.appearance_mode，重开加载，JSON 恢复保留本机选择。新增 2 项外观存储／失败重试回归用例，本轮未运行。schema 仍为 v2，应用身份、数据、Key 和草稿路径不变。
- 动漫库支持四种排序和清除筛选；三个主页面保持切换状态。深色覆盖侧栏、页面、卡片、输入与弹窗。设置分组、Key 显隐、固定保存／测试操作、备份预览自动滚动、共享日历输入与中文本地化已接入。
- 执行 flutter pub get --offline，仅新增 SDK flutter_localizations 及其 intl 0.20.3 依赖；核对刷新后的 Android 注册表仍包含安全存储和文件选择插件。
- 开发阶段仅进行格式化与静态分析，没有运行自动化测试、启动应用或浏览器、生成截图或实际接口联调；当时未构建包。后续用户授权的 1.0.5 打包已包含这些界面改造和 Android 插件修复，详见上节。
- 本次实际结果：19 个相关 Dart 文件完成格式化；flutter analyze --no-pub 最终输出 No issues found。新增的 8 项用例只通过静态分析，没有执行，不计入此前 105 项已运行结果。

## 此前 Android 插件注册修正（已纳入 1.0.5）

- 用户在 Android 16 / iQOO Z11 打开 1.0.4 的 AI 设置页后，报告“系统安全存储不可用”。检查发现 GeneratedPluginRegistrant.java 及旧包编译目录中的注册类字节码仅注册 integration_test / jni / jni_flutter，遗漏 flutter_secure_storage 和 android_file_picker；Gradle 编译了插件依赖，但并未将它们接入 FlutterEngine。
- 修正直接 Gradle 打包的准备流程：新增 scripts/prepare_android.ps1，通过 flutter pub get --offline 重新生成原生注册表、核对安全存储 / 文件选择插件并同步 debug 版本。已执行依赖元数据刷新，未更改依赖版本，未手工编辑 SDK、Pub 包源码或生成的注册类。
- Android preBuild 增加注册表检查；缺少任一必需插件就停止打包并提示刷新命令，不再生成会在运行时缺少插件的包。
- 安全存储适配器单独识别 MissingPluginException，提示安装修复版，避免误导为反复重试；设置页在 Key 读取失败时仍显示数据库里已有的地址和模型。
- 应用身份、数据库、Key namespace、加密算法和草稿目录不变；没有清空用户数据，也没有降级为明文保存 Key。
- 当时按用户选择仅修正代码和打包流程，没有启动应用、运行测试或重新打包。后续生成的 1.0.5+6 APK 已包含修复，设备操作仍需用户覆盖安装后体验。
- 本次仅核对重新生成的注册表内容，并完成 3 个修改 Dart 文件的静态分析及 PowerShell 脚本语法解析，均无问题；新增 Gradle 检查任务未执行，不将其报告为已编译或运行通过。

## 本轮界面与交互

- 统一浅色背景、青绿色强调色、圆角输入和卡片；重做桌面侧栏、手机导航、动漫库头部、搜索 / 清空搜索、带数量的状态筛选及本机设置入口。
- 动漫库改成内容自适应的一至三列封面卡片，展示状态、评分（包括 0）、标签和观看进度。未知总集数保留 `?`；无封面使用渐变占位。切换本机页后保留搜索文字，缩窄窗口或放大文字不使用固定高度网格。
- 详情页新增封面与进度区域、直接 +1 和即时撤销，总体备注提前，作品资料 / 日期可展开。个人表单分为作品身份、观看记录和评价与感想，其他资料折叠；AI 录入区分查找和确认步骤，并标识所选候选。
- Android / Windows 使用同一组页面、控制器、业务用例与数据库规则，没有按平台删减功能。两端分别保存数据，通过 JSON 迁移；原生插件和输入交互仍需设备验证。
- 新增 2 项响应布局 / 交互测试，明确设置 1280×800、390×844、390×600、844×390 的实际 Flutter 布局。旧窄屏测试此前只改 physicalSize，在实时测试绑定下仍可能使用默认布局，本轮补上 setSurfaceSize 并重新通过窄屏录入、旋转草稿恢复和长分集备注检查。
- 12 个测试文件合计 105 项已分文件执行通过，核心用例另含 41 条行为检查；静态分析无问题。完整脚本曾在备注测试缺少滚动时停止，修正后该文件两项通过；另一轮在 AI 页面测试进程出现 did not complete，单独重跑通过。没有把中断运行当成成功，完整脚本的一次不中断运行仍受本机测试进程偶发退出影响。
- 已用真实 Flutter 页面渲染并查看桌面动漫库、手机动漫库、桌面详情和桌面表单预览。截图使用专用虚构记录和本机字体，没有读取正式数据库或联网；不是 Android 真机截图。设计和复现命令见 [界面说明](UI.md)。

## 本轮界面检查

| 检查 | 实际结果 |
| --- | --- |
| flutter analyze --no-pub | 无问题 |
| 分文件测试 | 12 个文件共 105 项通过，包含新增 2 项响应布局与交互测试；中断后单独重跑的范围见上文 |
| Windows 原生离线流程 | 通过：私有测试目录、中文录入 / 评分零 / 备注 / 编辑 / 关闭重开 |
| Windows 原生记录工具 | 通过：分集备注 CRUD、清理历史取消 / 确认、仅补缺失资料 |
| Windows 原生 AI 流程 | 通过：独立测试安全存储、本机 HTTP 候选 / 详情、资料确认、刷次确认与只新建 |
| Windows 原生备份流程 | 通过：预览、确认、重复追加去重、导出和完整恢复；文件选择器仍为 fixture |
| Windows release | 构建通过；文件 / 产品版本 1.0.4+5，运行需保留相邻 DLL 和 data 目录 |
| Android debug | Gradle assembleDebug 通过（212 个任务）；aapt 核验 app.animelog.offline / 1.0.4 / versionCode 5 / MainActivity |
| Android 真机 | 尚未进行；布局测试和构建不能替代输入法、返回键、安全存储、选择器和覆盖升级的设备验收 |

Windows 原生离线和备份测试也曾在 did not complete / 临时监听目录清理错误时中断，单独重跑通过。AI 和备份测试在新布局下，滚动后需要等待下一帧才能点击确认；现已明确等待布局完成，并在 AI 流程断言按钮可命中后点击，不能把未命中的点击当成保存成功。

## 此前记录工具交付

- 详情页增加分集备注：新增、修改集数 / 内容 / 日历日期、确认删除，同集多条备注有独立 UUID。编辑保留创建时刻，不触碰总体备注、个人进度或观看历史。接口核对所属记录，并禁止用分集接口操作总体备注或其他记录的备注；写入备注及父记录更新时间在一个事务内。
- 编辑页降低进度时出现“同时删除高于新进度的观看历史”，默认关闭。保存前预览删除数量，取消返回表单；确认后在同一事务中保存表单 / 总体备注并删除高于目标进度的历史。父记录和具体历史集合再次核对，数量相同但日期 / 集数 / 身份变化也拒绝旧预览；分集备注不删除。
- 历史来源的开始日期在批量清理后重新计算，手动或来源未知的日期保留。用户在同一表单明确清空开始日期时仍保持空值，不从剩余历史补回。修正普通编辑将来源未知日期重新标为 manual 的问题，保留 v2 允许的未知来源。
- 详情页增加“补全缺失资料”：有 Bangumi ID 时获取同一条目，否则展示真实候选并由用户选定。查询、预览和保存使用独立用例，没有 AI Client 或新建 Repository，不需要 AI 接口配置。只补空缺的原名、季度、形式、来源组合、总集数、时长、简介、封面、首播和完结情况；标题、已有值（含 false）、所有个人字段、备注和历史保留。
- 总集数与当前进度、已完成状态或保留历史冲突时跳过该字段并显示原因，不改状态或进度来适配来源。来源身份和明确季度 / 形式冲突拒绝补全；预览后记录发生变化会拒绝旧确认。确认提交仅更新作品资料，不新增动漫、历史或备注。
- 以上复用六张表和 v2 schema，不需要迁移或重新创建数据库；Android / Windows 的应用身份、数据库目录、Key 与未提交草稿路径保持原值。该阶段尚未进行界面整体重设计。

## 本轮记录工具检查

| 检查 | 实际结果 |
| --- | --- |
| flutter analyze --no-pub | 无问题 |
| 新增业务测试 | 19 项通过：分集备注持久化 / JSON 恢复 / 归属校验 / 回滚，默认历史保留 / 批量清理 / 过期确认 / 日期保护，以及资料补全冲突 / 私人字段保护 / 过期确认 / 回滚 / 取消 |
| 新增界面测试 | 2 项通过：390×600 / 1.8 倍文字下的长备注验证与保存，以及无来源记录的季度 / 形式冲突拒绝、候选预览与确认补全 |
| Windows record_tools_flow_test | 通过：真实后台 SQLite，分集备注新增 / 编辑 / 确认删除，批量历史清理的取消 / 确认，真实本机 HTTP 详情查询，补全预览返回不写库，确认后保留标题 / 已有资料 / 评分 0 / 进度 / 标签 / 备注 / 历史 |
| scripts/check_tests.ps1 完整回归 | 11 个文件顺序独立运行，合计 103 项全部通过：此前 82 项加本轮 19 项业务 / 2 项界面测试；核心检查另含 41 条行为检查 |
| Windows release | 通过；build/windows/x64/runner/Release/animelog.exe，文件 / 产品版本 1.0.3+4；运行需保留相邻 DLL 与 data 目录 |
| Android debug | Gradle assembleDebug 通过（212 个任务）；build/app/outputs/flutter-apk/app-debug.apk，aapt 核验 app.animelog.offline / 1.0.3 / versionCode 4 |
| Android 真机 | 当前仍未连接真机或模拟器，不将构建通过报告为设备运行、系统选择器或覆盖升级验收 |

Windows 原生记录工具测试使用专用数据库 / 草稿目录和本机 HttpServer，SourceProvider 与 HTTP 适配器真实，不读取正式库或 Key，不调用 AI。单次多文件测试即使使用 --concurrency=1 也出现过 did not complete；显式 -j 1 的全量运行曾有最后两个旧界面用例中断，而单独运行该文件两项均通过。新增 scripts/check_tests.ps1 按文件创建独立测试进程并在首个失败处停止，用于本机完整回归；集成测试与构建仍必须在该脚本结束后顺序运行。没有修改 SDK 或删除正式数据。

## 此前 AI 阶段交付

- 新增 OpenAI-compatible HTTP 适配器，使用配置的 base URL、模型与非流式 chat/completions。AI 单次 20 秒、资料单次 10 秒、识别链路 45 秒；后续请求使用剩余预算，错误不自动重试。取消关闭当前 Client 并触发 AbortableRequest，接收响应正文时仍能取消。JSON 正文限制 2 MiB，不跟随重定向，错误消息不暴露 Key 或原始服务响应。
- “本机 → AI 接口设置”支持保存地址 / 模型、替换或删除 Key，以及不保存配置的连接测试。http 1.6.0 / flutter_secure_storage 11.2.0 已实际解析并锁定依赖；Windows 安全存储为 4.2.2。地址和模型进入 app_settings，Key 及绑定 endpoint 只进入系统安全存储。换地址不复用旧 Key；SQLite 配置提交失败时，新 Key 也不能被旧 endpoint 读取。
- “添加动漫”支持单个名称识别、最多两种标题查询、按 Bangumi ID 去重、真实候选显示、唯一严格匹配推荐及最多一次候选 AI。AI 仅接收前 20 个候选，用户最多可见 40 个去重候选；未展示给 AI 的 ID、明确季度 / 形式冲突不能自动推荐，未知形式仍标明未知。
- 用户选择候选后按 ID 查询详情，核验作品类型和 ID，展示标题、原名、形式、季度、首播、话数和简介。Bangumi 声明的话数 eps 映射为总集数，0 / 未知保留 null；不使用可能包含特别章节的 total_episodes，不根据候选顺序推测形式。没有可靠资料的字段留空。
- 点击“确认资料，填写新记录”才进入现有编辑表单和本地刷次确认。查询、推荐和详情没有写 Repository；所有保存仍调用原创建用例，普通 / 重刷都 INSERT，新记录默认在看 / 进度 0 / 空评分与备注，不写自动历史，不更新旧记录。
- 输入改变会取消旧请求并更新 draftId，迟到的响应不能覆盖新输入。取消、失败和无配置均保留手动添加入口。原始输入及选定资料保存在私有草稿文件；选定资料恢复后可继续编辑，保存重试保持 draftId。
- 录入预览、表单、列表和详情增加封面显示。封面按 URL 的 SHA-256 缓存在私有目录，同 URL 并发下载去重，下载限制 10 秒 / 5 MiB；缓存写入失败仍显示下载内容，失败回退远程图片或占位图，封面操作不参加新建事务。
- 刷次确认现在列出相关记录，并只在实际数据库保存期间显示保存动画；等待确认时锁定重复提交，但不提示已经开始保存。Android main manifest 已加入 INTERNET、明确的本地 HTTP 支持，并关闭自动备份，避免系统迁移加密 Key；JSON 备份能力保留。

## 此前 AI 阶段检查

| 检查 | 实际结果 |
| --- | --- |
| flutter analyze --no-pub | 无问题 |
| flutter test --no-pub --concurrency=1 | 82 项通过：此前 52 项加本轮 30 项；核心用例另包含 41 条行为检查 |
| Windows ai_flow_test 原生流程 | 通过：系统安全存储写 / 读 / 删除、设置连接测试和保存、真实 HTTP → 候选 → 详情 → 编辑 → 刷次确认 → SQLite 新建；确认前不写库，旧记录保留评分 0 / 备注 / 完成进度，新记录无个人 AI 字段或历史 |
| scripts/check_bangumi.dart | 实际公开查询通过：返回 20 个候选，按 ID 253 获取“星际牛仔”，标题 / 原名 / TV / 26 集映射正确；一次人工重跑前曾出现 10 秒超时，应用适配器不自动重试 |
| Windows release | 通过；build/windows/x64/runner/Release/animelog.exe，运行需保留相邻 DLL 与 data 目录；未做完整 release 交互验收 |
| 用户 Windows release 实测反馈 | 用户确认手动录入、编辑、进度 +1 和实际配置的 AI 录入正常；记为用户实测反馈，尚未覆盖完整平台验收清单 |
| Android debug | Gradle assembleDebug 通过（212 个任务）；build/app/outputs/flutter-apk/app-debug.apk，aapt 核验 app.animelog.offline / 1.0.2 / versionCode 3、MainActivity 入口和 INTERNET 权限 |
| flutter devices | Windows 可用，未连接 Android 真机或模拟器，不能报告 Android 插件运行或覆盖升级已验收 |

原生 AI 流程使用本机 HttpServer fixture，走真实 package:http 和后台 SQLite，没有调用付费 AI 服务。安全存储只使用独立测试 namespace，不访问正式 Key。纯测试另覆盖 endpoint 规范化、未知或批量协议、个人字段隔离、最多两次 AI、前 20 个候选身份校验、源失败、认证 / 限流 / 断网、无效 JSON、大小限制、取消与响应正文中断、链路剩余预算、旧响应隔离、保存前草稿恢复、缓存离线读取 / 写入失败以及跨存储提交失败的 Key 隔离。窄屏界面使用 390 像素和 1.8 倍文字，验证无配置时返回恢复与手动确认新建。

本机并行启动多个 LiveTestWidgetsFlutterBinding 测试进程时出现 did not complete；顺序执行 82 项全部通过。Flutter unit test、Windows 原生集成测试与原生构建应顺序运行；同时构建 / 测试曾使 build/native_assets/windows/sqlite3.dll 被占用。没有通过删除数据库或修改 SDK 处理问题。用户已确认实际 AI 录入正常；更多作品形式和异常场景、Android 真机及其安全存储、完整 release 交互仍待验收。

接口实现核对了 [OpenAI Chat completions 参考](https://developers.openai.com/api/reference/resources/chat)、[Bangumi v0 schema](https://github.com/bangumi/api/blob/master/open-api/v0.yaml)、[http 请求取消](https://pub.dev/packages/http) 和 [安全存储平台说明](https://pub.dev/packages/flutter_secure_storage)。未硬编码默认模型或 API Key。

## 此前已完成的离线与备份阶段

离线闭环已经接入真实 Drift / SQLite：手动添加 → 动漫库 → 详情查看与编辑 → 数据库关闭重开及 Windows 进程退出后再次启动。没有用模拟记录填充页面。

- 数据库使用应用私有目录、NativeDatabase 后台 isolate、schemaVersion=2；六张表、普通索引、CHECK、唯一 UUID 和级联外键已建立。显式 v1→v2 迁移仅放宽开始日期来源约束，保留旧记录及关系，迁移数据保留与 schema 一致性测试通过。
- 新建继续调用原 core 创建接口，记录和 draftId 凭据在同一事务中插入。重复提交复用首次 UUID，同名和同来源的其他草稿分别新建，不修改原记录，不生成观看历史。
- 标题、原名、季度、形式、总集数、时长、来源、简介、封面地址、首播/完结资料，以及状态、进度、评分、备注、日期、标签和刷次可以手动编辑。可空字段可清空，评分 0 和进度 0 保留。
- 本地刷次提示复用 core 规则；来源不明的完整标题关联先确认身份，再建议刷次。用户可采用建议、保留表单次数或普通新建。
- 动漫库支持搜索、状态筛选、进度 +1。+1 在事务内读取最新进度，只新增一个有明确日历日期的事件；已知总集数到顶转为看完，继续 +1 禁用。提供短暂撤销，后续操作或回执失效会拒绝旧撤销。
- 详情支持补记一集、纠正集数/日期、删除单条历史。表单编辑和历史纠正默认保留进度或历史，不推算缺失观看日期。历史来源的开始日期会重新计算，手动日期受到保护，也可将当前历史日期固定为手动日期。
- 总体备注与结构化备注在同一事务中维护；删除动漫前展示关联历史/备注数量，只级联删除选定 UUID 的数据。
- 手机宽度使用底部导航，全屏表单和详情；宽窗口使用侧栏。表单可滚动，保存固定在键盘上方，支持 Ctrl+Enter；返回会保留添加草稿或确认放弃编辑。草稿单独存 UTF-8 私有文件，重新进入可继续或丢弃。
- Android applicationId / namespace 固定为 app.animelog.offline；Windows 产品与公司名称固定为 AnimeLog。后续升级保持这些身份和私有目录不变。
- Drift v1/v2 schema 均保存在 drift_schemas，迁移验证代码由它们生成。后续提高版本仍必须增加显式迁移与数据保留测试，不能启动时删表重建。

本轮补齐 JSON 闭环，入口为“本机 → 备份与迁移”：

- 在一致读事务内获取全库快照，编码和文件写入在事务外；不受当前搜索/状态筛选影响。UTF-8 中文、评分/进度 0、空值、观看日、总体及分集备注均保留。
- file_picker 13.1.0 使用实际 v13 API：单文件选择后按字节流读取，保存传入 UTF-8 字节；Android content URI 不作为文件路径解析。取消与写入失败不报告成功，单文件限制 50 MiB。
- 完整恢复先校验全部内容、创建私有快照，再展示替换数量并确认。快照失败停止；提交时本机内容变化拒绝旧预览；写入在单事务中完成。成功后清理旧提交凭据、旧草稿和撤销回执，保留本机设置。
- 追加导入只增加不存在的动漫 UUID 及其整组历史/备注，已有 UUID 全组跳过，不按标题合并、不更新个人进度、不重算刷次。恢复前快照可从应用内再次预览并恢复。
- v5 按真实 records/嵌套 notes 结构转换，以文件 SHA-256、表名和旧 ID 生成稳定 UUID v5，修复旧关系；旧整数 ID 不与本机 ID 合并。有时区时刻转 UTC，缺时区按 Asia/Shanghai，观看日固定。来源不明的开始日期及原来源空值保留。
- 修正派生刷次标签的数量、不支持的漫画等类别及未支持字段会显示在预览中，原 JSON 不修改。未来格式、非法字段、重复身份、坏关联和总体备注冲突会定位并拒绝整个文件。

## 此前离线与备份阶段的检查记录

| 检查 | 实际结果 |
| --- | --- |
| flutter doctor -v / flutter devices | 工具检查通过；Windows 可用，无已连接 Android 真机或模拟器 |
| dart run build_runner build | Drift 类型生成通过，生成文件随源码保留 |
| dart run drift_dev schema dump / schema generate | v1/v2 schema 已保留，迁移验证代码已生成 |
| flutter analyze --no-pub | 无问题 |
| flutter test --no-pub | 52 项通过：原 19 项（核心用例含 41 条检查）加 20 项备份校验、7 项 SQLite/迁移、6 项备份用例/文件测试 |
| Windows offline_flow_test 原生集成测试 | 通过；真实 path_provider 私有目录、后台 SQLite、中文备注、评分 0、新建、编辑和连接重开 |
| Windows process_persistence_test 分两次独立运行 | 写入/编辑进程退出后，第二个进程读取相同记录通过；测试只使用独立 fixture，读取后清理 |
| Windows backup_flow_test 原生页面测试 | 通过：预览前不写入、确认追加、重复追加预览、真实 UTF-8 文件导出、确认完整恢复及列表刷新；系统选择结果由 fixture 替代 |
| Windows debug / release 构建 | 通过；release 可执行文件位于 build/windows/x64/runner/Release/animelog.exe，运行需保留相邻 DLL 与 data 目录 |
| Android debug 构建 | Gradle assembleDebug 通过；build/app/outputs/flutter-apk/app-debug.apk，包名与入口校验通过，含三个 ABI 的真实 SQLite 原生库；没有 Android 真机验收结论 |

数据库测试覆盖并发同草稿提交、独立同名记录、备注写入失败回滚、历史写入失败回滚、并发 +1、到顶约束、即时/失效撤销、日期保护、字段清空、历史保留、删除数量变化及外键级联。文件测试覆盖中文草稿和稳定 draftId。界面测试使用真实 SQLite 与草稿文件、实时测试时钟，覆盖添加/详情/编辑/重开、+1 撤销、390 像素宽度、1.8 倍文字、旋转与草稿继续填写。Windows 原生集成测试是 debug 模式；release 构建通过不代表 release 交互验收或 Android 真机验收。

本轮另验证 JSON 内容/关系往返、内部 ID 变化、整组追加跳过、旧 ID 碰撞、同集多次观看、0 与 null、64 位整数、无时区旧时间、非法时区偏移、总体/分集备注、未知日期来源保护、导入触发器失败回滚、过期预览拒绝、私有快照失败及恢复、选择取消、导出写入失败和草稿清理。自动化测试替代了 OS 选择对话框的用户选择，数据库和读写文件均真实；两端系统选择器交互仍需人工验收。

## 环境问题与重现

本机未启用 Windows Developer Mode，Flutter 的插件符号链接创建会报错。已使用目录 Junction 完成构建，无需修改系统设置或 Flutter SDK。依赖清单改变后可执行：

~~~powershell
& 'D:\dev\flutter\bin\flutter.bat' pub get
# 若上述提示 symlink support，依赖仍已解析；准备目录连接后使用 --no-pub。
./scripts/prepare_windows_links.ps1
& 'D:\dev\flutter\bin\flutter.bat' build windows --release --no-pub
~~~

Android 首次 flutter build apk --debug 停在 JDK 的 Unable to establish loopback connection。本机 JBR 25 与另有的 JBR 21 均出现相同错误。检查堆栈后，对本次 Gradle 进程设置不存在的 Unix socket 临时目录，令 JDK 回退 TCP，已继续到插件/应用配置。Maven Central / Plugin Portal 的部分请求返回 404，使用 Google 托管的 Maven Central 镜像后已编译 Flutter Gradle 插件；没有修改 SDK 源码或全局 Gradle 配置。

本次使用的命令为：

~~~powershell
cd D:\Projects\AnimeLog\android
$env:JAVA_HOME = 'D:\AndroidStudio\jbr'
$env:JAVA_TOOL_OPTIONS = '-Djdk.net.unixdomain.tmpdir=D:/Projects/AnimeLog/build/nonexistent-socket-dir'
../scripts/prepare_android.ps1
./gradlew.bat assembleDebug --no-daemon --init-script ../scripts/android-repositories.init.gradle
~~~

应用配置随后要求 NDK 28.2.13676358。自动下载长期停留在 0 字节，先中止该构建，再直接下载官方 android-ndk-r28c-windows.zip，按官方 repository2-3.xml 核对 SHA-1（086bba43ff2f5eb0e387b15c8278bb4e0d89ba1d）后安装到指定 SDK 版本目录。没有重复安装 Flutter。

之后两个官方 Android 构建 JAR 的 Java TLS 握手失败，使用 curl 从原始 Google Maven 地址下载对应 POM/JAR，并验证 ZIP 完整性，放在 build/android-maven。init script 仅在该临时缓存存在时优先使用它。SDK Platform 35 / CMake 3.22.1 自动补齐后，assembleDebug 实际通过（152 个任务）。已检查 APK 包名 app.animelog.offline、MainActivity 入口及三个 ABI 的 SQLite 库；构建与 ZIP 完整性不证明设备安装/运行成功。默认工程仍使用 Flutter 生成的官方仓库配置，镜像 init script 仅在显式指定时生效。

此前加入 Android 文件选择插件后，Kotlin 增量缓存无法计算 C: Pub cache 到 D: 项目的相对路径。工程 gradle.properties 已设置 kotlin.incremental=false，重新 assembleDebug 通过（182 个任务）；未修改 Flutter SDK 或 Pub 包源码。直接使用 Gradle 时应将 local.properties 中 flutter.versionName / flutter.versionCode 与当前 pubspec 的 1.0.4 / 5 保持一致。

## 仍未完成与下一阶段

1. Android release 真机安装与返回键/输入法/后台/覆盖升级检查；Windows release 交互验收、无障碍和完整键盘巡检。Android release 构建已在 1.0.27 完成，当前沿用旧版签名证书，未生成新的商店发布签名身份。
2. JSON 与分集备注编辑已实现；Windows 系统保存/打开对话框人工验收、Android SAF/云文件 URI 真机往返、覆盖升级与异常存储环境仍需实际设备检查。
3. 用户已实测实际配置的 AI 录入正常，基础联通不再列为未验证项。名称 / 第二季 / 剧场版 / OVA 的完整样本和异常场景仍需覆盖；自动化原生流程使用 HTTP fixture，Bangumi 公开源已实际查询成功。
4. 分集备注、可选批量历史清理和独立资料补全的功能缺口已关闭。第二轮观看总览与基础统计、浅色／深色、设置／备份分组及日期选择已纳入 1.0.5 两端包，尚未运行验收；继续真实设备体验与键盘细节检查。图谱、漫画留在后续版本。
5. Windows 安全存储已实际验证；Android 安全存储、两端覆盖升级与以后新增 schema 的升级检查仍需完成，现有 v1→v2 升级已验证。窄屏、大字体测试通过不能替代 Android 设备运行验收。

## 重跑本轮检查

~~~powershell
cd D:\Projects\AnimeLog
& 'D:\dev\flutter\bin\flutter.bat' analyze --no-pub
./scripts/check_tests.ps1
& 'D:\dev\flutter\bin\flutter.bat' test integration_test/record_tools_flow_test.dart -d windows --no-pub
& 'D:\dev\flutter\bin\flutter.bat' test integration_test/ai_flow_test.dart -d windows --no-pub
& 'D:\dev\flutter\bin\dart.bat' run scripts/check_bangumi.dart
& 'D:\dev\flutter\bin\flutter.bat' test integration_test/offline_flow_test.dart -d windows --no-pub
& 'D:\dev\flutter\bin\flutter.bat' test integration_test/backup_flow_test.dart -d windows --no-pub
& 'D:\dev\flutter\bin\flutter.bat' test integration_test/process_persistence_test.dart -d windows --no-pub
& 'D:\dev\flutter\bin\flutter.bat' test integration_test/process_persistence_test.dart -d windows --no-pub --dart-define=VERIFY_REOPEN=true
~~~

跨进程测试的两次调用必须按顺序运行。第一次留下专用测试 fixture，第二次读取后清理；如果第一次被打断，应先检查专用 fixture 再重新测试，不删除正式数据库。
