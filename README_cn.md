Razer Basilisk X HyperSpeed 驱动 For macos

适用于 macOS 12+ 的 Razer Basilisk X HyperSpeed 鼠标控制软件

本项目只适用于Razer Basilisk X HyperSpeed鼠标驱动，并为想从openRazer移植到macos的提供一种思路，可自行移植其他设备驱动

从[Releases](https://github.com/liu5580/Razer-Basilisk-X-HyperSpeed-Driver-For-macos/releases/tag/V1.0.0)中下载最新构建版本

可直接运行版本在项目/build中的RazerControl.app和命令行工具razerctl，可直接下载运行，支持macos12+

## 自构建步骤：

### 方法一：自动构建安装（推荐）
```bash
cd RazerControlMac
./Scripts/build.sh
./Scripts/install.sh
```

### 方法二：手动安装
1. 构建应用程序：
```bash
make clean && make
```

2. 安装应用程序：
```bash
# 安装图形界面应用
cp -r build/RazerControl.app /Applications/

# 安装命令行工具
sudo cp build/razerctl /usr/local/bin/
sudo chmod +x /usr/local/bin/razerctl
```

## 系统要求

- **操作系统**: macOS 12.0 (Monterey) 或更高版本
- **硬件**: Razer Basilisk X HyperSpeed 鼠标
- **开发工具** (仅构建时需要): 
  - Xcode Command Line Tools
  - clang 编译器

## 使用方法

### 菜单栏应用

1. **启动应用**：
   - 从 Applications 文件夹中双击 `RazerControl.app`
   - 应用在后台运行，只在菜单栏显示图标（不在 Dock 中显示）
   - 在菜单栏中寻找鼠标图标

2. **打开设置**：
   - **左键点击**菜单栏图标直接打开设置窗口
   - **右键点击**菜单栏图标显示选项菜单（打开设置、退出）
   - 设置窗口显示所有设备控制和信息

3. **后台运行**：
   - 关闭设置窗口后应用继续在后台运行
   - 应用保持在菜单栏中随时可用
   - 右键点击菜单栏图标可退出应用

### 主要功能

#### DPI 控制
- 滑块调节 100-16000 DPI
- 预设按钮快速设置 (400, 800, 1600, 3200, 6400)
- 立即生效

#### 轮询率设置
- 在 125Hz/500Hz/1000Hz 之间切换
- 更高轮询率提供更流畅的光标移动，但可能使用更多 CPU

#### 电池监控
- 实时电池电量显示
- 低电量警告

### 命令行工具

```bash
# 设置 DPI
razerctl dpi 1600

# 设置轮询率
razerctl polling 1000

# 查看电池状态
razerctl battery

# 获取设备信息
razerctl info

# 查看当前所有设置
razerctl status
```

## 权限设置

### USB 设备访问权限

1. 首次运行时，系统可能要求授予 USB 设备访问权限
2. 如果应用无法检测到设备：
   - 进入 `系统偏好设置` > `安全性与隐私` > `隐私`
   - 在左侧列表中找到 `输入监控` 或相关权限
   - 确保 `RazerControl` 被勾选

### 管理员权限

- CLI 工具安装需要 `sudo` 权限
- 应用运行不需要管理员权限

## 故障排除

### 设备未检测到
1. **检查连接**：确保鼠标通过 USB 连接（不是蓝牙）
2. **系统信息**：打开 `关于本机` > `系统报告` > `USB`，查找设备
3. **重新连接**：拔出并重新插入 USB 接收器
4. **重启应用**：退出并重新启动 RazerControl

### 菜单栏图标找不到
1. **仔细查找**：菜单栏图标可能较小，请仔细查找
2. **活动监视器**：检查 RazerControl 是否在活动监视器中运行
3. **重新启动**：尝试退出并重新启动应用
4. **从应用程序文件夹启动**：确保从 Applications 文件夹启动

### 构建错误
1. **安装开发工具**：
```bash
xcode-select --install
```

2. **检查 SDK**：
```bash
xcrun --show-sdk-path
```

3. **清理重建**：
```bash
make clean && make
```

### 权限问题
1. **系统偏好设置** > **安全性与隐私** > **隐私**
2. 添加 `RazerControl.app` 到必要的权限列表
3. 重启应用程序

## 技术细节

### 支持的功能
- ✅ DPI 调节 (100-16000)
- ✅ 轮询率设置 (125/500/1000 Hz)
- ✅ 电池电量监控（显示数值可能错误）
- ✅ 固件版本查询
- ✅ 设备序列号查询
- ✅ 菜单栏集成
- ✅ 后台运行（隐藏 Dock 图标）
- ✅ 自定义应用图标（透明鼠标图标）
- ✅ 命令行界面
- ✅ 改进的设备重连机制

### 已知限制
- 仅支持 USB 连接模式
- 不支持宏设置
- 不支持按键重映射

### USB 协议
基于 openRazer 项目的 USB HID 通信协议：
- 厂商 ID: 0x1532 (Razer)
- 产品 ID: 0x0083 (Basilisk X HyperSpeed)
- 报告长度: 90 字节

### 后台运行
- 使用 LSUIElement 配置，应用只在菜单栏显示
- 不在 Dock 中显示图标，减少界面干扰
- 后台持续监控设备状态

## 卸载

### 完全卸载
```bash
# 删除应用程序
rm -rf /Applications/RazerControl.app

# 删除命令行工具
sudo rm -f /usr/local/bin/razerctl

# 删除偏好设置（可选）
rm -rf ~/Library/Preferences/com.razercontrol.macos.*
```

## 获取帮助

1. **查看日志**：
   - 应用日志：`Console.app` 搜索 "RazerControl"
   - 系统日志：检查 USB 相关错误

2. **常见问题**：
   - 确保使用官方 USB 接收器
   - 尝试不同的 USB 端口
   - 检查鼠标电量
   - 如果菜单栏图标消失，重启应用

3. **报告问题**：
   - 收集系统信息和错误日志
   - 描述具体的重现步骤

## 版本信息

- **当前版本**: 1.0.0
- **兼容系统**: macOS 12.0+
- **支持设备**: Razer Basilisk X HyperSpeed
- **更新日期**: 2025.5.31

---

**免责声明**: 这是一个非官方工具，与 Razer Inc. 无关。使用风险自负。参考openRazer开源项目遵守开源协议GPL
🈲严禁抄袭转发🈲@https://github.com/openrazer/openrazer
