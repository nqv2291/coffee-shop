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

