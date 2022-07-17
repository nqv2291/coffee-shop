const {conn, sql} = require('../config/database');


function route(app) {
    app.get('/', async (req, res) => {
      // http://localhost:3000/
      var pool = await conn;
      var sqlString = "EXEC getAllProducts";
      return await pool.request().query(sqlString, function(err, data) {
        if (data != undefined) {
          res.send(data.recordset);
        }
      });
      
    });    
 
    app.get('/:id', async (req, res) => {
      // eg: http://localhost:3000/COFT01P01
      var id =  req.params.id;
      var pool = await conn;
      var sqlString = "EXEC getProductByID '" + id + "'";
      return await pool.request().query(sqlString, function(err, data) {
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
    
    app.post('/login', async (req, res) => {
      // http://localhost:3000/login
      var username = req.body.username;
      var password = req.body.password;
      var pool = await conn;
      var sqlString = "EXEC getCustomerLoginInfo @username, @password";
      return await pool.request()
      .input('username', sql.VarChar, username)
      .input('password', sql.VarChar, password)
      .query(sqlString, function(err, data) {
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
      .query(sqlString, function(err, data) {
        if (data.recordset != undefined) {
          res.send(data.recordset);
        }
      });
    });
}

module.exports = route;