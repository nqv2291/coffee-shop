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