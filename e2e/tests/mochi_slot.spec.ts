import { getTestPage, setupConsoleLogging } from "./test_utils";

const { test, expect } = require('@playwright/test');

const testPageName = "slot_test.html";

test.describe('Mochi Slot Test Page', () => {

    test('slot is working correctly', async ({ page }) => {
        const consoleMessages: string[] = [];
        page.on('console', msg => consoleMessages.push(msg.text()));

        await page.goto(getTestPage(testPageName));
        await expect(page).toHaveTitle('Slot Test - Mochi Test Page');

        // Initial navigation for file:// protocol testing
        await page.evaluate(() => {
            // @ts-ignore
            if (window.Opal && window.Opal.MochiRouter) {
                // @ts-ignore
                window.Opal.MochiRouter.$navigate('/slot-test');
            }
        });
        const slotTestHeading = page.locator('h2', { hasText: 'Slot Test' });
        await expect(slotTestHeading).toBeVisible();

        const slotContHeading = page.locator('slot-test h2', { hasText: 'Slot Container' });
        await expect(slotContHeading).toBeVisible();

        const counterHeading = page.locator('slot-test my-counter h1', { hasText: 'Count123: 99' });
        await expect(counterHeading).toBeVisible();
    });
});
