-- Don't forget to connect to the target database

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
DROP PROCEDURE IF EXISTS Audit.InsertOperationsEventLog;
GO

DROP SCHEMA Audit;
GO

CREATE SCHEMA Audit;
GO

CREATE TABLE Audit.OperationsEventLog
(
    OpsSK int IDENTITY,
    EventDateTime datetime DEFAULT GETDATE(),
    EventState varchar(100),
    SourceType varchar(100),
    -- stored procedure, data factory pipeline, etc
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

DROP PROCEDURE IF EXISTS Audit.InsertOperationsEventLog;
GO

CREATE PROCEDURE Audit.InsertOperationsEventLog
    @EventState varchar(100),
    @SourceType varchar(100),
    -- stored procedure, data factory pipeline, etc
    @SourceName varchar(100),
    @ErrorNumber int,
    @ErrorMessage varchar(8000),
    @StatusMessage varchar(8000)
AS
BEGIN
    BEGIN TRY
        INSERT INTO Audit.OperationsEventLog
        ([EventState], [SourceType], [SourceName], [ErrorNumber], [ErrorMessage], [StatusMessage])
    VALUES
        (@EventState, @SourceType, @SourceName, @ErrorNumber, @ErrorMessage, @StatusMessage)
    END TRY
    BEGIN CATCH
        SELECT ERROR_NUMBER() as ErrorNumber,
        ERROR_MESSAGE() as ErrorMessage;

        THROW;
    END CATCH
END
GO

CREATE TYPE dim.EmployeeType AS TABLE(
    id int NOT NULL,
    firstName varchar(100) NOT NULL,
    lastName varchar(100) NOT NULL
);
GO

CREATE PROCEDURE dim.Load_Employee
    @Employee as dim.EmployeeType READONLY
AS
BEGIN
    DECLARE @ErrorNumber int = NULL;
    DECLARE @ErrorMessage varchar(8000) = NULL;
    DECLARE @StatusMessage varchar(8000) = NULL;
    DECLARE @SourceRowCount int = 0;

    BEGIN TRY
        SELECT @SourceRowCount = ISNULL(COUNT(*), 0)
    FROM @Employee 

        SET @StatusMessage = 'Starting load of dim.Employee.  Source rowcount: ' + CONVERT(varchar(8000), @SourceRowCount)

        EXEC Audit.InsertOperationsEventLog
            @EventState = 'Information', 
            @SourceType = 'Stored Procedure', 
            @SourceName = '[dim].[Load_Employee]', 
            @ErrorNumber = NULL, 
            @ErrorMessage = NULL, 
            @StatusMessage = @StatusMessage;

        MERGE INTO dim.Employee as TARGET
        USING @Employee as SOURCE 
        ON      TARGET.SourceKey = SOURCE.id 
        WHEN MATCHED AND
            (   SOURCE.firstName <> TARGET.firstName OR
        SOURCE.lastName <> TARGET.lastName
            )
        THEN UPDATE SET
                    target.firstName = source.firstName, 
                    target.lastName = source.lastName 
        WHEN NOT MATCHED BY TARGET THEN 
            INSERT(SourceKey, firstName, LastName)
            VALUES (source.id, source.firstName, source.lastName)
        WHEN NOT MATCHED BY SOURCE THEN 
            DELETE;

        EXEC Audit.InsertOperationsEventLog
            @EventState = 'Success',
            @SourceType = 'Stored Procedure', 
            @SourceName = '[dim].[Load_Employee]', 
            @ErrorNumber = NULL, 
            @ErrorMessage = NULL, 
            @StatusMessage = 'Finished load of dim.Employee'
    END TRY
    BEGIN CATCH
        SELECT ERROR_NUMBER() as ErrorNumber,
        ERROR_MESSAGE() as ErrorMessage;

        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorMessage = ERROR_MESSAGE();

        EXEC Audit.InsertOperationsEventLog
            @EventState = 'Failure', 
            @SourceType = 'Stored Procedure', 
            @SourceName = '[dim].[Load_Employee]', 
            @ErrorNumber = @ErrorNumber, 
            @ErrorMessage = @ErrorMessage, 
            @StatusMessage = 'Load of dim.Employee failed';

        THROW;
    END CATCH
END
GO

