import { StrictMode } from "react";
import { screen, waitFor } from "@testing-library/react";
import { http, HttpResponse } from "msw";
import { describe, expect, it, vi } from "vitest";
import api from "@/shared/api/client";
import { jobsApi } from "@/features/jobs/api/jobs";
import { productsApi } from "@/features/products/api/products";
import { smartHomeApi } from "@/features/smart-home/api/smartHome";
import { TodayPage } from "@/features/today";
import { server } from "../mocks/server";
import { renderWithApp } from "../test-utils";

describe("TodayPage", () => {
  it("renders the lived-in morning brief from mocked APIs", async () => {
    renderWithApp(<TodayPage />, { withAuth: false });

    expect(screen.getByText("正在整理今天的节奏...")).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByText("今天只提醒 2 件事。")).toBeInTheDocument();
    });

    expect(screen.getByText(/Dell 显示器/)).toBeInTheDocument();
    expect(screen.getByText(/Frontend Engineer/)).toBeInTheDocument();
    expect(screen.getByText("家里设备都在安静运行。")).toBeInTheDocument();
  });

  it("renders the core brief when smart-home summary is unavailable", async () => {
    server.use(http.get("/api/v1/smart-home/summary", () => HttpResponse.error()));

    renderWithApp(<TodayPage />, { withAuth: false });

    await waitFor(() => {
      expect(screen.getByText("今天只提醒 2 件事。")).toBeInTheDocument();
    });

    expect(screen.getByText(/Dell 显示器/)).toBeInTheDocument();
    expect(screen.getByText(/Frontend Engineer/)).toBeInTheDocument();
  });

  it("deduplicates today data loading during StrictMode remounts", async () => {
    const dashboardSpy = vi.spyOn(api, "get").mockResolvedValue({
      data: {
        user: {
          total_products: 3,
          price_drops_today: 1,
          new_jobs_today: 2,
          match_count: 1,
          crawl_count_today: 4,
        },
        system: null,
      },
    });
    const productsSpy = vi.spyOn(productsApi, "list").mockResolvedValue({
      data: {
        items: [
          {
            id: 12,
            title: "Dell 显示器",
            platform: "jd",
          },
        ],
      },
    } as never);
    const matchesSpy = vi.spyOn(jobsApi, "getMatchResults").mockResolvedValue({
      data: {
        items: [
          {
            id: 9,
            match_score: 92,
            job_title: "Frontend Engineer",
            job_company: "Example Co",
            job_location: "Shanghai",
          },
        ],
      },
    } as never);
    const summarySpy = vi.spyOn(smartHomeApi, "getSummary").mockResolvedValue({
      data: {
        configured: true,
        connected: true,
        active_count: 1,
        unavailable_count: 0,
      },
    } as never);
    const entitiesSpy = vi.spyOn(smartHomeApi, "listEntities");

    renderWithApp(
      <StrictMode>
        <TodayPage />
      </StrictMode>,
      { withAuth: false },
    );

    await waitFor(() => {
      expect(screen.getByText("今天只提醒 2 件事。")).toBeInTheDocument();
    });

    expect(dashboardSpy).toHaveBeenCalledTimes(1);
    expect(productsSpy).toHaveBeenCalledTimes(1);
    expect(matchesSpy).toHaveBeenCalledTimes(1);
    expect(summarySpy).toHaveBeenCalledTimes(1);
    expect(entitiesSpy).not.toHaveBeenCalled();
  });
});
