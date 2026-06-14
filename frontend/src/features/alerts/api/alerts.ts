import {
  alertsListAlerts,
  alertsGetAlert,
  alertsCreateAlert,
  alertsUpdateAlert,
  alertsDeleteAlert,
} from "@/shared/api/generated/alerts/alerts";
import type { AlertCreate, AlertUpdate } from "@/shared/api/generated/models";

export const alertsApi = {
  list: (params?: { product_id?: number; active?: boolean }) =>
    alertsListAlerts(params),

  get: (id: number) => alertsGetAlert(id),

  create: (data: AlertCreate) => alertsCreateAlert(data),

  update: (id: number, data: AlertUpdate) =>
    alertsUpdateAlert(id, data),

  delete: (id: number) => alertsDeleteAlert(id),
};
