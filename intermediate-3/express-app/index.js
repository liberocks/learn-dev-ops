const express = require('express');
const client = require('prom-client');
const app = express();

// Initialize Prometheus registry
const register = new client.Registry();

// Add default metrics (CPU, memory, etc.)
client.collectDefaultMetrics({ register });

// Create a custom metric for latency
const checkoutLatency = new client.Gauge({
  name: 'custom_checkout_latency',
  help: 'Latency of checkout requests in ms',
  labelNames: ['env', 'service']
});
register.registerMetric(checkoutLatency);

app.get('/checkout', (req, res) => {
  const start = Date.now();
  
  // Simulate processing time (random between 100ms and 500ms)
  const delay = Math.floor(Math.random() * 400) + 100;
  
  setTimeout(() => {
    const duration = Date.now() - start;
    
    // Record metric
    checkoutLatency.set({ env: 'production', service: 'checkout-api' }, duration);
    console.log(`Checkout processed in ${duration}ms`);
    
    res.json({ status: 'success', duration: duration });
  }, delay);
});

// Expose metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

app.listen(8080, () => {
  console.log('Checkout API listening on port 8080');
});
