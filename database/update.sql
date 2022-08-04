
DROP PROC getProductByID
GO

CREATE PROC getProductByID
@productID CHAR(9)
AS
SELECT productID, productName, description, image, quantity, price, rating
FROM vwProductCategory
WHERE productID = @productID
GO


DROP PROC insertNewOrder
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

	
    SELECT @orderID AS orderID, (ISNULL(MAX(orderItemID), 0) + 1) AS baseOrderItemID
	FROM OrderItem;
END
GO