# SmartLab 用户权限系统设计方案

本文档详细说明智慧实验室安全监测与预警系统的用户认证和权限管理设计方案。

---

## 一、需求分析

### 1.1 用户角色

根据信息科学与技术学院的实际使用场景，系统需要支持以下用户角色：

| 角色 | 代码 | 说明 | 典型用户 |
|------|------|------|----------|
| **管理员** | `admin` | 系统最高权限，管理所有实验室 | IT管理人员 |
| **教师** | `teacher` | 实验室负责人，管理指定实验室 | 指导老师、实验室主任 |
| **研究生** | `graduate` | 日常使用，部分管理权限 | 硕士/博士研究生 |
| **本科生助理** | `undergraduate` | 基础使用权限 | 本科生实验助理 |

### 1.2 功能权限矩阵

| 功能 | 管理员 | 教师 | 研究生 | 本科生助理 |
|------|--------|------|--------|------------|
| **查看监测数据** | ✅ 全部 | ✅ 负责实验室 | ✅ 分配实验室 | ✅ 分配实验室 |
| **查看报警历史** | ✅ | ✅ | ✅ | ✅ |
| **确认/处理报警** | ✅ | ✅ | ✅ | ❌ |
| **设备控制(电源/阀门)** | ✅ | ✅ | ✅(需审批) | ❌ |
| **危化品领用** | ✅ | ✅ | ✅(需审批) | ❌ |
| **危化品入库** | ✅ | ✅ | ❌ | ❌ |
| **用户管理** | ✅ | ❌ | ❌ | ❌ |
| **实验室配置** | ✅ | ✅(负责实验室) | ❌ | ❌ |
| **阈值调整** | ✅ | ✅ | ❌ | ❌ |
| **报表导出** | ✅ | ✅ | ✅ | ❌ |
| **切换实验室** | ✅ 全部 | ✅ 负责实验室 | ✅ 分配实验室 | ✅ 分配实验室 |

### 1.3 实验室访问控制

```
院楼806
├── 负责人: 王老师 (teacher)
├── 研究生: 张三、李四 (graduate)
└── 本科生助理: 王五、赵六 (undergraduate)

西学楼新信科实验室
├── 负责人: 李老师 (teacher)
├── 研究生: 陈七 (graduate)
└── 本科生助理: 钱八 (undergraduate)
```

---

## 二、系统架构

### 2.1 认证流程

```
┌─────────────────────────────────────────────────────────────────┐
│                        登录流程                                  │
└─────────────────────────────────────────────────────────────────┘

用户 ───────────────────────────────────────────────────────────► API
      │                                                            │
      │  1. POST /auth/login                                       │
      │     { username, password }                                 │
      │                                                            │
      │  2. 验证凭据                                                │
      │     - 校验学号/工号格式                                     │
      │     - 验证密码 (BCrypt)                                    │
      │     - 检查账户状态                                          │
      │                                                            │
      │  3. 返回令牌                                                │
      │     { access_token, refresh_token, user, permissions }     │
      ◄────────────────────────────────────────────────────────────│
      │                                                            │
      │  4. 存储令牌 (Flutter Secure Storage)                      │
      │                                                            │
      │  5. 加载用户权限和可访问实验室                               │
```

### 2.2 授权机制

```dart
// 权限检查示例
class PermissionChecker {
  static bool canControlDevice(User user, String labId) {
    if (user.role == UserRole.admin) return true;
    if (user.role == UserRole.undergraduate) return false;
    return user.accessibleLabs.contains(labId);
  }
  
  static bool canAcknowledgeAlert(User user) {
    return user.role != UserRole.undergraduate;
  }
  
  static bool canManageChemicals(User user, String action) {
    if (action == 'view') return true;
    if (action == 'checkout') {
      return user.role == UserRole.admin || 
             user.role == UserRole.teacher ||
             user.role == UserRole.graduate;
    }
    if (action == 'checkin') {
      return user.role == UserRole.admin || 
             user.role == UserRole.teacher;
    }
    return false;
  }
}
```

---

## 三、数据模型

### 3.1 用户实体

```dart
/// 用户实体
class User extends Equatable {
  final String id;
  final String username;         // 学号/工号
  final String name;             // 真实姓名
  final UserRole role;           // 用户角色
  final String? department;      // 院系
  final String? phone;           // 手机号
  final String? email;           // 邮箱
  final String? avatarUrl;       // 头像
  final List<String> accessibleLabIds;  // 可访问的实验室ID列表
  final DateTime? lastLoginAt;   // 最后登录时间
  final bool isActive;           // 账户是否激活
  
  const User({...});
}

/// 用户角色枚举
enum UserRole {
  admin,
  teacher,
  graduate,
  undergraduate;
  
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return '系统管理员';
      case UserRole.teacher:
        return '教师';
      case UserRole.graduate:
        return '研究生';
      case UserRole.undergraduate:
        return '本科生助理';
    }
  }
  
  int get level {
    switch (this) {
      case UserRole.admin:
        return 100;
      case UserRole.teacher:
        return 80;
      case UserRole.graduate:
        return 60;
      case UserRole.undergraduate:
        return 40;
    }
  }
}
```

### 3.2 认证状态

```dart
/// 认证状态
class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;
  final List<LabInfo> accessibleLabs;
  final String? currentLabId;
  final String? errorMessage;
  
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.accessibleLabs = const [],
    this.currentLabId,
    this.errorMessage,
  });
  
  bool get isLoggedIn => status == AuthStatus.authenticated && user != null;
  
  bool get canControlDevices => 
      user != null && user!.role != UserRole.undergraduate;
  
  bool get canManageLab =>
      user != null && (user!.role == UserRole.admin || user!.role == UserRole.teacher);
}

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}
```

---

