# 实测问题与排查

本记录来自 2026-09-24 至 25 日的 Windows 网易中国版基岩端 1.21.120.0；Java NeoForge 1.21.10 另见 [Java 版实测](java-case.md)。官网为 <https://www.minecraft.com.cn/index-from-minecraft.html>。本机的完整安装路径、用户目录和截图未纳入公开备份。应通过实际 `Minecraft.Windows.exe`、`WPFLauncher.exe` 进程定位游戏与启动器；基岩版用户设置通常位于 `%APPDATA%\MinecraftPE_Netease\minecraftpe\options.txt`。

## 这次实际做了什么

1. 经网易官方入口安装、登录并启动中国版，先把基岩版基础语言设为 `en_US`。暂停菜单虽出现英文，`模组设置`、画质和模组页仍有中文，因此定位网易资源包的语言键与硬编码 JSON，备份后只改实际生效的少量标签，再逐页重启验收。
2. 为了让游戏在此电脑的图形环境中运行，处理了基岩版的驱动警告及软件渲染。玩家后来从“旧我的世界”图标重开时看到另一层启动器的红色“立即下载”，导致之前口头的打开路径不符。最终确认已安装世界在金黄色 `WPFLauncher.exe` 的“开始游戏”列表，而不是外层“网易发烧游戏”下载页。
3. 重启基岩版时曾再次看到中文，尽管命令读出的配置写着 `game_language:en_US`。排查发现 Codex 桌面应用读写的是 AppContainer 的私有 AppData 副本，游戏读的真实 Roaming 文件仍是 `zh_CN`。备份真实文件并改为 `en_US` 后，重新进入世界，`Resume Game`、`Settings`、`Mod Settings`、`Save & Quit` 与设置分类均显示英文，正常退出后真实配置仍保留 `en_US`。这是文件检查不能代替游戏 UI 验收的关键例子。
4. Java 版另行设为 `lang:en_us`，发现网易启动器重开时会改写 Java 的 `options.txt`；采用启动前临时只读、游戏窗口出现后解锁、退出后恢复英文的辅助脚本。此电脑还需要软件 OpenGL 环境。最终在游戏内 `Game Menu` 和 `Options` 页面截图验收英文。
5. 建立两个桌面快捷方式：`Minecraft Bedrock (English)` 直接打开已安装的金黄色启动器；`Minecraft Java (English)` 调用此电脑专用辅助脚本。实际 UI 双击验证，并做了 10 页逐步红圈图解，标出两个版本的入口、世界卡片、游戏内验收页和错误下载入口。该图解含玩家数据，未纳入公开仓库。屏幕上的网易徽标、启动器、昵称及世界名仍可能是中文。

| 观察到的问题 | 原因或证据 | 已验证的处理 |
| --- | --- | --- |
| 基础设置已英文，但 `模组设置` 仍中文 | 网易包 `texts\languages.json` 只有 `zh_CN`，其 `zh_CN.lang` 仍提供 `pause.generalSetting` | 将该键设为 `Mod Settings`，退出并重启游戏 |
| Video 页面出现中文画质等级 | 同一 `zh_CN.lang` 的 `options.graphics_level`、`.level1`、`.level2`、`.level3`、`.recommend`、`.self_define` | 仅翻译这些键，重启后看到 `Graphics Quality: Standard(Recommended)` |
| Video 页面底部出现 `渲染引擎` | `ui\settings_sections\general_section.json` 硬编码 `$option_label` | 将对应值改为 `Rendering Engine`，重启后可见 |
| Mod Settings 内标题是 `模组信息` | `ui\netease\mod\netease_general_setting.json` 硬编码标题与输入提示 | 分别改为 `Mod Information` 与 `Enter text`；标题已在游戏内验证 |
| 启动器、徽标、昵称、世界名仍是中文 | 它们不由上述游戏语言键统一控制；昵称和世界名是用户内容 | 截图时清楚说明；不要为“界面翻译”擅自改账号或世界名称 |
| 仅增加 `en_US.lang` 或修改网易包的 `languages.json` 后仍有中文 | 该尝试在实测机器上未解决已发现的残留；已撤销 | 保留原始语言声明，对实际生效的 `zh_CN` 键和硬编码 UI 标签做最小补丁 |
| 配置文件读到 `game_language:en_US`，重启后游戏却仍是中文 | 2026-09-25 实测：打包的 Codex 桌面应用把普通 `%APPDATA%` 路径重定向到 `AppData\Local\Packages\OpenAI.Codex_...\LocalCache\Roaming\...` 私有副本；游戏读的是真正的 `AppData\Roaming\MinecraftPE_Netease\minecraftpe\options.txt`，当时仍是 `zh_CN` | 对确认属于目标用户的本地盘符路径，使用 Windows `\\?\C:\...\options.txt` 扩展路径读取、备份并修改真实文件；本 skill 的脚本现已如此处理。再次启动游戏，用暂停菜单和设置页验证，而非只看文件文本 |
| 桌面旧“我的世界”图标打开“网易发烧游戏”，基岩版显示红色“立即下载” | 该图标通向外层下载入口；已安装的世界在 `WPFLauncher.exe` 的金黄色启动器内 | 关闭外层窗口，打开实际安装的启动器，在左下角点“开始游戏”，按世界卡片的“基岩版”标签选中并启动；不要因下载提示重复安装 |
| 草拟的基岩英文 PowerShell 快捷方式不能作为验收依据 | 本机曾创建一份未成功执行的基岩启动脚本，它不是最终桌面快捷方式的目标，也未纳入公开备份 | 不复制或推荐该草稿；最终基岩快捷方式直指已安装的 `WPFLauncher.exe`，并通过真实配置与游戏 UI 验收 |
| 虚拟/旧显卡环境出现显卡驱动警告，游戏不能正常显示 | 机器 OpenGL 能力不足，与英文设置无关 | 优先更新受支持的显卡驱动。实测机器最后采用应用目录内的 Mesa3D 26.2.1 `opengl32.dll` 和 `libgallium_wgl.dll` 软件渲染才可进入游戏；这只是特定环境的兼容方案，帧率慢，不能当作常规语言设置，也不要从不明来源复制 DLL |

