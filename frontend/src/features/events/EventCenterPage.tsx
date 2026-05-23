import { useEffect, useState } from "react";
import dayjs, { type Dayjs } from "dayjs";
import {
  App,
  Button,
  DatePicker,
  Drawer,
  Input,
  Select,
  Space,
  Table,
  Tag,
} from "antd";
import type { ColumnsType } from "antd/es/table";

import { eventsApi } from "./api/events";
import type { EventCenterItem, EventCenterQuery, EventKind } from "./types";

const { RangePicker } = DatePicker;

const KIND_COLORS: Record<EventCenterItem["kind"], string> = {
  audit: "purple",
  system: "blue",
  platform: "red",
};

const SEVERITY_COLORS: Record<string, string> = {
  info: "default",
  warning: "gold",
  error: "red",
};

type DateRangeValue = [Dayjs | null, Dayjs | null] | null;

export default function EventCenterPage() {
  const message = App.useApp().message;
  const [items, setItems] = useState<EventCenterItem[]>([]);
  const [selectedItem, setSelectedItem] = useState<EventCenterItem | null>(
    null,
  );
  const [loading, setLoading] = useState(false);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(20);
  const [kind, setKind] = useState<EventKind>("all");
  const [eventType, setEventType] = useState("");
  const [category, setCategory] = useState("");
  const [severity, setSeverity] = useState("");
  const [source, setSource] = useState("");
  const [keyword, setKeyword] = useState("");
  const [dateRange, setDateRange] = useState<DateRangeValue>(null);

  const rangeStart = dateRange?.[0]?.valueOf() ?? null;
  const rangeEnd = dateRange?.[1]?.valueOf() ?? null;
  const startAt = dateRange?.[0]?.toISOString();
  const endAt = dateRange?.[1]?.toISOString();

  useEffect(() => {
    let cancelled = false;
    const query: EventCenterQuery = {
      kind,
      event_type: eventType || undefined,
      category: category || undefined,
      severity: severity || undefined,
      source: source || undefined,
      keyword: keyword || undefined,
      start_at: startAt,
      end_at: endAt,
      page,
      page_size: pageSize,
    };

    const load = async () => {
      setLoading(true);
      try {
        const response = await eventsApi.listEvents(query);
        if (cancelled) {
          return;
        }
        setItems(response.items);
        setTotal(response.total);
      } catch (error: unknown) {
        if (cancelled) {
          return;
        }
        const errorMessage =
          error instanceof Error ? error.message : "Failed to fetch events";
        message.error(errorMessage);
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    };

    void load();

    return () => {
      cancelled = true;
    };
  }, [
    kind,
    eventType,
    category,
    severity,
    source,
    keyword,
    page,
    pageSize,
    rangeStart,
    rangeEnd,
    startAt,
    endAt,
    message,
  ]);

  useEffect(() => {
    if (page !== 1) {
      return;
    }

    const query: EventCenterQuery = {
      kind,
      event_type: eventType || undefined,
      category: category || undefined,
      severity: severity || undefined,
      source: source || undefined,
      keyword: keyword || undefined,
      start_at: startAt,
      end_at: endAt,
      page,
      page_size: pageSize,
    };
    const eventSource = new EventSource(eventsApi.buildStreamUrl(query), {
      withCredentials: true,
    });
    eventSource.onmessage = (event) => {
      try {
        const nextItem = JSON.parse(event.data) as EventCenterItem;
        setItems((current) => {
          if (current.some((item) => item.id === nextItem.id)) {
            return current;
          }
          return [nextItem, ...current].slice(0, pageSize);
        });
        setTotal((current) => current + 1);
      } catch {
        message.warning("Realtime event payload could not be parsed");
      }
    };
    eventSource.onerror = () => {
      return;
    };

    return () => eventSource.close();
  }, [
    kind,
    eventType,
    category,
    severity,
    source,
    keyword,
    page,
    pageSize,
    rangeStart,
    rangeEnd,
    startAt,
    endAt,
    message,
  ]);

  const resetFilters = () => {
    setKind("all");
    setEventType("");
    setCategory("");
    setSeverity("");
    setSource("");
    setKeyword("");
    setDateRange(null);
    setPage(1);
  };

  const columns: ColumnsType<EventCenterItem> = [
    {
      title: "Kind",
      dataIndex: "kind",
      width: 110,
      render: (value: EventCenterItem["kind"]) => (
        <Tag color={KIND_COLORS[value]}>{value.toUpperCase()}</Tag>
      ),
    },
    {
      title: "Event Type",
      dataIndex: "event_type",
      width: 220,
      render: (value: string) => (
        <span style={{ fontFamily: "'JetBrains Mono', monospace" }}>
          {value}
        </span>
      ),
    },
    {
      title: "Message",
      dataIndex: "message",
      ellipsis: true,
    },
    {
      title: "Severity",
      dataIndex: "severity",
      width: 110,
      render: (value: string) => (
        <Tag color={SEVERITY_COLORS[value] || "default"}>
          {value.toUpperCase()}
        </Tag>
      ),
    },
    {
      title: "Source",
      dataIndex: "source",
      width: 180,
      ellipsis: true,
    },
    {
      title: "Time",
      dataIndex: "occurred_at",
      width: 190,
      render: (value: string) => dayjs(value).format("YYYY-MM-DD HH:mm:ss"),
    },
    {
      title: "Action",
      key: "action",
      width: 110,
      render: (_, record) => (
        <Button size="small" onClick={() => setSelectedItem(record)}>
          Details
        </Button>
      ),
    },
  ];

  return (
    <div>
      <div className="page-header bg-mint">
        <div className="page-header-inner">
          <div>
            <p className="page-eyebrow">System Events</p>
            <h1 className="page-title">Event Center</h1>
            <p className="page-subtitle">
              Unified audit, runtime, and platform event stream with realtime
              updates
            </p>
          </div>
        </div>
      </div>

      <div style={{ marginBottom: 16 }}>
        <Space size={[12, 12]} wrap>
          <Select
            value={kind}
            style={{ width: 140 }}
            onChange={(value) => {
              setKind(value);
              setPage(1);
            }}
            options={[
              { label: "All Kinds", value: "all" },
              { label: "Audit", value: "audit" },
              { label: "System", value: "system" },
              { label: "Platform", value: "platform" },
            ]}
          />
          <Input
            placeholder="Event type"
            value={eventType}
            onChange={(event) => {
              setEventType(event.target.value);
              setPage(1);
            }}
            style={{ width: 180 }}
          />
          <Input
            placeholder="Category"
            value={category}
            onChange={(event) => {
              setCategory(event.target.value);
              setPage(1);
            }}
            style={{ width: 160 }}
          />
          <Select
            allowClear
            placeholder="Severity"
            value={severity || undefined}
            onChange={(value) => {
              setSeverity(value || "");
              setPage(1);
            }}
            style={{ width: 140 }}
            options={[
              { label: "Info", value: "info" },
              { label: "Warning", value: "warning" },
              { label: "Error", value: "error" },
            ]}
          />
          <Input
            placeholder="Source"
            value={source}
            onChange={(event) => {
              setSource(event.target.value);
              setPage(1);
            }}
            style={{ width: 180 }}
          />
          <Input.Search
            placeholder="Keyword"
            allowClear
            value={keyword}
            onChange={(event) => {
              setKeyword(event.target.value);
              setPage(1);
            }}
            onSearch={() => setPage(1)}
            style={{ width: 220 }}
          />
          <RangePicker
            showTime
            value={dateRange}
            onChange={(value) => {
              setDateRange(value);
              setPage(1);
            }}
          />
          <Button onClick={resetFilters}>Reset</Button>
        </Space>
      </div>

      <Table
        rowKey="id"
        columns={columns}
        dataSource={items}
        loading={loading}
        pagination={{
          current: page,
          pageSize,
          total,
          showSizeChanger: true,
          showTotal: (value) => `Total ${value} events`,
          onChange: (nextPage, nextPageSize) => {
            setPage(nextPage);
            setPageSize(nextPageSize);
          },
        }}
      />

      <Drawer
        title="Event Details"
        size="large"
        open={selectedItem !== null}
        onClose={() => setSelectedItem(null)}
      >
        {selectedItem ? (
          <Space direction="vertical" size={12} style={{ display: "flex" }}>
            <div>
              <strong>ID:</strong> {selectedItem.id}
            </div>
            <div>
              <strong>Kind:</strong> {selectedItem.kind}
            </div>
            <div>
              <strong>Event Type:</strong> {selectedItem.event_type}
            </div>
            <div>
              <strong>Category:</strong> {selectedItem.category}
            </div>
            <div>
              <strong>Severity:</strong> {selectedItem.severity}
            </div>
            <div>
              <strong>Status:</strong> {selectedItem.status || "-"}
            </div>
            <div>
              <strong>Source:</strong> {selectedItem.source}
            </div>
            <div>
              <strong>User ID:</strong> {selectedItem.user_id ?? "-"}
            </div>
            <div>
              <strong>Entity:</strong> {selectedItem.entity_type || "-"} /{" "}
              {selectedItem.entity_id || "-"}
            </div>
            <div>
              <strong>Trace ID:</strong> {selectedItem.trace_id || "-"}
            </div>
            <div>
              <strong>Occurred At:</strong>{" "}
              {dayjs(selectedItem.occurred_at).format("YYYY-MM-DD HH:mm:ss")}
            </div>
            <div>
              <strong>Message:</strong> {selectedItem.message}
            </div>
            <div>
              <strong>Payload:</strong>
              <pre
                style={{
                  marginTop: 8,
                  padding: 12,
                  borderRadius: 16,
                  background: "var(--color-surface-soft)",
                  color: "var(--color-ink)",
                  overflowX: "auto",
                  fontSize: 12,
                }}
              >
                {JSON.stringify(selectedItem.payload, null, 2)}
              </pre>
            </div>
          </Space>
        ) : null}
      </Drawer>
    </div>
  );
}
