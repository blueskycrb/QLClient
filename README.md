# QLClient

QLClient 是一个面向青龙面板的 iOS 客户端，使用 SwiftUI 编写，最低支持 iOS 16。它通过青龙 Open API 连接你的服务端，可以在手机上管理定时任务、环境变量和脚本文件。

## 功能

- Open API 登录，支持保存多个青龙账号
- 顶部账号按钮快速切换账号
- 白天模式、夜间模式、跟随系统
- 定时任务列表、运行、停止、启用、禁用
- 定时任务新增、编辑、置顶、取消置顶
- 定时任务日志查看
- 环境变量列表、新增、编辑、启用、禁用
- 环境变量置顶、取消置顶，并按网页版规则排序
- 脚本目录浏览、脚本内容查看和编辑保存
- 兼容青龙 v2.20.0 的任务、变量和脚本返回格式

## 安装

GitHub Actions 会自动构建无签名 IPA，并发布到 Release。

- 最新版本：[QLClient-unsigned.ipa](https://github.com/blueskycrb/QLClient/releases/download/qlclient-unsigned-latest/QLClient-unsigned.ipa)
- 所有版本：[Releases](https://github.com/blueskycrb/QLClient/releases)

### TrollStore

1. 下载 Release 中的 `QLClient-unsigned.ipa`。
2. 把 IPA 传到 iPhone。
3. 在 TrollStore 中点击 `+`。
4. 选择 `Install IPA from File` 并安装。

### 其他安装方式

如果不用 TrollStore，可以使用 Sideloadly、AltStore 等工具重新签名后安装。免费 Apple ID 通常需要定期重新签名。

## 青龙权限

在青龙 Web 面板中创建 Open API 应用，并给应用授予以下权限：

- `system`
- `crons`
- `envs`
- `scripts`

如果缺少某项权限，对应页面可能会返回 `401` 或权限错误。

## 本地构建

项目使用 `Project.yml` + XcodeGen 生成 Xcode 工程。

```bash
brew install xcodegen
xcodegen generate
xcodebuild \
  -project QLClient.xcodeproj \
  -scheme QLClient \
  -configuration Release \
  -destination "generic/platform=iOS" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build
```

构建完成后，将 `QLClient.app` 放入 `Payload/` 目录并压缩为 `.ipa` 即可安装或重新签名。

## 发布

推送到 `main` 后，GitHub Actions 会构建无签名 IPA，并发布：

- `qlclient-unsigned-latest`
- `qlclient-unsigned-<commit>`

固定版本链接适合避免浏览器或安装工具缓存旧包。
