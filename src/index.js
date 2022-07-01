const express = require('express');
const morgan = require('morgan');
const { engine } = require('express-handlebars');
const path = require('path');

const app = express();
const port = 3000;

// HTTP logger
app.use(morgan('combined'));

// template engine
app.engine('hbs', engine({
  extname: '.hbs'
}));
app.set('view engine', 'hbs');
app.set('views', path.join(__dirname, 'resources/views'));

// route
app.get('/', (req, res) => {
    res.render('home');
});

app.listen(port, () => {
  console.log(`App listening on http://localhost:${port}`)
});