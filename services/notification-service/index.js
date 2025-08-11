const express = require('express');
const app = express();

app.get('/', (req, res) => {
  res.send('Notification Service: sending alerts');
});

app.listen(8080, () => {
  console.log('Notification service running on port 8080');
});
