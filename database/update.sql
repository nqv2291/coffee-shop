DROP PROC insertNewProduct
GO
CREATE PROC insertNewProduct
@categoryID CHAR(6), @name VARCHAR(30), @description VARCHAR(MAX), @image VARCHAR(MAX), @quantity INT, @price DECIMAL(10,2)
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