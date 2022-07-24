DROP PROC getCustomerLoginInfo
GO
CREATE PROC getCustomerLoginInfo
@username CHAR(30), @password CHAR(30)
AS
SELECT * FROM Customer WHERE username = @username AND password = @password
GO


DROP TABLE Review;
DROP TABLE OrderItem;
DROP TABLE Orders;
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


DROP PROC insertNewOrderUserInfo
GO

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

DELETE FROM Category
WHERE 1=1
GO

INSERT INTO Category (categoryID, name, parentID)
VALUES  ('COFT00', 'Coffee', NULL),
        ('TEAT00', 'Tea', NULL),
        ('CAKT00', 'Cake', NULL),
        ('COFT01', 'Blend', 'COFT00'),
        ('COFT02', 'Collaboration', 'COFT00'),
        ('COFT03', 'Single Origin', 'COFT00'),
        ('COFT04', 'Steeped', 'COFT00'),
        ('TEAT01', 'Black tea', 'TEAT00'),
        ('TEAT02', 'Green tea', 'TEAT00'),
        ('TEAT03', 'Caffeine tea', 'TEAT00'),
        ('TEAT04', 'White tea', 'TEAT00'),
        ('TEAT05', 'Matcha tea', 'TEAT00'),
        ('CAKT01', 'Vegan Cakes', 'CAKT00'),
        ('CAKT02', 'Heart Shaped Cakes', 'CAKT00'),
        ('CAKT03', 'Party Cakes', 'CAKT00'),
        ('CAKT04', 'Midnight Cakes', 'CAKT00')
GO

CREATE PROC getTypeByCategory
@parentID CHAR(6)
AS
BEGIN
	SELECT categoryID, name FROM Category
	WHERE parentID = @parentID
END
GO