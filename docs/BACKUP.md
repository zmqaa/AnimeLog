# AnimeLog JSON 备份与旧数据迁移

版本：2026-10-10。Android 和 Windows 完全独立；JSON 用于用户主动搬移、备份与恢复，不实现同步。

当前状态：已接入 AnimeLog v1 导出/恢复/追加、恢复前本机快照及 AnimeTrack v5 适配，入口为“本机 → 备份与迁移”。真实 SQLite/文件测试及 Windows 原生页面流程通过；系统选择器人工操作与 Android 真机验证仍待完成。详见 [实现状态](IMPLEMENTATION_STATUS.md)。

## 1. 新格式

UTF-8 JSON，顶层 format 固定 anime-log，formatVersion 从 1 开始。使用 UUID 关联，不携带 SQLite 内部整数 id。

~~~json
{
  "format": "anime-log",
  "formatVersion": 1,
  "exportedAt": "2026-10-10T04:00:00.000Z",
  "anime": [
    {
      "uuid": "a6f1a5b0-9314-4d7a-8c90-2d7e2cda8d13",
      "metadata": {
        "title": "某动画",
        "originalTitle": null,
        "season": null,
        "entryType": null,
        "sourceProvider": null,
        "sourceId": null,
        "totalEpisodes": null,
        "durationMinutes": null,
        "summary": null,
        "coverUrl": null,
        "premiereDate": null,
        "isFinished": null
      },
      "status": "watching",
      "progress": 0,
      "score": null,
      "notes": null,
      "tags": [],
      "rewatchCount": null,
      "startDate": null,
      "startDateSource": null,
      "endDate": null,
      "createdAt": "2026-10-10T03:00:00.000Z",
      "updatedAt": "2026-10-10T03:00:00.000Z"
    }
  ],
  "watchHistory": [],
  "notes": []
}
~~~

历史含 uuid、animeUuid、episode、watchedOn、可空 watchedAt、createdAt。备注含 uuid、animeUuid、可空 episode、content、notedOn、createdAt、updatedAt。

不导出 API Key、AI 配置、数据库路径、localCoverPath、草稿或 intake_commits。远程封面地址可保留，缺少本机缓存可重新下载；JSON 不包含图片文件。数据库 schema 版本与备份格式版本独立。

实现补充：文件最大 50 MiB；新格式 UUID 为规范小写 UUID，时间戳要求 UTC ISO（以 Z 结尾）。UTF-8 BOM 可读取。非法字段、重复身份和总体备注冲突会显示字段位置，整个文件通过校验后才显示提交预览。解析和 JSON 编码在后台 isolate 执行。

## 2. 导出

在一致的数据库读事务内获取动漫、历史和备注快照。序列化和系统文件写入在读事务结束后执行，避免长时间持有事务。

使用系统保存对话框，建议文件名 AnimeLog-YYYYMMDD-HHmmss.json。Android 按系统 URI / 字节流接口写入，Windows 使用保存位置；选择取消不算失败。只有实际写入成功才报告导出完成。

UTF-8 中文、评分 0、进度 0、空值和用户日历日期必须原样往返。一次导出全部动漫，不让筛选状态偷偷限制备份范围。

## 3. 导入的两个模式

| 模式 | 用途与结果 |
| --- | --- |
| 完整恢复 | 用文件中的动漫、历史和备注替换本机这三类数据；适合把一端的完整记录搬到另一端 |
| 追加导入 | 只增加本机不存在的动漫 UUID 及其关联历史、备注；已有 UUID 的整组记录跳过，不更新现有记录 |

本机非空时先选择模式，再展示将新增 / 替换 / 跳过的数量。追加导入不会把另一端的新进度合入已有记录；要采用文件的整套最新数据，使用完整恢复。

即使两条记录同标题、同来源，只要 UUID 不同就分别保留。重刷记录不可按标题合并。对于已存在的 UUID，无论字段是否不同，追加模式都保留本机整组数据，并显示跳过数量。

导入保留文件中的 rewatchCount 和标签，不调用新建流程，不自动把二刷改成三刷。只有用户之后主动添加新记录时，才按恢复后的已有明确次数生成建议。

