# Java 版实测：语言、启动与图形兼容

本记录来自 2026-09-25 在 Windows 网易中国版 Java NeoForge 1.21.10 上的实测。公开备份省略了本机实际路径和带玩家信息的截图；下表只保留定位方式：

| 项目 | 此电脑实测值 |
| --- | --- |
| 金黄色网易《我的世界》启动器 | 当前安装目录中的 `WPFLauncher.exe` |
| Java 游戏目录及语言文件 | 当前世界所用游戏目录中的 `options.txt` |
| 运行中的游戏 Java 程序 | 从目标 `javaw.exe` 进程取得其实际路径 |
| 游戏语言键 | `lang:en_us`，与基岩版的 `game_language:en_US` 不同 |
| 本机原有桌面快捷方式 | `Minecraft Java (English).lnk`，调用本机专用脚本；该脚本未收录在公开备份中 |

## 问题与处理

1. **游戏内语言改好，重新启动又变中文。** 此机器的网易启动器会在启动 Java 游戏时改写 `options.txt`。实测处理是在启动前备份并写入 `lang:en_us`，临时将文件设为只读；游戏窗口出现后解除只读，让游戏正常保存其他设置；游戏退出后再次写回英文并设只读。原始本机脚本已通过 Java `Game Menu` 和 `Options` 页面英文截图及重新启动验收。运行中的游戏可看到 `options.txt` 暂时为可写，这是预期状态；结束后应恢复只读。
2. **Java 游戏因这台电脑的图形能力无法正常启动。** 本机启动脚本把 `GALLIUM_DRIVER=llvmpipe` 和 `LIBGL_ALWAYS_SOFTWARE=true` 传给启动器，并依赖已核实来源的本地图形兼容环境。它可能显著降低帧率。另一台电脑若本来能运行 Java 游戏，不要为了英文设置而启用软件渲染或复制 DLL。
3. **从普通启动器或旧桌面图标进入，结果与教程不同。** 本机的旧“我的世界”图标进入外层“网易发烧游戏”；已安装世界在金黄色 `WPFLauncher.exe` 的左下角“开始游戏”内。选择带蓝色“JAVA版”标签的卡片，再点右侧“启动”。卡片位置可能变化。
4. **以为启动器也会是英文。** 已核对英文的是 Java 游戏内的 `Game Menu`、`Options...`、`Language...`、`Video Settings...` 等；网易启动器仍显示中文。

## 在另一台电脑复用

先在游戏内 Options → Language 选择英文并正常重启。只有观察到启动器改写语言时才使用本 skill 的 [Java 启动脚本](../scripts/Start-NeteaseMinecraftJavaEnglish.ps1)。从实际运行的 Java 进程和世界目录取得三个路径，而非照抄上表。运行 `-AuditOnly` 应仅显示找到的文件、语言、只读状态及进程状态；目标启动器和游戏完全关闭后才正式执行。示例：

```powershell
$skill = 'C:\Users\<用户名>\.codex\skills\minecraft-netease-english'
& "$skill\scripts\Start-NeteaseMinecraftJavaEnglish.ps1" `
    -LauncherPath 'C:\实际路径\WPFLauncher.exe' `
    -GameRoot 'C:\实际路径\Java游戏目录' `
    -JavaPath 'C:\实际路径\javaw.exe' `
    -AuditOnly
```

审计确认后去掉 `-AuditOnly` 执行；仅在确有图形兼容问题且已准备可信环境时追加 `-SoftwareOpenGL`。如游戏进程命令行不含游戏目录名，可显式传 `-GameProcessMarker`，其值必须能唯一标识目标 Java 游戏。脚本会将原 `options.txt` 备份到用户文档的 `MinecraftEnglishBackups`；另设 `-BackupRoot` 可改位置。若把脚本做成快捷方式，先用可见 PowerShell 测通，再隐藏窗口，确保故障时看得到错误。

本机曾保存游戏菜单、设置页截图和逐页红圈图解。截图含玩家名称、世界名称等个人信息，未纳入公开仓库。换电脑时应重新截该电脑的真实画面，不能把旧截图当成新机器验收。

参数化脚本来自本机已经实测的启动逻辑，目前通过了 PowerShell 语法检查和 `-AuditOnly` 路径/进程审计；由于更新 skill 时游戏仍在运行，没有强行关闭用户游戏再执行一次完整启动。另一台电脑首次使用时，须在可见窗口试跑并完成游戏内与重启验收。

## 第二台电脑补充实测（2026-09-27）

另一台电脑安装在另一盘。`MCLDownload\Game\.minecraft\options.txt` 写着 `lang:en_us`，却不是实际运行目录；正常启动 Java 世界后，`netease_minecraft_neoforge\options.txt` 更新时间变化并显示 `lang:zh_cn`。从游戏内设为 English (US) 后当次菜单为英文，但下次启动又回中文。备份实际文件，把唯一的 `lang:zh_cn` 改成 `lang:en_us` 并设只读，使用原网易启动器再次进入同一世界后，`Game Menu`、`Options`、新手操作提示均为英文。网易启动器、世界名和部分加载画面仍是中文。

只读方案的代价是游戏无法把键位、画面等其它选项写回这个文件。若需要正常保存其它选项，先解除只读，改用本 skill 的启动脚本并按实际启动、退出流程验收。另一次退出时 Java 世界已经保存且窗口消失，但 `javaw.exe` 与启动器进程仍残留；确认世界保存完成后再结束残留进程，勿在存档仍写入时强行结束。
