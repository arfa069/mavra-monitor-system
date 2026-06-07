import { useEffect, useState } from "react";
import { Row, Col, Card, Segmented, Skeleton, Tag } from "antd";
import api from "@/shared/api/client";
import { motion } from "framer-motion";
import { useStaggerAnimation } from "@/shared/hooks/useStaggerAnimation";
import {
  ShoppingCartOutlined,
  FallOutlined,
  FileSearchOutlined,
  CheckCircleOutlined,
  SyncOutlined,
  TeamOutlined,
  DatabaseOutlined,
  AlertOutlined,
  HddOutlined,
  CloudServerOutlined,
} from "@ant-design/icons";
import { useAuth } from "@/shared/contexts/AuthContext";
import {
  KPICard,
  RecentAlertsPanel,
  TrendChartSection,
  PieChartSection,
} from "./components";
import { useDashboardSSE } from "./hooks/useDashboardSSE";
import { useDashboardTrends } from "./hooks/useDashboardTrends";
import { useRecentAlerts } from "./hooks/useRecentAlerts";
import type { DashboardKPIResponse, TimeRange } from "./types";

// NOTE: Up to 7 concurrent trend requests may be fired simultaneously.
// Browser connection limits (typically 6 per domain) can cause some requests
// to queue behind others, creating a minor waterfall delay. A backend
// aggregation endpoint would be the proper fix; we keep separate calls
// to preserve endpoint granularity and cacheability.
//
// NOTE: The initial KPI HTTP fetch and the SSE connection may race.
// This is acceptable — SSE data takes precedence (real-time) and will
// overwrite initialData once connected. The shared `api` client ensures
// consistent auth headers across both paths.

const TIME_RANGE_OPTIONS = [
  { label: "7天", value: 7 },
  { label: "30天", value: 30 },
  { label: "90天", value: 90 },
];

