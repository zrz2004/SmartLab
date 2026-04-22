# SmartLab

SmartLab 是一个面向高校实验室的安全监测与预警系统，前端使用 Flutter，后端使用 Node.js/Express，数据落在 PostgreSQL，并通过 NocoDB 存储图片取证记录。当前版本重点围绕“无实时传感器条件下的 AI 图像巡检”构建学生上传、教师复核、管理员配置、危化品管理和告警联动闭环。

## 功能概览

- 实验室登录、注册申请、权限分级与实验室切换
- 两个实验室场景：
  - 院楼806实验室
  - 西学楼一楼信科实验室
- AI 图像取证与安全分析：
  - 环境
  - 电源
  - 安防水路
  - 危化品
- AI 告警中心、显眼弹窗提醒、人工复核
- 危化品库存、责任人、联系人、入库、出库、增删改查
- 学生定时上传提醒：
  - 默认 19:00 / 23:00
  - 教师和管理员可修改提醒时间
  - Android 支持后台/被杀/重启后本地通知恢复

## 技术栈

- Flutter 3 / Dart 3
- flutter_bloc
- get_it
- dio
- hive / flutter_secure_storage
- flutter_local_notifications
- Node.js / Express
- PostgreSQL
- NocoDB

## 项目结构

```text
SmartLab/
├── backend/                 # Node.js / Express API
├── database/                # 迁移与种子
├── docs/                    # 项目文档
├── smart_lab/               # Flutter App
└── AGENTS.md                # 项目约束与环境信息
```

## 运行说明

### Flutter

```bash
cd smart_lab
flutter pub get
flutter run
```

Android Release 构建：

```bash
cd smart_lab
flutter build apk --release
```

构建产物：

- `smart_lab/build/app/outputs/flutter-apk/app-release.apk`
- `smart_lab/build/app/outputs/flutter-apk/SmartLab.apk`

### 后端

```bash
cd backend
npm install
npm start
```

默认公网 API：

- `http://47.109.158.254:3000/api/v1`

健康检查：

- `http://47.109.158.254:3000/health`

## 数据与部署

- PostgreSQL：保存用户、实验室、告警、设备、危化品、AI 巡检元数据
- NocoDB：保存图片上传记录与人工复核表
- systemd 服务：`smartlab-api`
- 线上目录：`/opt/smartlab-api`

## 当前重点能力

### 1. AI 代替传感器的巡检主链路

学生在规定时段上传实验室现场图片，后端调用视觉模型完成安全分析，生成风险等级、原因、证据和建议动作，并写入告警中心。

### 2. 定时上传提醒

- 仅学生账号收到提醒
- 教师和管理员不弹提醒
- 每个实验室分别维护提醒时间
- 老师/管理员可修改提醒时间并同步到学生设备

### 3. 危化品管理

- 联系人实时编辑并保存到数据库
- 试剂新增、编辑、删除
- 责任人指定
- 入库、出库、日志留痕

## 开发校验

常用命令：

```bash
cd smart_lab
flutter analyze
flutter test
```

## 说明

本仓库当前包含本地开发和线上部署配套改造，建议在提交生产配置前再次检查环境变量、数据库权限和通知权限配置，避免直接暴露真实凭据。
