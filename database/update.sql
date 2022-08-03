CREATE PROC getProductReviews
@productID CHAR(9)
AS
BEGIN
	SELECT username, comment, star
	FROM OrderItem oi JOIN Review rv ON oi.orderItemID = rv.orderItemID
	WHERE productID = @productID;
END
GO

CREATE TRIGGER tg_updateProductRating
ON Review
AFTER INSERT
AS
BEGIN
	DECLARE @sum INT, @pid CHAR(9), @nbRating INT;
	SET @pid = (SELECT productID FROM OrderItem WHERE orderItemID = (SELECT orderItemID FROM inserted));
	SET @sum = ISNULL((SELECT SUM(rating) FROM Product WHERE productID = @pid), 0) + (SELECT star FROM inserted);
	SET @nbRating = (SELECT COUNT(rating) FROM Product WHERE productID = @pid) + 1;
	SELECT @pid as pid, @sum as sumr, @nbRating as numberRating ;

	UPDATE Product
	SET rating = @sum/@nbRating
	WHERE productID = @pid;
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
