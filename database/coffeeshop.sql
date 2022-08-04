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

ALTER TABLE Orders
ADD CONSTRAINT Orders_chk_Status CHECK (orderStatus IN ('processing', 'completed', 'cancelled'))
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

-- Products--------------------------------------------------------------------
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

CREATE PROC getAllSortedProducts
@sortBy VARCHAR(30)
AS
BEGIN
	DECLARE @order CHAR(4), @criteria VARCHAR(30), @sqlQuery VARCHAR(1000);
	SET @order = SUBSTRING(@sortBy, 1, 3);
	SET @criteria = SUBSTRING(@sortBy, 5, 30);
	SET @sqlQuery = 'SELECT productID, productName, image, quantity, price, rating, categoryID, categoryName, parentID
					FROM vwProductCategory
					ORDER BY ' + @criteria;

	IF @order = 'INC'
		SET @sqlQuery = @sqlQuery + ' ASC';
	ELSE IF @order = 'DEC'
		SET @sqlQuery = @sqlQuery + ' DESC';
	EXEC(@sqlQuery);
END
GO

CREATE PROC getProductReviews
@productID CHAR(9)
AS
BEGIN
	SELECT username, comment, star
	FROM OrderItem oi JOIN Review rv ON oi.orderItemID = rv.orderItemID
	WHERE productID = @productID;
END
GO


-- Customers-------------------------------------------------------------------
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

CREATE PROC insertNewOrder
@username VARCHAR(30), @message NVARCHAR(1000), @totalPayment DECIMAL(10, 2),
@fullname NVARCHAR(100), @address NVARCHAR(150), @phone CHAR(10), @email VARCHAR(100)
AS
BEGIN
    DECLARE @orderID INT;
    SET @orderID = (SELECT COUNT(*) FROM Orders) + 1;

    INSERT INTO Orders (orderID, username, orderFullname, orderAddress, orderPhone, orderEmail, orderMessage, orderDate, totalPayment)
    VALUES (@orderID, @username, @fullname, @address, @phone, @email, @message, GETDATE(), @totalPayment)

    SELECT @orderID AS orderID, (MAX(orderItemID) + 1) AS baseOrderItemID
	FROM OrderItem;
END
GO

CREATE PROC insertNewOrderItem
@orderItemID INT, @orderID INT, @productID CHAR(9), @quantity INT, @totalPrice DECIMAL(10, 2)
AS
BEGIN
	BEGIN TRANSACTION
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
				SELECT 'success' AS message, '0' AS errCode;
				COMMIT TRANSACTION
			END
	END TRY  
	BEGIN CATCH
		SELECT 'fail' AS message, '2' AS errCode;
		ROLLBACK
	END CATCH;
END
GO


CREATE PROC getOrderItems
@orderID INT
AS
BEGIN
	SELECT o.orderItemID, o.productID, p.name, p.image, o.quantity, o.totalPrice 
	FROM OrderItem o JOIN Product p ON o.productID = p.productID
	WHERE orderID = @orderID;
END
GO


CREATE PROC insertNewReview
@orderItemID INT, @username VARCHAR(30), @comment VARCHAR(1000), @rate TINYINT
AS
BEGIN
	BEGIN TRANSACTION
	BEGIN TRY
		IF (@rate > 5) OR (@rate < 0)
			BEGIN
				SELECT 'incorrect rating' AS message, '1' AS errCode;
				ROLLBACK
			END
		DECLARE @reviewID INT;
		IF (SELECT COUNT(*) FROM review) = 0
			SET @reviewID = 1
		ELSE 
			SET @reviewID = (SELECT MAX(reviewID) FROM review) + 1;		
		INSERT INTO Review
		VALUES (@reviewID, @orderItemID, @username, @comment, @rate);

		IF @@ROWCOUNT = 0
			THROW 50000, 'fail', 1;
		SELECT 'success' AS message, '0' AS errCode;
		COMMIT TRANSACTION
	END TRY  
	BEGIN CATCH
		SELECT 'fail' AS message, '3' AS errCode;
		ROLLBACK
	END CATCH;
END
GO



-- Admin-----------------------------------------------------------------------
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

CREATE PROC updateOrderStatus
@orderID INT, @status VARCHAR(20)
AS
BEGIN	
	BEGIN TRY  

        IF @status NOT IN ('processing', 'completed', 'cancelled')
            BEGIN
                SELECT 'invalid status' AS message, '1' AS errCode;
                ROLLBACK
            END

		UPDATE Orders
        SET orderStatus = @status
        WHERE orderID = @orderID;

        IF @@ROWCOUNT = 0
			THROW 50000, 'Failed insert new product', 1;
		SELECT 'success' AS message, '0' AS errCode;
	END TRY  
	BEGIN CATCH  
		SELECT 'fail' AS message, '2' AS errCode; 
	END CATCH;
END
GO


CREATE PROC updateProductQuantity
@productID CHAR(9), @quantity INT
AS
BEGIN	
	BEGIN TRY  

        IF @quantity < 0
            BEGIN
                SELECT 'invalid number' AS message, '1' AS errCode;
                ROLLBACK
            END

	    UPDATE Product
        SET quantity = quantity + @quantity
        WHERE productID = @productID;

        IF @@ROWCOUNT = 0
			THROW 50000, 'Failed update product quantity', 1;
		SELECT 'success' AS message, '0' AS errCode;
	END TRY  
	BEGIN CATCH  
		SELECT 'fail' AS message, '2' AS errCode; 
	END CATCH;
END
GO





-------------------------------------------------------------------------------
-- CREATE TRIGGER
-------------------------------------------------------------------------------

CREATE TRIGGER tg_updateProductRating
ON Review
AFTER INSERT
AS
BEGIN
	DECLARE @sum INT, @pid CHAR(9), @nbRating INT;
	SET @pid = (SELECT productID FROM OrderItem WHERE orderItemID = (SELECT orderItemID FROM inserted));
	SET @sum = ISNULL((SELECT SUM(rating) FROM Product WHERE productID = @pid), 0) + (SELECT star FROM inserted);
	SET @nbRating = (SELECT COUNT(rating) FROM Product WHERE productID = @pid) + 1;

	UPDATE Product
	SET rating = @sum/@nbRating
	WHERE productID = @pid;
END
GO


-------------------------------------------------------------------------------
-- NOT IMPLEMENTED YET
-------------------------------------------------------------------------------

-- Admin-----------------------------------------------------------------------
-- CREATE PROC getAllCustomerInfo
-- AS
-- SELECT username, fullname, address, phone, email FROM Customer
-- GO



-- Customer-------------------------------------------------------------------
-- CREATE PROC getAllOrderByUsername
-- @username VARCHAR(30)
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




-- nếu xóa 1 product thì cập nhật kiểu gì?
-- thêm 1 cột isdeleted vào product


