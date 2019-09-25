-- don't forget to connect to the Source database
DELETE FROM dbo.Employees
WHERE id = 33;
GO

INSERT INTO dbo.Employees(firstName, lastName)
VALUES('insertedEmployee101firstName', 'insertedEmployee101lastName')
GO

UPDATE dbo.Employees
SET firstName = 'updatedEmployee66firstName', 
    lastName = 'updatedEmployee66lastName'
WHERE id = 66;
GO

