import { getTestPage } from "./test_utils";

const { test, expect } = require('@playwright/test');

function getChartsPage(): string {
    return getTestPage("charts.html");
}

test.describe('Charts Page', () => {
    test('chart-demo component renders', async ({ page }) => {
        await page.goto(getChartsPage());

        const chartDemo = page.locator('chart-demo');
        await expect(chartDemo).toBeVisible();
    });

    test('chart container div renders with correct dimensions', async ({ page }) => {
        await page.goto(getChartsPage());

        const chartDemo = page.locator('chart-demo');
        const mainDiv = chartDemo.locator('#main');

        await expect(mainDiv).toBeVisible();

        const width = await mainDiv.evaluate((el) => (el as HTMLElement).style.width);
        const height = await mainDiv.evaluate((el) => (el as HTMLElement).style.height);

        expect(width).toBe('600px');
        expect(height).toBe('400px');
    });

    test('chart renders after loading', async ({ page }) => {
        await page.goto(getChartsPage());

        const chartDemo = page.locator('chart-demo');
        const mainDiv = chartDemo.locator('#main');

        await page.waitForTimeout(4000);

        const hasCanvas = await mainDiv.locator('canvas').count();
        const hasSvg = await mainDiv.locator('svg').count();

        // ECharts typically uses canvas, but we check for both
        expect(hasCanvas + hasSvg).toBeGreaterThan(0);
    });

    test('chart canvas has non-zero dimensions after loading', async ({ page }) => {
        await page.goto(getChartsPage());

        await page.waitForTimeout(4000);

        const chartDemo = page.locator('chart-demo');
        const mainDiv = chartDemo.locator('#main');
        const canvas = mainDiv.locator('canvas').first();

        await expect(canvas).toBeVisible();

        const canvasDimensions = await canvas.evaluate((el) => {
            const canvasEl = el as HTMLCanvasElement;
            return {
                width: canvasEl.width,
                height: canvasEl.height
            };
        });

        expect(canvasDimensions.width).toBeGreaterThan(0);
        expect(canvasDimensions.height).toBeGreaterThan(0);
    });

    test('chart is initialized within the shadow DOM', async ({ page }) => {
        await page.goto(getChartsPage());

        await page.waitForTimeout(4000);

        // Verify that the chart is rendered inside the shadow DOM
        const hasChartInShadowDOM = await page.evaluate(() => {
            const chartDemo = document.querySelector('chart-demo');
            const shadowRoot = chartDemo?.shadowRoot;
            const mainDiv = shadowRoot?.querySelector('#main');
            const canvas = mainDiv?.querySelector('canvas');

            return {
                hasChartDemo: !!chartDemo,
                hasShadowRoot: !!shadowRoot,
                hasMainDiv: !!mainDiv,
                hasCanvas: !!canvas
            };
        });

        expect(hasChartInShadowDOM.hasChartDemo).toBe(true);
        expect(hasChartInShadowDOM.hasShadowRoot).toBe(true);
        expect(hasChartInShadowDOM.hasMainDiv).toBe(true);
        expect(hasChartInShadowDOM.hasCanvas).toBe(true);
    });

    test('chart component logs to console', async ({ page }) => {
        const consoleLogs: string[] = [];

        page.on('console', msg => {
            consoleLogs.push(msg.text());
        });

        await page.goto(getChartsPage());

        await page.waitForTimeout(4000);

        expect(consoleLogs.some(log => log.includes('ChartDemo mounted'))).toBe(true);
        expect(consoleLogs.some(log => log.includes('done'))).toBe(true);
    });

    test('feather icons library is loaded', async ({ page }) => {
        await page.goto(getChartsPage());

        const featherAvailable = await page.evaluate(() => {
            return typeof (window as any).feather !== 'undefined';
        });

        expect(featherAvailable).toBe(true);
    });
});
