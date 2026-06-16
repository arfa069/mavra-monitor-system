// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'serializers.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializers _$serializers = (Serializers().toBuilder()
      ..add(AdminUserListResponse.serializer)
      ..add(AdminUserResponse.serializer)
      ..add(AdminUserUpdate.serializer)
      ..add(AlertCreate.serializer)
      ..add(AlertResponse.serializer)
      ..add(AlertUpdate.serializer)
      ..add(AppSchemasAuthMessageResponse.serializer)
      ..add(AuditLogListResponse.serializer)
      ..add(AuditLogResponse.serializer)
      ..add(AuthSessionResponse.serializer)
      ..add(BatchOperationResult.serializer)
      ..add(BlogCategoryResponse.serializer)
      ..add(BlogMediaResponse.serializer)
      ..add(BlogPostCreate.serializer)
      ..add(BlogPostCreateStatusEnum.serializer)
      ..add(BlogPostListItem.serializer)
      ..add(BlogPostListItemStatusEnum.serializer)
      ..add(BlogPostListResponse.serializer)
      ..add(BlogPostResponse.serializer)
      ..add(BlogPostResponseStatusEnum.serializer)
      ..add(BlogPostUpdate.serializer)
      ..add(BlogPostUpdateStatusEnum.serializer)
      ..add(BlogTagResponse.serializer)
      ..add(CleanupResultResponse.serializer)
      ..add(CleanupResultResponseStatusEnum.serializer)
      ..add(CrawlLogResponse.serializer)
      ..add(CrawlProfileBackupExportRequest.serializer)
      ..add(CrawlProfileBackupImportResponse.serializer)
      ..add(CrawlProfileCreate.serializer)
      ..add(CrawlProfileLoginSessionRequest.serializer)
      ..add(CrawlProfileLoginSessionResponse.serializer)
      ..add(CrawlProfileLoginSessionResponseStatusEnum.serializer)
      ..add(CrawlProfileRenameRequest.serializer)
      ..add(CrawlProfileResponse.serializer)
      ..add(CrawlProfileResponseStatusEnum.serializer)
      ..add(CrawlProfileRuntimeCapabilities.serializer)
      ..add(CrawlProfileRuntimeCapabilitiesModeEnum.serializer)
      ..add(CrawlProfileRuntimeCapabilitiesRecommendedActionEnum.serializer)
      ..add(CrawlProfileTestRequest.serializer)
      ..add(CrawlProfileTestResponse.serializer)
      ..add(CrawlProfileTestResponseStatusEnum.serializer)
      ..add(CrawlProfileUpdate.serializer)
      ..add(CrawlProfileUpdateStatusEnum.serializer)
      ..add(CrawlerWorkerResponse.serializer)
      ..add(DashboardKPIResponse.serializer)
      ..add(EventCenterItem.serializer)
      ..add(EventCenterItemKindEnum.serializer)
      ..add(EventCenterListResponse.serializer)
      ..add(HTTPValidationError.serializer)
      ..add(HealthResponse.serializer)
      ..add(HealthResponseStatusEnum.serializer)
      ..add(JobConfigCronUpdate.serializer)
      ..add(JobConfigScheduleInfo.serializer)
      ..add(JobConfigSchedulesResponse.serializer)
      ..add(JobCrawlLogResponse.serializer)
      ..add(JobListResponse.serializer)
      ..add(JobResponse.serializer)
      ..add(JobResponsePlatformEnum.serializer)
      ..add(JobSearchConfigCreate.serializer)
      ..add(JobSearchConfigCreatePlatformEnum.serializer)
      ..add(JobSearchConfigResponse.serializer)
      ..add(JobSearchConfigResponsePlatformEnum.serializer)
      ..add(JobSearchConfigUpdate.serializer)
      ..add(JobSearchConfigUpdatePlatformEnum.serializer)
      ..add(LocationInner.serializer)
      ..add(LoginClientKind.serializer)
      ..add(LoginLogResponse.serializer)
      ..add(LogoutRequest.serializer)
      ..add(MatchAnalyzeRequest.serializer)
      ..add(MatchResultListResponse.serializer)
      ..add(MatchResultResponse.serializer)
      ..add(MatchTaskQueuedResponse.serializer)
      ..add(MatchTaskQueuedResponseStatusEnum.serializer)
      ..add(PasswordChange.serializer)
      ..add(PermissionResponse.serializer)
      ..add(PriceHistoryResponse.serializer)
      ..add(ProductBatchCreate.serializer)
      ..add(ProductBatchCreateItem.serializer)
      ..add(ProductBatchDelete.serializer)
      ..add(ProductBatchUpdate.serializer)
      ..add(ProductCreate.serializer)
      ..add(ProductCronSchedulesResponse.serializer)
      ..add(ProductListResponse.serializer)
      ..add(ProductPlatformCronCreate.serializer)
      ..add(ProductPlatformCronResponse.serializer)
      ..add(ProductPlatformCronUpdate.serializer)
      ..add(ProductPlatformProfileBindingResponse.serializer)
      ..add(ProductPlatformProfileBindingUpdate.serializer)
      ..add(ProductResponse.serializer)
      ..add(ProductUpdate.serializer)
      ..add(ProfileUpdate.serializer)
      ..add(RecentAlert.serializer)
      ..add(RefreshTokenRequest.serializer)
      ..add(ResourcePermissionGrant.serializer)
      ..add(ResourcePermissionGrantResponse.serializer)
      ..add(ResourcePermissionListResponse.serializer)
      ..add(ResourcePermissionResponse.serializer)
      ..add(ResourcePermissionUpdate.serializer)
      ..add(RolePermissionMatrixResponse.serializer)
      ..add(RolePermissionResponse.serializer)
      ..add(RolePermissionUpdate.serializer)
      ..add(RolePermissionUpdateResponse.serializer)
      ..add(ScheduleInfo.serializer)
      ..add(SchedulerJobsResponse.serializer)
      ..add(SchedulerStatusResponse.serializer)
      ..add(ServiceInfoResponse.serializer)
      ..add(ServiceInfoResponseStatusEnum.serializer)
      ..add(SessionResponse.serializer)
      ..add(SmartHomeConfigResponse.serializer)
      ..add(SmartHomeConfigTestRequest.serializer)
      ..add(SmartHomeConfigTestResponse.serializer)
      ..add(SmartHomeConfigUpdate.serializer)
      ..add(SmartHomeEntity.serializer)
      ..add(SmartHomeEntityDomainEnum.serializer)
      ..add(SmartHomeEntityListResponse.serializer)
      ..add(SmartHomeServiceRequest.serializer)
      ..add(SmartHomeServiceResponse.serializer)
      ..add(SmartHomeSummaryResponse.serializer)
      ..add(SystemKPI.serializer)
      ..add(TaskErrorResponse.serializer)
      ..add(TaskErrorResponseStatusEnum.serializer)
      ..add(TaskProgressResponse.serializer)
      ..add(TaskProgressResponseStatusEnum.serializer)
      ..add(TaskQueuedResponse.serializer)
      ..add(TaskQueuedResponseStatusEnum.serializer)
      ..add(ThresholdPercent.serializer)
      ..add(ThresholdPercent1.serializer)
      ..add(TokenLoginRequest.serializer)
      ..add(TrendDataPoint.serializer)
      ..add(TrendDataset.serializer)
      ..add(TrendResponse.serializer)
      ..add(UserConfigCreate.serializer)
      ..add(UserConfigResponse.serializer)
      ..add(UserConfigUpdate.serializer)
      ..add(UserCreate.serializer)
      ..add(UserKPI.serializer)
      ..add(UserRegister.serializer)
      ..add(UserResponse.serializer)
      ..add(UserResumeCreate.serializer)
      ..add(UserResumeResponse.serializer)
      ..add(UserResumeUpdate.serializer)
      ..add(ValidationError.serializer)
      ..add(WeChatBindRequest.serializer)
      ..add(WeChatExchangeRequest.serializer)
      ..add(WeChatExchangeResponse.serializer)
      ..add(WeChatQrResponse.serializer)
      ..add(WeChatRegisterRequest.serializer)
      ..add(WeChatUnboundResponse.serializer)
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(AdminUserResponse)]),
          () => ListBuilder<AdminUserResponse>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(AuditLogResponse)]),
          () => ListBuilder<AuditLogResponse>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(BlogPostListItem)]),
          () => ListBuilder<BlogPostListItem>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(BlogTagResponse)]),
          () => ListBuilder<BlogTagResponse>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(EventCenterItem)]),
          () => ListBuilder<EventCenterItem>())
      ..addBuilderFactory(
          const FullType(
              BuiltList, const [const FullType(JobConfigScheduleInfo)]),
          () => ListBuilder<JobConfigScheduleInfo>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(JobResponse)]),
          () => ListBuilder<JobResponse>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(LocationInner)]),
          () => ListBuilder<LocationInner>())
      ..addBuilderFactory(
          const FullType(
              BuiltList, const [const FullType(MatchResultResponse)]),
          () => ListBuilder<MatchResultResponse>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(PermissionResponse)]),
          () => ListBuilder<PermissionResponse>())
      ..addBuilderFactory(
          const FullType(
              BuiltList, const [const FullType(RolePermissionResponse)]),
          () => ListBuilder<RolePermissionResponse>())
      ..addBuilderFactory(
          const FullType(
              BuiltList, const [const FullType(ProductBatchCreateItem)]),
          () => ListBuilder<ProductBatchCreateItem>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(ProductResponse)]),
          () => ListBuilder<ProductResponse>())
      ..addBuilderFactory(
          const FullType(
              BuiltList, const [const FullType(ResourcePermissionResponse)]),
          () => ListBuilder<ResourcePermissionResponse>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(SmartHomeEntity)]),
          () => ListBuilder<SmartHomeEntity>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(String)]),
          () => ListBuilder<String>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(String)]),
          () => ListBuilder<String>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(String)]),
          () => ListBuilder<String>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(String)]),
          () => ListBuilder<String>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(String)]),
          () => ListBuilder<String>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(String)]),
          () => ListBuilder<String>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(TrendDataPoint)]),
          () => ListBuilder<TrendDataPoint>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(TrendDataset)]),
          () => ListBuilder<TrendDataset>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(String)]),
          () => ListBuilder<String>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(ValidationError)]),
          () => ListBuilder<ValidationError>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(int)]),
          () => ListBuilder<int>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(int)]),
          () => ListBuilder<int>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(int)]),
          () => ListBuilder<int>())
      ..addBuilderFactory(
          const FullType(
              BuiltList, const [const FullType.nullable(JsonObject)]),
          () => ListBuilder<JsonObject?>())
      ..addBuilderFactory(
          const FullType(BuiltMap,
              const [const FullType(String), const FullType(ScheduleInfo)]),
          () => MapBuilder<String, ScheduleInfo>())
      ..addBuilderFactory(
          const FullType(BuiltMap,
              const [const FullType(String), const FullType(ScheduleInfo)]),
          () => MapBuilder<String, ScheduleInfo>())
      ..addBuilderFactory(
          const FullType(BuiltMap,
              const [const FullType(String), const FullType(ScheduleInfo)]),
          () => MapBuilder<String, ScheduleInfo>())
      ..addBuilderFactory(
          const FullType(BuiltMap, const [
            const FullType(String),
            const FullType.nullable(JsonObject)
          ]),
          () => MapBuilder<String, JsonObject?>())
      ..addBuilderFactory(
          const FullType(BuiltMap, const [
            const FullType(String),
            const FullType.nullable(JsonObject)
          ]),
          () => MapBuilder<String, JsonObject?>())
      ..addBuilderFactory(
          const FullType(BuiltMap, const [
            const FullType(String),
            const FullType.nullable(JsonObject)
          ]),
          () => MapBuilder<String, JsonObject?>())
      ..addBuilderFactory(
          const FullType(BuiltMap, const [
            const FullType(String),
            const FullType.nullable(JsonObject)
          ]),
          () => MapBuilder<String, JsonObject?>())
      ..addBuilderFactory(
          const FullType(BuiltMap, const [
            const FullType(String),
            const FullType.nullable(JsonObject)
          ]),
          () => MapBuilder<String, JsonObject?>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(BlogTagResponse)]),
          () => ListBuilder<BlogTagResponse>())
      ..addBuilderFactory(
          const FullType(BuiltMap, const [
            const FullType(String),
            const FullType.nullable(JsonObject)
          ]),
          () => MapBuilder<String, JsonObject?>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(int)]),
          () => ListBuilder<int>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(String)]),
          () => ListBuilder<String>())
      ..addBuilderFactory(
          const FullType(BuiltMap, const [
            const FullType(String),
            const FullType.nullable(JsonObject)
          ]),
          () => MapBuilder<String, JsonObject?>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(int)]),
          () => ListBuilder<int>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(String)]),
          () => ListBuilder<String>()))
    .build();

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
