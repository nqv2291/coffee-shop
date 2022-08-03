
CREATE PROC getOrderItems
@orderID INT
AS
BEGIN
	SELECT o.orderItemID, o.productID, p.name, p.image, o.quantity, o.totalPrice 
	FROM OrderItem o JOIN Product p ON o.productID = p.productID
	WHERE orderID = @orderID;
END
GO

DROP PROC IF EXISTS insertNewReview
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
