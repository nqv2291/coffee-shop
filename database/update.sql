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