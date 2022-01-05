PROGRAM _INIT
	// --------------------------------------------------------------------------------------------------------------------
	// Preset function blocks
	MpDatabaseCore_0.MpLink := ADR(gDatabaseCore);
	MpDatabaseQuery_0.MpLink := ADR(gDatabaseCore);

	SqlTimeout.PT := TIMEOUT;
	
	REPEAT
		MpCfgRW_01.Enable 		:= TRUE;
		MpCfgRW_01.MpLink 		:= gDatabaseCore;
		MpCfgRW_01.ReadWrite 	:= MpCfgRead;
		MpCfgRW_01.ParaName 	:= 'IPAddress';
		MpCfgRW_01.GroupArray	:= 0;
		MpCfgRW_01();
		UNTIL MpCfgRW_01.CommandDone
	END_REPEAT;
	
END_PROGRAM

PROGRAM _CYCLIC
		// Trigger ping request
	PingTimer.IN := TRUE;
	PingTimer.PT := PING_TIMEOUT;
	PingTimer();
	// Try to ping network share if not connected
	IF(MpCfgRW_01.Value <> '' AND PingTimer.Q) THEN
		IcmpPing_0(enable := 1, pHost := ADR(MpCfgRW_01.Value), timeout := PING_TIMEOUT);
		// Ping was OK
		IF(IcmpPing_0.status = ERR_OK) THEN
			PingTimer(IN := FALSE);
			Database.PAR.CanPing := TRUE;
			// Disconnect from share when ping failed
		ELSIF(IcmpPing_0.status <> ERR_FUB_BUSY) THEN
			PingTimer(IN := FALSE);
			Database.PAR.CanPing := FALSE;
			IF(Database.PAR.IsConnected) THEN
				Database.CMD.Disconnect := TRUE;
			END_IF
		END_IF
	ELSIF(PingTimer.Q) THEN
		PingTimer(IN := FALSE);
	END_IF
	
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

			IF MpDatabaseCore_0.CommandDone OR MpDatabaseCore_0.Error THEN
				IF MpDatabaseCore_0.Error THEN
					Database.ERR.No := MpDatabaseCore_0.StatusID;
					dbState := dbSTATE_ERROR;
				ELSE
					Database.CMD.Connect := FALSE;
					dbState := dbSTATE_WAIT;
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

			IF MpDatabaseCore_0.CommandDone OR MpDatabaseCore_0.Error THEN

				IF MpDatabaseCore_0.Error THEN
					Database.ERR.No := MpDatabaseCore_0.StatusID;
					dbState := dbSTATE_ERROR;
				ELSE
					Database.CMD.Disconnect := FALSE;
					dbState := dbSTATE_WAIT;			
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

			IF MpDatabaseQuery_0.CommandDone OR MpDatabaseQuery_0.Error THEN
				Database.CMD.Execute := FALSE;

				IF MpDatabaseQuery_0.Error THEN
					Database.ERR.No := MpDatabaseQuery_0.StatusID;
					dbState := dbSTATE_ERROR;
				ELSE
					dbState := dbSTATE_WAIT;			
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

			IF MpDatabaseQuery_0.CommandDone OR MpDatabaseQuery_0.Error THEN
				Database.CMD.NextRow := FALSE;

				IF MpDatabaseQuery_0.Error THEN
					Database.ERR.No := MpDatabaseQuery_0.StatusID;
					dbState := dbSTATE_ERROR;
				ELSE
					dbState := dbSTATE_WAIT;			
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