若修改不生效：确认正在编辑的目录是当前 `Minecraft.Windows.exe` 的目录，选对登录游戏的 Windows 用户的 `options.txt`；必须完整退出游戏后编辑，并重新进入世界。若资源文件键名改变，先搜索游戏包中屏幕上的原文，再核对上下文。本节的基岩配置文件与资源包流程不适用于 Java 版或国际版。

复查基准：暂停菜单四个按钮、所有可见设置分类、Video 页滚动到底部及展开高级图形项、模组设置标题。实测曾留有 16 张最终截图；其中退出后的网易启动器截图保留中文，作为“未完全英文”的证据。截图与逐步图解含玩家名称、世界名称等个人信息，因此未纳入公开仓库。换电脑必须重新截图。

## 第二台电脑的补充实测（2026-09-27）

- 两份基岩配置 `MinecraftPE_Netease` 与 `MinecraftPC_Netease_PB` 同时存在。在 9 月 27 日的一次启动中，前者随游戏更新，改为 `en_US` 后英文生效；但后续从桌面正常入口重开，实际客户端与配置路径发生切换，不能永久把后者当成旧配置。
- 游戏根目录在另一盘的 `MCLDownload\MinecraftBENeteasePath\x64_mc`，说明不能假定与第一台电脑同盘。脚本从实际游戏根目录审计资源键后，改动了四个文件；重进游戏后暂停菜单、Settings、Video、Audio 与 Mod Information 为英文。
- Windows PowerShell 5.1 对单元素 JSON 数组套 `@(...)` 会形成嵌套数组，原资源清单审计误报；脚本现已逐项展开。脚本保留 UTF-8 BOM 以便 PowerShell 5.1 正确读取中文匹配字面量。游戏接受的网易 UI JSON 可能被 PowerShell 5.1 的 `ConvertFrom-Json` 拒绝，因此针对已审计的唯一字符串做精确替换，不以该解析器结果判断游戏 JSON 是否有效。

### 重启后再次变中文的根因与修复

- 9 月 27 日目标机重启后，从桌面正常入口进入的基岩版暂停菜单和设置页均为中文。任务管理器“打开文件所在的位置”确认本次 `Minecraft.Windows.exe` 进程位于另一套已安装客户端，不是此前补丁针对的客户端。前者的 `data\resource_packs` 中 `vanilla`、`vanilla_netease` 是无扩展名的单个打包文件，不能使用只处理可浏览资源目录的脚本给它打补丁。
- 在真实用户的 Roaming 目录里，`MinecraftPE_Netease\minecraftpe\options.txt` 保持 `game_language:en_US`，但修改时间停留在这次启动前；`MinecraftPC_Netease_PB\minecraftpe\options.txt` 则在刚才游戏启动后更新，且内容为 `game_language:zh_CN`。以实际启动后的写入时间和内容区分当前配置，再完整退出游戏，将活跃文件备份并仅把 `game_language` 改为 `en_US`。
- 从桌面入口启动并进入世界后，暂停菜单四按钮显示 `Resume Game`、`Settings`、`Mod Settings`、`Save & Quit`，设置分类和选项也显示英文。保存退出游戏后又启动一次，暂停菜单仍为英文。网易徽标、账号昵称及世界名称仍显示中文，属于其它文本来源。
- 排查新电脑时的顺序：先定位当前进程的可执行文件，再比较候选 `options.txt` 的修改时间及语言值，修改活跃文件，最后在实际游戏菜单验收。不能沿用上次有效的目录，也不能只凭一份配置里已经写着 `en_US` 就认定游戏应为英文。
