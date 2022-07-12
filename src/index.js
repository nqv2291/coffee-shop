const express = require('express');
const morgan = require('morgan');
const { engine } = require('express-handlebars');
const path = require('path');
const route = require('./routes');

const app = express();
const port = 3000;

// config static files
app.use(express.static(path.join(__dirname, 'public')));

// HTTP logger
app.use(morgan('combined'));

// using middleware body-parser
app.use(express.urlencoded({
  extended: true
}));
app.use(express.json());

// template engine
app.engine('hbs', engine({
  extname: '.hbs'
}));
app.set('view engine', 'hbs');
app.set('views', path.join(__dirname, 'resources/views'));

// route init
route(app);


app.listen(port, () => {
  console.log(`App listening on http://localhost:${port}`)
});