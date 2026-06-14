import { useCallback, useEffect, useMemo, useState } from "react";
import {
  App,
  Button,
  Card,
  Col,
  Empty,
  Form,
  Input,
  InputNumber,
  Modal,
  Row,
  Select,
  Space,
  Switch,
  Tag,
  Typography,
} from "antd";
import {
  BulbOutlined,
  PoweroffOutlined,
  SettingOutlined,
} from "@ant-design/icons";
import { useAuth } from "@/shared/contexts/AuthContext";
import { formatApiError } from "@/shared/api/client";
import { smartHomeApi } from "./api/smartHome";
import { useSmartHomeSSE } from "./hooks/useSmartHomeSSE";
import type { SmartHomeConfig, SmartHomeEntity } from "./types";

const { Title, Text } = Typography;

/** Home Assistant service names allowed for direct invocation */
type HomeAssistantService =
  | "turn_on"
  | "turn_off"
  | "open_cover"
  | "stop_cover"
  | "close_cover"
  | "set_hvac_mode"
  | "set_temperature";

const SERVICE = {
  TURN_ON: "turn_on" as const,
  TURN_OFF: "turn_off" as const,
  OPEN_COVER: "open_cover" as const,
  STOP_COVER: "stop_cover" as const,
  CLOSE_COVER: "close_cover" as const,
  SET_HVAC_MODE: "set_hvac_mode" as const,
  SET_TEMPERATURE: "set_temperature" as const,
} satisfies Record<string, HomeAssistantService>;

function nextToggleService(entity: SmartHomeEntity): "turn_on" | "turn_off" {
  return entity.state === "on" ? SERVICE.TURN_OFF : SERVICE.TURN_ON;
}

function getDeviceName(entity: SmartHomeEntity): string {
  if (entity.area) return entity.area;
  if (entity.domain === "scene" || entity.domain === "script")
    return entity.name;
  const parts = entity.name.split(" ");
  if (parts.length <= 1) return entity.name;
  return parts.slice(0, -1).join(" ");
}

function isNumber(value: unknown): value is number {
  return typeof value === "number";
}

