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
        SET quantity = @quantity
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
