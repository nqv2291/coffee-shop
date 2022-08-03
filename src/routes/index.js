const { MAX } = require('mssql');
const { conn, sql } = require('../config/database');


function route(app) {

  app.post('/getProductReviews', async (req, res) => {
    var pool = await conn;
    var sqlGetProductReviews = "EXEC getProductReviews @productID";
    
    const getProductReviews = await pool.request()
      .input('productID', sql.Char(9), req.body.productID)
      .query(sqlGetProductReviews, function (err, data) {
        console.log(data.recordset);
        res.json(data.recordset);
      });
  });
  
  app.post('/addReview', async (req, res) => {
    var pool = await conn;
    var sqlAddNewReview = "EXEC insertNewReview @orderItemID, @username, @comment, @rating";
    
    const addNewReview = await pool.request()
      .input('orderItemID', sql.Int, req.body.orderItemID)
      .input('username', sql.VarChar(30), req.body.username)
      .input('comment', sql.VarChar(1000), req.body.comment)
      .input('rating', sql.TinyInt, req.body.rating)
      .query(sqlAddNewReview, function (err, data) {
        console.log(data.recordset);
        res.json(data.recordset);
      });
  });  

  // ------------------------------------------------------------------------------------------------

  app.post('/loadUserOrders', async (req, res) => {
    var pool = await conn;
    var sqlGetOrders = "SELECT orderID, orderFullname, orderDate, totalPayment, orderStatus FROM Orders WHERE username = @username";
    
    const getOrders = await pool.request()
      .input('username', sql.VarChar(30), req.body.username)
      .query(sqlGetOrders, function (err, data) {
        console.log(data.recordset);
        res.json(data.recordset);
      });
  });

  app.post('/loadOrderDetail', async (req, res) => {
    var pool = await conn;
    var sqlGetOrderDetail = "EXEC getOrderItems @orderID";
    const getOrderDetail = await pool.request()
      .input('orderID', sql.Int, req.body.orderID)
      .query(sqlGetOrderDetail, function (err, data) {
        console.log(data.recordset);
        res.json(data.recordset);
      });
  });  


  app.get('/loadProduct', async (req, res) => {
    var pool = await conn;
    var sqlGetProduct = "SELECT productID, categoryID, name, price, quantity FROM Product";
    
    const getProduct = await pool.request()
      .query(sqlGetProduct, function (err, data) {
        console.log(data.recordset);
        res.json(data.recordset);
      });
  });

  app.post('/changeQuantity', async (req, res) => {
    var pool = await conn;
    var sqlUpdateProductQuantity = "EXEC updateProductQuantity @productID, @quantity";
    
    const updateProductQuantity = await pool.request()
      .input('productID', sql.Char(9), req.body.productID)
      .input('quantity', sql.Int, req.body.quantity)
      .query(sqlUpdateProductQuantity, function (err, data) {
        console.log(data.recordset);
        res.json(data.recordset);
      });
  });



  app.post('/addOrder', async (req, res) => {
    var pool = await conn;
    var sqlMakeOrder = "EXEC insertNewOrder @username, @message, @totalPayment, @fullname, @address, @phone, @email";
    var sqlAddData = "EXEC insertNewOrderItem @orderItemID, @orderID, @productID, @quantity, @totalPrice";

    const insertNewOrder = await pool.request()
      .input('username', sql.VarChar(30), req.body.username)
      .input('message', sql.NVarChar(1000), req.body.message)
      .input('totalPayment', sql.Decimal(10, 2), req.body.totalPayment)
      .input('fullname', sql.NVarChar(100), req.body.fullname)
      .input('address', sql.NVarChar(150), req.body.address)
      .input('phone', sql.Char(10), req.body.phone)
      .input('email', sql.VarChar(100), req.body.email)
      .query(sqlMakeOrder);

    const insertOrderInfo = await req.body.data?.map(function (Data) {
      pool.request()
        .input('orderItemID', sql.Int, parseInt(insertNewOrder.recordset.at(0)["baseOrderItemID"]) +  parseInt(Data.cartID))
        .input('orderID', sql.Int, insertNewOrder.recordset.at(0)["orderID"])
        .input('productID', sql.Char(9), Data.productID)
        .input('quantity', sql.Int, Data.quantity)
        .input('totalPrice', sql.Decimal(10, 2), Data.totalPrice)
        .query(sqlAddData, function (err, data) {
          console.log(data.recordset);
          res.json(data.recordset);
        });
    });
  });

  app.get('/manageOrder', async (req, res) => {
    var pool = await conn;
    var sqlUpdateOrderStatus = "SELECT orderID, username, orderDate, totalPayment, orderStatus FROM Orders";
    
    const updateOrderStatus = await pool.request()
      .query(sqlUpdateOrderStatus, function (err, data) {
        console.log(data.recordset);
        // res.json(data.recordset);
      });
  });

  app.post('/manageOrder', async (req, res) => {
    var pool = await conn;
    var sqlUpdateOrderStatus = "EXEC updateOrderStatus @orderID, @status";
    
    const updateOrderStatus = await pool.request()
      .input('orderID', sql.Int, req.body.orderID)
      .input('status', sql.VarChar(20), req.body.status)
      .query(sqlUpdateOrderStatus, function (err, data) {
        console.log(data.recordset);
        // res.json(data.recordset);
      });
  });





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
      .input('name', sql.NVarChar(50), req.body.name)
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