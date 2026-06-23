import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/mavra_app.dart';
import '../core/auth/auth_repository.dart';
import '../core/config/app_config.dart';
import '../core/files/file_service.dart';
import '../features/admin/domain/admin_models.dart';
import '../features/alerts/domain/alert_models.dart';
import '../features/analytics/domain/analytics_models.dart';
import '../features/auth/domain/auth_models.dart';
import '../features/blog/domain/blog_models.dart';
import '../features/events/domain/event_models.dart';
import '../features/jobs/domain/job_models.dart';
import '../features/products/domain/product_models.dart';
import '../features/schedule/domain/schedule_models.dart';
import '../features/settings/domain/settings_models.dart';
import '../features/smart_home/domain/smart_home_models.dart';
import '../features/today/domain/today_models.dart';

const _visualInitialLocation = String.fromEnvironment(
  'VISUAL_QA_INITIAL_LOCATION',
  defaultValue: '',
);

Widget buildVisualQaApp({String? initialLocation}) {
  final configuredInitialLocation = _resolveInitialLocation(initialLocation);

  return ProviderScope(
    child: MavraApp(
      config: const AppConfig(apiBaseUrl: 'https://visual-qa.local/api/v1'),
      authController: AuthController(
        api: const _VisualAuthApi(),
        initialSession: _visualSession,
        repository: AuthRepository(
          storage: InMemoryTokenStorage(),
          policy: TokenPersistencePolicy.nativeSecureStorage,
        ),
      ),
      todayRepository: const _VisualTodayRepository(),
      eventRepository: const _VisualEventRepository(),
      alertRepository: const _VisualAlertRepository(),
      adminRepository: const _VisualAdminRepository(),
      analyticsRepository: const _VisualAnalyticsRepository(),
      blogRepository: const _VisualBlogRepository(),
      jobsRepository: const _VisualJobsRepository(),
      productRepository: const _VisualProductRepository(),
      scheduleRepository: const _VisualScheduleRepository(),
      settingsRepository: const _VisualSettingsRepository(),
      smartHomeRepository: const _VisualSmartHomeRepository(),
      initialLocation: configuredInitialLocation,
    ),
  );
}

String? _resolveInitialLocation(String? requested) {
  if (requested != null) {
    return requested;
  }
  if (_visualInitialLocation.isNotEmpty) {
    return _visualInitialLocation;
  }

  final base = Uri.base;
  final route = base.fragment.startsWith('/') ? base.fragment : base.path;
  return _knownVisualRoutes.contains(route) ? route : null;
}

const _knownVisualRoutes = {
  '/today',
  '/dashboard',
  '/events',
  '/alerts',
  '/analytics',
  '/jobs',
  '/products',
  '/schedule',
  '/smart-home',
  '/profile',
  '/settings',
  '/admin/users',
  '/admin/audit-logs',
  '/admin/blog',
};

const _visualPermissions = {
  'schedule:read',
  'smart_home:read',
  'smart_home:control',
  'smart_home:configure',
  'user:read',
  'user:manage',
  'rbac:read',
  'rbac:manage',
  'blog:read_admin',
  'blog:write',
  'config:read',
  'config:write',
};

final _visualSession = AuthSession(
  accessToken: 'visual-qa-access',
  refreshToken: 'visual-qa-refresh',
  expiresAt: DateTime.utc(2026, 6, 17, 23, 59),
  username: 'visual-qa-admin',
  permissions: _visualPermissions,
);

class _VisualAuthApi implements AuthApiClient {
  const _VisualAuthApi();

  @override
  Future<AuthSession> login(LoginCredentials credentials) async =>
      _visualSession;

  @override
  Future<void> register(RegisterAccountInput input) async {}

  @override
  Future<AccountProfile> fetchProfile() async => const AccountProfile(
    username: 'visual-qa-admin',
    email: 'visual-qa@example.local',
    role: 'super_admin',
    permissions: _visualPermissions,
  );

  @override
  Future<List<AccountSession>> listSessions() async => [
    AccountSession(
      id: 1,
      device: 'Windows release visual harness',
      ipAddress: '127.0.0.1',
      createdAt: DateTime.utc(2026, 6, 17, 8),
      lastActiveAt: DateTime.utc(2026, 6, 17, 9),
    ),
  ];

  @override
  Future<List<LoginHistoryEntry>> listLoginHistory() async => [
    LoginHistoryEntry(
      id: 1,
      ipAddress: '127.0.0.1',
      userAgent: 'Flutter visual QA',
      createdAt: DateTime.utc(2026, 6, 17, 9),
    ),
  ];

  @override
  Future<AccountProfile> updateProfile(AccountProfileDraft draft) async =>
      AccountProfile(
        username: draft.username,
        email: draft.email,
        role: 'super_admin',
        permissions: _visualPermissions,
      );

  @override
  Future<AuthSession> changePassword(PasswordChangeDraft draft) async =>
      _visualSession;

  @override
  Future<WeChatExchangeResult> exchangeWeChatCode(String code) async =>
      WeChatExchangeResult.bound(_visualSession);

