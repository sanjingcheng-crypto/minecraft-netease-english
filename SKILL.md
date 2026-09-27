---
name: minecraft-netease-english
description: 将 Windows 网易中国版《我的世界》基岩版或 Java 版的游戏内界面设为英文，并排查多层启动器、配置文件重定向、语言重置和残留中文。适用于网易中国版，不适用于国际版。
---

# 网易《我的世界》英文游戏界面

目标是让玩家**实际进入的游戏菜单和设置**显示英文，并留下重新打开游戏的清楚路径与截图证据。网易启动器、启动提示、品牌图像、玩家昵称和世界名可能继续显示中文；不要把这种结果称为“全部英文”。本 skill 来自 2026-09-24 至 27 日在两台 Windows 电脑上对中国版基岩端和 Java NeoForge 1.21.10 的实测。路径、版本与资源键在另一台电脑上都要重新确认。

## 先认清启动入口

1. 从网易官方下载、安装并用用户自己的账号登录；不要绕过登录。确认桌面入口打开的是哪一层：旧“我的世界”图标可能先进入“网易发烧游戏”，在已安装基岩版旁仍显示红色“立即下载”。这不是已安装世界的启动列表。
2. 找到实际安装的金黄色《我的世界》启动器 `WPFLauncher.exe`；不要照抄其它电脑的安装路径。从它左下角点蓝色“开始游戏”，进入世界列表。世界卡片的顺序会随最近使用变化，按**绿色“基岩版”**或**蓝色“JAVA版”**标签选择，再点右侧绿色“启动”。不要用左右位置判断版本。
3. 如用户需要日后自己启动，建立清晰命名的桌面快捷方式，并用 UI 双击实测。基岩版快捷方式可直达已安装的 `WPFLauncher.exe`；Java 版若需要下面的语言保护或图形兼容处理，快捷方式应调用经过验证的 Java 启动脚本。不要让用户依赖容易进入下载页的旧图标。

## 基岩版：语言与网易残留文本

1. 启动一次基岩版以生成当前 Windows 用户的配置。`%APPDATA%\MinecraftPE_Netease\minecraftpe\options.txt` 和 `%APPDATA%\MinecraftPC_Netease_PB\minecraftpe\options.txt` 都曾在不同启动路径下生效；同一电脑上两份可同时存在，不能按目录名称判断新旧。完整退出游戏，比较两份配置在刚才启动后的修改时间和 `game_language`，只修改当前实际写入的那份。用实际 `Minecraft.Windows.exe` 进程定位游戏根目录。安装目录和用户名不能照抄案例路径。
2. 如果当前游戏根目录的 `data\resource_packs\vanilla_netease` 是可浏览的目录，运行 [Set-NeteaseMinecraftEnglish.ps1](scripts/Set-NeteaseMinecraftEnglish.ps1)：先用 `-AuditOnly` 检查文件结构与待改项目，再正式执行。它备份原文件，把 `game_language` 改为 `en_US`，并对已验证的 `Mod Settings`、画质、渲染引擎和模组信息残留文本做最小补丁。另一次实测的资源包是无扩展名的单个打包文件，此脚本不适用；先备份并只改当前生效的 `options.txt`，再用游戏菜单验收。若资源结构、键数量或 JSON 不符合预期，停下检查新版本；不要整包批量翻译，也不要伪造 `en_US.lang`。
3. 从已安装启动器重新进入世界。按 Esc 核对 `Resume Game`、`Settings`、`Mod Settings`、`Save & Quit`；打开 Settings，核对 Accessibility、Game、Keyboard & Mouse、Video、Audio 等分类，以及用户要求的每个子页。仅看到文件中 `game_language:en_US` 不算验收通过。
4. 如果从打包的 Codex 桌面应用操作，普通 AppData 路径可能读到应用私有副本。脚本对本地盘符路径使用 `\\?\` 扩展路径来访问真实用户文件；仍须在新启动的游戏里验证。若游戏仍中文，优先读[实测问题与排查](references/case-notes.md)中的配置副本案例。

示例（先把占位路径替换为当前电脑的真实路径）：

```powershell
$skill = 'C:\Users\<用户名>\.codex\skills\minecraft-netease-english'
$game = 'C:\path\to\BedrockGame'
& "$skill\scripts\Set-NeteaseMinecraftEnglish.ps1" -GameRoot $game -AuditOnly
& "$skill\scripts\Set-NeteaseMinecraftEnglish.ps1" -GameRoot $game
```

若配置属于另一个 Windows 用户，显式传 `-OptionsPath`。脚本的备份默认放在当前用户文档的 `MinecraftEnglishBackups`，可用 `-BackupRoot` 指定其它位置。

## Java 版：语言与重启保持

1. 定位**当前启动的** Java 游戏目录和 `options.txt`，先在游戏内 Options → Language 选择 `English (US)`。完整退出并从网易启动器再启动，确认 `lang:en_us` 是否保留。另一台电脑上 `MCLDownload\Game\.minecraft\options.txt` 已是英文，但只是模板；实际被重写的文件在 `netease_minecraft_neoforge\options.txt`。可比较候选文件在启动前后的修改时间，但不要把模板当作实际配置。Java 版和基岩版使用不同配置文件及大小写。
2. 如果网易启动器在每次启动时把 Java 语言改回中文，先备份 `options.txt`，再用 [Start-NeteaseMinecraftJavaEnglish.ps1](scripts/Start-NeteaseMinecraftJavaEnglish.ps1) 进行有条件的语言保护：游戏启动前写入 `lang:en_us` 并临时设只读，游戏窗口出现后解锁以允许正常保存，游戏退出后再次写回英文并恢复只读。先运行 `-AuditOnly`，再用实际启动器、游戏目录及 `javaw.exe` 路径运行。脚本拒绝在目标启动器或游戏已运行时再启动一个实例。另一台电脑通过备份后将实际 `options.txt` 设为只读，用原启动器重启后验证英文；这种简化方法会使其它游戏设置也无法写回该文件，只有用户接受该限制时才保留。
3. 只有实测机器缺少可用 OpenGL 时才考虑脚本的 `-SoftwareOpenGL` 选项和可信来源的图形兼容组件；这是图形兼容措施，不是翻译所需步骤。Java 版加载可能较慢。详细证据与参数见 [Java 版实测](references/java-case.md)。
4. 进入世界按 Esc，应看到 `Game Menu`、`Options...`、`Save and Quit to Title`；点 Options 应看到 `Language...`、`Video Settings...`、`Controls...` 等英文项。正常退出，再重开一次验证语言不会反弹。

## 截图与交付

按用户看到的实际界面逐步截图，标出要点击的按钮；遇到入口与预期不同时先辨认窗口标题和卡片标签。至少保留桌面入口、金黄色启动器的“开始游戏”、目标版本卡片与“启动”、游戏内暂停菜单、设置页，以及出现过的下载页或显卡提示。对残留中文，区分 UI 标签、网易徽标、账号昵称、世界名和 Windows 水印，仅修可控的 UI 文本。游戏更新后重新审计。

故障与错误尝试记录在 [实测问题与排查](references/case-notes.md) 和 [Java 版实测](references/java-case.md)。
