USE [JPMorgan]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE dbo.[sp_DeleteTables]
(
	@BatchSize INT,
	@CntOftables INT,
	@DateToDelete DATE	
)
AS
/******************************************************************************************
 Description:					Selects list of tables and deletes records based on
							input parameters
 Important Checklist:			1. Please verify the parent tables don't have forigen key
							2. CDC is disabled
							3. Reseed Identity column if required.
							4. Check for indexes being disabled else inform dba's.
							5. Delete in batches
							6. Rebuild index	 -- Check with dba's, if required
							7. Update Statistics -- Check with dba's, if required

 Dependencies:					dbo.[Tables]: list of tables
							[dbo].[usp_DeleteRecords]: Loops through the table 
							and deletes the records.

 Sample Execution:				EXEC dbo.[sp_DeleteTables]
								@BatchSize = 100000,
								@CntOftables = 100,
								@DateToDelete = '20160101'
-- ***************************************************************************************
-- TicketNo		Created date		User		Comments
--				18-04-2016		Ssingh	Initial Creation
-- ***************************************************************************************/

BEGIN

BEGIN TRY

SET NOCOUNT ON;
	
--Varaibles
Declare @LoopCnt INT = 1				     --To Loop through the tables 
Declare @TableName VARCHAR(50);			--Running TableName to be deleted

--Logging
--Check if Tables has the table names to be deleted
IF (SELECT TOP 1 1 FROM DBO.[Tables])  > 0
BEGIN

--Step 1: Get distinct table Names
	SELECT 
			Name AS TableName,						
			RowNo = IDENTITY (INT, 1,1)
		INTO #Tables
	FROM
		dbo.[Tables]
	GROUP BY Name;

--Logging
	-- Loop through all the tables
	WHILE (@LoopCnt < = @CntOftables)
	BEGIN
		
--Step 2: Select table
		  SELECT @TableName=TableName
		  FROM #Tables
		  WHERE RowNo=@LoopCnt

 --Logging
			EXEC [dbo].[usp_DeleteRecords]   @CreatedDate=@DateToDelete
							 		 , @ChildTableName = @TableName
									 , @BatchSize= @BatchSize
	SET @LoopCnt = @LoopCnt + 1 ;
	 
	END

END

END TRY
BEGIN CATCH	

--- logging and error handling
---			
THROW;

END CATCH

END