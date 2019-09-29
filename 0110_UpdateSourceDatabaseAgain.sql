-- don't forget to connect to the source database
DELETE FROM dbo.Employees
WHERE id = 1024

INSERT INTO dbo.Employees(firstName, lastName)
VALUES ('newEmployeefirstNameAgain', 'newEmployeeLastNameAgain')

UPDATE dbo.Employees
SET firstName = 'updatedEmployeefirstNameAgain', 
    lastname = 'updatedEmployeelastNameAgain'
WHERE id = 512