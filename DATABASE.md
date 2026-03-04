# SmartLab 数据库设计文档

本文档详细说明智慧实验室安全监测与预警系统的数据库设计，包括远程数据库（PostgreSQL）、本地存储（Hive/SQLite）、以及缓存策略等所有数据层相关内容。

---

## 目录

1. [数据库架构概述](#数据库架构概述)
2. [服务器配置](#服务器配置)
3. [PostgreSQL 远程数据库](#postgresql-远程数据库)
4. [本地存储设计](#本地存储设计)
5. [数据模型详解](#数据模型详解)
6. [API 数据交互](#api-数据交互)
7. [MQTT 实时数据](#mqtt-实时数据)
8. [缓存策略](#缓存策略)
9. [数据安全](#数据安全)
10. [数据同步机制](#数据同步机制)

---

## 数据库架构概述

SmartLab 采用**混合存储架构**，结合远程数据库和本地存储，支持离线使用和实时数据同步：

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Flutter 应用层                               │
└─────────────────────┬───────────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────────┐
│                        数据层 (Data Layer)                           │
│  ┌─────────────┐   ┌─────────────────┐   ┌─────────────────────┐   │
│  │  远程数据源  │   │   本地数据源     │   │     缓存管理        │   │
│  │ (Dio/REST)  │   │ (Hive/SQLite)   │   │   (内存/文件)        │   │
│  └──────┬──────┘   └────────┬────────┘   └──────────┬──────────┘   │
└─────────┼──────────────────┼───────────────────────┼───────────────┘
          │                  │                       │
          ▼                  ▼                       ▼
┌─────────────────┐  ┌─────────────────┐   ┌─────────────────────────┐
│   PostgreSQL    │  │   本地 SQLite   │   │      Hive Box          │
│   (47.109.x.x)  │  │   (可选备份)    │   │  (轻量数据/设置)        │
└─────────────────┘  └─────────────────┘   └─────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        MQTT Broker (EMQX)                            │
│                     实时遥测数据 & 报警推送                           │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 服务器配置

### 生产环境配置

| 服务 | 地址 | 端口 | 说明 |
|------|------|------|------|
| **API 服务** | 47.109.158.254 | 3000 | Node.js/Express 后端 RESTful API |
| **PostgreSQL** | 47.109.158.254 | 5433 | 主数据库（非标准端口） |
| **MQTT Broker** | 47.109.158.254 | 1883 | EMQX（待部署，非 TLS） |

### API 基础配置

```dart
// 位置: lib/core/services/api_service.dart

static const String _baseUrl = 'http://47.109.158.254:3000/api/v1';
static const Duration _timeout = Duration(seconds: 30);
```

### 连接参数

| 参数 | 值 | 说明 |
|------|------|------|
| 连接超时 | 30 秒 | HTTP 请求连接超时 |
| 接收超时 | 30 秒 | HTTP 响应接收超时 |
| 内容类型 | application/json | 请求/响应格式 |
| 认证方式 | Bearer Token | JWT 令牌认证 |

---

## PostgreSQL 远程数据库

### 数据库连接信息

```
Host: 47.109.158.254
Port: 5433
Database: smartlab (推测)
User: 通过 API 访问（不直连）
```

> **注意**: Flutter 客户端不直接连接 PostgreSQL，通过 REST API 进行数据交互。

### 核心数据表设计

#### 1. 用户表 (users)

```sql
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username        VARCHAR(50) UNIQUE NOT NULL,      -- 学号/工号
    password_hash   VARCHAR(255) NOT NULL,            -- 密码哈希
    name            VARCHAR(100) NOT NULL,            -- 真实姓名
    role            VARCHAR(20) NOT NULL,             -- 角色: teacher/graduate/undergraduate
    department      VARCHAR(100),                     -- 所属院系
    phone           VARCHAR(20),                      -- 联系电话
    email           VARCHAR(100),                     -- 邮箱
    avatar_url      VARCHAR(255),                     -- 头像URL
    is_active       BOOLEAN DEFAULT TRUE,             -- 账户状态
    last_login_at   TIMESTAMP,                        -- 最后登录时间
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 索引
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_role ON users(role);
```

**字段说明**:
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | UUID | ✓ | 用户唯一标识 |
| username | VARCHAR(50) | ✓ | 登录账号（学号/工号） |
| password_hash | VARCHAR(255) | ✓ | BCrypt 加密的密码 |
| name | VARCHAR(100) | ✓ | 用户真实姓名 |
| role | VARCHAR(20) | ✓ | 用户角色 |
| department | VARCHAR(100) | | 所属院系/部门 |
| phone | VARCHAR(20) | | 手机号码 |
| email | VARCHAR(100) | | 电子邮箱 |
| avatar_url | VARCHAR(255) | | 头像图片URL |
| is_active | BOOLEAN | ✓ | 是否激活（默认true） |
| last_login_at | TIMESTAMP | | 最近登录时间 |
| created_at | TIMESTAMP | ✓ | 创建时间 |
| updated_at | TIMESTAMP | ✓ | 更新时间 |

**角色枚举值**:
- `admin` - 系统管理员
- `teacher` - 教师/实验室负责人
- `graduate` - 研究生
- `undergraduate` - 本科生助理

---

#### 2. 实验室表 (labs)

```sql
CREATE TABLE labs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(100) NOT NULL,            -- 实验室名称
    building_id     UUID NOT NULL,                    -- 所属建筑ID
    building_name   VARCHAR(100) NOT NULL,            -- 建筑名称
    floor           VARCHAR(20) NOT NULL,             -- 楼层
    room_number     VARCHAR(20) NOT NULL,             -- 房间号
    type            VARCHAR(50) NOT NULL,             -- 实验室类型
    manager_id      UUID REFERENCES users(id),        -- 负责人ID
    description     TEXT,                             -- 描述
    area_sqm        DECIMAL(10,2),                    -- 面积(平方米)
    capacity        INTEGER,                          -- 容纳人数
    status          VARCHAR(20) DEFAULT 'normal',     -- 状态
    safety_score    INTEGER DEFAULT 100,              -- 安全评分 0-100
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 索引
CREATE INDEX idx_labs_building ON labs(building_id);
CREATE INDEX idx_labs_manager ON labs(manager_id);
CREATE INDEX idx_labs_status ON labs(status);
```

**字段说明**:
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | UUID | ✓ | 实验室唯一标识 |
| name | VARCHAR(100) | ✓ | 实验室名称（如：院楼806） |
| building_id | UUID | ✓ | 关联建筑物ID |
| building_name | VARCHAR(100) | ✓ | 建筑物名称（冗余，便于查询） |
| floor | VARCHAR(20) | ✓ | 楼层（如：8F、1F） |
| room_number | VARCHAR(20) | ✓ | 房间号（如：806） |
| type | VARCHAR(50) | ✓ | 实验室类型 |
| manager_id | UUID | | 外键关联用户表 |
| description | TEXT | | 实验室描述 |
| area_sqm | DECIMAL | | 面积（平方米） |
| capacity | INTEGER | | 最大容纳人数 |
| status | VARCHAR(20) | ✓ | 当前状态 |
| safety_score | INTEGER | ✓ | 安全评分 (0-100) |
| created_at | TIMESTAMP | ✓ | 创建时间 |
| updated_at | TIMESTAMP | ✓ | 更新时间 |

**实验室类型枚举** (type):
- `chemistry` - 化学实验室
- `physics` - 物理实验室
- `biology` - 生物实验室
- `electronics` - 电子实验室
- `computer` - 计算机实验室
- `general` - 通用实验室

**状态枚举** (status):
- `normal` - 正常运行
- `warning` - 预警状态
- `alert` - 报警状态
- `offline` - 离线/停用
- `maintenance` - 维护中

---

#### 3. 建筑物表 (buildings)

```sql
CREATE TABLE buildings (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(100) NOT NULL,            -- 建筑名称
    code            VARCHAR(20) UNIQUE NOT NULL,      -- 建筑代码
    address         VARCHAR(255),                     -- 地址
    floors          INTEGER,                          -- 楼层数
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**字段说明**:
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | UUID | ✓ | 建筑物唯一标识 |
| name | VARCHAR(100) | ✓ | 建筑物名称（如：院楼、西学楼） |
| code | VARCHAR(20) | ✓ | 建筑物代码（唯一） |
| address | VARCHAR(255) | | 详细地址 |
| floors | INTEGER | | 总楼层数 |
| created_at | TIMESTAMP | ✓ | 创建时间 |

---

#### 4. 设备表 (devices)

```sql
CREATE TABLE devices (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(100) NOT NULL,            -- 设备名称
    type            VARCHAR(50) NOT NULL,             -- 设备类型
    model           VARCHAR(100),                     -- 设备型号
    serial_number   VARCHAR(100) UNIQUE,              -- 序列号
    lab_id          UUID NOT NULL REFERENCES labs(id),-- 所属实验室
    position        VARCHAR(100),                     -- 安装位置描述
    building_id     UUID NOT NULL,                    -- 建筑ID(MQTT主题用)
    room_id         VARCHAR(50) NOT NULL,             -- 房间ID(MQTT主题用)
    status          VARCHAR(20) DEFAULT 'offline',    -- 设备状态
    last_online_at  TIMESTAMP,                        -- 最后在线时间
    firmware_version VARCHAR(50),                     -- 固件版本
    metadata        JSONB,                            -- 扩展属性
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 索引
CREATE INDEX idx_devices_lab ON devices(lab_id);
CREATE INDEX idx_devices_type ON devices(type);
CREATE INDEX idx_devices_status ON devices(status);
CREATE INDEX idx_devices_building_room ON devices(building_id, room_id);
```

**字段说明**:
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | UUID | ✓ | 设备唯一标识 |
| name | VARCHAR(100) | ✓ | 设备名称 |
| type | VARCHAR(50) | ✓ | 设备类型代码 |
| model | VARCHAR(100) | | 设备型号 |
| serial_number | VARCHAR(100) | | 设备序列号（唯一） |
| lab_id | UUID | ✓ | 外键关联实验室 |
| position | VARCHAR(100) | | 安装位置描述 |
| building_id | UUID | ✓ | 建筑ID（用于MQTT主题） |
| room_id | VARCHAR(50) | ✓ | 房间ID（用于MQTT主题） |
| status | VARCHAR(20) | ✓ | 设备状态 |
| last_online_at | TIMESTAMP | | 最后在线时间 |
| firmware_version | VARCHAR(50) | | 固件版本号 |
| metadata | JSONB | | JSON格式扩展数据 |
| created_at | TIMESTAMP | ✓ | 创建时间 |
| updated_at | TIMESTAMP | ✓ | 更新时间 |

**设备类型枚举** (type):
| 类型代码 | 说明 | 监测数据 |
|----------|------|----------|
| `environmentSensor` | 环境传感器 | 温度、湿度、VOC、PM2.5 |
| `powerMonitor` | 电源监测模块 | 电压、电流、功率、漏电流 |
| `smartSocket` | 智能插座 | 功率、开关状态 |
| `smartBreaker` | 智能断路器 | 电流、跳闸状态 |
| `waterSensor` | 水浸传感器 | 水浸检测 |
| `flowMeter` | 流量计 | 水流量 |
| `electroValve` | 电磁阀 | 开关状态 |
| `doorSensor` | 门磁传感器 | 门开关状态 |
| `windowSensor` | 窗磁传感器 | 窗开关状态 |
| `pirSensor` | 红外传感器 | 人体感应 |
| `rfidReader` | RFID读写器 | 标签读取 |
| `camera` | 摄像头 | 视频流 |
| `gateway` | 物联网网关 | 通信中转 |

**设备状态枚举** (status):
- `online` - 在线正常
- `offline` - 离线
- `warning` - 预警状态
- `error` - 故障状态

---

#### 5. 遥测数据表 (telemetry)

```sql
CREATE TABLE telemetry (
    id              BIGSERIAL PRIMARY KEY,
    device_id       UUID NOT NULL REFERENCES devices(id),
    device_type     VARCHAR(50) NOT NULL,             -- 设备类型(冗余)
    values          JSONB NOT NULL,                   -- 传感器数值
    status          VARCHAR(20) DEFAULT 'online',     -- 数据状态
    timestamp       TIMESTAMP NOT NULL,               -- 采集时间
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 时序数据索引（按设备和时间查询）
CREATE INDEX idx_telemetry_device_time ON telemetry(device_id, timestamp DESC);
CREATE INDEX idx_telemetry_timestamp ON telemetry(timestamp DESC);

-- 分区表（按月分区，提高查询性能）
-- CREATE TABLE telemetry_2024_01 PARTITION OF telemetry
--     FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
```

**字段说明**:
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | BIGSERIAL | ✓ | 自增主键 |
| device_id | UUID | ✓ | 关联设备ID |
| device_type | VARCHAR(50) | ✓ | 设备类型（冗余提高查询效率） |
| values | JSONB | ✓ | 传感器数值（JSON格式） |
| status | VARCHAR(20) | ✓ | 数据状态 |
| timestamp | TIMESTAMP | ✓ | 数据采集时间 |
| created_at | TIMESTAMP | ✓ | 记录创建时间 |

**values 字段示例** (按设备类型):

**环境传感器**:
```json
{
  "temperature": 24.5,
  "humidity": 45.2,
  "voc_index": 120,
  "pm25": 28.5,
  "co2": 450
}
```

**电源监测模块**:
```json
{
  "voltage": 220.5,
  "current": 5.2,
  "power": 1145.6,
  "power_factor": 0.98,
  "leakage_current": 2.5,
  "frequency": 50.0
}
```

**水浸传感器**:
```json
{
  "water_detected": false,
  "moisture_level": 15
}
```

**门磁传感器**:
```json
{
  "is_open": false,
  "battery_level": 85
}
```

---

#### 6. 报警表 (alerts)

```sql
CREATE TABLE alerts (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type            VARCHAR(50) NOT NULL,             -- 报警类型
    level           VARCHAR(20) NOT NULL,             -- 报警级别
    title           VARCHAR(200) NOT NULL,            -- 报警标题
    message         TEXT NOT NULL,                    -- 报警详情
    device_id       UUID REFERENCES devices(id),      -- 关联设备
    device_name     VARCHAR(100),                     -- 设备名称(冗余)
    lab_id          UUID REFERENCES labs(id),         -- 关联实验室
    building_id     UUID,                             -- 建筑ID
    room_id         VARCHAR(50),                      -- 房间ID
    snapshot        JSONB,                            -- 报警时刻数据快照
    is_acknowledged BOOLEAN DEFAULT FALSE,            -- 是否已确认
    acknowledged_at TIMESTAMP,                        -- 确认时间
    acknowledged_by UUID REFERENCES users(id),        -- 确认人
    resolved_at     TIMESTAMP,                        -- 解决时间
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 索引
CREATE INDEX idx_alerts_level ON alerts(level);
CREATE INDEX idx_alerts_device ON alerts(device_id);
CREATE INDEX idx_alerts_lab ON alerts(lab_id);
CREATE INDEX idx_alerts_acknowledged ON alerts(is_acknowledged);
CREATE INDEX idx_alerts_created ON alerts(created_at DESC);
```

**字段说明**:
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | UUID | ✓ | 报警唯一标识 |
| type | VARCHAR(50) | ✓ | 报警类型代码 |
| level | VARCHAR(20) | ✓ | 报警级别 |
| title | VARCHAR(200) | ✓ | 报警标题 |
| message | TEXT | ✓ | 报警详细信息 |
| device_id | UUID | | 触发报警的设备 |
| device_name | VARCHAR(100) | | 设备名称（冗余） |
| lab_id | UUID | | 关联实验室 |
| building_id | UUID | | 建筑ID |
| room_id | VARCHAR(50) | | 房间ID |
| snapshot | JSONB | | 报警时刻的数据快照 |
| is_acknowledged | BOOLEAN | ✓ | 是否已确认处理 |
| acknowledged_at | TIMESTAMP | | 确认处理时间 |
| acknowledged_by | UUID | | 确认处理人 |
| resolved_at | TIMESTAMP | | 问题解决时间 |
| created_at | TIMESTAMP | ✓ | 报警创建时间 |

**报警类型枚举** (type):
| 类型代码 | 说明 | 级别 |
|----------|------|------|
| `temperatureHigh` | 温度过高 | warning/critical |
| `temperatureLow` | 温度过低 | warning/critical |
| `humidityHigh` | 湿度过高 | warning |
| `humidityLow` | 湿度过低 | warning |
| `vocHigh` | VOC超标 | warning/critical |
| `gasLeak` | 气体泄漏 | critical |
| `powerOverload` | 功率过载 | warning/critical |
| `leakageCurrent` | 漏电检测 | critical |
| `arcFault` | 电弧故障 | critical |
| `voltageAbnormal` | 电压异常 | warning |
| `waterLeak` | 水浸报警 | critical |
| `tapForgotten` | 水龙头未关 | warning |
| `doorUnlocked` | 门禁未锁 | warning |
| `windowOpen` | 窗户开启 | info |
| `intrusion` | 入侵检测 | critical |
| `chemicalMissing` | 试剂丢失 | critical |
| `chemicalExpired` | 试剂过期 | warning |
| `chemicalIncompatible` | 存储违规 | critical |
| `unauthorizedAccess` | 非法领用 | critical |
| `deviceOffline` | 设备离线 | warning |
| `deviceError` | 设备故障 | warning |
| `batteryLow` | 电池电量低 | info |

**报警级别枚举** (level):
| 级别 | 说明 | 处理要求 |
|------|------|----------|
| `critical` | 紧急 | 需立即处理，推送通知 |
| `warning` | 预警 | 需关注，24小时内处理 |
| `info` | 信息 | 提醒类，无需立即处理 |

---

#### 7. 危化品表 (chemicals)

```sql
CREATE TABLE chemicals (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rfid_tag        VARCHAR(50) UNIQUE NOT NULL,      -- RFID标签
    name            VARCHAR(200) NOT NULL,            -- 化学品名称
    cas_number      VARCHAR(50),                      -- CAS 登记号
    specification   VARCHAR(100),                     -- 规格
    quantity        DECIMAL(10,2) NOT NULL,           -- 数量
    unit            VARCHAR(20) NOT NULL,             -- 单位
    expiry_date     DATE NOT NULL,                    -- 有效期
    cabinet_id      UUID NOT NULL,                    -- 所属柜子ID
    status          VARCHAR(20) DEFAULT 'normal',     -- 状态
    hazard_class    VARCHAR(50) NOT NULL,             -- 危险等级
    incompatible_with TEXT[],                         -- 不相容物质
    msds_url        VARCHAR(255),                     -- MSDS文档链接
    emergency_procedure TEXT,                         -- 应急处置程序
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 索引
CREATE INDEX idx_chemicals_rfid ON chemicals(rfid_tag);
CREATE INDEX idx_chemicals_cabinet ON chemicals(cabinet_id);
CREATE INDEX idx_chemicals_status ON chemicals(status);
CREATE INDEX idx_chemicals_expiry ON chemicals(expiry_date);
```

**字段说明**:
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | UUID | ✓ | 化学品唯一标识 |
| rfid_tag | VARCHAR(50) | ✓ | RFID标签号（唯一） |
| name | VARCHAR(200) | ✓ | 化学品名称 |
| cas_number | VARCHAR(50) | | CAS化学品登记号 |
| specification | VARCHAR(100) | | 规格（如：500mL、AR级） |
| quantity | DECIMAL | ✓ | 当前数量 |
| unit | VARCHAR(20) | ✓ | 计量单位 |
| expiry_date | DATE | ✓ | 有效期截止日期 |
| cabinet_id | UUID | ✓ | 存放柜子ID |
| status | VARCHAR(20) | ✓ | 当前状态 |
| hazard_class | VARCHAR(50) | ✓ | 危险分类（GHS标准） |
| incompatible_with | TEXT[] | | 不相容化学品列表 |
| msds_url | VARCHAR(255) | | MSDS安全数据表链接 |
| emergency_procedure | TEXT | | 泄漏/误触应急处理流程 |
| created_at | TIMESTAMP | ✓ | 创建时间 |
| updated_at | TIMESTAMP | ✓ | 更新时间 |

**危化品状态枚举** (status):
- `normal` - 正常
- `expired` - 已过期
- `expiringSoon` - 即将过期（30天内）
- `missing` - 丢失
- `lowStock` - 库存不足
- `inUse` - 使用中

**危险等级枚举** (hazard_class - GHS标准):
| 代码 | 说明 | GHS图标 |
|------|------|---------|
| `explosive` | 爆炸物 | GHS01 |
| `flammable` | 易燃物 | GHS02 |
| `oxidizer` | 氧化剂 | GHS03 |
| `compressedGas` | 压缩气体 | GHS04 |
| `corrosive` | 腐蚀性 | GHS05 |
| `toxic` | 急性毒性 | GHS06 |
| `irritant` | 刺激性/致敏 | GHS07 |
| `healthHazard` | 健康危害 | GHS08 |
| `environmental` | 环境危害 | GHS09 |
| `nonHazardous` | 非危险品 | - |

---

#### 8. 危化品柜表 (chemical_cabinets)

```sql
CREATE TABLE chemical_cabinets (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(100) NOT NULL,            -- 柜子名称
    lab_id          UUID NOT NULL REFERENCES labs(id),-- 所属实验室
    rfid_reader_id  UUID REFERENCES devices(id),      -- 关联RFID读写器
    capacity        INTEGER,                          -- 最大容量
    current_count   INTEGER DEFAULT 0,                -- 当前存量
    allowed_classes TEXT[],                           -- 允许存放的危险等级
    last_scan_at    TIMESTAMP,                        -- 最后盘点时间
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

#### 9. 危化品操作日志表 (chemical_logs)

```sql
CREATE TABLE chemical_logs (
    id              BIGSERIAL PRIMARY KEY,
    chemical_id     UUID NOT NULL REFERENCES chemicals(id),
    action          VARCHAR(20) NOT NULL,             -- 操作类型
    quantity_change DECIMAL(10,2),                    -- 数量变化
    operator_id     UUID REFERENCES users(id),        -- 操作人
    operator_name   VARCHAR(100),                     -- 操作人姓名
    reason          TEXT,                             -- 操作原因
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 索引
CREATE INDEX idx_chem_logs_chemical ON chemical_logs(chemical_id);
CREATE INDEX idx_chem_logs_operator ON chemical_logs(operator_id);
CREATE INDEX idx_chem_logs_created ON chemical_logs(created_at DESC);
```

**操作类型枚举** (action):
- `check_in` - 入库
- `check_out` - 领用
- `return` - 归还
- `dispose` - 处置/报废
- `adjust` - 盘点调整
- `transfer` - 转移

---

#### 10. 用户-实验室关联表 (user_labs)

```sql
CREATE TABLE user_labs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id),
    lab_id          UUID NOT NULL REFERENCES labs(id),
    permission      VARCHAR(20) NOT NULL,             -- 权限级别
    granted_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    granted_by      UUID REFERENCES users(id),
    expires_at      TIMESTAMP,                        -- 权限过期时间
    UNIQUE(user_id, lab_id)
);

-- 索引
CREATE INDEX idx_user_labs_user ON user_labs(user_id);
CREATE INDEX idx_user_labs_lab ON user_labs(lab_id);
```

**权限级别枚举** (permission):
| 级别 | 说明 | 权限范围 |
|------|------|----------|
| `admin` | 管理员 | 完全控制，可授权他人 |
| `manager` | 负责人 | 设备控制、报警处理、查看报表 |
| `operator` | 操作员 | 设备控制、查看数据 |
| `viewer` | 只读 | 仅查看数据 |

---

#### 11. 刷新令牌表 (refresh_tokens)

```sql
CREATE TABLE refresh_tokens (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id),
    token_hash      VARCHAR(255) NOT NULL,            -- Token哈希值
    device_info     VARCHAR(255),                     -- 设备信息
    expires_at      TIMESTAMP NOT NULL,               -- 过期时间
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    revoked_at      TIMESTAMP                         -- 撤销时间
);

-- 索引
CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_expires ON refresh_tokens(expires_at);
```

---

## 本地存储设计

### Hive Box 配置

```dart
// 位置: lib/core/services/local_storage_service.dart

class LocalStorageService {
  // Hive Box 名称定义
  static const String _settingsBox = 'settings';      // 用户设置
  static const String _cacheBox = 'cache';            // 数据缓存
  static const String _alertsBox = 'offline_alerts';  // 离线报警
}
```

#### Box 详细说明

**1. settings Box** - 用户设置存储

| Key | 类型 | 说明 |
|-----|------|------|
| `theme_mode` | String | 主题模式: 'system'/'light'/'dark' |
| `notification_enabled` | bool | 通知开关 |
| `current_lab_id` | String | 当前选中的实验室ID |
| `language` | String | 语言设置 |
| `data_refresh_interval` | int | 数据刷新间隔(秒) |

**2. cache Box** - 数据缓存

缓存条目结构:
```dart
{
  'data': dynamic,                    // 缓存的数据
  'timestamp': int,                   // 缓存时间戳(毫秒)
  'expiry': int?,                     // 过期时长(毫秒)
}
```

常用缓存Key:
| Key | 内容 | TTL |
|-----|------|-----|
| `labs_list` | 实验室列表 | 5分钟 |
| `devices_{labId}` | 设备列表 | 2分钟 |
| `user_profile` | 用户信息 | 30分钟 |
| `latest_telemetry_{deviceId}` | 最新遥测数据 | 1分钟 |

**3. offline_alerts Box** - 离线报警队列

存储离线时产生的报警，等待网络恢复后上传。

---

### Flutter Secure Storage

用于存储敏感数据（加密存储）：

```dart
// 位置: lib/core/services/local_storage_service.dart

final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
);
```

**存储内容**:
| Key | 说明 | 示例 |
|-----|------|------|
| `access_token` | JWT访问令牌 | eyJhbGciOiJIUzI1N... |
| `refresh_token` | 刷新令牌 | rt_abc123... |
| `user_id` | 用户ID | uuid |
| `biometric_key` | 生物识别密钥 | 加密存储 |

---

## 数据模型详解

### 实体类对应关系

| 数据库表 | Dart 实体类 | 文件位置 |
|----------|-------------|----------|
| labs | Lab | `features/dashboard/domain/entities/lab.dart` |
| devices | Device | `features/dashboard/domain/entities/lab.dart` |
| telemetry | SensorData | `features/dashboard/domain/entities/sensor_data.dart` |
| alerts | Alert | `features/alerts/domain/entities/alert.dart` |
| chemicals | Chemical | `features/chemicals/domain/entities/chemical.dart` |

### SensorData 数据结构

```dart
class SensorData extends Equatable {
  final String deviceId;       // 设备ID
  final String deviceType;     // 设备类型
  final String buildingId;     // 建筑ID (MQTT主题用)
  final String roomId;         // 房间ID (MQTT主题用)
  final DateTime timestamp;    // 数据时间戳
  final Map<String, dynamic> values;  // 传感器数值
  final DeviceStatus status;   // 设备状态
}
```

---

## API 数据交互

### API 端点一览

```dart
// 位置: lib/core/constants/api_endpoints.dart

class ApiEndpoints {
  // 认证
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String profile = '/auth/profile';
  
  // 设备管理
  static const String devices = '/devices';
  static const String controlSwitch = '/control/switch';
  
  // 遥测数据
  static const String telemetryHistory = '/telemetry/history';
  static const String telemetryLatest = '/telemetry/latest';
  
  // 危化品管理
  static const String chemicalInventory = '/chemicals/inventory';
  static const String chemicalCabinets = '/chemicals/cabinets';
  static const String chemicalLogs = '/chemicals/logs';
  
  // 报警管理
  static const String alerts = '/alerts';
  static const String alertsStatistics = '/alerts/statistics';
  
  // 实验室管理
  static const String labs = '/labs';
  static const String buildings = '/buildings';
  
  // 用户管理
  static const String users = '/users';
  static const String roles = '/roles';
  
  // 报表
  static const String reports = '/reports';
  static const String energyReport = '/reports/energy';
  static const String complianceReport = '/reports/compliance';
}
```

### 认证流程

```
用户登录:
POST /auth/login
Request:  { "username": "admin", "password": "admin123" }
Response: { "access_token": "...", "refresh_token": "...", "user": {...} }

Token 刷新:
POST /auth/refresh
Request:  { "refresh_token": "..." }
Response: { "access_token": "...", "refresh_token": "..." }
```

---

## MQTT 实时数据

### MQTT 主题设计

```dart
// 位置: lib/core/constants/mqtt_topics.dart

// 主题格式:
// lab/{buildingId}/{roomId}/{deviceType}/{deviceId}/{messageType}

// 示例:
// lab/building_a/806/environment/env_001/telemetry
// lab/building_b/101/power/pwr_001/alert
```

**主题通配符订阅**:
| 主题 | 说明 |
|------|------|
| `lab/+/+/+/+/telemetry` | 所有遥测数据 |
| `lab/+/+/+/+/alert` | 所有报警事件 |
| `lab/+/+/+/+/status` | 所有设备状态 |

### MQTT 消息格式

**遥测数据消息**:
```json
{
  "device_id": "env_001",
  "device_type": "environment",
  "building_id": "building_a",
  "room_id": "806",
  "timestamp": "2024-01-15T10:30:00Z",
  "values": {
    "temperature": 24.5,
    "humidity": 45.2,
    "voc_index": 120
  },
  "status": "online"
}
```

**报警消息**:
```json
{
  "id": "alert_001",
  "type": "temperatureHigh",
  "level": "warning",
  "title": "温度过高",
  "message": "院楼806实验室温度达到27.5°C，超过警告阈值",
  "device_id": "env_001",
  "device_name": "环境传感器-1",
  "room_id": "806",
  "building_id": "building_a",
  "timestamp": "2024-01-15T10:30:00Z",
  "snapshot": {
    "temperature": 27.5,
    "threshold": 27.0
  }
}
```

---

## 缓存策略

### 缓存配置

```dart
// 推荐缓存时长配置

class CacheConfig {
  static const sensorListTTL = Duration(minutes: 5);    // 传感器列表
  static const sensorDetailTTL = Duration(minutes: 2);  // 传感器详情
  static const historyDataTTL = Duration(hours: 1);     // 历史数据
  static const userInfoTTL = Duration(minutes: 30);     // 用户信息
  static const labListTTL = Duration(minutes: 5);       // 实验室列表
}
```

### 缓存策略

| 数据类型 | 策略 | 说明 |
|----------|------|------|
| 实时遥测数据 | 不缓存 | 通过MQTT实时推送 |
| 历史数据 | 缓存1小时 | 历史数据不常变化 |
| 设备列表 | 缓存5分钟 | 定期刷新 |
| 用户信息 | 缓存30分钟 | 登录后缓存 |
| 报警列表 | 不缓存 | 实时性要求高 |

---

## 数据安全

### 敏感数据保护

1. **Token 存储**: 使用 Flutter Secure Storage 加密存储
2. **密码传输**: HTTPS + BCrypt 哈希
3. **API 认证**: JWT Bearer Token
4. **数据库**: PostgreSQL 角色权限控制

### 安全阈值配置

```dart
// 位置: lib/core/constants/safety_thresholds.dart

class SafetyThresholds {
  // 温度阈值 (°C)
  static const double tempNormalMin = 20.0;
  static const double tempNormalMax = 25.0;
  static const double tempWarningMax = 27.0;
  static const double tempCriticalMax = 35.0;
  
  // 漏电流阈值 (mA)
  static const double leakageWarningMa = 15.0;
  static const double leakageCriticalMa = 30.0;
  
  // VOC 阈值
  static const double vocNormalMax = 150.0;
  static const double vocWarningMax = 350.0;
  static const double vocCriticalMax = 400.0;
}
```

---

## 数据同步机制

### 离线数据处理

1. **离线报警队列**: 存储在 Hive `offline_alerts` Box
2. **网络恢复**: 自动上传离线数据
3. **冲突解决**: 服务端时间戳优先

### 数据同步流程

```
1. 应用启动
   └── 检查网络状态
       ├── 在线 → 同步远程数据
       └── 离线 → 使用本地缓存

2. 数据变更
   ├── 在线 → 立即同步到服务器
   └── 离线 → 加入离线队列

3. 网络恢复
   └── 处理离线队列 → 同步本地变更
```

---

## 附录

### 数据库ER图

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│ buildings│────<│   labs   │>────│  users   │
└──────────┘     └────┬─────┘     └────┬─────┘
                      │                │
                      │                │
                ┌─────▼─────┐    ┌─────▼─────┐
                │  devices  │    │ user_labs │
                └─────┬─────┘    └───────────┘
                      │
        ┌─────────────┼─────────────┐
        │             │             │
  ┌─────▼─────┐ ┌─────▼─────┐ ┌─────▼─────┐
  │ telemetry │ │  alerts   │ │ cabinets  │
  └───────────┘ └───────────┘ └─────┬─────┘
                                    │
                              ┌─────▼─────┐
                              │ chemicals │
                              └─────┬─────┘
                                    │
                              ┌─────▼─────┐
                              │chem_logs  │
                              └───────────┘
```

### 版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| 1.0.0 | 2024-01 | 初始版本 |

---

*文档维护: SmartLab 开发团队*
*最后更新: 2024年1月*
