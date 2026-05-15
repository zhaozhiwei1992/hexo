---
title: "腾讯云SSL证书自动续期"
date: "2025-09-25"
updated: "2025-09-25"
tags: [ECS,SSL]
categories: [SSL,证书,ECS,腾讯云]
---

# 前言
之前ssl证书都是一年有效期，现在三个月就得重新申请一次，涉及申请证书，下载，上传到服务器，重启nginx。事不过三，一个事情重复多次，那就得让他自动化处理。

需要的功能如下:
1. 能够判断证书到期时间并自动申请证书。
2. 能够将证书自动上传到服务器并自动重启nginx。
3. 能白嫖就白嫖，免费证书也很香。
4. 工具要操作简单，部署和使用都要简单。

基于以上几点，最终选择了certd这个开源工具。既然能用到这个，相信大家已经有一定的技术基础，对docker等就不单独介绍了。
# certd介绍
Certd是一个免费的全自动证书管理系统，让你的网站证书永不过期。下边是官方的一些介绍:

1. 全自动申请证书（支持所有注册商注册的域名，支持DNS-01、HTTP-01、CNAME代理等多种域名验证方式）
2. 全自动部署更新证书（目前支持部署到主机、阿里云、腾讯云等70+部署插件）
3. 支持通配符域名/泛域名，支持多个域名打到一个证书上，支持pem、pfx、der、jks等多种证书格式
4. 邮件通知、webhook通知、企微、钉钉、飞书、anpush等多种通知方式
5. 私有化部署，数据保存本地，安装简单快捷，镜像由Github Actions构建，过程公开透明
6. 授权加密，站点隐藏，2FA，密码防爆破等多重安全保障
7. 支持SQLite，PostgreSQL、MySQL多种数据库
8. 开放接口支持
9. 站点证书监控
10. 多用户管理
11. 多语言支持（中英双语切换）
12. 各版本向下兼容，一键无忧升级
# certd部署(docker方式)
## 环境准备
一台云服务器,并且已经安装好docker。我这里部署和使用是一台机器。一定要开放7001、7002端口，可以只开一个，用于certd访问。
![](https://19921514.xyz/fb/api/public/dl/3kDTYR8d/certd/images/001.png?inline=true)
![](https://19921514.xyz/fb/api/public/dl/3kDTYR8d/certd/images/002.png?inline=true)
## 部署
1. 下载: wget https://gitee.com/certd/certd/raw/v2/docker/run/docker-compose.yaml
2. 启动: docker-compose up -d
## 测试
```
http://your_server_ip:7001
https://your_server_ip:7002
默认账号密码：admin/123456
记得修改密码、记得修改密码、记得修改密码
```
# 创建流水线
## 目标
```
申请证书->部署证书->设置定时执行->设置邮件通知
```
## 准备工作
1. 已部署CertD服务（可官方Demo自助注册体验 https://certd.handfree.work/ ）
2. 注册一个域名（腾讯云DnsPod），既然都要自动续期了，肯定已经有域名了。
3. 准备好以上DNS解析服务商的AccessKey 和 AccessSecret
![](https://19921514.xyz/fb/api/public/dl/3kDTYR8d/certd/images/003.png?inline=true)
![](https://19921514.xyz/fb/api/public/dl/3kDTYR8d/certd/images/004.png?inline=true)
## 自动化流水线创建
1. 创建证书申请部署流水线
![](https://19921514.xyz/fb/api/public/dl/3kDTYR8d/certd/images/005.png?inline=true)
![](https://19921514.xyz/fb/api/public/dl/3kDTYR8d/certd/images/006.png?inline=true)
![](https://19921514.xyz/fb/api/public/dl/3kDTYR8d/certd/images/00601.png?inline=true)
2. 流水线详情
到这一步申请证书就已经配置完成了。 点击手动触发，就可以申请证书了。下边是申请证书的日志输出信息。
![](https://19921514.xyz/fb/api/public/dl/3kDTYR8d/certd/images/007.png?inline=true)
3. 添加部署到服务器主机任务
![](https://19921514.xyz/fb/api/public/dl/3kDTYR8d/certd/images/008.png?inline=true)
![](https://19921514.xyz/fb/api/public/dl/3kDTYR8d/certd/images/009.png?inline=true)
![](https://19921514.xyz/fb/api/public/dl/3kDTYR8d/certd/images/00901.png?inline=true)
4. 手动触发执行任务，测试一下
点击任务可以查看状态和日志，此时证书已经正确部署到服务器。
![](https://19921514.xyz/fb/api/public/dl/3kDTYR8d/certd/images/010.png?inline=true)
5. 查看证书到期时间
![](https://19921514.xyz/fb/api/public/dl/3kDTYR8d/certd/images/011.png?inline=true)
# 使用定时任务
配置定时触发，以后每天定时执行
cron格式，例如： 0 19 1 * * * 表示每天凌晨1点19执行
到期前35天会自动申请新证书并部署，没到期前不会重复申请
![](https://19921514.xyz/fb/api/public/dl/3kDTYR8d/certd/images/012.png?inline=true)
