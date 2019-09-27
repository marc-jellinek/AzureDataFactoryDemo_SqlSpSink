-- don't forget to connect to the Source database
WITH
    B2_01 AS (SELECT 1 as num UNION ALL SELECT 1 as num), 
    B2_10 AS (SELECT a.num FROM B2_01 a, B2_01 b, B2_01 c, B2_01 d, B2_01 e, B2_01 f, B2_01 g, B2_01 h, B2_01 i, B2_01 j), 
    B2_20 AS (SELECT a.num FROM B2_10 a, B2_10 b), 
    R2_20 AS (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) as rownum FROM B2_20)
INSERT INTO dbo.Employees(firstName, lastName)
SELECT      'firstName_' + RIGHT('0000000' + CONVERT(varchar(100), tt.rownum), 7) as firstName, 
            'lastName_' + RIGHT('0000000' + CONVERT(varchar(100), tt.rownum), 7) as lastName
FROM        R2_20 as tt -- tally table
WHERE       tt.rownum > 101 AND 
            tt.rownum <= 500000;
GO

SELECT      COUNT(*)
FROM        dbo.Employees;
GO