完整恢复确认前先在应用私有目录创建一份本机数据快照；创建失败则停止恢复。快照成功且用户确认后才替换数据，恢复不改 AI Key 或本机设置。

应用内的“恢复前的本机快照”可读取这些文件并再次进入完整恢复预览。预览与事务提交都核对本机内容摘要，本机数据在预览后变化时必须重新预览。快照只保存在本机私有目录，卸载仍会删除它；长期留存应另外导出到系统选择的位置。

## 4. 校验与事务

先读取并校验整个文件，再触及正式表：

- 拒绝未知 format / 更高不支持的 formatVersion；不能默默按旧格式猜测。
- 校验数组、必需字段、合法 UUID、数值范围、日期 / 时间、状态和重刷次数。
- 校验各数组内部 UUID 唯一，历史及备注必须关联文件中存在的动漫。
- 用备份中的明确日期保留观看日；不能转换时区后改写 watchedOn。
- 派生重刷标签根据 rewatchCount 标准化，显示修正数量；其他非法字段不得静默吞掉。
- 总体备注冲突、坏关联或格式损坏给出定位，不默认继续部分恢复。

所有写入在一个事务里完成；任一记录失败整体回滚。恢复成功后清理旧提交凭据和旧未提交草稿，清空显示缓存；恢复期间暂停其他写入。导入日志只含统计及字段定位，不记录用户全文或 Key。

新建 Repository 的幂等凭据不随备份导出。JSON 自身的 UUID 足以实现重复追加去重。第一版不提供逐字段冲突合并。

## 5. AnimeTrack 兼容范围

第一版必须支持 AnimeTrack formatVersion=5 的动漫、watchHistory 以及动漫内嵌的总体 / 分集 notes。数据结构以旧项目导出代码为准，适配器不能调用旧 AI 录入接口。

当前旧项目的 Android 和 Web 使用可迁移 v5 JSON；早期无版本或其他版本，在取得对应样例并验证之前不承诺支持。

LegacyBackupAdapter：

1. 识别并校验旧格式，与 AnimeLog 格式使用不同入口。
2. 将旧字段别名转为新模型，保持评分、标签、状态、进度、备注及已有历史。
3. 旧整数 ID 不与本机 ID 直接合并；建立本次文件的旧 ID → 新 UUID 映射，重建历史与备注关联。
4. 为无 UUID 的旧记录使用“文件内容 SHA-256 + 表名 + 旧 ID”的固定输入生成命名空间 UUID v5；无旧 ID 时使用已校验的数组位置。相同文件重复追加不会产生新记录。
5. 不同旧备份文件不能靠整数 ID 证明是同一条记录；追加可能形成重复组，预览需明确提示，搬移最新整份旧数据优先用完整恢复。
6. 识别二刷、三刷、数字刷等明确标签为 rewatchCount；保留其他标签，不根据同名记录数量推算次数。
7. 将原有 ISO watchedAt 转为 UTC，并按旧项目的 Asia/Shanghai 规则确定 watchedOn；缺少时区的旧时间按该时区解释，预览显示这一约定。
8. 旧开始日期来源为 history 时保留；明确用户日期设为 manual，来源无法确定时保持为空。
9. 忽略本机封面路径，保留有效远程地址；没有来源稳定 ID 时 sourceProvider / sourceId 均为空，不把旧数据库 ID 当 Bangumi ID。

漫画和其他当前不支持的数据在预览中显示未导入类别及数量。保留原 JSON，不能把“动漫导入成功”报告成整份旧数据已完整迁移。

## 6. 验收样本

覆盖普通记录、同名重刷、评分 0、未知总集数、进度清零、中文备注、总体与分集备注、同集再次观看、已知日期未知时刻、远程封面与旧本地路径。

必须验证：新格式往返内容一致、重复追加不增长、完整恢复消除本机额外记录、旧 ID 碰撞不串历史、坏数据事务回滚、Key 不泄露。数据库损坏、磁盘不足或系统选择取消不能报告成功。
