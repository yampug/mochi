import { getTestPage, setupConsoleLogging } from "./test_utils";

const { test, expect } = require('@playwright/test');

const testPageName = "ruby_importer.html";

test.describe('Ruby Importer Page Page', () => {

    test('logs hello from HelloSayer', async ({ page }) => {
         const consoleMessages: string[] = [];
         page.on('console', msg => consoleMessages.push(msg.text()));

         await page.goto(getTestPage(testPageName));

        expect(consoleMessages).toContainEqual(expect.stringContaining('Hello from HelloSayer!'));
     });
});
