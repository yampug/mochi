import express, { Request, Response } from 'express';
import path from 'path';

const app = express();
const PORT: number = 8777;

// Serve static files from the devground directory
app.use(express.static(path.join(__dirname, '..', '..', 'devground')));

// Handle root route to serve the HTML file
app.get('/', (req: Request, res: Response) => {
    res.sendFile(path.join(__dirname, '..', '..', 'devground', 'basic_counters.html'));
});

// Return plain text "123"
app.get('/abc', (req: Request, res: Response) => {
    res.set({
        'X-Custom-Header': 'test-value-123',
        'X-Request-Id': 'abc-' + Date.now(),
        'X-Server-Info': 'testapp-express',
        'Cache-Control': 'no-cache'
    });
    res.send('123');
});

// Return JSON data
app.get('/dummy_json', (req: Request, res: Response) => {
    res.set({
        'X-Custom-Header': 'json-endpoint',
        'X-Request-Id': 'json-' + Date.now(),
        'X-Server-Info': 'testapp-express',
        'X-Data-Type': 'application/json',
        'X-Item-Count': '3',
        'Cache-Control': 'max-age=300'
    });
    res.json({
        message: "Hello from testapp",
        data: {
            items: ["item1", "item2", "item3"],
            count: 3,
            timestamp: new Date().toISOString()
        },
        status: "success"
    });
});

// Start the server
app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
    console.log('Serving files from devground directory');
});