export default function DashboardPage() {
  const { isAdmin } = useAuth();
  const [days, setDays] = useState<TimeRange>(30);
  const [initialData, setInitialData] = useState<DashboardKPIResponse | null>(
    null,
  );
  const stagger = useStaggerAnimation(0.05, 0.05);

  // Fetch initial KPI data via HTTP
  useEffect(() => {
    const fetchInitial = async () => {
      try {
        const response =
          await api.get<DashboardKPIResponse>("/v1/dashboard/kpi");
        setInitialData(response.data);
      } catch {
        // Silently fail — SSE will provide data eventually
      }
    };
    fetchInitial();
  }, []);

  const { data: sseData, connected, error: sseError } = useDashboardSSE();
  const priceTrends = useDashboardTrends("price", days);
  const priceChangeTrends = useDashboardTrends("price_change", days);
  const jobTrends = useDashboardTrends("jobs", days);
  const jobMatchTrends = useDashboardTrends("job_matches", days);
  const productDist = useDashboardTrends("platform_products", days);
  const jobDist = useDashboardTrends("platform_jobs", days);

  // Admin-only trends
  const platformSuccess = useDashboardTrends("platform_success", days, isAdmin);
  const crawlFailures = useDashboardTrends("crawl_failures", days, isAdmin);

  // Admin-only recent alerts
  const { data: recentAlerts, loading: alertsLoading } = useRecentAlerts(10);

  // Prefer SSE data over initial data (real-time updates)
  const kpiData = sseData ?? initialData;
  const userKPI = kpiData?.user;
  const systemKPI = kpiData?.system;

  const refreshTag = (refreshing: boolean) =>
    refreshing ? <Tag color="processing">刷新中</Tag> : undefined;

  return (
    <motion.div
      variants={stagger.container}
      initial="hidden"
      animate="show"
      style={{ padding: "24px" }}
    >
      {/* Header */}
      <motion.div
        variants={stagger.item}
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          marginBottom: 24,
        }}
      >
        <h1 style={{ margin: 0, fontSize: 24, fontWeight: 600 }}>数据看板</h1>
        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
          <Segmented
            options={TIME_RANGE_OPTIONS}
            value={days}
            onChange={(v) => setDays(v as TimeRange)}
          />
          {!connected && sseError && <Tag color="warning">{sseError}</Tag>}
        </div>
      </motion.div>

      {/* Personal KPI Cards */}
      <motion.div variants={stagger.item}>
        <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
          <Col xs={12} sm={12} md={8} lg={4}>
            <KPICard
              title="监控商品数"
              value={userKPI?.total_products ?? 0}
              prefix={<ShoppingCartOutlined />}
            />
          </Col>
          <Col xs={12} sm={12} md={8} lg={4}>
            <KPICard
              title="今日降价"
              value={userKPI?.price_drops_today ?? 0}
              prefix={<FallOutlined />}
              valueStyle={{ color: "#e5484d" }}
            />
          </Col>
          <Col xs={12} sm={12} md={8} lg={4}>
            <KPICard
              title="新职位数"
              value={userKPI?.new_jobs_today ?? 0}
              prefix={<FileSearchOutlined />}
            />
          </Col>
          <Col xs={12} sm={12} md={8} lg={4}>
            <KPICard
              title="匹配分析"
              value={userKPI?.match_count ?? 0}
              prefix={<CheckCircleOutlined />}
            />
          </Col>
          <Col xs={12} sm={12} md={8} lg={4}>
            <KPICard
              title="今日爬取"
              value={userKPI?.crawl_count_today ?? 0}
              prefix={<SyncOutlined spin={connected} />}
            />
          </Col>
        </Row>
      </motion.div>

      {/* Product Monitoring */}
      <motion.div variants={stagger.item}>
        <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
          <Col xs={24} lg={8}>
            <Card
              title="各平台商品分布"
              extra={refreshTag(productDist.refreshing)}
              variant="borderless"
              style={{ borderRadius: 16 }}
            >
              <PieChartSection
                data={productDist.data}
                loading={productDist.loading}
                refreshing={productDist.refreshing}
              />
            </Card>
          </Col>
          <Col xs={24} lg={8}>
            <Card
              title="价格趋势"
              extra={refreshTag(priceTrends.refreshing)}
              variant="borderless"
              style={{ borderRadius: 16 }}
            >
              <TrendChartSection
                data={priceTrends.data}
                loading={priceTrends.loading}
                refreshing={priceTrends.refreshing}
              />
            </Card>
          </Col>
          <Col xs={24} lg={8}>
            <Card
              title="价格变化率趋势"
              extra={refreshTag(priceChangeTrends.refreshing)}
              variant="borderless"
              style={{ borderRadius: 16 }}
            >
              <TrendChartSection
                data={priceChangeTrends.data}
                loading={priceChangeTrends.loading}
                refreshing={priceChangeTrends.refreshing}
              />
            </Card>
          </Col>
        </Row>
      </motion.div>

      {/* Job Monitoring */}
      <motion.div variants={stagger.item}>
        <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
          <Col xs={24} lg={8}>
            <Card
              title="各平台职位分布"
              extra={refreshTag(jobDist.refreshing)}
              variant="borderless"
              style={{ borderRadius: 16 }}
            >
              <PieChartSection
                data={jobDist.data}
                loading={jobDist.loading}
                refreshing={jobDist.refreshing}
              />
            </Card>
          </Col>
          <Col xs={24} lg={8}>
            <Card
              title="新增职位趋势"
              extra={refreshTag(jobTrends.refreshing)}
              variant="borderless"
              style={{ borderRadius: 16 }}
            >
              <TrendChartSection
                data={jobTrends.data}
                loading={jobTrends.loading}
                refreshing={jobTrends.refreshing}
              />
            </Card>
          </Col>
          <Col xs={24} lg={8}>
            <Card
              title="职位匹配趋势"
              extra={refreshTag(jobMatchTrends.refreshing)}
              variant="borderless"
              style={{ borderRadius: 16 }}
            >
              <TrendChartSection
                data={jobMatchTrends.data}
                loading={jobMatchTrends.loading}
                refreshing={jobMatchTrends.refreshing}
              />
            </Card>
          </Col>
        </Row>
      </motion.div>

      {/* System Operations — Admin Only */}
      {isAdmin && (
        <>
          <motion.div variants={stagger.item}>
            <h2 style={{ fontSize: 20, fontWeight: 600, marginBottom: 16 }}>
              系统运营
            </h2>
          </motion.div>

          {/* System KPI Cards */}
          <motion.div variants={stagger.item}>
            {systemKPI ? (
              <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
                <Col xs={12} sm={8} lg={4}>
                  <KPICard
                    title="总用户数"
                    value={systemKPI.total_users}
                    prefix={<TeamOutlined />}
                  />
                </Col>
                <Col xs={12} sm={8} lg={4}>
                  <KPICard
                    title="今日爬取"
                    value={systemKPI.total_crawls}
                    prefix={<DatabaseOutlined />}
                  />
                </Col>
                <Col xs={12} sm={8} lg={4}>
                  <KPICard
                    title="成功率"
                    value={systemKPI.success_rate * 100}
                    suffix="%"
                    precision={1}
                    prefix={<CheckCircleOutlined />}
                  />
                </Col>
                <Col xs={12} sm={8} lg={4}>
                  <KPICard
                    title="活跃告警"
                    value={systemKPI.active_alerts}
                    prefix={<AlertOutlined />}
                    valueStyle={{
                      color:
                        systemKPI.active_alerts > 0 ? "#e5484d" : "#1ea64a",
                    }}
                  />
                </Col>
                <Col xs={12} sm={8} lg={4}>
                  <KPICard
                    title="磁盘使用"
                    value={systemKPI.disk_usage * 100}
                    suffix="%"
                    precision={1}
                    prefix={<HddOutlined />}
                  />
                </Col>
                <Col xs={12} sm={8} lg={4}>
                  <KPICard
                    title="内存使用"
                    value={systemKPI.memory_usage * 100}
                    suffix="%"
                    precision={1}
                    prefix={<CloudServerOutlined />}
                  />
                </Col>
              </Row>
            ) : (
              <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
                <Col xs={24}>
                  <Card variant="borderless" style={{ borderRadius: 16 }}>
                    <Skeleton active paragraph={{ rows: 1 }} />
                  </Card>
                </Col>
              </Row>
            )}
          </motion.div>

          {/* System Charts */}
          <motion.div variants={stagger.item}>
            <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
              <Col xs={24} lg={12}>
                <Card
                  title="平台成功率对比"
                  extra={refreshTag(platformSuccess.refreshing)}
                  variant="borderless"
                  style={{ borderRadius: 16 }}
                >
                  <TrendChartSection
                    data={platformSuccess.data}
                    loading={platformSuccess.loading}
                    refreshing={platformSuccess.refreshing}
                    chartType="bar"
                  />
                </Card>
              </Col>
              <Col xs={24} lg={12}>
                <Card
                  title="爬取失败趋势"
                  extra={refreshTag(crawlFailures.refreshing)}
                  variant="borderless"
                  style={{ borderRadius: 16 }}
                >
                  <TrendChartSection
                    data={crawlFailures.data}
                    loading={crawlFailures.loading}
                    refreshing={crawlFailures.refreshing}
                    chartType="bar"
                  />
                </Card>
              </Col>
            </Row>
          </motion.div>

          {/* Recent Alerts */}
          <motion.div variants={stagger.item}>
            <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
              <Col xs={24}>
                <Card
                  title="最近告警"
                  variant="borderless"
                  style={{ borderRadius: 16 }}
                >
                  <RecentAlertsPanel
                    alerts={recentAlerts}
                    loading={alertsLoading}
                  />
                </Card>
              </Col>
            </Row>
          </motion.div>
        </>
      )}
    </motion.div>
  );
}