export default function SmartHomePage() {
  const message = App.useApp().message;
  const { hasPermission } = useAuth();
  const canConfigure = hasPermission("smart_home:configure");
  const canControl = hasPermission("smart_home:control");
  const [entities, setEntities] = useState<SmartHomeEntity[]>([]);
  const [connected, setConnected] = useState(false);
  const [lastError, setLastError] = useState<string | null>(null);
  const [config, setConfig] = useState<SmartHomeConfig | null>(null);
  const [configOpen, setConfigOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const [testingConfig, setTestingConfig] = useState(false);
  const [form] = Form.useForm();

  const loadEntities = useCallback(async () => {
    setLoading(true);
    try {
      const response = await smartHomeApi.listEntities();
      setEntities(response.items as unknown as SmartHomeEntity[]);
      setConnected(response.connected);
      setLastError(response.last_error as unknown as string | null);
    } catch (error) {
      setConnected(false);
      setLastError(formatApiError(error, "Failed to load smart home entities"));
    } finally {
      setLoading(false);
    }
  }, []);

  const loadConfig = useCallback(async () => {
    if (!canConfigure) return;
    try {
      const response = await smartHomeApi.getConfig();
      setConfig(response as unknown as SmartHomeConfig);
      form.setFieldsValue({
        base_url: response.base_url,
        enabled: response.enabled,
      });
    } catch {
      setConfig(null);
    }
  }, [canConfigure, form]);

  useEffect(() => {
    const timer = window.setTimeout(() => {
      void loadEntities();
      void loadConfig();
    }, 0);
    return () => window.clearTimeout(timer);
  }, [loadEntities, loadConfig]);

  useSmartHomeSSE(
    connected,
    useCallback((nextEntity) => {
      setEntities((current) => {
        const index = current.findIndex(
          (item) => item.entity_id === nextEntity.entity_id,
        );
        if (index === -1) return current;
        const copy = [...current];
        copy[index] = nextEntity;
        return copy;
      });
    }, []),
    useCallback(() => {
      setLastError("Realtime smart home updates disconnected");
      setConnected(false);
    }, []),
  );

  const grouped = useMemo(() => {
    return entities.reduce<Record<string, SmartHomeEntity[]>>((acc, entity) => {
      const key = getDeviceName(entity);
      if (!acc[key]) acc[key] = [];
      acc[key].push(entity);
      return acc;
    }, {});
  }, [entities]);

  const callService = async (
    entity: SmartHomeEntity,
    service: HomeAssistantService,
    serviceData: Record<string, unknown> = {},
  ) => {
    if (entity.domain === "scene" || entity.domain === "script") {
      const confirmed = await new Promise<boolean>((resolve) => {
        Modal.confirm({
          title: `Run ${entity.name}?`,
          onOk: () => resolve(true),
          onCancel: () => resolve(false),
        });
      });
      if (!confirmed) return;
    }
    try {
      await smartHomeApi.callService(entity.entity_id, {
        service,
        service_data: serviceData,
      });
      message.success("Command sent");
      void loadEntities();
    } catch (error) {
      message.error(formatApiError(error, "Command failed"));
    }
  };

  const saveConfig = async () => {
    try {
      const values = await form.validateFields();
      const response = await smartHomeApi.updateConfig({
        base_url: values.base_url,
        token: values.token || null,
        enabled: values.enabled,
      });
      setConfig(response as unknown as SmartHomeConfig);
      setConfigOpen(false);
      message.success("Smart home config saved");
      void loadEntities();
    } catch (error) {
      message.error(formatApiError(error, "Failed to save smart home config"));
    }
  };

  const testConfig = async () => {
    try {
      const values = await form.validateFields(["base_url", "token"]);
      setTestingConfig(true);
      const response = await smartHomeApi.testConfig({
        base_url: values.base_url,
        token: values.token || null,
      });
      if (response.ok) {
        message.success(
          response.home_assistant_version
            ? `Connected to Home Assistant ${response.home_assistant_version}`
            : response.message,
        );
      } else {
        message.error(response.message);
      }
    } catch (error) {
      message.error(formatApiError(error, "Failed to test smart home config"));
    } finally {
      setTestingConfig(false);
    }
  };

  return (
    <div>
      <div className="page-header bg-coral">
        <div className="page-header-inner">
          <div>
            <p className="page-eyebrow">Smart Home</p>
            <h1 className="page-title">Smart Home</h1>
            <p className="page-subtitle">Home Assistant devices and scenes</p>
          </div>
          <Space>
            <Tag color={connected ? "green" : "red"}>
              {connected ? "Connected" : "Offline"}
            </Tag>
            <Button onClick={loadEntities} loading={loading}>
              Refresh
            </Button>
            {canConfigure && (
              <Button
                icon={<SettingOutlined />}
                onClick={() => setConfigOpen(true)}
              >
                Configure
              </Button>
            )}
          </Space>
        </div>
      </div>

      {lastError && (
        <Card style={{ marginBottom: 16 }}>
          <Text type="danger">{lastError}</Text>
        </Card>
      )}

      {entities.length === 0 ? (
        <Empty description="No supported Home Assistant entities found" />
      ) : (
        Object.entries(grouped).map(([group, items]) => (
          <div key={group} style={{ marginBottom: 24 }}>
            <Title level={4}>{group}</Title>
            <Row gutter={[16, 16]}>
              {items.map((entity) => (
                <Col key={entity.entity_id} xs={24} sm={12} lg={8} xl={6}>
                  <Card>
                    <Space direction="vertical" style={{ width: "100%" }}>
                      <Space
                        style={{
                          justifyContent: "space-between",
                          width: "100%",
                        }}
                      >
                        <Space>
                          <BulbOutlined />
                          <Text strong>{entity.name}</Text>
                        </Space>
                        <Tag>{entity.state}</Tag>
                      </Space>
                      <Text type="secondary">{entity.entity_id}</Text>
                      {["light", "switch", "fan"].includes(entity.domain) && (
                        <Switch
                          checked={entity.state === "on"}
                          disabled={!entity.available || !canControl}
                          onChange={() =>
                            void callService(entity, nextToggleService(entity))
                          }
                        />
                      )}
                      {entity.domain === "cover" && (
                        <Space>
                          <Button
                            disabled={!canControl}
                            onClick={() =>
                              void callService(entity, SERVICE.OPEN_COVER)
                            }
                          >
                            Open
                          </Button>
                          <Button
                            disabled={!canControl}
                            onClick={() =>
                              void callService(entity, SERVICE.STOP_COVER)
                            }
                          >
                            Stop
                          </Button>
                          <Button
                            disabled={!canControl}
                            onClick={() =>
                              void callService(entity, SERVICE.CLOSE_COVER)
                            }
                          >
                            Close
                          </Button>
                        </Space>
                      )}
                      {entity.domain === "climate" && (
                        <Space wrap>
                          <Select
                            value={entity.state}
                            disabled={!entity.available || !canControl}
                            style={{ minWidth: 100 }}
                            options={(Array.isArray(
                              entity.attributes.hvac_modes,
                            )
                              ? entity.attributes.hvac_modes.filter(
                                  (m): m is string => typeof m === "string",
                                )
                              : []
                            ).map((m) => ({
                              value: m,
                              label: m,
                            }))}
                            onChange={(mode) =>
                              void callService(entity, SERVICE.SET_HVAC_MODE, {
                                hvac_mode: mode,
                              })
                            }
                          />
                          {isNumber(entity.attributes.temperature) && (
                            <InputNumber
                              min={
                                isNumber(entity.attributes.min_temp)
                                  ? entity.attributes.min_temp
                                  : undefined
                              }
                              max={
                                isNumber(entity.attributes.max_temp)
                                  ? entity.attributes.max_temp
                                  : undefined
                              }
                              value={entity.attributes.temperature}
                              disabled={!entity.available || !canControl}
                              suffix="°C"
                              onChange={(value) => {
                                if (value !== null) {
                                  void callService(
                                    entity,
                                    SERVICE.SET_TEMPERATURE,
                                    {
                                      temperature: value,
                                    },
                                  );
                                }
                              }}
                            />
                          )}
                        </Space>
                      )}
                      {["scene", "script"].includes(entity.domain) && (
                        <Button
                          disabled={!canControl}
                          icon={<PoweroffOutlined />}
                          onClick={() =>
                            void callService(entity, SERVICE.TURN_ON)
                          }
                        >
                          Run
                        </Button>
                      )}
                    </Space>
                  </Card>
                </Col>
              ))}
            </Row>
          </div>
        ))
      )}

      <Modal
        title="Home Assistant"
        open={configOpen}
        onOk={saveConfig}
        onCancel={() => setConfigOpen(false)}
      >
        <Form form={form} layout="vertical" initialValues={{ enabled: true }}>
          <Form.Item
            name="base_url"
            label="Base URL"
            rules={[{ required: true }]}
          >
            <Input placeholder="http://homeassistant.local:8123" />
          </Form.Item>
          <Form.Item
            name="token"
            label={
              config?.token_configured ? "New Token" : "Long-Lived Access Token"
            }
          >
            <Input.Password
              placeholder={
                config?.token_configured
                  ? "Leave blank to keep existing token"
                  : "Paste token"
              }
            />
          </Form.Item>
          <Form.Item name="enabled" label="Enabled" valuePropName="checked">
            <Switch />
          </Form.Item>
          <Button loading={testingConfig} onClick={testConfig}>
            Test Connection
          </Button>
        </Form>
      </Modal>
    </div>
  );
}