  @override
  Future<void> logout() async {}
}

class _VisualTodayRepository implements TodayRepository {
  const _VisualTodayRepository();

  @override
  Future<TodaySnapshot> loadToday() async => const TodaySnapshot(
    headline: '今天只提醒 3 件事。',
    subhead: '其他事情都在安静运行，你可以先看最值得注意的变化。',
    quietScore: 48,
    attentionItems: [
      TodayAttentionItem(
        id: 'visual-price',
        kind: TodayAttentionKind.price,
        timeLabel: '今天',
        title: 'Taobao rice cooker 到了心理价位',
        description: '价格低于你设定的提醒条件，适合今天决定要不要买。',
        metric: '-3',
        actionLabel: '查看',
        route: '/products',
      ),
      TodayAttentionItem(
        id: 'visual-job',
        kind: TodayAttentionKind.job,
        timeLabel: '稍后',
        title: 'Senior Flutter Engineer 值得晚点打开',
        description: 'Mavra Labs · Shanghai',
        metric: '92',
        actionLabel: '收藏',
        route: '/jobs',
      ),
      TodayAttentionItem(
        id: 'visual-home',
        kind: TodayAttentionKind.home,
        timeLabel: '早晨',
        title: '家里连接需要看一下',
        description: 'Home Assistant 状态不是完全正常，建议确认连接和设备状态。',
        metric: '2',
        actionLabel: '看家里',
        route: '/smart-home',
      ),
    ],
    moduleStatuses: [
      TodayModuleStatus(
        label: '价格看守',
        state: TodayStatusState.attention,
        summary: '3 个商品到了值得看的价位。',
        route: '/products',
      ),
      TodayModuleStatus(
        label: '职位雷达',
        state: TodayStatusState.attention,
        summary: '8 个职位值得看看。',
        route: '/jobs',
      ),
      TodayModuleStatus(
        label: '家里设备',
        state: TodayStatusState.attention,
        summary: '2 个设备需要看一下。',
        route: '/smart-home',
      ),
    ],
  );
}

class _VisualAnalyticsRepository implements AnalyticsRepository {
  const _VisualAnalyticsRepository();

  @override
  Future<AnalyticsOverview> loadOverview({
    int days = 30,
    bool includeAdmin = false,
  }) async => AnalyticsOverview(
    userKpi: const DashboardUserKpi(
      totalProducts: 24,
      priceDropsToday: 3,
      newJobsToday: 8,
      matchCount: 12,
      crawlCountToday: 46,
    ),
    systemKpi: includeAdmin
        ? const DashboardSystemKpi(
            totalUsers: 6,
            totalCrawls: 240,
            successRate: 0.96,
            activeAlerts: 4,
            diskUsage: 0.42,
            memoryUsage: 0.58,
          )
        : null,
    userTrends: _visualUserTrends,
    systemTrends: includeAdmin ? _visualSystemTrends : const [],
    recentAlerts: [
      AnalyticsRecentAlert(
        id: 1,
        message: 'Taobao rice cooker dropped 12%',
        productTitle: 'Taobao rice cooker',
        alertType: 'price_drop',
        active: true,
        createdAt: DateTime.utc(2026, 6, 17, 8),
        platform: 'taobao',
      ),
      AnalyticsRecentAlert(
        id: 2,
        message: 'Boss Flutter lead match scored 92%',
        productTitle: 'Senior Flutter Engineer',
        alertType: 'job_match',
        active: false,
        createdAt: DateTime.utc(2026, 6, 17, 8, 30),
        platform: 'boss',
      ),
      AnalyticsRecentAlert(
        id: 3,
        message: 'Crawler profile needs review',
        productTitle: null,
        alertType: 'profile_review',
        active: true,
        createdAt: DateTime.utc(2026, 6, 17, 9),
        platform: null,
      ),
    ],
  );

  @override
  Stream<AnalyticsKpiSnapshot> watchKpiUpdates() => const Stream.empty();
}

