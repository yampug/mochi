import {getTestPage, setupConsoleLogging} from "./test_utils";

const { test, expect } = require('@playwright/test');

test('displays basic counters info correctly', async ({ page }) => {
    setupConsoleLogging(page);
    await page.goto(getTestPage("basic_counters.html"));
    await expect(page).toHaveTitle('Basic Counters - Mochi Test Page');

    // first counter
    await checkCounter(page, 0, "3", "0");
    // second counter
    await checkCounter(page, 1, "4", "0");
    // standalone plus five
    const standPlusFive = page.locator(".plus-five").nth(2);
    let plusFiveBtn = standPlusFive.locator("button");
    await expect(plusFiveBtn).toHaveText('Increment');
    let plusFiveOutput = standPlusFive.locator("div");
    await expect(plusFiveOutput).toHaveText(`pfcount: 0`);
});

test('first counter interaction - inc inc dec dec dec', async ({ page }) => {
    setupConsoleLogging(page);
    await page.goto(getTestPage("basic_counters.html"));
    // 1 - interact with the first counter and the second one should be untouched
    {
        let counter = page.locator('.wrapper').nth(0);

        const incBtn = counter.locator("button").nth(0);
        const decBtn = counter.locator("button").nth(1);

        await checkCounter(page, 0, "3", "0");
        await checkCounter(page, 1, "4", "0");
        await incBtn.click();
        await checkCounter(page, 0, "4", "1");
        await checkCounter(page, 1, "4", "0");
        await incBtn.click();
        await checkCounter(page, 0, "5", "2");
        await checkCounter(page, 1, "4", "0");
        await decBtn.click();
        await checkCounter(page, 0, "4", "3");
        await checkCounter(page, 1, "4", "0");
        await decBtn.click();
        await checkCounter(page, 0, "3", "4");
        await checkCounter(page, 1, "4", "0");
        await decBtn.click();
        await checkCounter(page, 0, "2", "5");
        await checkCounter(page, 1, "4", "0");
    }

    // 2 - interact with the second counter and the first one should be untouched
    {
        let counter = page.locator('.wrapper').nth(1);

        const incBtn = counter.locator("button").nth(0);
        const decBtn = counter.locator("button").nth(1);

        await checkCounter(page, 0, "2", "5");
        await checkCounter(page, 1, "4", "0");
        await incBtn.click();
        await checkCounter(page, 0, "2", "5");
        await checkCounter(page, 1, "5", "1");
        await incBtn.click();
        await checkCounter(page, 0, "2", "5");
        await checkCounter(page, 1, "6", "2");
        await decBtn.click();
        await checkCounter(page, 0, "2", "5");
        await checkCounter(page, 1, "5", "3");
        await decBtn.click();
        await checkCounter(page, 0, "2", "5");
        await checkCounter(page, 1, "4", "4");
        await decBtn.click();
        await checkCounter(page, 0, "2", "5");
        await checkCounter(page, 1, "3", "5");
    }
});


async function checkCounter(page, counterIndex: number, countValue: string, modifications: string) {
    let counter = page.locator('.wrapper').nth(counterIndex);

    const firstH1 = counter.locator("h1");
    await expect(firstH1).toHaveText(`Count123: ${countValue}`);

    const firstH2 = counter.locator("h2");
    await expect(firstH2).toHaveText(`Modifications: ${modifications}`);

    const incBtn = counter.locator("button").nth(0);
    await expect(incBtn).toHaveText('Increment');
    await expect(incBtn).toHaveAttribute('on:click', "{increment}");

    const decBtn = counter.locator("button").nth(1);
    await expect(decBtn).toHaveText('Decrement');
    await expect(decBtn).toHaveAttribute('on:click', "{decrement}");

    let plusFive = counter.locator(".plus-five");
    let plusFiveBtn = plusFive.locator("button");
    await expect(plusFiveBtn).toHaveText('Increment');
    let plusFiveOutput = plusFive.locator("div");
    await expect(plusFiveOutput).toHaveText(`pfcount: ${countValue}`);

    let input = counter.locator("input");
    await expect(input).toHaveAttribute('value', countValue);
    await expect(input).toHaveAttribute('on:change', "{input_changed}");
    await expect(input).toHaveAttribute('type', "text");
}
