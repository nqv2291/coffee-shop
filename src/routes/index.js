const { conn, sql } = require('../config/database');


function route(app) {
  app.get('/', (req, res) => {
    // http://localhost:3000/

    res.render('home');

  });

  app.get('/input', async (req, res) => {
    // http://localhost:3000/input
    res.render('admin');

  });

  app.get('/:id', async (req, res) => {
    // eg: http://localhost:3000/COFT01P01
    var id = req.params.id;
    var pool = await conn;
    var sqlString = "EXEC getProductByID '" + id + "'";
    return await pool.request().query(sqlString, function (err, data) {
      if (data.recordset.at(0) != undefined) {
        res.send(data.recordset.at(0)["image"]);

        res.writeHead(200, {
          'Content-Type': 'image/png',
          'Content-Length': img.length
        });
        res.end(img);

      } else {
        res.send("No image found");
      }
    });
  });

  app.post('/add_prod', async (req, res) => {
    var pool = await conn;
    var sqlString = "INSERT INTO Product (productID, categoryID, name, description, price, quantity) VALUES ('COFT01P07', 'COFT01', @name, @description, @price, @quantity)";
    return await pool.request()
      .input('name', sql.VarChar, req.body.name)
      .input('description', sql.VarChar, req.body.description)
      .input('price', sql.VarChar, req.body.price)
      .input('quantity', sql.VarChar, req.body.quantity)
      .query(sqlString, function (err, data) {
        res.json(req.body);
      })
    res.redirect('/');
  });

  app.post('/login', async (req, res) => {
    // http://localhost:3000/login
    var username = req.body.username;
    var password = req.body.password;
    var pool = await conn;
    var sqlString = "EXEC getCustomerLoginInfo @username, @password";
    return await pool.request()
      .input('username', sql.VarChar, username)
      .input('password', sql.VarChar, password)
      .query(sqlString, function (err, data) {
        if (data.recordset != undefined) {
          res.send(data.recordset);
        }
      });
  });


  app.post('/reg', async (req, res) => {
    // http://localhost:3000/register
    var username = req.body.username;
    var password = req.body.password;
    var fullname = req.body.fullname;
    var address = req.body.address;
    var phone = req.body.phone;
    var email = req.body.email;

    var pool = await conn;
    var sqlString = "insertCustomerInfo @username, @password, @fullname, @address, @phone, @email";
    return await pool.request()
      .input("username", sql.VarChar, username)
      .input("password", sql.VarChar, password)
      .input("fullname", sql.NVarChar, fullname)
      .input("address", sql.NVarChar, address)
      .input("phone", sql.VarChar, phone)
      .input("email", sql.VarChar, email)
      .query(sqlString, function (err, data) {
        if (data.recordset != undefined) {
          res.send(data.recordset);
        }
      });
  });
}

module.exports = route;