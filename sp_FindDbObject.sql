SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET QUOTED_IDENTIFIER ON;
SET NUMERIC_ROUNDABORT OFF;
SET IMPLICIT_TRANSACTIONS OFF;
SET STATISTICS TIME, IO OFF;
GO


/*********************************************************************************************

██████╗ ██╗ ███╗   ██╗ ██████╗ 
██╔═══╝ ██║ ████╗  ██║ ██╔══██╗ 
██████╗ ██║ ██╔██╗ ██║ ██║  ██║ 
██╔═══╝ ██║ ██║╚██╗██║ ██║  ██║ 
██║     ██║ ██║ ╚████║ ██████╔╝ 
╚═╝     ╚═╝ ╚═╝  ╚═══╝ ╚═════╝  

██████╗  ██████╗  
██╔══██╗ ██╔══██╗ 
██║  ██║ █████ ╔╝
██║  ██║ ██╔══██╗ 
██████╔╝ ██████╔╝ 
╚═════╝  ╚═════╝  

 ██████╗  ██████╗   ██████╗ ███████╗  ██████╗ ████████╗
██╔═══██╗ ██╔══██╗  ╚═══██║ ██╔════╝ ██╔════╝ ╚══██╔══╝
██║   ██║ █████ ╔╝      ██║ █████╗   ██║         ██║   
██║   ██║ ██╔══██╗ ██   ██║ ██╔══╝   ██║         ██║  
╚██████╔╝ ██████╔╝ ╚█████╔╝ ███████╗ ╚██████╗    ██║  
 ╚═════╝  ╚═════╝   ╚════╝  ╚══════╝  ╚═════╝    ╚═╝ 

Find Databases Objects... v1.0.0 
Copyright 2024 Dominik Dobija


v1.0.1
v1.0.0 Procedure was created
	


*********************************************************************************************/

