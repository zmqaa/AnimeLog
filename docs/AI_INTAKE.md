# AnimeLog AI 录入规格

版本：单部作品、仅新建，2026-10-10。本规格取代旧版的批量观看意图解析。

当前状态：已接入 OpenAI-compatible 非流式 HTTP、接口设置与测试、系统安全存储 Key、Bangumi 候选与详情、确认后新建，以及取消 / 超时 / 草稿恢复和封面缓存。Windows 原生安全存储与本机 HTTP fixture 页面流程已验证；真实模型服务及 Android 真机检查未完成。仍严格遵循本文件的单部识别、只新建边界。详见 [实现状态](IMPLEMENTATION_STATUS.md)。

## 1. 输入边界

用户只输入一部动漫的名称，可以加季度、剧场版、OVA、ONA、特别篇或官方副标题。例如：

- 某动画
- 某动画 第二季
- 某动画 剧场版 某副标题
- 某动画 OVA

不支持一句话录入多部作品或多个季度。AI 不拆分列表，不推算已看集数、观看日期、状态、评分、备注或重刷次数。

刷次由本地程序读取已有记录给出建议，不属于 AI 工作。没有可靠关联记录时默认普通记录；同一作品的已有记录全部看完时，建议最高明确刷次加一。表单允许用户改次数或选择普通记录，也允许在没有一刷记录时手动添加二刷。

## 2. 单条 AI 协议

~~~json
{
  "record": {
    "animeTitle": "某动画 第二季",
    "originalTitle": null,
    "titleKind": "generic-season",
    "season": 2,
    "entryType": null
  }
}
~~~

无法识别或输入多部作品时返回：

~~~json
{"record": null}
~~~

| 字段 | 规则 |
| --- | --- |
| animeTitle | 单个作品搜索标题，非空、最多 200 字符 |
| originalTitle | 可空；不确定就留空 |
| titleKind | official / generic-season / null；官方副标题不机械追加季数 |
| season | 正整数或 null；只采用用户明确限定，或完整官方续作名表达的季度 |
| entryType | tv / movie / ova / ona / special / null；没有明确形式时留空 |

不接受 records 数组，即使里面只有一条也不能偷偷取第一项。解析器只保留上述字段，AI 返回的 progress、status、watchedAt、score、tags、rewatchTag、sourceId、summary 等额外字段不能进入创建用例。

提示词的职责是提供作品身份线索，不能代替真实资料查询。

## 3. 从输入到草稿

1. 去除首尾空白，空输入不请求网络。
2. AI 识别单个搜索标题、季度和形式；无法识别时保留用户原始输入并允许手动添加。
3. SourceProvider 用原始标题与识别标题查询真实候选，最多两种查询，按来源 ID 去重。
4. 唯一严格标题 / 原名匹配可推荐候选；否则最多让 AI 从前 20 个实际候选中选择一次。
5. 本地校验返回 ID 必须在展示给 AI 的候选中；明确季度与形式已知时不得冲突。未知形式不能被当作已经验证一致。
6. 最多展示五个去重候选，可靠推荐置于首位，其余保留来源搜索顺序；没有可靠推荐时展示来源顺序的前五个。由用户选择或保存未匹配标题，不静默选第一项。
7. 按选定的来源 ID 获取详情，展示封面、标题、形式、季度、首播日期和总集数，用户可以纠正。
8. 读取本机同作品记录，计算本地刷次建议，展示原因及相关记录；生成一个带 draftId 的新建草稿。用户确认或修改普通 / 重刷选择后保存。

候选只是推荐，任何路径都必须经过用户确认。NEW GAME! 和 NEW GAME!! 等标题标点可能具有身份含义，严格匹配时保留。

## 4. 只有两种保存结果

| 选择 | 结果 |
| --- | --- |
| 普通记录 | INSERT 新记录，rewatchCount=null，没有重刷标签 |
| 第 N 刷，N>=2 | INSERT 新记录，rewatchCount=N，生成对应重刷标签 |

两者都是新建，使用同一创建用例，没有 AI 更新分支。已经存在同名 / 同来源的记录可以作为提示展示，但不能改变保存动作，也不能自动覆盖旧记录。

### 程序建议刷次的规则

- 双方有 sourceProvider + sourceId 时，组合完全相同才是同一作品；同名但来源 ID 不同不计入。季度、剧场版、OVA 不按系列总名混在一起。
- 旧记录缺少来源 ID 时，完整标题 / 原名精确匹配且季度、形式没有冲突，只作为待确认关联；用户确认同一作品后才参与计算，不靠模糊 contains 自动计入。
- 关联记录全部 status=completed 时，无明确刷次按一刷看待；下一刷等于最高 rewatchCount + 1。旧记录缺少结构字段时兼容二刷、3刷等完整标签。
- 记录按 UUID 去重，不把记录总条数当刷次；多个无刷次标签的重复记录不会自动变成三刷。
- 存在在看、想看或弃番记录时，展示已有记录并保留普通新建，用户可主动改为重刷。不偷偷把已有进度带进新记录。
- 用户明确改成普通或指定次数时覆盖程序建议。刷次在预览时固定，重复保存同一个 draftId 不重新递增；取消草稿不占用刷次。

这些规则只生成建议，不修改已有记录，也不把同一作品的刷次设成数据库唯一约束。