const _visualUserTrends = [
  AnalyticsTrendSection(
    type: AnalyticsTrendType.platformProducts,
    title: '各平台商品分布',
    chartKind: AnalyticsChartKind.pie,
    series: [
      TrendSeries(
        label: 'products',
        points: [
          TrendPoint(label: 'taobao', value: 12),
          TrendPoint(label: 'jd', value: 8),
          TrendPoint(label: 'amazon', value: 4),
        ],
      ),
    ],
  ),
  AnalyticsTrendSection(
    type: AnalyticsTrendType.price,
    title: '价格趋势',
    chartKind: AnalyticsChartKind.line,
    series: [
      TrendSeries(
        label: 'price',
        points: [
          TrendPoint(label: 'Mon', value: 12),
          TrendPoint(label: 'Tue', value: 18),
          TrendPoint(label: 'Wed', value: 15),
          TrendPoint(label: 'Thu', value: 22),
        ],
      ),
    ],
  ),
  AnalyticsTrendSection(
    type: AnalyticsTrendType.priceChange,
    title: '价格变化率趋势',
    chartKind: AnalyticsChartKind.line,
    series: [
      TrendSeries(
        label: 'change',
        points: [
          TrendPoint(label: 'Mon', value: -4),
          TrendPoint(label: 'Tue', value: -9),
          TrendPoint(label: 'Wed', value: 2),
          TrendPoint(label: 'Thu', value: -12),
        ],
      ),
    ],
  ),
  AnalyticsTrendSection(
    type: AnalyticsTrendType.platformJobs,
    title: '各平台职位分布',
    chartKind: AnalyticsChartKind.pie,
    series: [
      TrendSeries(
        label: 'jobs',
        points: [
          TrendPoint(label: 'boss', value: 9),
          TrendPoint(label: 'liepin', value: 5),
          TrendPoint(label: '51job', value: 4),
        ],
      ),
    ],
  ),
  AnalyticsTrendSection(
    type: AnalyticsTrendType.jobs,
    title: '新增职位趋势',
    chartKind: AnalyticsChartKind.line,
    series: [
      TrendSeries(
        label: 'jobs',
        points: [
          TrendPoint(label: 'Mon', value: 4),
          TrendPoint(label: 'Tue', value: 6),
          TrendPoint(label: 'Wed', value: 8),
          TrendPoint(label: 'Thu', value: 7),
        ],
      ),
    ],
  ),
  AnalyticsTrendSection(
    type: AnalyticsTrendType.jobMatches,
    title: '职位匹配趋势',
    chartKind: AnalyticsChartKind.line,
    series: [
      TrendSeries(
        label: 'matches',
        points: [
          TrendPoint(label: 'Mon', value: 3),
          TrendPoint(label: 'Tue', value: 5),
          TrendPoint(label: 'Wed', value: 9),
          TrendPoint(label: 'Thu', value: 12),
        ],
      ),
    ],
  ),
];

const _visualSystemTrends = [
  AnalyticsTrendSection(
    type: AnalyticsTrendType.platformSuccess,
    title: '平台成功率对比',
    chartKind: AnalyticsChartKind.bar,
    series: [
      TrendSeries(
        label: 'success',
        points: [
          TrendPoint(label: 'taobao', value: 94),
          TrendPoint(label: 'jd', value: 97),
          TrendPoint(label: 'boss', value: 91),
        ],
      ),
    ],
  ),
  AnalyticsTrendSection(
    type: AnalyticsTrendType.crawlFailures,
    title: '爬取失败趋势',
    chartKind: AnalyticsChartKind.bar,
    series: [
      TrendSeries(
        label: 'failures',
        points: [
          TrendPoint(label: 'Mon', value: 3),
          TrendPoint(label: 'Tue', value: 1),
          TrendPoint(label: 'Wed', value: 4),
          TrendPoint(label: 'Thu', value: 2),
        ],
      ),
    ],
  ),
];

class _VisualAdminRepository implements AdminRepository {
  const _VisualAdminRepository();

  @override
  Future<AdminSnapshot> loadAdmin(AdminFilter filter) async => AdminSnapshot(
    users: [
      AdminUser(
        id: 1,
        username: 'visual-qa-admin',
        email: 'visual-qa@example.local',
        role: 'super_admin',
        active: true,
        createdAt: DateTime.utc(2026, 6, 16),
      ),
      AdminUser(
        id: 2,
        username: 'ops-viewer',
        email: 'ops@example.local',
        role: 'viewer',
        active: true,
        createdAt: DateTime.utc(2026, 6, 15),
      ),
    ],
    rolePermissions: const [
      AdminRolePermission(
        role: 'super_admin',
        permissions: ['user:read', 'user:manage', 'rbac:manage'],
      ),
      AdminRolePermission(
        role: 'viewer',
        permissions: ['schedule:read', 'config:read'],
      ),
    ],
    auditLogs: [
      AdminAuditLog(
        id: 101,
        action: 'user.create',
        actorUserId: 1,
        targetType: 'user',
        targetId: 2,
        details: const {'email': 'ops@example.local', 'role': 'viewer'},
        ipAddress: '192.0.2.20',
        createdAt: DateTime.utc(2026, 6, 17, 9),
      ),
      AdminAuditLog(
        id: 102,
        action: 'settings.update',
        actorUserId: null,
        targetType: null,
        targetId: null,
        ipAddress: '203.0.113.8',
        createdAt: DateTime.utc(2026, 6, 17, 9, 10),
      ),
    ],
    totalUsers: 2,
    totalAuditLogs: 40,
    permissionsAvailable: true,
    realtime: true,
  );

  @override
  Future<List<AdminUser>> listUsers(AdminFilter filter) async {
    return (await loadAdmin(filter)).users;
  }

  @override
  Future<AuditLogPageState> listAuditLogs(AdminFilter filter) async {
    final snapshot = await loadAdmin(filter);
    return AuditLogPageState(
      items: snapshot.auditLogs,
      page: filter.auditPage,
      pageSize: filter.pageSize,
      total: snapshot.totalAuditLogs,
    );
  }

