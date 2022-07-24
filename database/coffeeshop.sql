CREATE DATABASE coffeeshop
GO
USE coffeeshop
GO

SET IMPLICIT_TRANSACTIONS OFF
GO

-------------------------------------------------------------------------------
-- CREATE TABLE
-------------------------------------------------------------------------------

CREATE TABLE Category (
    categoryID CHAR(6) NOT NULL,
    name VARCHAR(20) NOT NULL,
    parentID CHAR(6),

    CONSTRAINT Category_pk PRIMARY KEY (categoryID)
)
GO

CREATE TABLE Product (
    productID CHAR(9) NOT NULL,
    categoryID CHAR(6) NOT NULL,
    name NVARCHAR(50) NOT NULL,
    description NVARCHAR(MAX),
    image VARCHAR(MAX),
    quantity INT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    rating FLOAT,
    
    CONSTRAINT Product_pk PRIMARY KEY (productID),
    CONSTRAINT Product_fk_Category FOREIGN KEY (categoryID)
        REFERENCES Category (categoryID)
        ON UPDATE CASCADE
        ON DELETE CASCADE
)
GO

CREATE TABLE Customer (
    username VARCHAR(30) NOT NULL,
    password VARCHAR(30) NOT NULL,
    fullname NVARCHAR(100) NOT NULL,
    address NVARCHAR(150) NOT NULL,
    phone CHAR(10) NOT NULL,
    email VARCHAR(100) NOT NULL,
    
    CONSTRAINT Customer_pk PRIMARY KEY (username),
    CONSTRAINT AK_Email UNIQUE(email)
)
GO

CREATE TABLE Admin (
    username VARCHAR(30) NOT NULL,
    password VARCHAR(30) NOT NULL,
    
    CONSTRAINT Admin_pk PRIMARY KEY (username)
)
GO

CREATE TABLE Orders (
    orderID INT NOT NULL,
    username VARCHAR(30) NOT NULL,
    orderFullname NVARCHAR(100) NOT NULL,
    orderAddress NVARCHAR(150) NOT NULL,
    orderPhone CHAR(10) NOT NULL,
    orderEmail VARCHAR(100) NOT NULL,
    orderMessage NVARCHAR(1000),
    orderDate DATETIME NOT NULL,
    totalPayment DECIMAL(10,2) NOT NULL,
    orderStatus VARCHAR(20) NOT NULL DEFAULT 'processing',

    CONSTRAINT Orders_pk PRIMARY KEY (orderID),
    CONSTRAINT Orders_fk_Customer FOREIGN KEY (username)
        REFERENCES Customer (username)
        ON UPDATE CASCADE
        ON DELETE CASCADE
)
GO

CREATE TABLE OrderItem (
    orderItemID INT NOT NULL,
    orderID INT NOT NULL,
    productID CHAR(9) NOT NULL,
    quantity INT NOT NULL,
    totalPrice DECIMAL(10,2) NOT NULL,

    CONSTRAINT OrderItem_pk PRIMARY KEY (orderItemID),
    CONSTRAINT AK_Item UNIQUE(orderID, productID),
    CONSTRAINT OrderItem_fk_Orders FOREIGN KEY (orderID)
        REFERENCES Orders (orderID)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT OrderItem_fk_Product FOREIGN KEY (productID)
        REFERENCES Product (productID)
        ON UPDATE CASCADE
        ON DELETE CASCADE
)
GO

CREATE TABLE Review (
    reviewID INT NOT NULL,
    orderItemID INT,
    username VARCHAR(30) NOT NULL,
    comment NVARCHAR(1000),
    star TINYINT NOT NULL,

    CONSTRAINT Review_pk PRIMARY KEY (reviewID),
    CONSTRAINT AK_Review UNIQUE(orderItemID, username),
    CONSTRAINT Review_fk_OrderItem FOREIGN KEY (orderItemID)
        REFERENCES OrderItem (orderItemID)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT Review_fk_Customer FOREIGN KEY (username)
        REFERENCES Customer (username)
)
GO


-------------------------------------------------------------------------------
-- CREATE VIEW
-------------------------------------------------------------------------------

CREATE VIEW vwProductCategory
AS
SELECT p.productID, p.name AS productName, p.description, p.image, p.quantity, p.price, p.rating, c.categoryID, c.name AS categoryName, c.parentID
FROM Category c JOIN Product p ON c.categoryID = p.categoryID
GO


-------------------------------------------------------------------------------
-- CREATE PROCEDURE & FUNCTION
-------------------------------------------------------------------------------

-- Products
CREATE PROC getProductByID
@productID CHAR(9)
AS
SELECT productID, productName, description, image, quantity, price
FROM vwProductCategory
WHERE productID = @productID
GO

CREATE PROC getAllProducts 
AS
SELECT productID, productName, image, quantity, price, rating, categoryID, categoryName, parentID
FROM vwProductCategory
GO

