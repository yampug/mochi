import { getTestPage, setupConsoleLogging } from "./test_utils";

const { test, expect } = require('@playwright/test');

const testPageName = "feather_icons.html";

test.describe('Feather Icons Page', () => {
    test('displays page title and components correctly', async ({ page }) => {
        setupConsoleLogging(page);
        await page.goto(getTestPage(testPageName));

        const featherIcons = page.locator('feather-icon');
        await expect(featherIcons).toHaveCount(2);
    });

    test('coffee icon renders correctly', async ({ page }) => {
        setupConsoleLogging(page);
        await page.goto(getTestPage(testPageName));

        const coffeeIcon = page.locator('feather-icon').nth(0);
        await expect(coffeeIcon).toHaveAttribute('icon', 'coffee');

        const shadowRoot = coffeeIcon.locator('div.feather-icon');
        await expect(shadowRoot).toBeVisible();

        const svg = coffeeIcon.locator('svg');
        await expect(svg).toBeVisible();

        await expect(svg).toHaveAttribute('xmlns', 'http://www.w3.org/2000/svg');
        await expect(svg).toHaveAttribute('width', '24');
        await expect(svg).toHaveAttribute('height', '24');
        await expect(svg).toHaveAttribute('viewBox', '0 0 24 24');
        await expect(svg).toHaveAttribute('fill', 'none');
        await expect(svg).toHaveAttribute('stroke', 'currentColor');
        await expect(svg).toHaveAttribute('stroke-width', '2');
        await expect(svg).toHaveAttribute('stroke-linecap', 'round');
        await expect(svg).toHaveAttribute('stroke-linejoin', 'round');
        await expect(svg).toHaveAttribute('class', 'feather feather-coffee');
    });

    test('align-justify icon renders correctly', async ({ page }) => {
        setupConsoleLogging(page);
        await page.goto(getTestPage(testPageName));

        const alignIcon = page.locator('feather-icon').nth(1);

        await expect(alignIcon).toHaveAttribute('icon', 'align-justify');

        const shadowRoot = alignIcon.locator('div.feather-icon');
        await expect(shadowRoot).toBeVisible();

        const svg = alignIcon.locator('svg');
        await expect(svg).toBeVisible();

        await expect(svg).toHaveAttribute('xmlns', 'http://www.w3.org/2000/svg');
        await expect(svg).toHaveAttribute('class', 'feather feather-align-justify');
    });

    test('both icons have unique SVG content', async ({ page }) => {
        setupConsoleLogging(page);
        await page.goto(getTestPage(testPageName));

        const coffeeIcon = page.locator('feather-icon').nth(0);
        const alignIcon = page.locator('feather-icon').nth(1);

        const coffeeSvg = coffeeIcon.locator('svg');
        const alignSvg = alignIcon.locator('svg');

        await expect(coffeeSvg).toBeVisible();
        await expect(alignSvg).toBeVisible();

        const coffeeContent = await coffeeSvg.innerHTML();
        const alignContent = await alignSvg.innerHTML();

        expect(coffeeContent).not.toBe(alignContent);

        expect(coffeeContent).toContain('line');
        expect(coffeeContent).toContain('path');

        expect(alignContent).toContain('line');
    });

    test('icons are displayed in flex container', async ({ page }) => {
        setupConsoleLogging(page);
        await page.goto(getTestPage(testPageName));

        const container = page.locator('div[style*="display: flex"]');
        await expect(container).toBeVisible();

        const iconsInContainer = container.locator('feather-icon');
        await expect(iconsInContainer).toHaveCount(2);
    });

    test('icons render with default Feather Icons styling', async ({ page }) => {
        setupConsoleLogging(page);
        await page.goto(getTestPage(testPageName));

        const coffeeIcon = page.locator('feather-icon').nth(0);
        const svg = coffeeIcon.locator('svg');

        const width = await svg.getAttribute('width');
        const height = await svg.getAttribute('height');

        expect(width).toBe('24');
        expect(height).toBe('24');
    });

    test('feather icons library is loaded', async ({ page }) => {
        setupConsoleLogging(page);
        await page.goto(getTestPage(testPageName));

        const featherAvailable = await page.evaluate(() => {
            return typeof (window as any).feather !== 'undefined';
        });

        expect(featherAvailable).toBe(true);

        const hasIcons = await page.evaluate(() => {
            const feather = (window as any).feather;
            return feather && feather.icons && Object.keys(feather.icons).length > 0;
        });

        expect(hasIcons).toBe(true);
    });
});
