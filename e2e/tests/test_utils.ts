const path = require('path');

export function getTestFilePath(name: string): string {
    return path.join(__dirname, '..', '..', 'devground', name);
}

export function getTestFile(name: string): string {
    return `file://${getTestFilePath(name)}`
}
