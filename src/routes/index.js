const {conn, sql} = require('../config/database');

function route(app) {
    app.get('/', async (req, res) => {
      // http://localhost:3000/
      var pool = await conn;
      var sqlString = "EXEC getProductGeneralInfo";
      return await pool.request().query(sqlString, function(err, data) {
        if (data.recordset != undefined) {
          res.send(data);
        }
      });
      
    });    
 
    app.get('/:id', async (req, res) => {
      // eg: http://localhost:3000/COFT01P01
      var id =  req.params.id;
      var pool = await conn;
      var sqlString = "EXEC getAllProductGeneralInfoByID '" + id + "'";
      return await pool.request().query(sqlString, function(err, data) {
        res.send(data.recordset);
      });
    });
    
    /*
    app.get('/collections', async (req, res) => {
      // SELECT * FROM Category
      // --> get all information in Category table
      var pool = await conn;
      var sqlString = "SELECT * FROM Category";
      return await pool.request().query(sqlString, function(err, data) {
        res.send(data.recordset);
      });
      
    });

    app.get('/collections/:id', async (req, res) => {
      // SELECT * FROM Category WHERE categoryID LIKE 'CKE%'
      // --> get names of a specific type of product (eg: CKE -> Cake)
      var id =  req.params.id;
      var pool = await conn;
      var sqlString = "SELECT name FROM Category WHERE categoryID LIKE '" + id + "%'";
      return await pool.request().query(sqlString, function(err, data) {
        res.send(data.recordset);
      });
    });

    
    // Other testing routes
    app.get('/admin', (req, res) => {
      // INSERT INTO customer VALUES (username, password, fullname, phone email, address)
      res.render('admin');
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
    */
}

module.exports = route;