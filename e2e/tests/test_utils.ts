const path = require('path');

export function getTestFilePath(name: string): string {
    return path.join(__dirname, '..', '..', 'devground', 'public', 'test-pages', name);
}

export function getTestPage(name: string): string {
    return `file://${getTestFilePath(name)}`
}
