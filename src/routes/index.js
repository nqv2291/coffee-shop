const { MAX } = require('mssql');
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
    var pool = await conn;
    var sqlString = "EXEC getProductByID @productID";
    return await pool.request()
      .input('productID', sql.Char(9), req.params.id)
      .query(sqlString, function (err, data) {
        if (data.recordset.at(0) != undefined) {
          var rawData = data.recordset.at(0)["image"];
          var data = rawData.replace(/^data:image\/png;base64,/, '');
          var img = Buffer.from(data, 'base64');

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

  app.post('/addOrder', async (req, res) => {
    var pool = await conn;
    var sqlString = "EXEC insertNewOrderUserInfo @username, @message, @totalPayment";
    var sqlData = "EXEC insertNewOrderItem @orderID, @productID, @quantity, @totalPrice";

    const request = await pool.request()
      .input('username', sql.VarChar(30), req.body.username)
      .input('message', sql.NVarChar(1000), req.body.message)
      .input('totalPayment', sql.Decimal(10, 2), req.body.totalPayment)
      .query(sqlString);

    const requestInfos = req.body.data?.map(function (data) {
      pool.request()
        .input('orderID', sql.Int, data.orderID)
        .input('productID', sql.Char(9), data.productID)
        .input('quantity', sql.Int, data.quantity)
        .input('totalPrice', sql.Int, data.totalPrice)
        .query(sqlData, function (err, data) {
          res.json(data.recordset);
        });
    });
    

  });

  app.post('/getProductType', async (req, res) => {
    var pool = await conn;
    var sqlString = "EXEC getTypeByCategory @parentID";
    const request = await pool.request()
      .input('parentID', sql.Char(6), req.body.id)
      .query(sqlString, function (err, data) {
        res.json(data.recordset);
      })
  });

  app.post('/addProduct', async (req, res) => {
    var pool = await conn;
    var sqlString = "EXEC insertNewProduct @categoryID, @name, @description, @image, @quantity, @price";
    const request = await pool.request()
      .input('categoryID', sql.Char(6), req.body.categoryID)
      .input('name', sql.NVarChar(30), req.body.name)
      .input('description', sql.NVarChar(MAX), req.body.description)
      .input('image', sql.VarChar(MAX), req.body.image)
      .input('quantity', sql.Int, req.body.quantity)
      .input('price', sql.Decimal(10, 2), req.body.price)
      .query(sqlString, function (err, data) {
        res.json(data.recordset);
      })
  });

  app.post('/login', async (req, res) => {
    // http://localhost:3000/login
    var pool = await conn;
    var sqlString = "EXEC getCustomerLoginInfo @username, @password";
    return await pool.request()
      .input('username', sql.VarChar(30), req.body.username)
      .input('password', sql.VarChar(30), req.body.password)
      .query(sqlString, function (err, data) {
        if (data.recordset != undefined) {
          res.send(data.recordset);
        }
      });
  });


  app.post('/register', async (req, res) => {
    // http://localhost:3000/register
    var pool = await conn;
    var sqlString = "EXEC insertNewCustomer @username, @password, @fullname, @address, @phone, @email";
    return await pool.request()
      .input("username", sql.VarChar(30), req.body.username)
      .input("password", sql.VarChar(30), req.body.password)
      .input("fullname", sql.NVarChar(100), req.body.fullname)
      .input("address", sql.NVarChar(150), req.body.address)
      .input("phone", sql.Char(10), req.body.phone)
      .input("email", sql.VarChar(100), req.body.email)
      .query(sqlString, function (err, data) {
        res.json(data.recordset);
      });
  });
}

module.exports = route;