-- don't forget to connect to the Source database
SELECT      COUNT(*)
FROM        dbo.Employees

SELECT      TOP 100
            e.*
FROM        dbo.Employees e 
ORDER BY    e.id