import { getTestPage } from "./test_utils";
import { Page } from "@playwright/test";

const { test } = require("@playwright/test");

const RUNS = 5;
const URL = getTestPage("benchmark.html");

async function timeOp(page: Page, ms: number = 15000): Promise<number> {
    return page.evaluate(
        async (ms) =>
            new Promise<number>((resolve) => {
                const start = performance.now();
                requestAnimationFrame(() =>
                    requestAnimationFrame(() => resolve(performance.now() - start))
                );
            }),
        ms
    );
}

async function clickAndTime(page: Page, selector: string): Promise<number> {
    return page.evaluate(async (sel) => {
        const root = document.querySelector("mochi-benchmark")?.shadowRoot;
        const el = root?.querySelector(sel) as HTMLElement;
        if (!el) throw new Error(`selector not found: ${sel}`);
        const start = performance.now();
        el.click();
        await new Promise<void>((r) =>
            requestAnimationFrame(() => requestAnimationFrame(() => r()))
        );
        return performance.now() - start;
    }, selector);
}

async function setup1000(page: Page) {
    await page.goto(URL);
    await clickAndTime(page, "#run");
    await page.locator("mochi-benchmark").locator('[data-testid="row"]').nth(999).waitFor({ timeout: 10000 });
}

function median(arr: number[]): number {
    const s = [...arr].sort((a, b) => a - b);
    return s[Math.floor(s.length / 2)];
}

function fmt(ms: number): string {
    return ms.toFixed(1).padStart(8);
}

test("benchmark timing", async ({ page }) => {
    const results: { name: string; times: number[] }[] = [];

    const measure = async (
        name: string,
        prepare: () => Promise<void>,
        op: () => Promise<number>
    ) => {
        const times: number[] = [];
        for (let i = 0; i < RUNS; i++) {
            await prepare();
            times.push(await op());
        }
        results.push({ name, times });
    };

    await measure(
        "create 1,000 rows",
        () => page.goto(URL),
        () => clickAndTime(page, "#run")
    );

    await measure(
        "replace all rows",
        async () => { await setup1000(page); },
        () => clickAndTime(page, "#run")
    );

    await measure(
        "partial update (every 10th)",
        async () => { await setup1000(page); },
        () => clickAndTime(page, "#update")
    );

    await measure(
        "select row",
        async () => { await setup1000(page); },
        () =>
            page.evaluate(async () => {
                const root = document.querySelector("mochi-benchmark")?.shadowRoot!;
                const lbl = root.querySelector(".lbl") as HTMLElement;
                const start = performance.now();
                lbl.click();
                await new Promise<void>((r) =>
                    requestAnimationFrame(() => requestAnimationFrame(() => r()))
                );
                return performance.now() - start;
            })
    );

    await measure(
        "swap rows",
        async () => { await setup1000(page); },
        () => clickAndTime(page, "#swaprows")
    );

    await measure(
        "remove row",
        async () => { await setup1000(page); },
        () =>
            page.evaluate(async () => {
                const root = document.querySelector("mochi-benchmark")?.shadowRoot!;
                const btn = root.querySelector(".remove") as HTMLElement;
                const start = performance.now();
                btn.click();
                await new Promise<void>((r) =>
                    requestAnimationFrame(() => requestAnimationFrame(() => r()))
                );
                return performance.now() - start;
            })
    );

    await measure(
        "create 10,000 rows",
        () => page.goto(URL),
        () => clickAndTime(page, "#runlots")
    );

    await measure(
        "append 1,000 rows",
        async () => { await setup1000(page); },
        () => clickAndTime(page, "#add")
    );

    await measure(
        "clear rows",
        async () => { await setup1000(page); },
        () => clickAndTime(page, "#clear")
    );

    const col1 = Math.max(...results.map((r) => r.name.length));
    const header = `${"operation".padEnd(col1)}  ${"median".padStart(8)}  ${"min".padStart(8)}  ${"max".padStart(8)}  runs`;
    const sep = "-".repeat(header.length);
    console.log("\n" + sep);
    console.log(header);
    console.log(sep);
    for (const { name, times } of results) {
        const med = median(times);
        const min = Math.min(...times);
        const max = Math.max(...times);
        console.log(`${name.padEnd(col1)}  ${fmt(med)}ms  ${fmt(min)}ms  ${fmt(max)}ms  [${times.map((t) => t.toFixed(1)).join(", ")}]`);
    }
    console.log(sep + "\n");
});
