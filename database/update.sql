/*
{
    "username": "nqv2291",
    "message": "messss",
    "totalPayment": "12312",
    "fullname": "Viet",
    "address": "nowhere",
    "phone": "0123321123",
    "email": "fakemail@",
    "data": [
        {"cartID": "0", "productID": "COFT01P01", "quantity": "1", "totalPrice":"1"},
        {"cartID": "1", "productID": "COFT01P02", "quantity": "1", "totalPrice":"12"},
        {"cartID": "2", "productID": "CAKT01P01", "quantity": "1", "totalPrice":"12"}
    ]
}
*/


DROP PROC insertNewOrderUserInfo
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

    SELECT @orderID AS orderID, (COUNT(*) + 1) AS baseOrderItemID
	FROM OrderItem;
END
GO


DROP PROC insertNewOrderItem
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


ALTER TABLE Orders
ADD CONSTRAINT Orders_chk_Status CHECK (orderStatus IN ('processing', 'completed', 'cancelled'))
GO