  @override
  Future<List<AdminRolePermission>> loadRolePermissionMatrix() async {
    return (await loadAdmin(const AdminFilter())).rolePermissions;
  }

  @override
  Future<void> updateRolePermissions({
    required String role,
    required List<String> permissions,
  }) async {}

  @override
  Future<List<ResourcePermissionItem>> listResourcePermissions({
    int? userId,
    String? resourceType,
  }) async {
    return [
      ResourcePermissionItem(
        id: 1,
        resourceType: 'product',
        resourceId: '*',
        permission: 'read',
        createdAt: DateTime.utc(2026, 6, 17, 9),
        subjectId: 2,
      ),
    ];
  }

  @override
  Future<List<ResourcePermissionItem>> grantResourcePermissions(
    ResourcePermissionGrantDraft draft,
  ) async {
    return listResourcePermissions(userId: draft.subjectId);
  }

  @override
  Future<ResourcePermissionItem> updateResourcePermission(
    int permissionId,
    ResourcePermissionUpdateDraft draft,
  ) async {
    return ResourcePermissionItem(
      id: permissionId,
      resourceType: draft.resourceType ?? 'product',
      resourceId: draft.resourceId ?? '*',
      permission: draft.permission ?? 'read',
      createdAt: DateTime.utc(2026, 6, 17, 9),
      subjectId: 2,
    );
  }

  @override
  Future<void> revokeResourcePermission(int permissionId) async {}

  @override
  Future<void> createUser(AdminUserDraft draft) async {}

  @override
  Future<void> updateUser(int userId, AdminUserDraft draft) async {}

  @override
  Future<void> setUserActive(int userId, bool active) async {}

  @override
  Future<void> deleteUser(int userId) async {}
}

class _VisualProductRepository implements ProductRepository {
  const _VisualProductRepository();

  @override
  Future<ProductsSnapshot> loadProducts() async => ProductsSnapshot(
    products: const [
      ProductItem(
        id: 1,
        title: 'Taobao rice cooker',
        platform: 'taobao',
        currentPrice: '¥299',
        url: 'https://taobao.example/rice-cooker',
        enabled: true,
      ),
      ProductItem(
        id: 2,
        title: 'JD ergonomic office chair',
        platform: 'jd',
        currentPrice: '¥899',
        url: 'https://jd.example/chair',
        enabled: true,
      ),
      ProductItem(
        id: 3,
        title: 'Amazon standing desk',
        platform: 'amazon',
        currentPrice: r'$219',
        url: 'https://amazon.example/desk',
        enabled: false,
      ),
    ],
    history: const [
      PriceHistoryPoint(label: 'Monday', price: '¥329'),
      PriceHistoryPoint(label: 'Tuesday', price: '¥309'),
      PriceHistoryPoint(label: 'Wednesday', price: '¥299'),
    ],
    bindings: const [
      ProductProfileBinding(platform: 'taobao', profileName: 'taobao-main'),
      ProductProfileBinding(platform: 'jd', profileName: 'jd-work'),
    ],
    cronConfigs: const [
      ProductCronConfig(platform: 'taobao', cron: '0 9 * * *'),
      ProductCronConfig(platform: 'jd', cron: '30 10 * * 1-5'),
    ],
    crawlLogs: [
      ProductCrawlLog(
        message: 'Crawl completed for Taobao rice cooker',
        status: 'success',
        createdAt: DateTime.utc(2026, 6, 17, 8),
      ),
      ProductCrawlLog(
        message: 'JD profile reused cached session',
        status: 'info',
        createdAt: DateTime.utc(2026, 6, 17, 8, 30),
      ),
    ],
  );

  @override
  Future<ProductPageState> listProducts(ProductListQuery query) async {
    final snapshot = await loadProducts();
    return ProductPageState(
      items: snapshot.products,
      page: query.page,
      pageSize: query.pageSize,
      total: snapshot.products.length,
    );
  }

  @override
  Future<List<PriceHistoryPoint>> getProductHistory(
    int productId, {
    int days = 30,
  }) async {
    return (await loadProducts()).history;
  }

  @override
  Future<void> saveAlert(
    int productId,
    ProductAlertDraft draft, {
    int? alertId,
  }) async {}

  @override
  Future<List<ProductPlatformProfileBinding>> listProfileBindings() async {
    return const [
      ProductPlatformProfileBinding(
        platform: 'taobao',
        profileKey: 'taobao-main',
        profileStatus: 'available',
      ),
    ];
  }

  @override
  Future<void> saveProfileBinding({
    required String platform,
    required String profileKey,
  }) async {}

  @override
  Future<void> deleteProfileBinding(String platform) async {}

  @override
  Future<List<ProductCrawlLog>> listCrawlLogs({
    int? productId,
    String? status,
  }) async {
    return (await loadProducts()).crawlLogs;
  }

  @override
  Future<List<ProductCronConfig>> listProductSchedules() async {
    return (await loadProducts()).cronConfigs;
  }