新草稿默认 status=watching、progress=0，评分、备注、开始 / 完成日期为空；默认值来自应用，不是 AI 推断。用户可以通过普通表单修改新记录的个人字段；新建不自动写观看历史。已有进度的记录可通过独立的历史操作补记已知日期。

点击确认后，把草稿的明确字段和 draftId 交给创建接口。记录 UUID 是新生成的；重复提交同一个 draftId 复用首次提交结果。用户主动再次添加同名作品使用新的 draftId，可正常新建另一条记录。

## 5. 资料与个人数据

简介、封面、总集数、时长、首播日期、是否完结来自 SourceProvider；季度及形式先作为匹配限定，最终资料由用户确认。

对来源不明的作品，可以仅保存标题。来源字段要么全部为空，要么保存 sourceProvider + sourceId。本地缓存图片不属于作品身份。

已有记录的资料补全已接入详情页的独立操作，只补缺失资料，使用 Bangumi 搜索或已确认的来源 ID，不调用 AI。预览后确认，已有资料和所有个人字段受到保护；总集数冲突时保留未知，过期预览拒绝提交。新记录不继承旧记录的评分、备注、个人标签或进度；本地刷次规则只读取作品身份、完成状态和明确刷次生成建议。

## 6. 状态与恢复

Controller 状态为 idle → recognizing → searching → choosing → ready → saving → saved；失败或取消返回可编辑状态，不清空用户输入。

草稿未保存时可以持久化到应用私有文件，不进入正式动漫库。重启后提供继续或丢弃。同一个草稿在点击重试保存时保持 draftId；改变作品或主动新开添加流程才生成新 ID。

设置、网络和来源错误分别显示可执行的选择：配置接口、重试、手动选作品、手动添加。UI 不显示 AI 自报的 confidence 作为可靠性评分。

## 7. 客户端边界

AI Client 发送 OpenAI-compatible 非流式 chat/completions，请求失败和无效 JSON 都是可恢复错误。API Key 存安全存储，不进入提示词、日志或 JSON 备份。

实际适配器使用用户配置的 base URL 路径，去除尾斜杠后追加 chat/completions，不猜测 /v1。Key 和对应的规范化 endpoint 一起存入安全存储；更换地址不复用旧 Key，跨存储提交失败时也不把新 Key 发送给旧 endpoint。测试连接不保存配置。HTTP 只允许明确填写的 localhost、回环或 IPv4 私有网段；其他地址使用 HTTPS。AI、来源 HTTP 请求均不跟随重定向，不自动重试。

来源搜索每种标题最多取 20 个结果，最多两种查询；最多合并 40 个去重的真实候选用于原有推荐判断，候选 AI 仅接收前 20 个。页面最多展示五个候选，推荐置于首位，其余按来源顺序补齐；不足五个时按实际数量展示，不补造候选。搜索后必须手动选择具体候选，再以来源 ID 获取详情并确认。Bangumi 的 eps 表示声明的话数；total_episodes 是包含其他章节的数据库计数，不直接作为个人记录总集数。没有可靠完结日期、时长或形式时保留空值。

AnimeLog 不调用 AnimeTrack 的 /api/anime/quick-record：旧接口会直接写入服务器数据库，行为与本规格不同。也不保留旧请求中的 forceRewatch、stream 或更新结果结构。

## 8. 服务预设（2026-10-11）

- DeepSeek：默认 `https://api.deepseek.com`，可选 `deepseek-flash`、`deepseek-v4-pro`。模型与请求参数依据 [官方 Chat Completions 文档](https://api-docs.deepseek.com/api/create-chat-completion/)。这两个模型在已知官方 endpoint 上使用 `thinking: {type: disabled}`，适配现有 20 秒非流式录入请求。
- Qwen：默认北京 `https://dashscope.aliyuncs.com/compatible-mode/v1`，可选 `qwen-plus`、`qwen-flash`、`qwen3.5-plus`。高级设置可选择新加坡 `dashscope-intl.aliyuncs.com` 或美国弗吉尼亚 `dashscope-us.aliyuncs.com` 的相同兼容路径；Key 和模型权限以所属地域为准。[官方兼容接口说明](https://help.aliyun.com/zh/model-studio/compatibility-of-openai-with-dashscope) 确认这些原有域名仍可使用，无需用户额外填写业务空间 ID。
- Qwen 列出的模型在已知官方 endpoint 上使用顶层 `enable_thinking: false`；模型和参数依据 [深度思考模型说明](https://help.aliyun.com/zh/model-studio/deep-thinking) 与 [HTTP Chat Completions 参数](https://help.aliyun.com/zh/model-studio/qwen-api-via-openai-chat-completions/)。自定义域名、路径、端口或未列出的模型不附加服务商扩展参数。
- 预设只是界面辅助，SQLite 仍只保存 base URL 和模型。已有配置读取时保留地址和模型；其他模型可选择「自定义模型」，其他服务可选择「自定义」。加载／切换预设不请求网络或模型列表，默认只填 Key 即可保存。
- Key 保持系统安全存储与 endpoint 隔离；切换服务或地域、修改 endpoint 会清空未保存的 Key。相同 endpoint 的已保存 Key 可留空保留，连接测试继续不保存配置。这里的官方文档核对不代表已执行真实服务联调。