CREATE PROC insertNewProduct
@categoryID CHAR(6), @name NVARCHAR(50), @description VARCHAR(MAX), @image VARCHAR(MAX), @quantity INT, @price DECIMAL(10,2)
AS
BEGIN
	DECLARE @nbProduct INT
	SET @nbProduct = (SELECT COUNT(*) FROM Product WHERE categoryID = @categoryID) + 1;
	
	BEGIN TRY  
		INSERT INTO Product (productID, categoryID, name, description, image, quantity, price)
		VALUES (CONCAT(@categoryID, 'P', RIGHT(100+ @nbProduct,2)), @categoryID, @name, @description, @image, @quantity, @price);
		IF @@ROWCOUNT = 0
			THROW 50000, 'Failed insert new product', 1;
		SELECT 'success' AS message, '0' AS errCode;
	END TRY  
	BEGIN CATCH  
		SELECT 'fail' AS message, '1' AS errCode; 
	END CATCH;
END
GO


-- Customers
CREATE PROC getCustomerLoginInfo
@username CHAR(30), @password CHAR(30)
AS
SELECT * FROM Customer WHERE username = @username AND password = @password
GO

CREATE PROC insertNewCustomer
@username VARCHAR(30), @password VARCHAR(30), @fullname NVARCHAR(100), @address NVARCHAR(150), @phone CHAR(10), @email VARCHAR(100)
AS
BEGIN
    BEGIN TRY
		INSERT INTO Customer (username, password, fullname, address, phone, email)
		VALUES (@username, @password, @fullname, @address, @phone, @email);
        IF @@ROWCOUNT = 0
			THROW 50000, 'fail', 1;
		SELECT 'success' AS message, '0' AS errCode;
	END TRY  
	BEGIN CATCH  
		IF @username IN (SELECT username FROM Customer)
            SELECT 'This username is already taken' AS message, '1' AS errCode;
        ELSE
			BEGIN
			IF @email IN (SELECT email FROM Customer) 
				SELECT 'This email is already taken' AS message, '2' AS errCode;
			ELSE
				SELECT 'Failed create new account' AS message, '3' AS errCode;
			END
	END CATCH;
END
GO

-- CREATE PROC getAllCustomerInfo
-- AS
-- SELECT username, fullname, address, phone, email FROM Customer
-- GO

-- CREATE PROC getCustomerInfoByUsername
-- @username CHAR(30)
-- AS
-- SELECT username, fullname, address, phone, email FROM Customer WHERE username = @username
-- GO




-- Orders
-- CREATE PROC getAllOrders
-- AS
-- SELECT * FROM Orders
-- GO

-- CREATE PROC getAllOrderByUsername
-- @username CHAR(30)
-- AS
-- SELECT * FROM Orders WHERE username = @username
-- GO

-- CREATE PROC getOrderDetailByID
-- @orderID INT
-- AS
-- SELECT * 
-- FROM Orders o JOIN OrderItem i ON o.orderID = i.orderID
--      JOIN Product p ON i.productID = p.productID
-- WHERE o.orderID = @orderID
-- GO

CREATE PROC insertNewOrderUserInfo
@username VARCHAR(30), @message NVARCHAR(1000), @totalPayment DECIMAL(10, 2)
AS
BEGIN
    DECLARE @orderID INT;
    SET @orderID = (SELECT COUNT(*) FROM Orders) + 1;

    INSERT INTO Orders (orderID, username, orderFullname, orderAddress, orderPhone, orderEmail, orderMessage, orderDate, totalPayment)
    SELECT @orderID, username, fullname, address, phone, email, @message, GETDATE(), @totalPayment
    FROM Customer WHERE username = @username;

    SELECT @orderID AS orderID;
END
GO



CREATE PROC insertNewOrderItem
@orderID INT, @productID CHAR(9), @quantity INT, @totalPrice DECIMAL(10, 2)
AS
BEGIN
	BEGIN TRANSACTION
	DECLARE @orderItemID INT;
    SET @orderItemID = (SELECT COUNT(*) FROM OrderItem) + 1;
	BEGIN TRY
		INSERT INTO OrderItem
		VALUES (@orderItemID, @orderID, @productID, @quantity, @totalPrice);

		UPDATE Product
		SET quantity = quantity - @quantity
		WHERE productID = @productID;

		IF @@ROWCOUNT = 0
			THROW 50000, 'fail', 1;
		IF (SELECT quantity FROM Product WHERE productID = @productID) < 0
			BEGIN
				SELECT 'not enough product in stock' AS message, '1' AS errCode;
				ROLLBACK
			END
		ELSE
			BEGIN
				IF (SELECT totalPayment FROM Orders WHERE orderID = @orderID) < (SELECT SUM(totalPrice) FROM OrderItem WHERE orderID = @orderID)
					BEGIN
						SELECT 'incorrect total price of product' AS message, '2' AS errCode;
						ROLLBACK
					END
				ELSE
					BEGIN
						SELECT 'success' AS message, '0' AS errCode;
						COMMIT TRANSACTION
					END
			END
	END TRY  
	BEGIN CATCH
		SELECT 'fail' AS message, '3' AS errCode;
		ROLLBACK
	END CATCH;
END
GO





-- CREATE PROC insertNewOrderUserInfo  --> use GETDATE()
-- CREATE PROC insertNewOrderCustomInfo
-- DROP PROC insertProductInfo
-- GO

-- nếu xóa 1 product thì cập nhật kiểu gì?
-- thêm 1 cột isdeleted vào product