  @override
  Future<void> saveProductSchedule({
    required String platform,
    required String cronExpression,
    String timezone = 'Asia/Shanghai',
  }) async {}

  @override
  Future<void> deleteProductSchedule(String platform) async {}

  @override
  Future<int?> saveProduct(ProductDraft draft, {int? productId}) async =>
      productId ?? 99;

  @override
  Future<void> importProducts(PickedFileReference file) async {}

  @override
  Future<void> deleteProduct(int productId) async {}

  @override
  Future<void> batchDeleteProducts(List<int> productIds) async {}

  @override
  Future<void> requestCrawlNow() async {}
}

class _VisualJobsRepository implements JobsRepository {
  const _VisualJobsRepository();

  @override
  Future<JobsSnapshot> loadJobs() async => JobsSnapshot(
    jobs: const [
      JobItem(
        id: 1,
        title: 'Senior Flutter Engineer',
        company: 'Mavra Labs',
        platform: 'boss',
        location: 'Shanghai',
        status: 'new',
      ),
      JobItem(
        id: 2,
        title: 'Desktop App Lead',
        company: 'Quiet Tools',
        platform: 'liepin',
        location: 'Shenzhen',
        status: 'reviewing',
      ),
    ],
    configs: const [
      JobSearchConfig(
        id: 7,
        name: 'Boss Zhipin',
        platform: 'boss',
        keyword: 'flutter',
        location: 'Shanghai',
        cron: '0 8 * * *',
      ),
      JobSearchConfig(
        id: 8,
        name: 'Liepin desktop',
        platform: 'liepin',
        keyword: 'windows flutter',
        location: 'Shenzhen',
        cron: '30 8 * * 1-5',
      ),
    ],
    resumes: [
      ResumeItem(
        id: 3,
        fileName: 'visual-qa-resume.pdf',
        updatedAt: DateTime.utc(2026, 6, 16, 9),
      ),
    ],
    matches: const [
      JobMatchResult(
        jobTitle: 'Senior Flutter Engineer',
        score: '92%',
        reason: 'Strong Flutter and Windows desktop fit',
      ),
      JobMatchResult(
        jobTitle: 'Desktop App Lead',
        score: '88%',
        reason: 'Matches migration leadership and release QA experience',
      ),
    ],
    profiles: const [
      CrawlProfileItem(
        platform: 'boss',
        profileKey: 'boss-main',
        status: 'ready',
      ),
      CrawlProfileItem(
        platform: 'liepin',
        profileKey: 'liepin-safe',
        status: 'needs review',
      ),
    ],
    crawlLogs: [
      JobCrawlLog(
        message: 'Job crawl completed with 8 new matches',
        status: 'success',
        createdAt: DateTime.utc(2026, 6, 17, 8),
      ),
    ],
  );

  @override
  Future<JobPageState> listJobs(JobListQuery query) async {
    final snapshot = await loadJobs();
    return JobPageState(
      items: snapshot.jobs,
      page: query.page,
      pageSize: query.pageSize,
      total: snapshot.jobs.length,
    );
  }

  @override
  Future<JobDetail> loadJobDetail(int jobId) async {
    final job = (await loadJobs()).jobs.firstWhere((item) => item.id == jobId);
    return JobDetail(
      id: job.id,
      title: job.title,
      company: job.company,
      description: 'Visual QA job detail',
      url: 'https://jobs.example/$jobId',
    );
  }

  @override
  Future<List<JobMatchResult>> listMatchResults({
    int? resumeId,
    int? jobId,
    int page = 1,
    int pageSize = 20,
  }) async {
    return (await loadJobs()).matches;
  }

  @override
  Future<void> saveConfig(JobConfigDraft draft, {int? configId}) async {}

  @override
  Future<void> deleteConfig(int configId) async {}

  @override
  Future<void> requestCrawlAll() async {}

  @override
  Future<void> requestCrawlConfig(int configId) async {}

  @override
  Future<void> requestMatchAnalysis(int jobId, {required int resumeId}) async {}

  @override
  Future<void> uploadResume(PickedFileReference file) async {}

  @override
  Future<void> createResume(ResumeDraft draft) async {}

  @override
  Future<void> updateResume(int resumeId, ResumeDraft draft) async {}

  @override
  Future<void> deleteResume(int resumeId) async {}

  @override
  Future<void> selectResumeForMatch(int resumeId) async {}

  @override
  Future<void> importProfileBackup(PickedFileReference file) async {}

  @override
  Future<ProfileBackupExport> exportProfileBackup(String profileKey) async {
    return ProfileBackupExport(fileName: '$profileKey.zip', bytes: const [1]);
  }

  @override
  Future<void> createProfile({
    required String profileKey,
    required String platform,
  }) async {}

  @override
  Future<void> updateProfileStatus({
    required String profileKey,
    required String status,
  }) async {}

  @override
  Future<void> renameProfile({
    required String profileKey,
    required String newProfileKey,
  }) async {}

  @override
  Future<void> copyProfile(String profileKey) async {}

  @override
  Future<void> deleteProfile(String profileKey) async {}

