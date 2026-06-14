import {
  productsCrawlCrawlNow,
  productsCrawlGetCrawlStatus,
  productsCrawlGetCrawlResult,
  productsCrawlGetCrawlLogs,
} from "@/shared/api/generated/products-crawl/products-crawl";
import type {
  ProductsCrawlGetCrawlLogsParams,
  TaskQueuedResponse as CrawlNowResponse,
  TaskProgressResponse as CrawlStatusResponse,
} from "@/shared/api/generated/models";

export type { CrawlNowResponse, CrawlStatusResponse };
export type CrawlResultResponse = CrawlStatusResponse;

export const crawlApi = {
  crawlNow: () => productsCrawlCrawlNow(),

  getStatus: (taskId: string) => productsCrawlGetCrawlStatus(taskId),

  getResult: (taskId: string) => productsCrawlGetCrawlResult(taskId),

  getLogs: (params?: ProductsCrawlGetCrawlLogsParams) =>
    productsCrawlGetCrawlLogs(params),
};