IF OBJECT_ID('dbo.sp_FindDbObject') IS NULL
    EXEC ('CREATE PROCEDURE dbo.sp_FindDbObject AS RETURN 138;');
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_FindDbObject]
(
--~
    --What would you like to search for?
    @search_value nvarchar(2000) = NULL,

    --Select a method(s) for searching objects in the database
    --Valid column choices:
    --object, job, column
    --Note that metod names in the list must be separated by a semicolon or comma. = 'object;job;column;user'
    @search_metod varchar(100) = 'object;job;column',

    --Valid object types choices:
    --AF - Aggregate function (CLR)
    --C  - CHECK constraint
    --D  - DEFAULT (constraint or stand-alone)
    --F  - FOREIGN KEY constraint
    --FN - SQL scalar function
    --FS - Assembly (CLR) scalar-function
    --FT - Assembly (CLR) table-valued function
    --IF - SQL inline table-valued function
    --IT - Internal table
    --P  - SQL Stored Procedure
    --PC - Assembly (CLR) stored-procedure
    --PG - Plan guide
    --PK - PRIMARY KEY constraint
    --R  - Rule (old-style, stand-alone)
    --RF - Replication-filter-procedure
    --S  - System base table
    --SN - Synonym
    --SO - Sequence object
    --U  - Table (user-defined)
    --V  - View
    --SQ - Service queue
    --TA - Assembly (CLR) DML trigger
    --TF - SQL table-valued-function
    --TR - SQL DML trigger / SQL DDL trigger
    --TT - Table type
    --UQ - UNIQUE constraint
    --X  - Extended stored procedure
    --ST - STATS_TREE
    --ET - External Table
    --EC - Edge constraint
    @search_object_data_type varchar(100) = NULL,

    -- TODO
    @search_column_data_type varchar(100) = NULL,

    --Select the database(s) in which you want to search for objects or column
    --Valid column choices:
    --all dbs names except tempdb
    --
    --Note that metod names in the list must be separated by a semicolon or comma. 
    @search_database varchar(1000) = NULL,

    --Help! What do I do?
    @help bit = 0
--~
)
AS
BEGIN
	SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @name as sysname;
	DECLARE @SQL as nvarchar(max);

	IF
	  @search_metod	IS NULL 
    BEGIN;
        RAISERROR('Input parameters cannot be NULL', 16, 1);
        RETURN;
    END;

	SET @search_metod  = REPLACE(REPLACE(REPLACE(@search_metod ,CHAR(10),''), CHAR(13),''),',',';')

	IF @search_database IS NOT NULL 
	BEGIN;
		SET @search_database  = REPLACE(REPLACE(REPLACE(@search_database ,CHAR(10),''), CHAR(13),''),',',';')
	END
	IF @search_column_data_type IS NOT NULL
	BEGIN;
		SET @search_column_data_type  = REPLACE(REPLACE(REPLACE(@search_column_data_type ,CHAR(10),''), CHAR(13),''),',',';')
	END
		IF @search_object_data_type IS NOT NULL
	BEGIN;
		SET @search_object_data_type  = REPLACE(REPLACE(REPLACE(@search_object_data_type ,CHAR(10),''), CHAR(13),''),',',';')
	END

	IF @help = 1
    BEGIN;
        DECLARE
            @header VARCHAR(MAX),
            @params VARCHAR(MAX),
            @outputs VARCHAR(MAX);

        SELECT
            @header =
                REPLACE
                (
                    REPLACE
                    (
                        CONVERT
                        (
                            VARCHAR(MAX),
                            SUBSTRING
                            (
                                t.text,
                                CHARINDEX('/' + REPLICATE('*', 93), t.text) + 94,
                                CHARINDEX(REPLICATE('*', 93) + '/', t.text) - (CHARINDEX('/' + REPLICATE('*', 93), t.text) + 94)
                            )
                        ),
                        CHAR(13)+CHAR(10),
                        CHAR(13)
                    ),
                    '    ',
                    ''
                ),
            @params =
                CHAR(13) +
                    REPLACE
                    (
                        REPLACE
                        (
                            CONVERT
                            (
                                VARCHAR(MAX),
                                SUBSTRING
                                (
                                    t.text,
                                    CHARINDEX('--~', t.text) + 5,
                                    CHARINDEX('--~', t.text, CHARINDEX('--~', t.text) + 5) - (CHARINDEX('--~', t.text) + 5)
                                )
                            ),
                            CHAR(13)+CHAR(10),
                            CHAR(13)
                        ),
                        '    ',
                        ''
                    )
                --,@outputs =
                --    CHAR(13) +
                --        REPLACE
                --        (
                --            REPLACE
                --            (
                --                REPLACE
                --                (
                --                    CONVERT
                --                    (
                --                        VARCHAR(MAX),
                --                        SUBSTRING
                --                        (
                --                            t.text,
                --                            CHARINDEX('OUTPUT COLUMNS'+CHAR(13)+CHAR(10)+'--------------', t.text) + 32,
                --                            CHARINDEX('*/', t.text, CHARINDEX('OUTPUT COLUMNS'+CHAR(13)+CHAR(10)+'--------------', t.text) + 32) - (CHARINDEX('OUTPUT COLUMNS'+CHAR(13)+CHAR(10)+'--------------', t.text) + 32)
                --                        )
                --                    ),
                --                    '    ',
                --                    CHAR(255)
                --                ),
                --                CHAR(13)+CHAR(10),
                --                CHAR(13)
                --            ),
                --            '    ',
                --            ''
                --        ) +
                --        CHAR(13)
        FROM sys.dm_exec_requests AS r
        CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS t
        WHERE
            r.session_id = @@SPID;

		
        WITH
        a0 AS
        (SELECT 1 AS n UNION ALL SELECT 1),
        a1 AS
        (SELECT 1 AS n FROM a0 AS a CROSS JOIN a0 AS b),
        a2 AS
        (SELECT 1 AS n FROM a1 AS a CROSS JOIN a1 AS b),
        a3 AS
        (SELECT 1 AS n FROM a2 AS a CROSS JOIN a2 AS b),
        a4 AS
        (SELECT 1 AS n FROM a3 AS a CROSS JOIN a3 AS b),
        numbers AS
        (
            SELECT TOP(LEN(@header) - 1)
                ROW_NUMBER() OVER
                (
                    ORDER BY (SELECT NULL)
                ) AS number
            FROM a4
            ORDER BY
                number
        )
        SELECT
            RTRIM(LTRIM(
                SUBSTRING
                (
                    @header,
                    number + 1,
                    CHARINDEX(CHAR(13), @header, number + 1) - number - 1
                )
            )) AS [------header---------------------------------------------------------------------------------------------------------------]
        FROM numbers
        WHERE
            SUBSTRING(@header, number, 1) = CHAR(13);
		PRINT @params;
		WITH
        a0 AS
        (SELECT 1 AS n UNION ALL SELECT 1),
        a1 AS
        (SELECT 1 AS n FROM a0 AS a CROSS JOIN a0 AS b),
        a2 AS
        (SELECT 1 AS n FROM a1 AS a CROSS JOIN a1 AS b),
        a3 AS
        (SELECT 1 AS n FROM a2 AS a CROSS JOIN a2 AS b),
        a4 AS
        (SELECT 1 AS n FROM a3 AS a CROSS JOIN a3 AS b),
        numbers AS
        (
            SELECT TOP(LEN(@params) - 1)
                ROW_NUMBER() OVER
                (
                    ORDER BY (SELECT NULL)
                ) AS number
            FROM a4
            ORDER BY
                number
        ),
        tokens AS
        (
            SELECT
                RTRIM(LTRIM(
                    SUBSTRING
                    (
                        @params,
                        number + 1,
                        CHARINDEX(CHAR(13), @params, number + 1) - number - 1
                    )
                )) AS token,
                number,
                CASE
                    WHEN SUBSTRING(@params, number + 1, 1) = CHAR(13) THEN number
                    ELSE COALESCE(NULLIF(CHARINDEX(',' + CHAR(13) + CHAR(13), @params, number), 0), LEN(@params))
                END AS param_group,
                ROW_NUMBER() OVER
                (
                    PARTITION BY
                        CHARINDEX(',' + CHAR(13) + CHAR(13), @params, number),
                        SUBSTRING(@params, number+1, 1)
                    ORDER BY
                        number
                ) AS group_order
            FROM numbers
            WHERE
                SUBSTRING(@params, number, 1) = CHAR(13)
        ),
        parsed_tokens AS
        (
            SELECT
                MIN
                (
                    CASE
                        WHEN token LIKE '@%' THEN token
                        ELSE NULL
                    END
                ) AS parameter,
                MIN
                (
                    CASE
                        WHEN token LIKE '--%' THEN RIGHT(token, LEN(token) - 2)
                        ELSE NULL
                    END
                ) AS description,
                param_group,
                group_order
            FROM tokens
            WHERE
                NOT
                (
                    token = ''
                    AND group_order > 1
                )
            GROUP BY
                param_group,
                group_order
        )
        SELECT
            CASE
                WHEN description IS NULL AND parameter IS NULL THEN '-------------------------------------------------------------------------'
                WHEN param_group = MAX(param_group) OVER() THEN parameter
                ELSE COALESCE(LEFT(parameter, LEN(parameter) - 1), '')
            END AS [------parameter----------------------------------------------------------],
            CASE
                WHEN description IS NULL AND parameter IS NULL THEN '----------------------------------------------------------------------------------------------------------------------'
                ELSE COALESCE(description, '')
            END AS [------description-----------------------------------------------------------------------------------------------------]
        FROM parsed_tokens
        ORDER BY
            param_group,
            group_order;

		RETURN 
	END 

	
	IF (OBJECT_ID('tempdb..#SearchResultObject') IS NOT NULL) DROP TABLE #SearchResultObject
	CREATE TABLE #SearchResultObject (
								  [DB]					sysname
								, [Schema]				nvarchar(100)
								, [ObjectName]			nvarchar(200)
								, [ObjectType]			nvarchar(200)
								, [text]				nvarchar(max)
								)
								
	IF (OBJECT_ID('tempdb..#SearchResultColumn') IS NOT NULL) DROP TABLE #SearchResultColumn
	CREATE TABLE #SearchResultColumn(
								  [DB]					nvarchar(128)
								, [Schema]				nvarchar(128)
								, [TableName]			nvarchar(128)
								, [ColumnName]			nvarchar(128)
								, [DataType]			nvarchar(128)
								)

	IF (OBJECT_ID('tempdb..#SearchResultUser') IS NOT NULL) DROP TABLE #SearchResultUser
	CREATE TABLE #SearchResultUser (
								  [DB]					sysname 
								, [Name]				sysname
								, [Type]				varchar(200) 
								)

	IF (OBJECT_ID('tempdb..#SearchResultUserPermission') IS NOT NULL) DROP TABLE #SearchResultUserPermission
	CREATE TABLE #SearchResultUserPermission(
								  [DB]					sysname 
								, [UserType]			varchar(20)
								, [DatabaseUserName]	sysname 
								, [LoginName]			sysname NULL
								, [Role]				sysname NULL
								, [PermissionType]		nvarchar(255) 
								, [PermissionState]		nvarchar(255)
								, [ObjectType]			nvarchar(255)
								, [Schema]				nvarchar(255)
								, [ObjectName]			nvarchar(255)
								, [ColumnName]			nvarchar(255)
								)


	IF (@search_database IS NULL )
	BEGIN;
		DECLARE db_cursor CURSOR FAST_FORWARD READ_ONLY FOR 
		SELECT name 
		FROM [master].[dbo].[sysdatabases]
		WHERE name NOT IN ('tempdb') ;
	END;
	ELSE 
	BEGIN;
		DECLARE db_cursor CURSOR FOR 
		SELECT name 
		FROM [master].[dbo].[sysdatabases]
		WHERE name NOT IN ('tempdb') 
			AND name IN ( SELECT [value] FROM  STRING_SPLIT(@search_database,';'));
	END;

	OPEN db_cursor  
	FETCH NEXT FROM db_cursor INTO @name  

	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		IF( EXISTS(SELECT 1 FROM STRING_SPLIT(@search_metod,';') WHERE value = 'object'))
		BEGIN;
				SET @SQL = 'USE ' + QUOTENAME(@name) + 
						' INSERT INTO #SearchResultObject 
						SELECT DISTINCT ' + QUOTENAME(@name,'''') + ' DB,
						OBJECT_SCHEMA_NAME(o.id) [Schema],
						o.name AS [Object Name] ,
						CASE 
							WHEN o.xtype = ''AF'' THEN  ''Aggregate function (CLR)''
							WHEN o.xtype = ''C''  THEN  ''CHECK constraint''
							WHEN o.xtype = ''D''  THEN  ''DEFAULT (constraint or stand-alone)''
							WHEN o.xtype = ''F''  THEN  ''FOREIGN KEY constraint''
							WHEN o.xtype = ''FN'' THEN  ''SQL scalar function''
							WHEN o.xtype = ''FS'' THEN  ''Assembly (CLR) scalar-function''
							WHEN o.xtype = ''FT'' THEN  ''Assembly (CLR) table-valued function''
							WHEN o.xtype = ''IF'' THEN  ''SQL inline table-valued function''
							WHEN o.xtype = ''IT'' THEN  ''Internal table''
							WHEN o.xtype = ''P''  THEN  ''SQL Stored Procedure''
							WHEN o.xtype = ''PC'' THEN  ''Assembly (CLR) stored-procedure''
							WHEN o.xtype = ''PG'' THEN  ''Plan guide''
							WHEN o.xtype = ''PK'' THEN  ''PRIMARY KEY constraint''
							WHEN o.xtype = ''R''  THEN  ''Rule (old-style, stand-alone)''
							WHEN o.xtype = ''RF'' THEN  ''Replication-filter-procedure''
							WHEN o.xtype = ''S''  THEN  ''System base table''
							WHEN o.xtype = ''SN'' THEN  ''Synonym''
							WHEN o.xtype = ''SO'' THEN  ''Sequence object''
							WHEN o.xtype = ''U''  THEN  ''Table (user-defined)''
							WHEN o.xtype = ''V''  THEN  ''View''
							WHEN o.xtype = ''SQ'' THEN  ''Service queue''
							WHEN o.xtype = ''TA'' THEN  ''Assembly (CLR) DML trigger''
							WHEN o.xtype = ''TF'' THEN  ''SQL table-valued-function''
							WHEN o.xtype = ''TR'' THEN  ''SQL DML trigger''
							WHEN o.xtype = ''TT'' THEN  ''Table type''
							WHEN o.xtype = ''UQ'' THEN  ''UNIQUE constraint''
							WHEN o.xtype = ''X''  THEN  ''Extended stored procedure''
							WHEN o.xtype = ''ST'' THEN  ''STATS_TREE''
							WHEN o.xtype = ''ET'' THEN  ''External Table''
							WHEN o.xtype = ''EC'' THEN  ''Edge constraint''
							ELSE ''Inne''
						END as [Object Type]
						, text
						FROM sys.sysobjects o 
							LEFT JOIN sys.syscomments c ON o.id = c.id
						WHERE 1 = 1'  

					IF @search_value IS NOT NULL
					BEGIN
						SET @SQL = @SQL +	' AND (c.text like CONCAT( ''%'',' + QUOTENAME(@search_value,'''') + ',''%'')'
										+		'OR o.name like CONCAT( ''%'',' + QUOTENAME(@search_value,'''') + ',''%''))';
					END

					IF @search_object_data_type IS NOT NULL
					BEGIN
						SET @SQL = @SQL +	' AND o.type IN (SELECT [value] FROM STRING_SPLIT(' + QUOTENAME(@search_object_data_type, '''') + ','';''))'
					END
					
					EXEC (@SQL);
				END;

				IF( EXISTS(SELECT 1 FROM STRING_SPLIT(@search_metod,';') WHERE value = 'column'))
				BEGIN;
					SET @SQL = 'USE ' + QUOTENAME(@name) + ' INSERT INTO #SearchResultColumn
					SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE
					FROM INFORMATION_SCHEMA.COLUMNS 
					WHERE 1 = 1'
					IF @search_value IS NOT NULL
					BEGIN;
						SET @SQL = @SQL +	' AND COLUMN_NAME LIKE CONCAT( ''%'',' + QUOTENAME(@search_value,'''') + ',''%'')'
					END;
					IF @search_column_data_type IS NOT NULL
					BEGIN;
						SET @SQL = @SQL +	' AND DATA_TYPE IN (SELECT [value] FROM STRING_SPLIT(' + QUOTENAME(@search_column_data_type, '''') + ','';''))'
					END;
					
					--PRINT @SQL
					EXEC (@SQL)
				END;

				IF( EXISTS(SELECT 1 FROM STRING_SPLIT(@search_metod,';') WHERE value = 'user'))
				BEGIN;
					SET @SQL = 'USE ' + QUOTENAME(@name) + 'INSERT INTO #SearchResultUser 
								SELECT 
									' + QUOTENAME(@name,'''') + ' DB
										, [name]
										, CASE 
											WHEN [type] = ''A'' THEN ''Application role'' 
											WHEN [type] = ''C'' THEN ''User mapped to a certificate'' 
											WHEN [type] = ''E'' THEN ''External user from Microsoft Entra ID'' 
											WHEN [type] = ''G'' THEN ''Windows group'' 
											WHEN [type] = ''K'' THEN ''User mapped to an asymmetric key'' 
											WHEN [type] = ''R'' THEN ''Database role'' 
											WHEN [type] = ''S'' THEN ''SQL user'' 
											WHEN [type] = ''U'' THEN ''Windows user'' 
											WHEN [type] = ''X'' THEN ''External group from Microsoft Entra group or applications'' 
										END
								FROM 
									sys.database_principals 
								WHERE 
									[name] like CONCAT( ''%'',' + QUOTENAME(@search_value,'''') + ',''%'')'
					EXEC (@SQL)
					IF EXISTS(SELECT 1 FROM #SearchResultUser)
					BEGIN
						SET @SQL = 'USE ' + QUOTENAME(@name) + 'INSERT INTO #SearchResultUserPermission 
						SELECT ' + QUOTENAME(@name,'''') + ' DB, P.* FROM (
							SELECT
								[UserType] = CASE princ.[type] WHEN ''S'' THEN ''SQL User'' WHEN ''U'' THEN ''Windows User'' WHEN ''G'' THEN ''Windows Group'' END, [DatabaseUserName] = princ.[name],
								[LoginName] = ulogin.[name], [Role] = NULL, [PermissionType]   = perm.[permission_name], [PermissionState]  = perm.[state_desc], [ObjectType] = CASE perm.[class] WHEN 1 THEN obj.[type_desc]ELSE perm.[class_desc] END, [Schema] = objschem.[name], [ObjectName] = CASE perm.[class] WHEN 3 THEN permschem.[name] WHEN 4 THEN imp.[name] ELSE OBJECT_NAME(perm.[major_id]) END, [ColumnName] = col.[name]
							FROM
								sys.database_principals            AS princ
								LEFT JOIN sys.server_principals    AS ulogin    ON ulogin.[sid] = princ.[sid]
								LEFT JOIN sys.database_permissions AS perm      ON perm.[grantee_principal_id] = princ.[principal_id]
								LEFT JOIN sys.schemas              AS permschem ON permschem.[schema_id] = perm.[major_id]
								LEFT JOIN sys.objects              AS obj       ON obj.[object_id] = perm.[major_id]
								LEFT JOIN sys.schemas              AS objschem  ON objschem.[schema_id] = obj.[schema_id]
								LEFT JOIN sys.columns              AS col       ON col.[object_id] = perm.[major_id] AND col.[column_id] = perm.[minor_id]
								LEFT JOIN sys.database_principals  AS imp       ON imp.[principal_id] = perm.[major_id]
							WHERE princ.[type] IN (''S'',''U'',''G'') AND princ.[name] NOT IN (''sys'', ''INFORMATION_SCHEMA'')'
							SET @SQL = @SQL + ' UNION
							SELECT
								[UserType] = CASE membprinc.[type] WHEN ''S'' THEN ''SQL User'' WHEN ''U'' THEN ''Windows User'' WHEN ''G'' THEN ''Windows Group'' END,
								[DatabaseUserName] = membprinc.[name],[LoginName]        = ulogin.[name],[Role]             = roleprinc.[name],
								[PermissionType]   = perm.[permission_name],[PermissionState]  = perm.[state_desc],[ObjectType] = CASE perm.[class] WHEN 1 THEN obj.[type_desc] ELSE perm.[class_desc]END,
								[Schema] = objschem.[name], [ObjectName] = CASE perm.[class]WHEN 3 THEN permschem.[name] WHEN 4 THEN imp.[name] ELSE OBJECT_NAME(perm.[major_id]) END, [ColumnName] = col.[name]
							FROM
								sys.database_role_members          AS members
								JOIN      sys.database_principals  AS roleprinc ON roleprinc.[principal_id] = members.[role_principal_id]
								JOIN      sys.database_principals  AS membprinc ON membprinc.[principal_id] = members.[member_principal_id]
								LEFT JOIN sys.server_principals    AS ulogin    ON ulogin.[sid] = membprinc.[sid]
								LEFT JOIN sys.database_permissions AS perm      ON perm.[grantee_principal_id] = roleprinc.[principal_id]
								LEFT JOIN sys.schemas              AS permschem ON permschem.[schema_id] = perm.[major_id]
								LEFT JOIN sys.objects              AS obj       ON obj.[object_id] = perm.[major_id]
								LEFT JOIN sys.schemas              AS objschem  ON objschem.[schema_id] = obj.[schema_id]
								LEFT JOIN sys.columns              AS col       ON col.[object_id] = perm.[major_id] AND col.[column_id] = perm.[minor_id]
								LEFT JOIN sys.database_principals  AS imp       ON imp.[principal_id] = perm.[major_id]
							WHERE
								membprinc.[type] IN (''S'',''U'',''G'') AND membprinc.[name] NOT IN (''sys'', ''INFORMATION_SCHEMA'')'
							SET @SQL = @SQL + ' UNION
							SELECT
								[UserType]         = ''{All Users}'',[DatabaseUserName] = ''{All Users}'',[LoginName]        = ''{All Users}'',[Role]             = roleprinc.[name],
								[PermissionType]   = perm.[permission_name],[PermissionState]  = perm.[state_desc],[ObjectType] = CASE perm.[class]WHEN 1 THEN obj.[type_desc] ELSE perm.[class_desc] END,
								[Schema] = objschem.[name], [ObjectName] = CASE perm.[class] WHEN 3 THEN permschem.[name] WHEN 4 THEN imp.[name] ELSE OBJECT_NAME(perm.[major_id]) END,
								[ColumnName] = col.[name]
							FROM
								sys.database_principals            AS roleprinc
								LEFT JOIN sys.database_permissions AS perm      ON perm.[grantee_principal_id] = roleprinc.[principal_id]
								LEFT JOIN sys.schemas              AS permschem ON permschem.[schema_id] = perm.[major_id]
								JOIN      sys.objects              AS obj       ON obj.[object_id] = perm.[major_id]
								LEFT JOIN sys.schemas              AS objschem  ON objschem.[schema_id] = obj.[schema_id]
								LEFT JOIN sys.columns              AS col       ON col.[object_id] = perm.[major_id] AND col.[column_id] = perm.[minor_id]
								LEFT JOIN sys.database_principals  AS imp       ON imp.[principal_id] = perm.[major_id]
							WHERE
								roleprinc.[type] = ''R'' AND roleprinc.[name] = ''public''	AND obj.[is_ms_shipped] = 0
						) P 
						WHERE [DatabaseUserName] like CONCAT( ''%'',' + QUOTENAME(@search_value,'''') + ',''%'')
							OR [Role] like CONCAT( ''%'',' + QUOTENAME(@search_value,'''') + ',''%'')
						ORDER BY 
							[UserType],	[DatabaseUserName],	[LoginName],[Role],	[Schema],[ObjectName],[ColumnName],[PermissionType],[PermissionState],[ObjectType]'
					
					EXEC (@SQL)
					END;
				END;

		  FETCH NEXT FROM db_cursor INTO @name
	END 

	CLOSE db_cursor  
	DEALLOCATE db_cursor 

	IF( EXISTS(SELECT 1 FROM STRING_SPLIT(@search_metod,';') WHERE value = 'object'))
	BEGIN;
		SELECT DISTINCT O.DB
			, O.[Schema]
			, O.[ObjectName]
			, O.ObjectType
			, O.[text]
		FROM #SearchResultObject O 
	END;
	IF( EXISTS(SELECT 1 FROM STRING_SPLIT(@search_metod,';') WHERE value = 'column'))
	BEGIN;
		SELECT DISTINCT *
		FROM #SearchResultColumn C
	END;
	IF( EXISTS(SELECT 1 FROM STRING_SPLIT(@search_metod,';') WHERE value = 'job'))
	BEGIN;
	SELECT 
		Job.name 	AS JobName,
		Job.enabled	AS ActiveStatus,
		JobStep.step_name	AS JobStepName,
		JobStep.command		AS JobCommand
	FROM
		msdb.dbo.sysjobs Job
		INNER JOIN msdb.dbo.sysjobsteps JobStep
		ON Job.job_id = JobStep.job_id
		WHERE JobStep.command like CONCAT('%',@search_value,'%')
	END
	IF( EXISTS(SELECT 1 FROM STRING_SPLIT(@search_metod,';') WHERE value = 'user'))
	BEGIN;
		SELECT * FROM #SearchResultUser
		SELECT * FROM #SearchResultUserPermission
	END;
	DROP TABLE #SearchResultObject
	DROP TABLE #SearchResultUser
END
GO