  @override
  Future<void> releaseStaleProfile(String profileKey) async {}

  @override
  Future<void> openProfileLoginSession({
    required String profileKey,
    required String platform,
  }) async {}

  @override
  Future<void> closeProfileLoginSession(String profileKey) async {}

  @override
  Future<void> testProfile({
    required String profileKey,
    required String platform,
  }) async {}
}

class _VisualSmartHomeRepository implements SmartHomeRepository {
  const _VisualSmartHomeRepository();

  @override
  Future<SmartHomeSnapshot> loadSmartHome() async => const SmartHomeSnapshot(
    config: SmartHomeConfig(
      baseUrl: 'https://ha.visual.local',
      enabled: true,
      lastStatus: 'ok',
      tokenConfigured: true,
    ),
    summary: SmartHomeSummary(
      configured: true,
      connected: true,
      activeCount: 12,
      unavailableCount: 1,
    ),
    entities: [
      SmartHomeEntityItem(
        domain: 'light',
        entityId: 'light.living_room',
        name: 'Living room lamp',
        state: 'on',
        area: 'Living room',
        available: true,
      ),
      SmartHomeEntityItem(
        domain: 'switch',
        entityId: 'switch.bedroom',
        name: 'Bedroom switch',
        state: 'off',
        area: 'Bedroom',
        available: true,
      ),
      SmartHomeEntityItem(
        domain: 'sensor',
        entityId: 'sensor.office_temperature',
        name: 'Office temperature',
        state: '24.2',
        area: 'Office',
        available: true,
      ),
      SmartHomeEntityItem(
        domain: 'cover',
        entityId: 'cover.garage',
        name: 'Garage door',
        state: 'closed',
        area: 'Garage',
        available: true,
      ),
      SmartHomeEntityItem(
        domain: 'climate',
        entityId: 'climate.hallway',
        name: 'Hallway thermostat',
        state: 'cool',
        area: 'Hallway',
        available: true,
        attributes: {
          'hvac_modes': ['cool', 'heat', 'off'],
          'temperature': 21.0,
          'min_temp': 16.0,
          'max_temp': 30.0,
        },
      ),
      SmartHomeEntityItem(
        domain: 'scene',
        entityId: 'scene.evening',
        name: 'Evening scene',
        state: 'idle',
        area: null,
        available: true,
      ),
      SmartHomeEntityItem(
        domain: 'script',
        entityId: 'script.movie',
        name: 'Movie mode',
        state: 'idle',
        area: null,
        available: true,
      ),
      SmartHomeEntityItem(
        domain: 'switch',
        entityId: 'switch.wiing_ym01_ffd1_vertical_swing',
        name: '上下摆风',
        state: 'unavailable',
        area: null,
        available: false,
      ),
      SmartHomeEntityItem(
        domain: 'switch',
        entityId: 'switch.wiing_ym01_ffd1_sleep_mode',
        name: '睡眠模式',
        state: 'unavailable',
        area: null,
        available: false,
      ),
      SmartHomeEntityItem(
        domain: 'climate',
        entityId: 'climate.wiing_ym01_ffd1_air_conditioner',
        name: '空调',
        state: 'cool',
        area: null,
        available: true,
        attributes: {
          'hvac_modes': ['cool', 'heat', 'off'],
          'temperature': 24.0,
        },
      ),
      SmartHomeEntityItem(
        domain: 'switch',
        entityId: 'switch.zhimi_fa1_alarm',
        name: '风扇 提示音',
        state: 'on',
        area: null,
        available: true,
      ),
      SmartHomeEntityItem(
        domain: 'fan',
        entityId: 'fan.zhimi_fa1_fan',
        name: '风扇',
        state: 'on',
        area: null,
        available: true,
      ),
      SmartHomeEntityItem(
        domain: 'light',
        entityId: 'light.hallway',
        name: 'Hallway light',
        state: 'unavailable',
        area: 'Hallway',
        available: false,
      ),
    ],
    canControl: true,
    canConfigure: true,
    realtimeConnected: true,
  );

  @override
  Stream<List<SmartHomeEntityItem>> watchEntities() => const Stream.empty();

  @override
  Future<void> saveConfig(SmartHomeConfigDraft draft) async {}

  @override
  Future<SmartHomeServiceResult> testConfig(SmartHomeConfigDraft draft) async {
    return const SmartHomeServiceResult(
      ok: true,
      message: 'Home Assistant reachable',
    );
  }

  @override
  Future<SmartHomeServiceResult> callService(
    SmartHomeServiceDraft draft,
  ) async {
    return const SmartHomeServiceResult(
      ok: true,
      message: 'Visual QA service call mocked',
    );
  }
}

class _VisualBlogRepository implements BlogRepository {
  const _VisualBlogRepository();

