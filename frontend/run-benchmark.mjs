/**
 * Mavra Monitor System — Performance Benchmark
 * Measures Core Web Vitals + resource budgets across key pages.
 * Run AFTER starting the dev server: npm run dev -- --port 3000
 * Usage: node run-benchmark.mjs [--baseline] [--quick]
 */
import { chromium } from "@playwright/test";
import { execSync } from "child_process";
import { writeFileSync, readFileSync, existsSync, mkdirSync } from "fs";
import { resolve, dirname } from "path";
import { fileURLToPath } from "url";

const __dir = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(__dir, "../../");
const BASELINE_FILE = resolve(__dir, "baselines/baseline.json");
const args = process.argv.slice(2);
const BASELINE_MODE = args.includes("--baseline");
const QUICK_MODE = args.includes("--quick");
const BASE_URL = "http://localhost:3000";

const PAGES = [
  { path: "/jobs",       label: "Jobs" },
  { path: "/dashboard",  label: "Dashboard" },
  { path: "/products",   label: "Products" },
  { path: "/today",      label: "Today" },
  { path: "/smart-home", label: "Smart Home" },
];

// ─── helpers ─────────────────────────────────────────────────────────────────
const ms = (n) => `${Math.round(n)}ms`;
const kb = (n) => `${(n / 1024).toFixed(1)}KB`;

function delta(base, cur) {
  const diff = cur - base;
  const pct = base ? ((diff / base) * 100).toFixed(0) : "n/a";
  const sign = diff > 0 ? "+" : "";
  return { diff, pct, label: `${sign}${Math.round(diff)}ms (${sign}${pct}%)` };
}

function status(metric, base, cur) {
  if (!base) return "—";
  const d = delta(base, cur);
  if (metric === "requests") {
    return d.diff / base > 0.3 ? "⚠️  WARNING" : "✅ OK";
  }
  if (metric === "bytes") {
    const r = d.diff / base;
    if (r > 0.25) return "🔴 REGRESSION";
    if (r > 0.10) return "⚠️  WARNING";
    return "✅ OK";
  }
  // timing
  const r = d.diff / base;
  const abs = d.diff;
  if (r > 0.5 || abs > 500) return "🔴 REGRESSION";
  if (r > 0.2 || abs > 200) return "⚠️  WARNING";
  if (d.diff < 0) return "✅ IMPROVED";
  return "✅ OK";
}

// ─── measure one page ─────────────────────────────────────────────────────────
async function measurePage(browser, url) {
  const ctx = await browser.newContext();
  const page = await ctx.newPage();

  await page.goto(url, { waitUntil: "networkidle", timeout: 30_000 });

  const nav = await page.evaluate(() => {
    const n = performance.getEntriesByType("navigation")[0];
    if (!n) return null;
    return {
      ttfb:           n.responseStart - n.requestStart,
      domInteractive: n.domInteractive - n.startTime,
      domComplete:    n.domComplete    - n.startTime,
      fullLoad:       n.loadEventEnd   - n.startTime,
    };
  });

  const paint = await page.evaluate(() => {
    const entries = {};
    for (const e of performance.getEntriesByType("paint")) {
      if (e.name === "first-contentful-paint") entries.fcp = e.startTime;
    }
    return entries;
  });

  const resources = await page.evaluate(() =>
    performance.getEntriesByType("resource").map((r) => ({
      name:  r.name.split("/").pop().split("?")[0],
      type:  r.initiatorType,
      size:  r.transferSize  || 0,
      duration: Math.round(r.duration),
    }))
  );

  const network = await page.evaluate(() => {
    const r = performance.getEntriesByType("resource");
    const byType = r.reduce((a, e) => {
      a[e.initiatorType] = (a[e.initiatorType] || 0) + 1;
      return a;
    }, {});
    return {
      total_requests: r.length,
      total_bytes:    r.reduce((s, e) => s + (e.transferSize || 0), 0),
      by_type:        byType,
    };
  });

  const jsBundles  = resources.filter((r) => r.type === "script");
  const cssBundles = resources.filter((r) => r.type === "css");
  const jsBytes    = jsBundles.reduce((s, r) => s + r.size, 0);
  const cssBytes   = cssBundles.reduce((s, r) => s + r.size, 0);

  const top10 = [...resources]
    .sort((a, b) => b.duration - a.duration)
    .slice(0, 10);

  await ctx.close();

  return {
    ttfb:           nav?.ttfb           ?? 0,
    fcp:            paint.fcp           ?? 0,
    domInteractive: nav?.domInteractive ?? 0,
    domComplete:    nav?.domComplete    ?? 0,
    fullLoad:       nav?.fullLoad       ?? 0,
    totalRequests:  network.total_requests,
    totalBytes:     network.total_bytes,
    jsBytes,
    cssBytes,
    byType:         network.by_type,
    top10,
    jsFiles:        jsBundles,
    cssFiles:       cssBundles,
  };
}

