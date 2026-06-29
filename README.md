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

下载 Release 中的 IPA 后，可以通过 TrollStore 安装。

- 最新版本：[QLClient-unsigned.ipa](https://github.com/blueskycrb/QLClient/releases/download/qlclient-unsigned-latest/QLClient-unsigned.ipa)
- 所有版本：[Releases](https://github.com/blueskycrb/QLClient/releases)

### TrollStore

1. 下载 Release 中的 `QLClient-unsigned.ipa`。
2. 把 IPA 传到 iPhone。
3. 在 TrollStore 中点击 `+`。
4. 选择 `Install IPA from File` 并安装。

## 青龙权限

在青龙 Web 面板中创建 Open API 应用，并给应用授予以下权限：

- `system`
- `crons`
- `envs`
- `scripts`

如果缺少某项权限，对应页面可能会返回 `401` 或权限错误。
