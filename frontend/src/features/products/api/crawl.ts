import {
  productsCrawlCrawlNow,
  productsCrawlGetCrawlStatus,
  productsCrawlGetCrawlResult,
  productsCrawlGetCrawlLogs,
} from "@/shared/api/generated/products-crawl/products-crawl";
import type {
  TaskQueuedResponse as CrawlNowResponse,
  TaskProgressResponse as CrawlStatusResponse,
} from "@/shared/api/generated/models";

export type { CrawlNowResponse, CrawlStatusResponse };
export type CrawlResultResponse = CrawlStatusResponse;

export const crawlApi = {
  crawlNow: () => productsCrawlCrawlNow(),

  getStatus: (taskId: string) => productsCrawlGetCrawlStatus(taskId),

  getResult: (taskId: string) => productsCrawlGetCrawlResult(taskId),

  getLogs: (params?: {
    product_id?: number;
    status?: string;
    hours?: number;
    limit?: number;
  }) => {
    /* eslint-disable-next-line @typescript-eslint/no-explicit-any */
    return productsCrawlGetCrawlLogs(params as any);
  },
};
