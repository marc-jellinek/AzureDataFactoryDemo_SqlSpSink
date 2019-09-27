-- don't forget to connect to the source database
DELETE FROM dbo.Employees
WHERE id = 33

INSERT INTO dbo.Employees(firstName, lastName)
VALUES ('newEmployeefirstName', 'newEmployeeLastName')

UPDATE dbo.Employees
SET firstName = 'updatedEmployeefirstName', 
    lastname = 'updatedEmployeelastName'
WHERE id = 66