  @override
  Future<BlogSnapshot> loadBlog(BlogFilter filter) async => BlogSnapshot(
    posts: [
      BlogPostItem(
        id: 1,
        title: 'Morning note',
        slug: 'morning-note',
        status: 'draft',
        excerpt: 'Brief operating note for the migration room.',
        updatedAt: DateTime.utc(2026, 6, 17, 8),
        categoryName: 'Ops',
        tagNames: const ['pricing', 'flutter'],
        coverUrl: null,
      ),
      BlogPostItem(
        id: 2,
        title: 'Release checklist',
        slug: 'release-checklist',
        status: 'scheduled',
        excerpt: 'Device evidence, screenshots, and merge gates.',
        updatedAt: DateTime.utc(2026, 6, 17, 9),
        categoryName: 'Engineering',
        tagNames: const ['qa'],
        coverUrl: '/blog-media/release.png',
      ),
    ],
    categories: const [
      BlogCategory(id: 1, name: 'Ops', slug: 'ops'),
      BlogCategory(id: 2, name: 'Engineering', slug: 'engineering'),
    ],
    tags: const [
      BlogTag(id: 1, name: 'pricing', slug: 'pricing'),
      BlogTag(id: 2, name: 'flutter', slug: 'flutter'),
      BlogTag(id: 3, name: 'qa', slug: 'qa'),
    ],
    totalPosts: 2,
  );

  @override
  Future<BlogSnapshot> listPosts(BlogFilter filter) => loadBlog(filter);

  @override
  Future<List<BlogCategory>> listCategories() async {
    return (await loadBlog(const BlogFilter())).categories;
  }

  @override
  Future<List<BlogTag>> listTags() async {
    return (await loadBlog(const BlogFilter())).tags;
  }

  @override
  Future<BlogPostDraft> loadPostDraft(int postId) async => const BlogPostDraft(
    title: 'Morning note',
    slug: 'morning-note',
    status: 'draft',
    body: 'Existing markdown body for visual QA.',
    editor: BlogEditorValue(
      html: '<p>Existing markdown body for visual QA.</p>',
      json: {
        'type': 'doc',
        'content': [
          {
            'type': 'paragraph',
            'content': [
              {'type': 'text', 'text': 'Existing markdown body for visual QA.'},
            ],
          },
        ],
      },
    ),
    excerpt: 'Brief operating note for the migration room.',
    categoryName: 'Ops',
    tagNames: ['pricing', 'flutter'],
    coverUrl: null,
    canonicalUrl: 'https://example.com/blog/morning-note',
    ogImageUrl: '/blog-media/visual-og.png',
  );

  @override
  Future<void> savePost(BlogPostDraft draft, {int? postId}) async {}

  @override
  Future<BlogMediaAsset> uploadMedia(PickedFileReference file) async {
    return const BlogMediaAsset(
      id: 7,
      fileName: 'visual-cover.png',
      publicUrl: '/blog-media/visual-cover.png',
    );
  }
}

class _VisualSettingsRepository implements SettingsRepository {
  const _VisualSettingsRepository();

  @override
  Future<SettingsSnapshot> loadSettings() async => SettingsSnapshot(
    userConfig: UserSettingsConfig(
      id: 1,
      username: 'visual-qa-admin',
      dataRetentionDays: 365,
      feishuWebhookUrl: 'https://open.feishu.example/visual-hook',
      updatedAt: DateTime.utc(2026, 6, 17),
    ),
    themeMode: 'system',
  );

  @override
  Future<SettingsSnapshot> saveSettings(SettingsDraft draft) async {
    return SettingsSnapshot(
      userConfig: UserSettingsConfig(
        id: 1,
        username: 'visual-qa-admin',
        dataRetentionDays: draft.dataRetentionDays,
        feishuWebhookUrl: draft.feishuWebhookUrl,
        updatedAt: DateTime.utc(2026, 6, 17),
      ),
      themeMode: draft.themeMode,
      motionSpeed: draft.motionSpeed,
    );
  }

  @override
  Future<SettingsSnapshot> saveMotionSpeed(String motionSpeed) async {
    final snapshot = await loadSettings();
    return SettingsSnapshot(
      userConfig: snapshot.userConfig,
      themeMode: snapshot.themeMode,
      motionSpeed: motionSpeed,
    );
  }
}

class _VisualScheduleRepository implements ScheduleRepository {
  const _VisualScheduleRepository();

  @override
  Future<ScheduleSnapshot> loadSchedule() async => const ScheduleSnapshot(
    status: SchedulerStatus(
      label: 'Scheduler running',
      timezone: 'Asia/Shanghai',
    ),
    productSchedules: [
      ProductSchedule(
        platform: 'taobao',
        cronExpression: '0 9 * * *',
        nextRunAt: '2026-06-18 09:00',
      ),
    ],
    jobSchedules: [
      JobSchedule(
        configId: 7,
        name: 'Boss morning',
        cronExpression: '30 8 * * 1-5',
        nextRunAt: '2026-06-18 08:30',
      ),
    ],
    settings: ScheduleSettings(
      retentionDays: 365,
      feishuWebhookUrl: 'https://open.feishu.cn/webhook/visual',
    ),
    canConfigure: true,
  );

  @override
  Future<List<ProductSchedule>> listProductSchedules() async {
    return (await loadSchedule()).productSchedules;
  }

