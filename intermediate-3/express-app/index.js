const express = require('express');
const StatsD = require('hot-shots');
const app = express();

// Initialize DogStatsD client
const client = new StatsD({
  host: process.env.DD_AGENT_HOST,
  port: 8125,
  globalTags: { env: 'production', service: 'checkout-api' }
});

app.get('/checkout', (req, res) => {
  const start = Date.now();
  
  // Simulate processing time (random between 100ms and 500ms)
  const delay = Math.floor(Math.random() * 400) + 100;
  
  setTimeout(() => {
    const duration = Date.now() - start;
    
    // Send custom metric to Datadog
    client.gauge('custom.checkout.latency', duration);
    console.log(`Checkout processed in ${duration}ms`);
    
    res.json({ status: 'success', duration: duration });
  }, delay);
});

app.listen(8080, () => {
  console.log('Checkout API listening on port 8080');
});
