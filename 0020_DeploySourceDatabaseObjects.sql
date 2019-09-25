-- don't forget to connect to the source database

DROP TABLE IF EXISTS dbo.Employees;
GO

CREATE TABLE dbo.Employees
(
    id int IDENTITY,
    firstName varchar(100) NOT NULL,
    lastName varchar(100) NOT NULL,
    CONSTRAINT PK_dbo_Employees PRIMARY KEY (id),
    CONSTRAINT UQ_dbo_Employees UNIQUE (firstName, lastName)
);
GO

DECLARE @i int = 0;
DECLARE @firstName varchar(100) = '';
DECLARE @lastName varchar(100) = '';

WHILE @i < 100
BEGIN
    SET @firstName = 'firstName_' + RIGHT('0000000' + CONVERT(varchar(100), @i), 7)
    SET @lastName = 'lastName_' + RIGHT('0000000' + CONVERT(varchar(100), @i), 7)

    INSERT INTO dbo.Employees
        (firstName, LastName)
    VALUES (@firstName, @lastName)

    SET @i += 1;
END
GO

SELECT   *
FROM     dbo.Employees
