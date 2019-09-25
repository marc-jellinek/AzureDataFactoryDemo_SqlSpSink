-- don't forget to connect to the Source database
DECLARE @i int = 102;
DECLARE @firstName varchar(100);
DECLARE @lastName varchar(100);

WHILE @i < 1000000
BEGIN
    SET @firstName = 'firstName_' + RIGHT('0000000' + CONVERT(varchar(100), @i), 7);
    SET @lastName = 'lastName_' + RIGHT('0000000' + CONVERT(varchar(100), @i), 7);

    INSERT INTO dbo.Employees
        (firstName, LastName)
    VALUES (@firstName, @lastName);

    SET @i += 1;
END
GO

SELECT      COUNT(*)
FROM        dbo.Employees