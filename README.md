# 📱 BLE 调试工具

> 基于 Flutter 开发的蓝牙低功耗（BLE）调试 APP，支持 Android 设备。

![Build APK](https://github.com/Tyche9955/ble-app/actions/workflows/build.yml/badge.svg)

---

## ✨ 功能特性

| 功能 | 说明 |
|------|------|
| 🔍 扫描设备 | 实时扫描周边 BLE 设备，显示设备名称、MAC 地址、信号强度（RSSI） |
| 🔗 连接/断开 | 一键连接目标设备，自动处理断线回调 |
| 📦 服务发现 | 自动加载 GATT 服务树及所有特征值（Characteristic） |
| 📖 读取数据 | 读取特征值，同时显示 HEX 和 UTF-8 文本格式 |
| ✉️ 发送数据 | 自动识别 HEX 格式（如 `01 02 FF`）或普通文本并发送 |
| 🔔 订阅通知 | 订阅特征值 Notify，实时接收设备推送数据 |
| 📋 操作日志 | 带时间戳的完整操作日志，方便调试 |

---

## 📲 下载安装

### 方式一：直接下载 APK（推荐）

1. 点击进入 👉 [Actions 页面](https://github.com/Tyche9955/ble-app/actions)
2. 点击最新一次成功的构建（绿色 ✅）
3. 在页面底部 **Artifacts** 区域下载 `BLE-App-Release`
4. 解压后得到 `app-release.apk`
5. 传到手机安装即可

> ⚠️ 安装前请在手机设置中开启「允许安装未知来源应用」

### 方式二：自行编译

参考下方「本地开发」章节。

---

## 🖼️ 界面预览

```
┌─────────────────────────┐
│  🔵 BLE 扫描             │
│─────────────────────────│
│  [🔍 开始扫描]           │
│                         │
│  设备名称    MAC地址  RSSI│
│  ─────────────────────  │
│  MyDevice   AA:BB:..  -65│
│  Unknown    CC:DD:..  -80│
│  Sensor-01  EE:FF:..  -72│
└─────────────────────────┘

┌─────────────────────────┐
│  MyDevice        [断开] │
│─────────────────────────│
│  📦 服务 0x180A          │
│    🔷 0x2A29  [read]    │
│    🔷 0x2A24  [read]    │
│  📦 服务 0xFFF0          │
│    🔷 0xFFF1  [notify]  │
│─────────────────────────│
│  [输入框]        [发送]  │
│  [📖 读取]  [🔔 订阅通知]│
│─────────────────────────│
│  日志                   │
│  [17:30] 连接成功        │
│  [17:30] 发现 2 个服务   │
└─────────────────────────┘
```

---

## 🛠️ 技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| Flutter | 3.24.5 | 跨平台 UI 框架 |
| flutter_blue_plus | ^1.31.15 | BLE 蓝牙通信库 |
| permission_handler | ^11.3.0 | Android/iOS 权限管理 |
| provider | ^6.1.2 | 状态管理 |

---

## 📁 项目结构

```
ble-app/
├── .github/
│   └── workflows/
│       └── build.yml          # GitHub Actions 自动打包配置
├── lib/
│   ├── main.dart              # 应用入口，主题配置
│   ├── ble_provider.dart      # BLE 核心逻辑（扫描/连接/读写/通知）
│   ├── scan_screen.dart       # 扫描页面（设备列表）
│   └── device_screen.dart     # 设备详情页（服务/特征值/操作）
├── android/
│   └── app/src/main/
│       └── AndroidManifest.xml  # Android 蓝牙权限配置
└── pubspec.yaml               # Flutter 依赖配置
```

---

## 🔧 Android 权限说明

APP 运行需要以下权限：

| 权限 | 用途 |
|------|------|
| `BLUETOOTH_SCAN` | 扫描周边 BLE 设备 |
| `BLUETOOTH_CONNECT` | 连接 BLE 设备 |
| `ACCESS_FINE_LOCATION` | Android 12 以下扫描 BLE 需要定位权限 |

> 首次运行时 APP 会弹出权限申请弹窗，请点击「允许」。

---

## 💻 本地开发

### 环境要求

- Flutter 3.24.5+
- Android Studio 或 VS Code
- Android SDK（API 21+）
- 支持 BLE 的 Android 手机（Android 5.0+）

### 步骤

```bash
# 1. 克隆仓库
git clone https://github.com/Tyche9955/ble-app.git
cd ble-app

# 2. 创建 Flutter 项目脚手架
flutter create --org com.bleapp --project-name ble_app .

# 3. 安装依赖
flutter pub get

# 4. 运行（连接手机或启动模拟器）
flutter run

# 5. 打包 APK
flutter build apk --release
# APK 位置：build/app/outputs/flutter-apk/app-release.apk
```

---

## 🤖 自动打包（GitHub Actions）

每次向 `main` 分支推送代码，GitHub Actions 会自动：

1. 搭建 Flutter 编译环境
2. 编译 Release APK
3. 上传 APK 到 Artifacts（保留 30 天）

也可以手动触发：
1. 进入 [Actions 页面](https://github.com/Tyche9955/ble-app/actions)
2. 选择 **Build BLE APK**
3. 点击 **Run workflow** → **Run workflow**

---

## ❓ 常见问题

**Q: 扫描不到设备？**
- 确认手机蓝牙已开启
- 确认已授予定位权限（Android 12 以下必须）
- 部分设备需要开启 GPS

**Q: 连接失败？**
- 确认设备未被其他手机连接
- 尝试重启目标 BLE 设备
- 检查设备是否需要配对

**Q: 发送数据没有响应？**
- 确认选择的特征值支持 `write` 属性
- 检查数据格式是否正确

---

## 📄 License

MIT License © 2024 Tyche9955