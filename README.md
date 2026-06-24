# ql_ios

青龙 iOS 客户端归档仓库。

## 新版 SwiftUI 客户端

仓库已新增一个从零实现的青龙 iOS 客户端源码，位于 `QLClient/`。它基于 `whyour/qinglong` 当前服务端源码中的 Open API：

- `GET /open/auth/token`
- `GET /open/system`
- `GET /open/dashboard/overview`
- `GET /open/crons`
- `PUT /open/crons/run`
- `PUT /open/crons/stop`
- `PUT /open/crons/enable`
- `PUT /open/crons/disable`
- `GET /open/crons/:id/log`
- `GET /open/envs`
- `POST /open/envs`
- `PUT /open/envs`
- `PUT /open/envs/enable`
- `PUT /open/envs/disable`

当前第一版覆盖登录、系统概览、任务列表、任务运行/停止/启停、任务日志、环境变量列表、变量新增/编辑/启停。脚本文件、订阅、依赖管理等危险操作先不放进第一版，后续可以继续扩展。

新版客户端最低支持 iOS 16，使用 `Project.yml` + XcodeGen 生成 Xcode 工程，GitHub Actions 会构建无签名 IPA 并发布到 `qlclient-unsigned-latest` Release。

## 当前状态

这个仓库仍保留历史 IPA 包、打包脚本和旧共享 Xcode scheme。旧工程缺少完整的 Xcode 工程文件和源代码：

- 缺少 `amz_profit_calculator.xcodeproj/project.pbxproj`
- 缺少 `.swift`、`.m`、`.h`、`.plist`、Storyboard 等源码文件
- `versions/v1.0.21_20260527_1909/BUILD_INFO.json` 显示最新包来自 `feature/app-store-subscription` 分支的 `eac2f80` 提交，但该源码分支不在当前公开仓库中

因此，旧客户端不能从源码重新构建，也不能直接修改旧代码。新版 SwiftUI 客户端是独立重写的可构建工程。

## 直接下载 IPA

仓库包含已归档的 IPA 文件。GitHub Actions 会把 `versions/` 目录下最新的 `qlmb-adhoc.ipa` 发布到 `unsigned-latest` Release，下载 Release 里的 `.ipa` 文件即可，不需要把 zip 改后缀。

安装到 TrollStore 时请直接使用 Release 资产中的 `qlmb-adhoc.ipa`。

## 本地安装

### TrollStore

1. 下载 Release 里的 `qlmb-adhoc.ipa`。
2. 把 IPA 传到 iPhone。
3. 在 TrollStore 中点击 `+`，选择 `Install IPA from File`。
4. 选择 `qlmb-adhoc.ipa` 安装。

### Sideloadly / AltStore

如果不用 TrollStore，可以用 Sideloadly 或 AltStore 重新签名安装。免费 Apple ID 通常需要 7 天重新签名一次。

## 重新构建所需文件

如果要真正构建新版 IPA、优化代码或适配青龙网页版新功能，请补齐以下内容：

- 完整 `.xcodeproj` 或 `.xcworkspace`
- iOS 源码文件
- `Info.plist`、资源文件、Core Data model 等工程依赖
- 可用的构建 scheme

补齐后可以再把 GitHub Actions 改成真正的 Xcode 构建流程。
