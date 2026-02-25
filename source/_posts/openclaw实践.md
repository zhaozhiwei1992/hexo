---
title: "openclaw实践"
date: "2026-02-25"
updated: "2026-02-25"
tags: [penclaw、AI]
categories: penclaw、AI
---

# 什么是openclaw以及能做什么

OpenClaw（曾用名：Clawdbot、Moltbot），一款可以部署在个人电脑上的AI代理，采用"龙虾"图标设计，slogan是"The
AI that actually does things"，由程序员彼得·斯坦伯格开发。

个人主要关注它能够关联telegram，飞书等作为客户端，这样能够很方便的通过移动端来进行控制。它本身权限也足够，理论上可以在个人电脑操作一切，一些运维工作，文档处理，聊天，邮件等都可以进行处理。但是一定要注意安全性，安全性，安全性。

# 准备工作

## 环境准备

``` {.bash org-language="sh"}
# node版本要在22+, 为了避免环境依赖，并且本地存在多个node版本，可以考虑用nvm来管理
nvm use 22.14.0

# 操作系统
archlinux
```

## apikey

我这里使用的是智谱的那个code plan,
glm4.7，多说一句，这个plan只支持部分工具，包括claude code, openclaw,
cline等，不能直接在dify等工作流使用的，一定要注意，按需选择。

## 清理

如果之前安装过但是没成功，最好先备份配置目录，然后全部删除，防止影响。

# 安装

目前其实存在两个版本，如果不纠结英文可以用原版，或者可以考虑中文版本。

## 安装配置

``` {.bash org-language="sh"}
1. install
  pnpm add -g openclaw@latest
2. Run the onboarding wizard
  openclaw onboard --install-daemon
```

## 快速开始引导

快速开始保持默认设置：

本地网关（回环） 工作区默认设置（或现有工作区） 网关端口 18789
网关认证令牌（自动生成，即使是回环） Tailscale 暴露关闭 Telegram +
WhatsApp 私信默认为白名单（这里第一次可以先不配置,
如果需要可以看对接telegram配置部分）

配置模型key

## 检查网关

``` {.bash org-language="sh"}
如果您安装了服务，它应该已经在运行：
openclaw gateway status
```

## 界面访问

``` {.bash org-language="sh"}
# 国内版
openclaw-cn dashboard --no-open |xclip -selection c

# linux下使用下述命令会生成一个url, 直接浏览器访问即可, windows下可以直接查看openclaw.json配置文件中的token
openclaw dashboard --no-open |xclip -selection c

http://127.0.0.1:18789/?token=58bfd507741fae2e3ee10aaab291c5d1765aae0a731f2b5b
```

此时在界面上发一个简单的测试，正常有回复即表示成功。后续怎么使用就看个人发挥了。

# 常用操作

## 检查网关

``` {.bash org-language="sh"}
openclaw gateway status
```

## 重启网关

openclaw gateway restart

## 更新(国内版)

有坑，国内版升级1.6.0直接噶了。 npm i -g openclaw-cn@latest
--registry=<https://registry.npmmirror.com> && openclaw-cn doctor &&
openclaw-cn gateway restart

# 配置文件(重要)

\~/.openclaw/openclaw.json

# 对接telegram

通过telegram作为openclaw的前端，可以远程通过telegram查看一些本地内容。比如查看自己的待办事项，添加一些小想法。甚至如果是开发人员，都可以用手机来控制电脑写代码。

默认使用长轮询；如果有公网更推荐使用webhook来处理。

## 创建机器人

1.  打开 Telegram 并与 \@BotFather对话。确认用户名确实是 \@BotFather。
2.  运行 /newbot，然后按照提示操作（名称 + 以 bot 结尾的用户名）。
3.  复制 token 并安全保存。

## 设置 token

环境变量：TELEGRAM_BOT_TOKEN=... 或配置：channels.telegram.botToken:
\"...\"。

## 重启 Gateway 网关

私信访问默认使用配对模式；首次联系时需要批准配对码。

## 最小配置

``` yml
{
  channels: {
    telegram: {
      enabled: true,
      botToken: "123:abc",
      dmPolicy: "pairing",
      "proxy": "http://10.11.12.164:7890" # 注意这里如果环境不允许，需要增加一个属性，否则一直无法给telegram发消息。
    },
  },
}​

```

## 生成配对码

在telgram机器人选择start,首次访问会生成配对码

``` example
OpenClaw: access not configured.

Your Telegram user id: xxxx6

Pairing code: XGxxxkxj

Ask the bot owner to approve with:
openclaw pairing approve telegram XGxxxkxj
```

## 使用openclaw进行配对

openclaw pairing list telegram

openclaw pairing approve telegram XGxxxkxj

## 使用

此时就可以直接通过telegram给openclaw下达指令了，可以先发一个
测试，等待能够正常回复即可。

# 其它使用场景

## 管理邮件gmail

生成一些脚本，做一些邮件之类的清理工作。这个用claudecode也行，后续可以不通过openclaw触发。

## 待续

# 问题处理

## Webchat UI fails to authenticate: \'gateway token missing\' even with token in URL #1690

``` example
使用命令行获取带令牌的链接
在终端中运行以下命令：
openclaw-cn dashboard --no-open
此命令会：
自动生成带令牌的仪表板链接
将链接复制到剪贴板
显示链接但不会自动打开浏览器
然后复制输出的链接并在浏览器中打开，即可自动带令牌访问 Web 页面。
```

# 参考

<https://clawd.org.cn/gateway/token-mismatch-troubleshooting>

<https://clawd.org.cn/>

<https://github.com/openclaw/openclaw>
