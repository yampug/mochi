import { getTestPage, setupConsoleLogging } from "./test_utils";

const { test, expect } = require('@playwright/test');

const testPageName = "browser_utils.html";

test.describe('Browser Utils Page', () => {

    test('logs hello from HelloSayer', async ({ page }) => {
         const consoleMessages: string[] = [];
         page.on('console', msg => consoleMessages.push(msg.text()));

         await page.goto(getTestPage(testPageName));

        expect(consoleMessages).toContainEqual(expect.stringContaining("Window"));
     });
});
