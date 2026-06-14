import {
  alertsListAlerts,
  alertsGetAlert,
  alertsCreateAlert,
  alertsUpdateAlert,
  alertsDeleteAlert,
} from "@/shared/api/generated/alerts/alerts";
import type { AlertCreateRequest, AlertUpdateRequest } from "@/shared/api/generated/models";

export const alertsApi = {
  list: (params?: { product_id?: number; active?: boolean }) =>
    alertsListAlerts(params),

  get: (id: number) => alertsGetAlert(id),

  create: (data: AlertCreateRequest) => alertsCreateAlert(data),

  update: (id: number, data: AlertUpdateRequest) =>
    alertsUpdateAlert(id, data),

  delete: (id: number) => alertsDeleteAlert(id),
};
