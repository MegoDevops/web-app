const express = require('express');
const path = require('path');
const axios = require('axios');
const cors = require('cors');
const app = express();
const port = 8080;

app.use(cors());
app.use(express.json());

// Serve static files from the built Vue app
app.use(express.static(path.join(__dirname, 'dist')));

// Health check
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy', service: 'web' });
});

// API proxy endpoints - handle API calls from the Vue app
app.get('/api/vote', async (req, res) => {
  try {
    const apiResponse = await axios.get('http://garden-api:8080/api/vote');
    res.json(apiResponse.data);
  } catch (error) {
    res.status(500).json({ error: 'Failed to connect to API', details: error.message });
  }
});

app.post('/api/vote', async (req, res) => {
  try {
    const apiResponse = await axios.post('http://garden-api:8080/api/vote', req.body);
    res.json(apiResponse.data);
  } catch (error) {
    res.status(500).json({ error: 'Failed to connect to API', details: error.message });
  }
});

// Socket.io proxy if needed
app.use('/socket.io', async (req, res) => {
  try {
    // Forward socket.io requests if you have a result service
    const resultResponse = await axios({
      method: req.method,
      url: `http://result:8080${req.url}`,
      data: req.body,
      headers: req.headers
    });
    res.json(resultResponse.data);
  } catch (error) {
    res.status(500).json({ error: 'Failed to connect to result service' });
  }
});

// Handle SPA routing - serve index.html for all other routes
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'dist', 'index.html'));
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Vue.js production server running on port ${port}`);
});