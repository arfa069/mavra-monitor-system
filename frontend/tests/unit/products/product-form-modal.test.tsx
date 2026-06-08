import { screen, fireEvent, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi, beforeEach } from "vitest";
import ProductFormModal from "@/features/products/components/ProductFormModal";
import { renderWithApp } from "../test-utils";

describe("ProductFormModal", () => {
  const onSubmit = vi.fn();
  const onCancel = vi.fn();

  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("detects platforms automatically from typed URLs", async () => {
    renderWithApp(
      <ProductFormModal
        open
        onCancel={onCancel}
        onSubmit={onSubmit}
      />
    );

    const user = userEvent.setup();
    const urlInput = screen.getByLabelText("Product URL");

    // Type JD URL
    await user.type(urlInput, "https://item.jd.com/12345.html");
    await waitFor(() => {
      expect(screen.getByText("JD")).toBeInTheDocument();
    });

    // Clear and Type Taobao URL
    await user.clear(urlInput);
    await user.type(urlInput, "https://item.taobao.com/item.htm?id=123");
    await waitFor(() => {
      expect(screen.getByText("Taobao")).toBeInTheDocument();
    });

    // Clear and Type Amazon URL
    await user.clear(urlInput);
    await user.type(urlInput, "https://www.amazon.com/dp/B000");
    await waitFor(() => {
      expect(screen.getByText("Amazon")).toBeInTheDocument();
    });
  });

  it("requires platform and product URL and validates URL format", async () => {
    renderWithApp(
      <ProductFormModal
        open
        onCancel={onCancel}
        onSubmit={onSubmit}
      />
    );

    const okBtn = screen.getByRole("button", { name: /ok/i });
    fireEvent.click(okBtn);

    expect(await screen.findByText("Please select platform")).toBeInTheDocument();
    expect(screen.getByText("Please enter product URL")).toBeInTheDocument();

    const user = userEvent.setup();
    const urlInput = screen.getByLabelText("Product URL");
    await user.type(urlInput, "not-a-url");
    
    expect(await screen.findByText("Invalid URL format")).toBeInTheDocument();
  });

  it("populates initial values in edit mode", async () => {
    const mockProduct = {
      id: 123,
      platform: "jd",
      url: "https://item.jd.com/123.html",
      title: "Test JD Item",
      active: true,
      price: 100,
      lowest_price: 90,
      created_at: "2026-06-08T00:00:00Z",
      updated_at: "2026-06-08T00:00:00Z"
    };

    const mockAlert = {
      id: 99,
      active: true,
      threshold_percent: 10
    };

    renderWithApp(
      <ProductFormModal
        open
        record={mockProduct}
        existingAlert={mockAlert}
        onCancel={onCancel}
        onSubmit={onSubmit}
      />
    );

    expect(await screen.findByText("JD")).toBeInTheDocument();
    expect(screen.getByLabelText("Product URL")).toHaveValue("https://item.jd.com/123.html");
    expect(screen.getByLabelText("Title")).toHaveValue("Test JD Item");
    expect(screen.getByLabelText("Active")).toBeChecked();
    expect(screen.getByLabelText("Enable Alert")).toBeChecked();
    expect(screen.getByRole("spinbutton")).toHaveValue("10");
  });

  it("submits alert enable/disable payloads correctly", async () => {
    renderWithApp(
      <ProductFormModal
        open
        onCancel={onCancel}
        onSubmit={onSubmit}
      />
    );

    const user = userEvent.setup();
    const urlInput = screen.getByLabelText("Product URL");
    await user.type(urlInput, "https://item.jd.com/12345.html");

    // Enable Alert switch using fireEvent.click
    const alertSwitch = screen.getByLabelText("Enable Alert");
    console.log("BEFORE CLICK:", alertSwitch.outerHTML);
    fireEvent.click(alertSwitch);
    console.log("AFTER CLICK:", alertSwitch.outerHTML);

    // Wait for and enter threshold
    const thresholdInput = await screen.findByRole("spinbutton");
    await user.clear(thresholdInput);
    await user.type(thresholdInput, "12");

    const okBtn = screen.getByRole("button", { name: /ok/i });
    await user.click(okBtn);

    await waitFor(() => {
      expect(onSubmit).toHaveBeenCalledWith({
        platform: "jd",
        url: "https://item.jd.com/12345.html",
        title: undefined,
        active: true,
        alert: {
          existingId: null,
          enabled: true,
          threshold: 12
        }
      });
    });
  });

  it("handles cancel button clicks", async () => {
    renderWithApp(
      <ProductFormModal
        open
        onCancel={onCancel}
        onSubmit={onSubmit}
      />
    );

    const cancelBtn = await screen.findByRole("button", { name: /cancel/i });
    fireEvent.click(cancelBtn);

    expect(onCancel).toHaveBeenCalled();
  });
});
