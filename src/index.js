const express = require('express');
const morgan = require('morgan');
const { engine } = require('express-handlebars');
const {conn, sql} = require('./config/database');
const path = require('path');

const app = express();
const port = 3000;

// config static files
app.use(express.static(path.join(__dirname, 'public')));

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

app.get('/collections', (req, res) => {
  // SELECT * FROM product
});

app.post('/register', (req, res) => {
  // INSERT INTO customer VALUES (username, password, fullname, phone email, address)
});

app.put('/update', (req, res) => {
  // UPDATE product SET name =?, price=?, quantity=? WHERE productID =? AND size=?
});

app.delete('/delete/:id', (req, res) => {
  var id = req.params.id;
  // DELETE FROM product WHERE productID = ?
});


app.listen(port, () => {
  console.log(`App listening on http://localhost:${port}`)
});