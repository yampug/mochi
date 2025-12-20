const path = require('path');
import { Page } from '@playwright/test';

export function getTestFilePath(name: string): string {
    return path.join(__dirname, '..', '..', 'devground', 'public', 'test-pages', name);
}

export function getTestPage(name: string): string {
    return `file://${getTestFilePath(name)}`
}

/**
 * Setup console logging for a page to capture and log browser console messages.
 * This helps debug issues by showing console.log, errors, and warnings from the browser.
 */
export function setupConsoleLogging(page: Page) {
    // Capture all console messages
    page.on('console', msg => {
        const type = msg.type();
        const text = msg.text();
        const location = msg.location();

        // Format the console message with type and location
        const prefix = `[Browser Console ${type.toUpperCase()}]`;
        const locationInfo = location.url ? ` (${location.url}:${location.lineNumber}:${location.columnNumber})` : '';

        // Use different console methods based on message type
        if (type === 'error') {
            console.error(`${prefix}${locationInfo}`, text);
        } else if (type === 'warning') {
            console.warn(`${prefix}${locationInfo}`, text);
        } else if (type === 'log' || type === 'info' || type === 'debug') {
            console.log(`${prefix}${locationInfo}`, text);
        } else {
            console.log(`${prefix}${locationInfo}`, text);
        }
    });

    // Capture page errors (uncaught exceptions)
    page.on('pageerror', error => {
        console.error('[Browser Uncaught Exception]', error.message);
        console.error(error.stack);
    });

    // Capture failed requests
    page.on('requestfailed', request => {
        console.error(`[Browser Request Failed] ${request.url()}: ${request.failure()?.errorText}`);
    });
}