// ─── budget check ─────────────────────────────────────────────────────────────
function budgetCheck(m) {
  const checks = [
    { metric: "FCP",            budget: 1800,    actual: m.fcp,           unit: "ms" },
    { metric: "DOM Complete",   budget: 3000,    actual: m.domComplete,   unit: "ms" },
    { metric: "Full Load",      budget: 4000,    actual: m.fullLoad,      unit: "ms" },
    { metric: "Total JS",       budget: 500*1024,actual: m.jsBytes,       unit: "KB", kb: true },
    { metric: "Total CSS",      budget: 100*1024,actual: m.cssBytes,      unit: "KB", kb: true },
    { metric: "Total Transfer", budget: 2*1024*1024, actual: m.totalBytes, unit: "MB", mb: true },
    { metric: "HTTP Requests",  budget: 60,      actual: m.totalRequests, unit: "" },
  ];

  let pass = 0;
  const rows = checks.map((c) => {
    const pct = c.actual / c.budget;
    let result;
    if (pct <= 1)       { result = "✅ PASS";         pass++; }
    else if (pct < 1.2) { result = "⚠️  WARN";  }
    else                { result = "❌ FAIL"; }

    const fmtBudget = c.mb ? `${(c.budget/1024/1024).toFixed(0)}MB`
                    : c.kb ? kb(c.budget)
                    : `${c.budget}${c.unit}`;
    const fmtActual = c.mb ? `${(c.actual/1024/1024).toFixed(1)}MB`
                    : c.kb ? kb(c.actual)
                    : `${Math.round(c.actual)}${c.unit}`;
    return { metric: c.metric, budget: fmtBudget, actual: fmtActual, result };
  });

  return { rows, score: `${pass}/${checks.length}` };
}

// ─── report printer ───────────────────────────────────────────────────────────
function printReport(results, baseline) {
  const lines = [];
  const hr = (ch = "═", w = 56) => ch.repeat(w);

  lines.push(`\n${"═".repeat(60)}`);
  lines.push(` PERFORMANCE BENCHMARK — ${BASE_URL}`);
  lines.push(`${"═".repeat(60)}`);
  lines.push(` Mode: ${BASELINE_MODE ? "BASELINE CAPTURE" : QUICK_MODE ? "QUICK" : "FULL AUDIT"}`);
  lines.push(` Date: ${new Date().toISOString()}`);
  if (baseline) lines.push(` vs Baseline: ${baseline.timestamp} (${baseline.branch})`);
  lines.push("");

  const regressions = [];

  for (const [path, m] of Object.entries(results.pages)) {
    const label = PAGES.find((p) => p.path === path)?.label ?? path;
    const b = baseline?.pages?.[path];

    lines.push(`\n┌${"─".repeat(58)}┐`);
    lines.push(` Page: ${label} (${path})`);
    lines.push(`└${"─".repeat(58)}┘`);

    const fmt = (v, base, type) => {
      const cur  = type === "bytes" ? kb(v)  : ms(v);
      if (!base) return cur;
      const bFmt = type === "bytes" ? kb(base) : ms(base);
      const d    = delta(base, v);
      const st   = status(type || "timing", base, v);
      return `${cur} (was ${bFmt}, ${d.label}) ${st}`;
    };

    lines.push(`  TTFB            ${fmt(m.ttfb,           b?.ttfb)}`);
    lines.push(`  FCP             ${fmt(m.fcp,            b?.fcp)}`);
    lines.push(`  DOM Interactive ${fmt(m.domInteractive, b?.domInteractive)}`);
    lines.push(`  DOM Complete    ${fmt(m.domComplete,    b?.domComplete)}`);
    lines.push(`  Full Load       ${fmt(m.fullLoad,       b?.fullLoad)}`);
    lines.push(`  HTTP Requests   ${m.totalRequests}${b ? ` (was ${b.totalRequests})` : ""}`);
    lines.push(`  Transfer        ${fmt(m.totalBytes,     b?.totalBytes, "bytes")}`);
    lines.push(`  JS Bundles      ${fmt(m.jsBytes,        b?.jsBytes,    "bytes")}`);
    lines.push(`  CSS Bundles     ${fmt(m.cssBytes,       b?.cssBytes,   "bytes")}`);

    // collect regressions
    if (b) {
      const checks = [
        ["FCP",          m.fcp,            b.fcp,          "timing"],
        ["Full Load",    m.fullLoad,       b.fullLoad,     "timing"],
        ["JS Bundles",   m.jsBytes,        b.jsBytes,      "bytes"],
        ["Transfer",     m.totalBytes,     b.totalBytes,   "bytes"],
      ];
      for (const [name, cur, base2, type] of checks) {
        const st = status(type, base2, cur);
        if (st.includes("REGRESSION")) {
          regressions.push(`  [${path}] ${name}: ${type === "bytes" ? kb(base2) : ms(base2)} → ${type === "bytes" ? kb(cur) : ms(cur)}`);
        }
      }
    }

    // budget
    const budget = budgetCheck(m);
    lines.push(`\n  BUDGET CHECK (${budget.score} passing)`);
    for (const row of budget.rows) {
      lines.push(`    ${row.result}  ${row.metric.padEnd(16)} budget=${row.budget.padEnd(8)} actual=${row.actual}`);
    }

    // top resources
    if (!QUICK_MODE && m.top10.length) {
      lines.push(`\n  TOP SLOWEST RESOURCES`);
      m.top10.slice(0, 8).forEach((r, i) => {
        lines.push(`    ${String(i+1).padStart(2)}.  ${r.name.padEnd(34)} ${r.type.padEnd(8)} ${kb(r.size).padEnd(10)} ${r.duration}ms`);
      });
    }
  }

  if (regressions.length) {
    lines.push(`\n${"═".repeat(60)}`);
    lines.push(` 🔴 REGRESSIONS DETECTED: ${regressions.length}`);
    lines.push(`${"═".repeat(60)}`);
    regressions.forEach((r) => lines.push(r));
  } else if (baseline) {
    lines.push(`\n✅ No regressions vs baseline.`);
  }

  lines.push(`\n${"═".repeat(60)}\n`);
  return lines.join("\n");
}

