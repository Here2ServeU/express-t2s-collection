const express = require('express');
const app = express();
const PORT = 3000;

app.get('/', (req, res) => {
  res.send('Hello from Express App on ECS!');
});

app.listen(PORT, () => {
  console.log(`App is running on port ${PORT}`);
});