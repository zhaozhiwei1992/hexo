---
title: "CodeT：一种 Pi-native 的智能体实践方案"
date: "2026-08-04"
updated: "2026-08-04"
tags: [代码生成,Pi]
categories: 开发工具
---

# 项目概述

CodeT 是一个基于 [Pi CodingAgent](https://github.com/earendil-works/pi-coding-agent)构建的、\*\*文本驱动、插件化、渐进演进\*\*的软件工程智能体。

目标不是\"更聪明的 AI\"，而是\"****更可控的工程环境****\"。

CodeT 不是一个项目，也不是一个单体智能体。它是

-   一套工程哲学（Text as Truth / Evolve by Practice）
-   一套 Pi 插件命名与使用约定（codet-\*）
-   一组可独立演进的 Skills + Extensions

# 核心哲学

## 一切皆文本（Text as Truth）

-   \*规范\*： `AGENTS.md`{.verbatim}, `RULES.md`{.verbatim},
    `TODO.md`{.verbatim}, `PLAN.md`{.verbatim}
-   \*代码\*：源码本身就是文本
-   \*记忆\*：不依赖 SQLite / 向量库，只用 Markdown + JSONL
-   \*通信\*：多实例之间通过文件（而非 RPC / 内存）协作
-   \*版本化\*：所有\"智能体产物\"都可 `git diff`{.verbatim}

## 插件化（Pi Extension First）

-   每个能力 = 一个 **Pi Extension** + **Skill**
-   不修改 Pi 内核
-   有现成开源插件 → 直接用
-   没有 → 自己写 Skill（Markdown）+ Extension（TypeScript）,
    skill是内核, TypeScript内部直接调用
    pi.sendUserMessage(\"/skill:pi-init\")
-   插件可独立版本、独立维护

## 渐进式智能体（Evolve by Practice）

-   不做\"大而全\"的智能体
-   从 `/init`{.verbatim} 开始
-   在实际项目中用 → 踩坑 → 提炼规则 → 固化到插件
-   用 `/omfg`{.verbatim} 式机制把 Bad Case 变成规则

## AI 参与开发（AI-Assisted Construction）

-   CodeT 本身由 Pi 编写
-   每个新命令、Skill、工具，都由 Pi 生成初稿
-   人工 review → 修正 → 提交
-   变更同步写入 =AGENTS.md=，形成闭环

# 调度边界（非常重要）

CodeT 严格遵守以下边界：

-   Pi 负责：
    -   命令解析
    -   Skill / Extension 路由
    -   工具调用决策
    -   上下文管理
    -   多轮对话编排
-   CodeT 负责：
    -   定义命令语义
    -   提供 Skill（提示词）
    -   提供 Extension（工具封装）
    -   维护 AGENTS.md / RULES.md

CodeT 永远不会：

-   实现命令间调用链
-   管理会话状态
-   编排子 Agent
-   接管 Pi 的调度权

# 失败边界

CodeT 遵循"显式失败"原则：

-   任何命令失败时：
    -   不重试
    -   不自动回滚
    -   不隐藏错误
-   错误信息直接写入：
    -   终端输出
    -   或 STATUS.md
-   修复策略由人、或后续 Pi 会话决定

# 核心能力组成

## Context Loader（上下文加载）

### 职责

-   从 cwd 向上递归查找：
    -   `AGENTS.md`{.verbatim}
    -   `RULES.md`{.verbatim}
    -   `SYSTEM.md`{.verbatim} （可选）
-   按优先级合并
-   在会话开始时自动注入系统提示

### 设计约束

-   不缓存解析结果（每次启动重新扫描）
-   不引入数据库
-   支持全局（ `~/.pi/agent/`{.verbatim} ）+ 项目级（ `./`{.verbatim} ）

## Slash Commands（命令系统）

所有命令均以 `/xxx`{.verbatim} 形式存在，由 Pi 负责解析与调度，本质是
\*Prompt Template + 工具调用\*。

### 以/init为例

  命令                 作用                             形式
  -------------------- -------------------------------- -------------------------------
  `/init`{.verbatim}   初始化陌生项目，生成 AGENTS.md   Skill（MD） + Extension（TS）

`/init`{.verbatim} 已落地为
Skill（=skills/pi-init/SKILL.md=，见=codet-pi-init= 包），由模型用
bash/read/write 工具扫描项目并写 `AGENTS.md`{.verbatim} ------完全
Pi-native，逻辑活在文本资产里。另外保留一个\*\*薄 Extension
桥接\*\*，让在 Pi 中可用 `/init`{.verbatim} 入口（内部
`pi.sendUserMessage("/skill:pi-init ...")=），因为 Pi 的 Skill 命令固定为 =/skill:<name>`{.verbatim}
前缀；薄桥接仅为命名友好，不做扫描/生成。离线兜底：=/init --template
\[\<path\>\]= 用模板占位符（={{LANGUAGE}}=
等）确定性生成。模板可自由改文本，不需要改代码。

## Skill System（提示词资产）

-   每个 Skill = 一个目录 + `SKILL.md`{.verbatim}
-   Skill 可被 Pi 自动发现
-   Skill 内容：
    -   角色设定
    -   约束条件
    -   输出契约
    -   探索维度（模型自主决定顺序）

### 示例目录

``` text
skills/
└── pi-init/
    └── SKILL.md
```

## Multi-Instance Collaboration via tmux（多实例协作）

CodeT 不使用"子 Agent"概念，每个 `pi`{.verbatim}
实例都是平等的、独立的主 Agent。

-   用 tmux pane 启动多个 `pi`{.verbatim}
-   通过共享文件协作：
    -   `PLAN.md`{.verbatim}
    -   `TODO.md`{.verbatim}
    -   `STATUS.md`{.verbatim}
-   每个实例职责明确（backend / frontend / scripts）

### 约定优于机制

-   不写编排引擎
-   只在 `AGENTS.md`{.verbatim} 中写明协作约定

# 技术选型

## 运行时

-   Pi Coding Agent（宿主）
-   Node.js \>= 20（Extension 运行环境）
-   TypeScript（Extension 开发语言）
-   tmux（多实例编排）

## 文本格式

-   Markdown（规范、计划、待办、规则）
-   Org-mode（本设计文档及后续架构文档）
-   JSONL（会话日志，可选）

## 版本控制

-   Git（所有文本产物的版本化）
-   分支策略：feature/\* → develop → main

# 反模式清单（Anti-Patterns）

以下做法\*明确禁止\*，因为它们破坏\"一切皆文本\"的初心：

-   引入 SQLite / 向量数据库存储记忆或规则
-   用 TS 运行时状态保存会话上下文（应使用文件）
-   内置子 Agent 线程调度（应使用 tmux + 文件约定）
-   用 bitmap / 二进制格式做上下文压缩（应生成文本摘要）
-   用 hashline / 二进制 patch 做编辑校验（应 `git diff`{.verbatim} +
    `lint`{.verbatim} ）
-   把规范藏进数据库而非 `AGENTS.md`{.verbatim}

