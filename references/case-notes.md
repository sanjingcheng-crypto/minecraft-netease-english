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
