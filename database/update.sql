DROP PROC getCustomerLoginInfo
GO
CREATE PROC getCustomerLoginInfo
@username CHAR(30), @password CHAR(30)
AS
SELECT * FROM Customer WHERE username = @username AND password = @password
GO