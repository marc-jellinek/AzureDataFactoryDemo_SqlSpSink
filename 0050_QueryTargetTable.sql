-- don't forget to connect to the Target database
SELECT      COUNT(*)
FROM        dim.Employee;
GO

SELECT      COUNT(*)
FROM        dim.Employee_History;
GO 

SELECT      *
FROM        Audit.OperationsEventLog
ORDER BY    OpsSK DESC;

SELECT      OpsSK, 
            StatusMessage
FROM        Audit.OperationsEventLog
ORDER BY    OpsSK ASC
GO