const express = require('express');
const morgan = require('morgan');
const app = express();
const port = 3000;

// HTTP logger
app.use(morgan('combined'));

app.get('/', (req, res) => {
    res.send('hello world!')
});

app.listen(port, () => {
  console.log(`App listening on http://localhost:${port}`)
});