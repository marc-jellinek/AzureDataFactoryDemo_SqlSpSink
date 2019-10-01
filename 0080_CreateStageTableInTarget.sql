-- don't forget to connect to the Target database
DROP TABLE IF EXISTS Stage.Employees

DROP SCHEMA Stage;
GO

CREATE SCHEMA Stage;
GO

CREATE TABLE Stage.Employees(
    id int NOT NULL, 
    firstName varchar(100) NOT NULL, 
    lastName varchar(100) NOT NULL
)
GO

ALTER TABLE dim.Employee SET (SYSTEM_VERSIONING=OFF);
GO

DROP TABLE IF EXISTS dim.Employee;
DROP TABLE IF EXISTS dim.Employee_History;
DROP PROCEDURE IF EXISTS dim.Load_Employee;
DROP TYPE IF EXISTS dim.EmployeeType;
GO

DROP SCHEMA dim;
GO

DROP TABLE IF EXISTS Audit.OperationsEventLog;
GO

CREATE TABLE Audit.OperationsEventLog(
    OpsSK int IDENTITY, 
    EventDateTime datetime DEFAULT GETDATE(), 
    EventState varchar(100), 
    SourceType varchar(100), -- stored procedure, data factory pipeline, etc
    SourceName varchar(100),
    ErrorNumber int NULL, 
    ErrorMessage varchar(8000) NULL, 
    StatusMessage varchar(8000) NOT NULL
);
GO

CREATE SCHEMA dim;
GO

CREATE TABLE dim.Employee
(
    EmployeeSK int identity NOT NULL,
    SourceKey int NOT NULL,
    firstName varchar(100) NOT NULL,
    lastName varchar(100) NOT NULL,
    [_ValidFrom] datetime2(0) GENERATED ALWAYS AS ROW START CONSTRAINT DF_ValidFrom DEFAULT (DATEADD(second, (-1), sysutcdatetime())) NOT NULL,
    [_ValidTo] datetime2(0) GENERATED ALWAYS AS ROW END CONSTRAINT DF_ValidTo DEFAULT '9999.12.31 23.:59:59.99' NOT NULL,
    CONSTRAINT PK_dim_Employee PRIMARY KEY NONCLUSTERED ([firstName], [lastName]),
    CONSTRAINT UQ_dim_Employee UNIQUE (firstName, lastName),
    PERIOD FOR SYSTEM_TIME ([_ValidFrom], [_ValidTo])
)
WITH (SYSTEM_VERSIONING = ON(HISTORY_TABLE=[dim].[Employee_History], DATA_CONSISTENCY_CHECK=ON));
GO

DROP PROCEDURE IF EXISTS dim.Load_Employee;
GO

DROP TYPE IF EXISTS dim.EmployeeType;
GO



