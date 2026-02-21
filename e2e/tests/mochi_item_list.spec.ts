import { getTestPage, setupConsoleLogging } from "./test_utils";

const { test, expect } = require('@playwright/test');

const testPageName = "item_list.html";

test.describe('Item List Test Page', () => {

    test('item lists are working correctly', async ({ page }) => {
        const consoleMessages: string[] = [];
        page.on('console', msg => consoleMessages.push(msg.text()));

        await page.goto(getTestPage(testPageName));
        await expect(page).toHaveTitle('Item List - Mochi Test Page');

        // Initial navigation for file:// protocol testing
        await page.evaluate(() => {
            // @ts-ignore
            if (window.Opal && window.Opal.MochiRouter) {
                // @ts-ignore
                window.Opal.MochiRouter.$navigate('/item-list');
            }
        });
        const itemListHeading = page.getByRole('heading', { name: 'Item List', exact: true });
        await expect(itemListHeading).toBeVisible();

        const itemListElHeading = page.locator('item-list h2', { hasText: 'Item List (Each Block Demo)' });
        await expect(itemListElHeading).toBeVisible();

        const counterEl = page.locator('item-list .wrapper p').filter({ hasText: 'Counter' });
        await expect(counterEl).toHaveText("Counter: 0");

        const addItemBtn = page.locator('item-list .wrapper button').filter({ hasText: 'Add Item' });
        const removeItemBtn = page.locator('item-list .wrapper button').filter({ hasText: 'Remove Item' });

        await addItemBtn.click();
        await expect(counterEl).toHaveText("Counter: 1");
        await addItemBtn.click();
        await expect(counterEl).toHaveText("Counter: 2");
        await removeItemBtn.click();
        await expect(counterEl).toHaveText("Counter: 1");
        await addItemBtn.click();
        await expect(counterEl).toHaveText("Counter: 2");
        await removeItemBtn.click();
        await removeItemBtn.click();
        await expect(counterEl).toHaveText("Counter: 0");
        // as we start with 3 elements already, lets remove them too
        await removeItemBtn.click();
        await removeItemBtn.click();
        await removeItemBtn.click();
        await expect(counterEl).toHaveText("Counter: -3");

        const noItemsIfLabel = page.locator('item-list mochi-if p', { hasText: 'No items to display' });
        await expect(noItemsIfLabel).toBeVisible();
    });
});
