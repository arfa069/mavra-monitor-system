export interface Alert {
  id: number;
  product_id: number;
  alert_type: string;
  threshold_percent: number | null;
  last_notified_at: string | null;
  last_notified_price: number | null;
  active: boolean;
  created_at: string;
  updated_at: string;
}

export interface AlertCreateRequest {
  product_id: number;
  threshold_percent?: number;
  active?: boolean;
}

export interface AlertUpdateRequest {
  threshold_percent?: number;
  active?: boolean;
}
