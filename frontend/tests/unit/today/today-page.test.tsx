import { screen, waitFor } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { TodayPage } from "@/features/today";
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
});