// ─── main ─────────────────────────────────────────────────────────────────────
async function main() {
  // Verify dev server is running
  try {
    const testResp = await fetch(`${BASE_URL}/`);
    console.log(`✓ Dev server running (HTTP ${testResp.status})`);
  } catch {
    console.error(`\n❌ Dev server not reachable at ${BASE_URL}`);
    console.error("   Start it first: npm run dev -- --port 3000");
    process.exit(1);
  }

  const browser = await chromium.launch({ headless: true });
  const results = { timestamp: new Date().toISOString(), url: BASE_URL, branch: "unknown", pages: {} };

  try {
    results.branch = execSync("git branch --show-current", { cwd: ROOT, encoding: "utf8" }).trim();
  } catch {}

  const pagesToTest = QUICK_MODE ? PAGES.slice(0, 2) : PAGES;

  for (const { path, label } of pagesToTest) {
    const url = `${BASE_URL}${path}`;
    process.stdout.write(`  Measuring ${label.padEnd(14)} ${url} ...`);
    try {
      results.pages[path] = await measurePage(browser, url);
      console.log(` ✓ ${ms(results.pages[path].fullLoad)}`);
    } catch (e) {
      console.log(` ✗ ${e.message}`);
    }
  }

  await browser.close();

  // Load baseline for comparison
  const baseline = !BASELINE_MODE && existsSync(BASELINE_FILE)
    ? JSON.parse(readFileSync(BASELINE_FILE, "utf8"))
    : null;

  if (BASELINE_MODE) {
    mkdirSync(dirname(BASELINE_FILE), { recursive: true });
    writeFileSync(BASELINE_FILE, JSON.stringify(results, null, 2));
    console.log(`\n✅ Baseline saved → ${BASELINE_FILE}`);
  }

  // Print report
  const report = printReport(results, baseline);
  console.log(report);

  // Save dated report
  const date = new Date().toISOString().slice(0, 10);
  const reportPath = resolve(__dir, `${date}-benchmark.md`);
  const jsonPath   = resolve(__dir, `${date}-benchmark.json`);
  writeFileSync(reportPath, report);
  writeFileSync(jsonPath,   JSON.stringify({ results, baseline: baseline ?? null }, null, 2));
  console.log(`Reports saved:\n  ${reportPath}\n  ${jsonPath}`);
}

main().catch((e) => { console.error(e); process.exit(1); });
