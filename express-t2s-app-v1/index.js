const express = require('express');
const app = express();
const path = require('path');

// Serve static files from the 'public' directory
app.use(express.static('public'));

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Emmanuel Services app running at http://localhost:${PORT}`);
});