  @override
  Future<List<JobSchedule>> listJobSchedules() async {
    return (await loadSchedule()).jobSchedules;
  }

  @override
  Future<CronPreview> previewCron(ScheduleRuleDraft draft) async {
    return CronPreview(expression: draft.cronExpression);
  }

  @override
  Future<CronPreview> generateCron(ScheduleRuleDraft draft) {
    return previewCron(draft);
  }

  @override
  Future<void> saveRule(ScheduleRuleDraft draft) async {}

  @override
  Future<void> saveProductCron({
    required String platform,
    required String? cronExpression,
    String timezone = 'Asia/Shanghai',
  }) async {}

  @override
  Future<void> createProductCron({
    required String platform,
    required String cronExpression,
    String timezone = 'Asia/Shanghai',
  }) async {}

  @override
  Future<void> deleteProductCron(String platform) async {}

  @override
  Future<void> saveJobCron({
    required int configId,
    required String? cronExpression,
    String timezone = 'Asia/Shanghai',
  }) async {}

  @override
  Future<void> saveSettings(ScheduleSettings settings) async {}
}

class _VisualAlertRepository implements AlertRepository {
  const _VisualAlertRepository();

  @override
  Future<List<AlertItem>> listAlerts({
    AlertFilter filter = AlertFilter.all,
  }) async {
    return [
      AlertItem(
        id: 1,
        productId: 1,
        productTitle: 'Taobao rice cooker',
        alertType: 'price_drop',
        thresholdLabel: '10%',
        active: true,
        lastNotifiedPrice: '¥299',
        updatedAt: DateTime.utc(2026, 6, 17, 8),
      ),
    ];
  }

  @override
  Stream<AlertItem> watchAlerts({AlertFilter filter = AlertFilter.all}) {
    return const Stream.empty();
  }
}

class _VisualEventRepository implements EventRepository {
  const _VisualEventRepository();

  @override
  Future<EventPage> listEvents({EventQuery query = const EventQuery()}) async {
    final items = [
      EventFeedItem(
        id: 'evt-1',
        kind: EventKind.audit,
        category: 'auth',
        eventType: 'user.login',
        message: 'visual-qa-admin logged in',
        severity: 'info',
        source: 'visual-qa',
        occurredAt: DateTime.utc(2026, 6, 17, 9),
        status: 'delivered',
        userId: 1,
        entityType: 'user',
        entityId: '1',
        traceId: 'trace-login-visual',
        payload: const {'ip': '127.0.0.1', 'role': 'super_admin'},
      ),
      EventFeedItem(
        id: 'evt-2',
        kind: EventKind.platform,
        category: 'crawler',
        eventType: 'profile.challenge',
        message: 'Boss profile requires review',
        severity: 'warning',
        source: 'visual-qa',
        occurredAt: DateTime.utc(2026, 6, 17, 9, 10),
        status: 'pending',
        userId: 1,
        entityType: 'profile',
        entityId: 'boss-main',
        traceId: 'trace-profile-visual',
        payload: const {'reason': 'captcha', 'platform': 'boss'},
      ),
      EventFeedItem(
        id: 'evt-3',
        kind: EventKind.system,
        category: 'runtime',
        eventType: 'worker.restarted',
        message: 'Crawler worker restarted after transient failure',
        severity: 'error',
        source: 'scheduler',
        occurredAt: DateTime.utc(2026, 6, 17, 9, 20),
        status: 'resolved',
        entityType: 'worker',
        entityId: 'crawler',
        traceId: 'trace-worker-visual',
        payload: const {'exit_code': 1, 'retry': true},
      ),
    ];
    final filtered = items.where((item) => _visualEventMatches(item, query));
    return EventPage(
      items: filtered.toList(),
      page: query.page,
      pageSize: query.pageSize,
      total: items.length,
    );
  }

  @override
  Stream<EventFeedItem> watchEvents({EventQuery query = const EventQuery()}) {
    return const Stream.empty();
  }
}

bool _visualEventMatches(EventFeedItem item, EventQuery query) {
  if (query.filter != EventFilter.all && item.kind.name != query.filter.name) {
    return false;
  }
  if (!_visualEqualsIfPresent(query.eventType, item.eventType)) {
    return false;
  }
  if (!_visualEqualsIfPresent(query.category, item.category)) {
    return false;
  }
  if (!_visualEqualsIfPresent(query.severity, item.severity)) {
    return false;
  }
  if (!_visualEqualsIfPresent(query.source, item.source)) {
    return false;
  }
  final keyword = query.keyword?.trim().toLowerCase();
  if (keyword == null || keyword.isEmpty) {
    return true;
  }
  return [
    item.message,
    item.eventType,
    item.category,
    item.source,
    item.entityType,
    item.entityId,
    item.traceId,
  ].whereType<String>().any((value) => value.toLowerCase().contains(keyword));
}

bool _visualEqualsIfPresent(String? expected, String actual) {
  return expected == null || expected.isEmpty || actual == expected;
}
