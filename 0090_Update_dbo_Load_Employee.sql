-- don't forget to connect to the target database
ALTER PROCEDURE dim.Load_Employee
    --@Employee as dim.EmployeeType READONLY
AS
BEGIN
    DECLARE @ErrorNumber int = NULL;
    DECLARE @ErrorMessage varchar(8000) = NULL;
    DECLARE @StatusMessage varchar(8000) = NULL;
    DECLARE @SourceRowCount int = 0;

    BEGIN TRY
        SELECT  @SourceRowCount = ISNULL(COUNT(*), 0)
        --FROM    @Employee
        FROM    Stage.Employees 

        SET @StatusMessage = 'Starting load of dim.Employee.  Source rowcount: ' + CONVERT(varchar(8000), @SourceRowCount)

        EXEC Audit.InsertOperationsEventLog
            @EventState = 'Information', 
            @SourceType = 'Stored Procedure', 
            @SourceName = '[dim].[Load_Employee]', 
            @ErrorNumber = NULL, 
            @ErrorMessage = NULL, 
            @StatusMessage = @StatusMessage;

        MERGE INTO dim.Employee as TARGET
        --USING @Employee as SOURCE 
        USING Stage.Employees as SOURCE
        ON      TARGET.SourceKey = SOURCE.id 
        WHEN MATCHED AND
            (   SOURCE.firstName <> TARGET.firstName OR
                SOURCE.lastName <> TARGET.lastName
            )
        THEN UPDATE SET
                    target.firstName = source.firstName, 
                    target.lastName = source.lastName 
        WHEN NOT MATCHED THEN 
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