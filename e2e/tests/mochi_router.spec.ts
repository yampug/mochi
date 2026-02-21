import { getTestPage, setupConsoleLogging } from "./test_utils";

const { test, expect } = require('@playwright/test');

const testPageName = "mochi_router.html";

test.describe('Mochi Router Test Page', () => {

    test('can go to about', async ({ page }) => {
        const consoleMessages: string[] = [];
        page.on('console', msg => consoleMessages.push(msg.text()));

        await page.goto(getTestPage(testPageName));
        await expect(page).toHaveTitle('Mochi Router - Mochi Test Page');

        // Initial navigation for file:// protocol testing
        await page.evaluate(() => {
            // @ts-ignore
            if (window.Opal && window.Opal.MochiRouter) {
                // @ts-ignore
                window.Opal.MochiRouter.$navigate('/mochi-router');
            }
        });

        // are we on the home page?
        const homeHeading = page.locator('mochi-route[match="/mochi-router"] h3', { hasText: 'Home Page' });
        await expect(homeHeading).toBeVisible();

        await page.getByRole('link', { name: 'About' }).click();

        // are we on the about page?
        console.log(consoleMessages);
        expect(consoleMessages).toContainEqual(expect.stringContaining("MochiRouter: navigating to /about"));
        const aboutHeading = page.locator('mochi-route[match="/about"] h3', { hasText: 'About Page' });
        await expect(aboutHeading).toBeVisible();

        await page.getByRole('link', { name: 'Contact' }).click();

        // are we on the contact page?
        console.log(consoleMessages);
        expect(consoleMessages).toContainEqual(expect.stringContaining("MochiRouter: navigating to /contact"));
        const contactHeading = page.locator('mochi-route[match="/contact"] h3', { hasText: 'Contact Page' });
        await expect(contactHeading).toBeVisible();

        await page.getByRole('link', { name: 'External Link' }).click();
        console.log(consoleMessages);
        await expect(page).toHaveURL(/example\.com/);
    });
});