## 四、页面设计规划

### 4.1 页面列表

| 页面 | 路由 | 说明 | 权限要求 |
|------|------|------|----------|
| 登录页 | `/login` | 学号密码登录 | 无 |
| 注册页 | `/register` | 用户注册(需审核) | 无 |
| 实验室选择页 | `/select-lab` | 选择要进入的实验室 | 已登录 |
| 仪表盘 | `/` | 安全总览 | 已登录 |
| 个人中心 | `/profile` | 用户信息和设置 | 已登录 |

### 4.2 页面流程

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   启动页    │ ──► │   登录页    │ ──► │ 实验室选择  │ ──► │   仪表盘    │
│  (Splash)   │     │  (Login)    │     │(SelectLab)  │     │ (Dashboard) │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
       │                   │                                        │
       │                   │                                        │
       │                   ▼                                        │
       │            ┌─────────────┐                                 │
       │            │   注册页    │                                 │
       │            │ (Register)  │                                 │
       │            └─────────────┘                                 │
       │                                                            │
       │     (有 Token 且未过期)                                    │
       └────────────────────────────────────────────────────────────┘
```

### 4.3 登录页面设计

**现有登录页面已实现基础布局，需要增强以下功能：**

1. **表单验证增强**
   - 学号格式验证 (如：2021XXXXX)
   - 密码强度提示
   - 错误信息展示

2. **登录状态持久化**
   - 记住密码功能
   - Token 自动刷新

3. **多种登录方式**
   - 学号/工号 + 密码 (主要)
   - 生物识别 (指纹/面容)
   - 二维码扫描 (可选)

### 4.4 注册页面设计（新增）

**注册流程：**
1. 填写基本信息（学号、姓名、手机号）
2. 选择身份角色
3. 选择所属实验室（多选）
4. 设置密码
5. 提交审核（教师/管理员审核）

### 4.5 实验室选择页面（新增）

**功能需求：**
- 显示用户可访问的实验室列表
- 每个实验室显示：名称、位置、当前状态、安全评分
- 快速切换功能
- 记住上次选择

---

## 五、实现计划

### 5.1 第一阶段：基础认证 (优先实现)

1. **创建 AuthBloc** - 管理认证状态
2. **增强 LoginPage** - 连接真实API
3. **创建 User 实体** - 用户数据模型
4. **实现 Token 管理** - 安全存储和刷新
5. **添加路由守卫** - 登录状态检查

### 5.2 第二阶段：实验室切换

1. **创建 LabSelectionPage** - 实验室选择页面
2. **更新 MockDataProvider** - 支持动态切换
3. **更新各模块 BLoC** - 响应实验室切换

### 5.3 第三阶段：权限控制

1. **实现 PermissionChecker** - 权限检查工具
2. **更新 UI 组件** - 根据权限显示/隐藏功能
3. **添加操作日志** - 记录关键操作

### 5.4 第四阶段：注册功能 (可选)

1. **创建 RegisterPage** - 注册页面
2. **实现审核流程** - 后台审核
3. **通知机制** - 审核结果通知

---

## 六、技术实现要点

### 6.1 AuthBloc 结构

```dart
// Events
abstract class AuthEvent extends Equatable {}
class AuthCheckRequested extends AuthEvent {}
class AuthLoginRequested extends AuthEvent {
  final String username;
  final String password;
}
class AuthLogoutRequested extends AuthEvent {}
class AuthLabChanged extends AuthEvent {
  final String labId;
}

// States
class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;
  final List<LabInfo> accessibleLabs;
  final String? currentLabId;
  final String? errorMessage;
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService apiService;
  final LocalStorageService storageService;
  
  AuthBloc({...}) : super(const AuthState()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthLabChanged>(_onAuthLabChanged);
  }
}
```

### 6.2 路由守卫

```dart
// app_router.dart 中的 redirect 配置
redirect: (context, state) {
  final authState = context.read<AuthBloc>().state;
  final isLoggedIn = authState.isLoggedIn;
  final isLoggingIn = state.matchedLocation == '/login';
  final isRegistering = state.matchedLocation == '/register';
  
  // 未登录且不在登录/注册页，跳转到登录页
  if (!isLoggedIn && !isLoggingIn && !isRegistering) {
    return '/login';
  }
  
  // 已登录但在登录页，跳转到首页
  if (isLoggedIn && isLoggingIn) {
    return '/';
  }
  
  // 已登录但未选择实验室
  if (isLoggedIn && 
      authState.currentLabId == null && 
      state.matchedLocation != '/select-lab') {
    return '/select-lab';
  }
  
  return null;
},
```

---

## 七、建议

### 7.1 推荐实现方案

基于项目当前状态和您的需求，建议采用**渐进式实现**：

**立即实现：**
1. ✅ 完善现有登录页面，连接真实API
2. ✅ 创建 AuthBloc 管理认证状态
3. ✅ 实现实验室选择功能

**后续迭代：**
1. 🔄 添加用户注册功能（需后端支持审核流程）
2. 🔄 实现细粒度权限控制
3. 🔄 添加操作审计日志

### 7.2 考虑因素

| 因素 | 说明 | 建议 |
|------|------|------|
| **开发周期** | 毕业设计时间有限 | 优先实现核心功能 |
| **后端支持** | 需要API支持 | 可先用Mock数据 |
| **用户体验** | 登录流程要简洁 | 支持记住密码 |
| **安全性** | Token需安全存储 | 使用加密存储 |

---

## 八、下一步行动

如果您同意此设计方案，我将：

1. **创建 AuthBloc** 及相关事件/状态
2. **创建用户实体** (User, UserRole)
3. **增强登录页面** 连接真实认证逻辑
4. **创建实验室选择页面**
5. **更新路由守卫**

是否继续执行？
