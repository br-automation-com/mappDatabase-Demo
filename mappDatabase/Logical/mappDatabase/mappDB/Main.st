PROGRAM _INIT
	// --------------------------------------------------------------------------------------------------------------------
	// Preset function blocks
	MpDatabaseCore_0.MpLink := ADR(gDatabaseCore);
	MpDatabaseQuery_0.MpLink := ADR(gDatabaseCore);

	SqlTimeout.PT := TIMEOUT;
END_PROGRAM

PROGRAM _CYCLIC
	// --------------------------------------------------------------------------------------------------------------------
	// Database state machine
	// --------------------------------------------------------------------------------------------------------------------
	CASE dbState OF
		// --------------------------------------------------------------------------------------------------------------------
		// Wait state
		dbSTATE_WAIT:
			// --------------------------------------------------------------------------------------------------------------------
			// Connect to database
			IF Database.CMD.Connect THEN
				dbState := dbSTATE_CONNECT;
			END_IF
			
			// Disconnect from database
			IF Database.CMD.Disconnect THEN
				dbState := dbSTATE_DISCONNECT;
			END_IF
			
			// Execute SQL command
			IF Database.CMD.Execute THEN
				dbState := dbSTATE_QUERY;
			END_IF
			
			// Get next entry
			IF Database.CMD.NextRow THEN
				dbState := dbSTATE_NEXT;
			END_IF
			
			// --------------------------------------------------------------------------------------------------------------------
			// Reset error information and timeout timer
			IF Database.CMD.Connect OR Database.CMD.Disconnect OR Database.CMD.Execute OR Database.CMD.NextRow THEN
				Database.ERR.No := 0;
				brsmemset(ADR(Database.ERR.Text), 0, SIZEOF(Database.ERR.Text));

				MpDatabaseCore_0.Enable := TRUE;
				MpDatabaseQuery_0.Enable := TRUE;
				MpDatabaseQuery_0.ErrorReset := TRUE;
				MpDatabaseCore_0.ErrorReset := TRUE;
				MpDatabaseQuery_0();
				MpDatabaseCore_0();
				
				SqlTimeout.IN := 0;
				SqlTimeout();
			END_IF

		// --------------------------------------------------------------------------------------------------------------------
		// Connect state
		dbSTATE_CONNECT:	
			SqlTimeout.IN := 1;
			SqlTimeout();

			IF MpDatabaseCore_0.CommandDone OR MpDatabaseCore_0.Error <> 0 THEN
				IF MpDatabaseCore_0.Error = ERR_OK THEN
					Database.CMD.Connect := FALSE;
					dbState := dbSTATE_WAIT;
				ELSE
					Database.ERR.No := MpDatabaseCore_0.StatusID;
					dbState := dbSTATE_ERROR;
				END_IF
			ELSIF SqlTimeout.Q THEN
				Database.ERR.No := ERR_SQL_TIMEOUT_CONNECT;
				MpDatabaseCore_0.Enable := FALSE;
				dbState := dbSTATE_ERROR;					
			END_IF
			
		// --------------------------------------------------------------------------------------------------------------------
		// Disconnect state
		dbSTATE_DISCONNECT:		
			SqlTimeout.IN := 1;
			SqlTimeout();

			IF MpDatabaseCore_0.CommandDone OR MpDatabaseCore_0.Error <> 0 THEN

				IF MpDatabaseCore_0.Error = ERR_OK THEN
					Database.CMD.Disconnect := FALSE;
					dbState := dbSTATE_WAIT;			
				ELSE
					Database.ERR.No := MpDatabaseCore_0.StatusID;
					dbState := dbSTATE_ERROR;
				END_IF
			ELSIF SqlTimeout.Q THEN
				Database.ERR.No := ERR_SQL_TIMEOUT_CONNECT;
				MpDatabaseCore_0.Enable := FALSE;
				dbState := dbSTATE_ERROR;					
			END_IF
			
		// --------------------------------------------------------------------------------------------------------------------
		// Query state
		dbSTATE_QUERY:	
			SqlTimeout.IN := 1;
			SqlTimeout();

			IF MpDatabaseQuery_0.CommandDone OR MpDatabaseQuery_0.Error <> 0 THEN
				Database.CMD.Execute := FALSE;

				IF MpDatabaseQuery_0.Error = ERR_OK THEN
					dbState := dbSTATE_WAIT;			
				ELSE
					Database.ERR.No := MpDatabaseQuery_0.StatusID;
					dbState := dbSTATE_ERROR;
				END_IF
			ELSIF NOT Database.PAR.IsConnected THEN
				Database.ERR.No := ERR_SQL_NOT_CONNECTED;
				dbState := dbSTATE_ERROR;					
			ELSIF SqlTimeout.Q THEN
				Database.ERR.No := ERR_SQL_TIMEOUT_QUERY;
				MpDatabaseQuery_0.Enable := FALSE;
				dbState := dbSTATE_ERROR;					
			END_IF
			
		// --------------------------------------------------------------------------------------------------------------------
		// Read next row
		dbSTATE_NEXT:	
			SqlTimeout.IN := 1;
			SqlTimeout();

			IF MpDatabaseQuery_0.CommandDone OR MpDatabaseQuery_0.Error <> 0 THEN
				Database.CMD.NextRow := FALSE;

				IF MpDatabaseQuery_0.Error = ERR_OK THEN
					dbState := dbSTATE_WAIT;			
				ELSE
					Database.ERR.No := MpDatabaseQuery_0.StatusID;
					dbState := dbSTATE_ERROR;
				END_IF
			ELSIF SqlTimeout.Q THEN
				Database.ERR.No := ERR_SQL_TIMEOUT_QUERY;
				MpDatabaseQuery_0.Enable := FALSE;
				dbState := dbSTATE_ERROR;					
			END_IF	
			
		// --------------------------------------------------------------------------------------------------------------------
		// Error state
		dbSTATE_ERROR:
			Database.CMD.Connect := FALSE;
			Database.CMD.Disconnect := FALSE;
			Database.CMD.Execute := FALSE;
			Database.CMD.NextRow := FALSE;
			
			IF Database.ERR.No = mpDATABASE_ERR_SQL_SERVER THEN
				Database.ERR.Text := 'Error response from SQL server. Check SQL syntax!';
			ELSIF Database.ERR.No = mpCOM_ERR_ACTIVATION THEN
				Database.ERR.Text := 'Could not create component query. Try to reboot PLC and script!';
			ELSIF Database.ERR.No = mpDATABASE_ERR_QUERY_RESULT THEN
				Database.ERR.Text := 'Check the query to determine if correct table and column names were used.';
			ELSIF Database.ERR.No = mpDATABASE_INF_NO_DATA THEN
				Database.ERR.Text := 'No more data available.';
			ELSIF Database.ERR.No = mpDATABASE_ERR_HTTP_SERVER AND NOT Database.PAR.IsConnected THEN
				Database.ERR.Text := 'Not connected to database. Try to reboot PLC and script!';
			ELSIF Database.ERR.No = ERR_SQL_TIMEOUT_CONNECT THEN
				Database.ERR.Text := 'SQL timeout during connection. Make sure script and server is running.';
			ELSIF Database.ERR.No = ERR_SQL_TIMEOUT_QUERY THEN
				Database.ERR.Text := 'SQL timeout during query.';
			ELSIF Database.ERR.No = ERR_SQL_NOT_CONNECTED THEN
				Database.ERR.Text := 'Not connected to database. Call command connect first';
			ELSE
				Database.ERR.Text := 'Generic SQL error.';
			END_IF
			
			dbState := dbSTATE_WAIT;
	END_CASE;
	
	// --------------------------------------------------------------------------------------------------------------------
	// Function block calls
	IF NOT MpDatabaseQuery_0.ErrorReset THEN
		MpDatabaseQuery_0.Execute := Database.CMD.Execute;
		MpDatabaseQuery_0.Next := Database.CMD.NextRow;
		MpDatabaseQuery_0.Name := ADR(Database.PAR.QueryName);
	END_IF
	MpDatabaseQuery_0();

	IF NOT MpDatabaseCore_0.ErrorReset THEN
		MpDatabaseCore_0.Connect := Database.CMD.Connect;
		MpDatabaseCore_0.Disconnect := Database.CMD.Disconnect;
	END_IF
	MpDatabaseCore_0();

	// Transfer function block data to global structure
	Database.PAR.IsConnected := MpDatabaseCore_0.Connected;
	Database.PAR.RowsTotal := MpDatabaseQuery_0.Info.Rows.Total;
	Database.PAR.RowsRead := MpDatabaseQuery_0.Info.Rows.Read;
	Database.PAR.RowsRemaining := MpDatabaseQuery_0.Info.Rows.Remaining;

	// Clear error reset command
	MpDatabaseQuery_0.ErrorReset := FALSE;
	MpDatabaseCore_0.ErrorReset := FALSE;

END_PROGRAM

PROGRAM _EXIT
	// --------------------------------------------------------------------------------------------------------------------
	// Exit function blocks
	MpDatabaseCore_0.Enable := FALSE;
	MpDatabaseCore_0();

	MpDatabaseQuery_0.Enable := FALSE;
	MpDatabaseQuery_0();

END_PROGRAM

