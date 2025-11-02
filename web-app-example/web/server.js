const express = require('express');
const axios = require('axios');
const cors = require('cors');
const app = express();
const port = 8080;

app.use(cors());
app.use(express.json());
app.use(express.static('.'));

// Health check
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});

// Root endpoint
app.get('/', (req, res) => {
  res.send('Garden Web Application is running');
});

// Proxy to API
app.get('/api/vote', async (req, res) => {
  try {
    const apiResponse = await axios.get('http://garden-api:8080/api/vote');
    res.json(apiResponse.data);
  } catch (error) {
    res.status(500).json({ error: 'Failed to connect to API' });
  }
});

app.post('/api/vote', async (req, res) => {
  try {
    const apiResponse = await axios.post('http://garden-api:8080/api/vote', req.body);
    res.json(apiResponse.data);
  } catch (error) {
    res.status(500).json({ error: 'Failed to connect to API' });
  }
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Web application listening on port ${port}`);
});