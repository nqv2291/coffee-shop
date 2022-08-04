
CREATE PROC getAllSortedProducts
@sortBy VARCHAR(30)
AS
BEGIN
	DECLARE @order CHAR(4), @criteria VARCHAR(30), @sqlQuery VARCHAR(1000);
	SET @order = SUBSTRING(@sortBy, 1, 3);
	SET @criteria = SUBSTRING(@sortBy, 5, 30);
	SET @sqlQuery = 'SELECT productID, productName, image, quantity, price, rating, categoryID, categoryName, parentID
					FROM vwProductCategory
					ORDER BY ' + @criteria;

	IF @order = 'INC'
		SET @sqlQuery = @sqlQuery + ' ASC';
	ELSE IF @order = 'DEC'
		SET @sqlQuery = @sqlQuery + ' DESC';
	EXEC(@sqlQuery);
END
GO