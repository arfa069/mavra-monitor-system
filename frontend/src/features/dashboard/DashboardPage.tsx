import { useEffect, useState } from "react";
import { Row, Col, Card, Segmented, Spin, Tag } from "antd";
import axios from "axios";
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
import { KPICard, TrendChart, DashboardPieChart } from "./components";
import { useDashboardSSE } from "./hooks/useDashboardSSE";
import { useDashboardTrends } from "./hooks/useDashboardTrends";
import type { DashboardKPIResponse, TimeRange } from "./types";

const TIME_RANGE_OPTIONS = [
  { label: "7天", value: 7 },
  { label: "30天", value: 30 },
  { label: "90天", value: 90 },
];

export default function DashboardPage() {
  const { user } = useAuth();
  const [days, setDays] = useState<TimeRange>(30);
  const [initialData, setInitialData] = useState<DashboardKPIResponse | null>(
    null,
  );
  const isAdmin = user?.role === "admin" || user?.role === "super_admin";

  // Fetch initial KPI data via HTTP
  useEffect(() => {
    const fetchInitial = async () => {
      try {
        const apiUrl = import.meta.env.VITE_API_URL || "/api/v1";
        const response = await axios.get<DashboardKPIResponse>(
          `${apiUrl}/dashboard/kpi`,
          { withCredentials: true },
        );
        setInitialData(response.data);
      } catch {
        // Silently fail — SSE will provide data eventually
      }
    };
    fetchInitial();
  }, []);

  const { data: sseData, connected, error: sseError } = useDashboardSSE();
  const priceTrends = useDashboardTrends("price", days);
  const jobTrends = useDashboardTrends("jobs", days);
  const productDist = useDashboardTrends("platform_products", days);
  const jobDist = useDashboardTrends("platform_jobs", days);
  const salaryDist = useDashboardTrends("salary", days);

  // Admin-only trends
  const systemHealth = useDashboardTrends("system_health", days);
  const platformSuccess = useDashboardTrends("platform_success", days);

  // Prefer SSE data over initial data (real-time updates)
  const kpiData = sseData ?? initialData;
  const userKPI = kpiData?.user;
  const systemKPI = kpiData?.system;

  return (
    <div style={{ padding: "24px" }}>
      {/* Header */}
      <div
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
      </div>

      {/* Personal KPI Cards */}
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

      {/* Product Monitoring */}
      <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
        <Col xs={24} lg={12}>
          <Card
            title="各平台商品分布"
            variant="borderless"
            style={{ borderRadius: 16 }}
          >
            {productDist.loading ? (
              <Spin />
            ) : productDist.data ? (
              <DashboardPieChart data={productDist.data} />
            ) : (
              <div>暂无数据</div>
            )}
          </Card>
        </Col>
        <Col xs={24} lg={12}>
          <Card
            title="价格趋势"
            variant="borderless"
            style={{ borderRadius: 16 }}
          >
            {priceTrends.loading ? (
              <Spin />
            ) : priceTrends.data ? (
              <TrendChart data={priceTrends.data} />
            ) : (
              <div>暂无数据</div>
            )}
          </Card>
        </Col>
      </Row>

      {/* Job Monitoring */}
      <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
        <Col xs={24} lg={8}>
          <Card
            title="各平台职位分布"
            variant="borderless"
            style={{ borderRadius: 16 }}
          >
            {jobDist.loading ? (
              <Spin />
            ) : jobDist.data ? (
              <DashboardPieChart data={jobDist.data} />
            ) : (
              <div>暂无数据</div>
            )}
          </Card>
        </Col>
        <Col xs={24} lg={8}>
          <Card
            title="新增职位趋势"
            variant="borderless"
            style={{ borderRadius: 16 }}
          >
            {jobTrends.loading ? (
              <Spin />
            ) : jobTrends.data ? (
              <TrendChart data={jobTrends.data} />
            ) : (
              <div>暂无数据</div>
            )}
          </Card>
        </Col>
        <Col xs={24} lg={8}>
          <Card
            title="薪资区间分布"
            variant="borderless"
            style={{ borderRadius: 16 }}
          >
            {salaryDist.loading ? (
              <Spin />
            ) : salaryDist.data ? (
              <TrendChart data={salaryDist.data} chartType="bar" />
            ) : (
              <div>暂无数据</div>
            )}
          </Card>
        </Col>
      </Row>

      {/* System Operations — Admin Only */}
      {isAdmin && systemKPI && (
        <>
          <h2 style={{ fontSize: 20, fontWeight: 600, marginBottom: 16 }}>
            系统运营
          </h2>

          {/* System KPI Cards */}
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
                  color: systemKPI.active_alerts > 0 ? "#e5484d" : "#1ea64a",
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

          {/* System Charts */}
          <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
            <Col xs={24} lg={12}>
              <Card
                title="系统健康度趋势"
                variant="borderless"
                style={{ borderRadius: 16 }}
              >
                {systemHealth.loading ? (
                  <Spin />
                ) : systemHealth.data ? (
                  <TrendChart data={systemHealth.data} />
                ) : (
                  <div>暂无数据</div>
                )}
              </Card>
            </Col>
            <Col xs={24} lg={12}>
              <Card
                title="平台成功率对比"
                variant="borderless"
                style={{ borderRadius: 16 }}
              >
                {platformSuccess.loading ? (
                  <Spin />
                ) : platformSuccess.data ? (
                  <TrendChart data={platformSuccess.data} chartType="bar" />
                ) : (
                  <div>暂无数据</div>
                )}
              </Card>
            </Col>
          </Row>
        </>
      )}
    </div>
  );
}
