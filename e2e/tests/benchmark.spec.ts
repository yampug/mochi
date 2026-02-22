import { getTestPage, setupConsoleLogging } from "./test_utils";

const { test, expect } = require('@playwright/test');

const testPageName = "benchmark.html";

test.describe('Mochi Benchmark', () => {

    test('create 1000 rows', async ({ page }) => {
        setupConsoleLogging(page);
        await page.goto(getTestPage(testPageName));

        await page.locator('#run').click();

        const rows = page.locator('mochi-benchmark').locator('[data-testid="row"]');
        await expect(rows).toHaveCount(1000, { timeout: 10000 });
    });

    test('replace all rows', async ({ page }) => {
        setupConsoleLogging(page);
        await page.goto(getTestPage(testPageName));

        await page.locator('#run').click();
        await expect(page.locator('mochi-benchmark').locator('[data-testid="row"]')).toHaveCount(1000, { timeout: 10000 });

        await page.locator('#run').click();
        await expect(page.locator('mochi-benchmark').locator('[data-testid="row"]')).toHaveCount(1000, { timeout: 10000 });

        const firstId = await page.locator('mochi-benchmark').locator('[data-testid="row"] .col-id').first().textContent();
        expect(parseInt(firstId!)).toBe(1001);
    });

    test('partial update every 10th row', async ({ page }) => {
        setupConsoleLogging(page);
        await page.goto(getTestPage(testPageName));

        await page.locator('#run').click();
        await expect(page.locator('mochi-benchmark').locator('[data-testid="row"]')).toHaveCount(1000, { timeout: 10000 });

        await page.locator('#update').click();

        const firstLabel = await page.locator('mochi-benchmark').locator('[data-testid="row"] .lbl').first().textContent();
        expect(firstLabel).toContain(' !!!');

        const secondLabel = await page.locator('mochi-benchmark').locator('[data-testid="row"] .lbl').nth(1).textContent();
        expect(secondLabel).not.toContain(' !!!');
    });

    test('select row highlights it', async ({ page }) => {
        setupConsoleLogging(page);
        await page.goto(getTestPage(testPageName));

        await page.locator('#run').click();
        await expect(page.locator('mochi-benchmark').locator('[data-testid="row"]')).toHaveCount(1000, { timeout: 10000 });

        const firstRow = page.locator('mochi-benchmark').locator('[data-testid="row"]').first();
        await firstRow.locator('.lbl').click();

        await expect(firstRow).toHaveClass(/danger/);
    });

    test('swap rows', async ({ page }) => {
        setupConsoleLogging(page);
        await page.goto(getTestPage(testPageName));

        await page.locator('#run').click();
        await expect(page.locator('mochi-benchmark').locator('[data-testid="row"]')).toHaveCount(1000, { timeout: 10000 });

        const rows = page.locator('mochi-benchmark').locator('[data-testid="row"]');
        const row2LabelBefore = await rows.nth(1).locator('.lbl').textContent();
        const row999LabelBefore = await rows.nth(998).locator('.lbl').textContent();

        await page.locator('#swaprows').click();

        const row2LabelAfter = await rows.nth(1).locator('.lbl').textContent();
        const row999LabelAfter = await rows.nth(998).locator('.lbl').textContent();

        expect(row2LabelAfter).toBe(row999LabelBefore);
        expect(row999LabelAfter).toBe(row2LabelBefore);
    });

    test('remove row', async ({ page }) => {
        setupConsoleLogging(page);
        await page.goto(getTestPage(testPageName));

        await page.locator('#run').click();
        await expect(page.locator('mochi-benchmark').locator('[data-testid="row"]')).toHaveCount(1000, { timeout: 10000 });

        const firstId = await page.locator('mochi-benchmark').locator('[data-testid="row"] .col-id').first().textContent();

        await page.locator('mochi-benchmark').locator('[data-testid="row"]').first().locator('.remove').click();

        await expect(page.locator('mochi-benchmark').locator('[data-testid="row"]')).toHaveCount(999, { timeout: 10000 });

        const newFirstId = await page.locator('mochi-benchmark').locator('[data-testid="row"] .col-id').first().textContent();
        expect(newFirstId).not.toBe(firstId);
    });

    test('clear removes all rows', async ({ page }) => {
        setupConsoleLogging(page);
        await page.goto(getTestPage(testPageName));

        await page.locator('#run').click();
        await expect(page.locator('mochi-benchmark').locator('[data-testid="row"]')).toHaveCount(1000, { timeout: 10000 });

        await page.locator('#clear').click();

        await expect(page.locator('mochi-benchmark').locator('[data-testid="row"]')).toHaveCount(0, { timeout: 10000 });
    });

    test('append 1000 rows', async ({ page }) => {
        setupConsoleLogging(page);
        await page.goto(getTestPage(testPageName));

        await page.locator('#run').click();
        await expect(page.locator('mochi-benchmark').locator('[data-testid="row"]')).toHaveCount(1000, { timeout: 10000 });

        await page.locator('#add').click();
        await expect(page.locator('mochi-benchmark').locator('[data-testid="row"]')).toHaveCount(2000, { timeout: 15000 });
    });
});
