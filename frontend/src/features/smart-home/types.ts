export type SmartHomeDomain =
  | "light"
  | "switch"
  | "fan"
  | "cover"
  | "climate"
  | "scene"
  | "script";

export interface SmartHomeConfig {
  id: number;
  base_url: string;
  enabled: boolean;
  last_status: string | null;
  last_error: string | null;
  created_at: string;
  updated_at: string;
  token_configured: boolean;
}

export interface SmartHomeConfigUpdate {
  base_url: string;
  token?: string | null;
  enabled: boolean;
}

export interface SmartHomeEntity {
  entity_id: string;
  domain: SmartHomeDomain;
  name: string;
  state: string;
  area: string | null;
  attributes: Record<string, unknown>;
  last_changed: string | null;
  last_updated: string | null;
  available: boolean;
}

export interface SmartHomeEntityListResponse {
  items: SmartHomeEntity[];
  total: number;
  connected: boolean;
  last_error: string | null;
}

export interface SmartHomeServiceRequest {
  service: string;
  service_data: Record<string, unknown>;
}
