// -------------------------------------------------------------------------
// Read mapp configuration parameter
// -------------------------------------------------------------------------
FUNCTION_BLOCK MpCfgRW
	// Abort command
	IF EDGENEG(Enable) THEN
		// Close file if it was already opened
		IF Info.state >= stateOpen AND Info.state <> stateError THEN
			Info.state := stateClose;
		END_IF
	END_IF

	// -------------------------------------------------------------------------
	// MpLink state machine
	CASE Info.state OF	
		// -------------------------------------------------------------------------
		// Wait for new command
		stateWait:
			// Reset all funtion blocks
			Info.DevLink_1.enable 				:= FALSE;
			Info.DevLink_1();
			Info.MpComConfigManager_1.Enable 	:= FALSE;
			Info.MpComConfigManager_1();
			Info.FileOpen_1.enable				:= FALSE;
			Info.FileOpen_1();
			Info.FileRead_1.enable				:= FALSE;
			Info.FileRead_1();
			Info.FileClose_1.enable				:= FALSE;
			Info.FileClose_1();

			// New command
			IF EDGEPOS(Enable) THEN
				// Make sure MpLink is not empty
				IF MpLink.Internal[0] = 0 THEN
					StatusID := MpCfgMpLinkEmpty;
					Info.state := stateError;
				ELSE
					// Make sure parameter is not empty
					IF ParaName = '' THEN
						StatusID := MpCfgParaNameEmpty;
						Info.state := stateError;
					ELSE					
						// Set start values
						Active := TRUE;
						DataType := '';
						Value := '';
						brsmemset(ADR(Info.Buffer), 0, SIZEOF(Info.Buffer));
						Info.state := stateDevLink;
					END_IF
				END_IF
			ELSE
				IF NOT Enable THEN
					CommandDone := FALSE;
				END_IF
				Active := FALSE;
			END_IF
			// -------------------------------------------------------------------------
		// Link file device used for exporting data
		stateDevLink:
			Info.DevLink_1.enable 	:= TRUE;
			Info.DevLink_1.pDevice	:= ADR('MpCfgDev');
			Info.DevLink_1.pParam	:= ADR('/DEVICE=C:/');
			Info.DevLink_1();
		
			// Success
			IF Info.DevLink_1.status = ERR_OK OR Info.DevLink_1.status = fiERR_DEVICE_ALREADY_EXIST THEN
				Info.state := stateExport;
			// Errror
			ELSIF Info.DevLink_1.status <> ERR_FUB_BUSY THEN
				StatusID := Info.DevLink_1.status;
				Info.state := stateError;
			END_IF
		// -------------------------------------------------------------------------
		// Export mapp data
		stateExport:
			Info.MpComConfigManager_1.Enable 		:= TRUE;
			Info.MpComConfigManager_1.MpLink		:= ADR(MpLink);
			Info.MpComConfigManager_1.DeviceName 	:= ADR('MpCfgDev');
			Info.MpComConfigManager_1.FileName 		:= ADR('MpCfg.xml');
			Info.MpComConfigManager_1.Scope			:= mpCOM_CONFIG_SCOPE_COMPONENT;
			Info.MpComConfigManager_1.Export		:= TRUE;
			Info.MpComConfigManager_1.Import		:= FALSE;
			Info.MpComConfigManager_1();
			
			// Success
			IF Info.MpComConfigManager_1.CommandDone AND NOT Info.MpComConfigManager_1.Error THEN
				Info.state := stateOpen;
			// Errror
			ELSIF Info.MpComConfigManager_1.Error THEN
				StatusID := Info.MpComConfigManager_1.StatusID;
				Info.state := stateError;
			END_IF
		// -------------------------------------------------------------------------
		// Open mapp data
		stateOpen:
			Info.FileOpen_1.enable		:= TRUE;
			Info.FileOpen_1.pDevice 	:= ADR('MpCfgDev');
			Info.FileOpen_1.pFile		:= ADR('MpCfg.xml');
			Info.FileOpen_1.mode 		:= fiREAD_WRITE;
			Info.FileOpen_1();
			
			// Success
			IF Info.FileOpen_1.status = ERR_OK THEN
				IF Info.FileOpen_1.filelen > SIZEOF(Info.Buffer) THEN
					StatusID := MpCfgBufferSizeExceeded;
					Info.state := stateError;
				ELSE
					Info.state := stateRead;
				END_IF
			// Errror
			ELSIF Info.FileOpen_1.status <> ERR_FUB_BUSY THEN
				StatusID := Info.FileOpen_1.status;
				Info.state := stateError;
			END_IF
			
		// -------------------------------------------------------------------------
		// Read mapp data file
		stateRead:
			Info.FileRead_1.enable		:= TRUE;
			Info.FileRead_1.ident		:= Info.FileOpen_1.ident;
			Info.FileRead_1.len			:= Info.FileOpen_1.filelen;
			Info.FileRead_1.pDest		:= ADR(Info.Buffer);
			Info.FileRead_1();
			
			// Success
			IF Info.FileRead_1.status = ERR_OK THEN
				Info.idx := 0;
				Info.DataOffset1 := 0;
				// Find group id first
				IF ADR(GroupArray) <> 0 THEN
					// Make sure array has at least one entry
					IF GroupArray.Item[0] <> '' THEN
						Info.state := stateFindGroup;
					// Find unique parameter
					ELSE
						Info.state := stateFindData;
					END_IF
				// Find unique parameter
				ELSE
					Info.state := stateFindData;
				END_IF
			// Errror
			ELSIF Info.FileRead_1.status <> ERR_FUB_BUSY THEN
				StatusID := Info.FileRead_1.status;
				Info.state := stateError;
			END_IF
				
		// -------------------------------------------------------------------------
		// Write mapp data file
		stateWrite:
			Info.FileWrite_1.enable		:= TRUE;
			Info.FileWrite_1.ident		:= Info.FileOpen_1.ident;
			Info.FileWrite_1.len		:= Info.FileLen;
			Info.FileWrite_1.pSrc		:= ADR(Info.Buffer);
			Info.FileWrite_1();
			
			// Success
			IF Info.FileWrite_1.status = ERR_OK THEN
				Info.state := stateClose;
			// Errror
			ELSIF Info.FileWrite_1.status <> ERR_FUB_BUSY THEN
				StatusID := Info.FileWrite_1.status;
				Info.state := stateError;
			END_IF
			
		// -------------------------------------------------------------------------
		// Find group data
		stateFindGroup:
			// Prepare group string
			Info.tmpStr1 := '<Group ID="';
			brsstrcat(ADR(Info.tmpStr1), ADR(GroupArray.Item[Info.idx]));
			brsstrcat(ADR(Info.tmpStr1), ADR('"'));
			// Find property string
			Info.DataOffset1 := Info.DataOffset1+FindInMem(ADR(Info.Buffer)+Info.DataOffset1, Info.FileOpen_1.filelen, ADR(Info.tmpStr1), brsstrlen(ADR(Info.tmpStr1)), FALSE);

			// Found group string
			IF Info.DataOffset1 > -1 THEN
				// Find next group name			
				IF Info.idx < SIZEOF(GroupArray)/SIZEOF(GroupArray.Item[0]) THEN
					Info.idx := Info.idx + 1;
					IF GroupArray.Item[Info.idx] = '' THEN
						Info.state := stateFindData;
					END_IF
				// Group was not found
				ELSE	
					StatusID := MpCfgGroupNotFound0+Info.idx;
					Info.state := stateError;
				END_IF
			// Group was not found
			ELSE
				StatusID := MpCfgGroupNotFound0+Info.idx;
				Info.state := stateError;
			END_IF
		// -------------------------------------------------------------------------
		// Find data
		stateFindData:
			// Prepare property string
			Info.tmpStr1 := '<Property ID="';
			brsstrcat(ADR(Info.tmpStr1), ADR(ParaName));
			brsstrcat(ADR(Info.tmpStr1), ADR('"'));
			// Find property string
			Info.DataOffset2 := FindInMem(ADR(Info.Buffer)+Info.DataOffset1, Info.FileOpen_1.filelen, ADR(Info.tmpStr1), brsstrlen(ADR(Info.tmpStr1)), FALSE);
			
			// Found parameter string
			IF Info.DataOffset2 > -1 THEN
				Info.DataOffset1 := Info.DataOffset1+Info.DataOffset2;
				// Prepare data type start string
				Info.tmpStr1 := 'DataType="';
				// Find data type string start
				Info.DataOffset2 := brsstrlen(ADR(Info.tmpStr1))+FindInMem(ADR(Info.Buffer)+Info.DataOffset1, Info.FileOpen_1.filelen, ADR(Info.tmpStr1), brsstrlen(ADR(Info.tmpStr1)), FALSE);

				// Found data type start
				IF Info.DataOffset2 > -1 THEN
					// Prepare data type end string
					Info.tmpStr1 := '"';
					// Find data type string
					Info.DataLen := FindInMem(ADR(Info.Buffer)+Info.DataOffset1+Info.DataOffset2, Info.FileOpen_1.filelen, ADR(Info.tmpStr1), brsstrlen(ADR(Info.tmpStr1)), FALSE);

					// Found data type end, copy data to output
					IF Info.DataLen > -1 THEN
						brsmemset(ADR(DataType), 0, SIZEOF(DataType));
						brsmemcpy(ADR(DataType), ADR(Info.Buffer)+Info.DataOffset1+Info.DataOffset2, Info.DataLen);

						// Prepare value start string
						Info.tmpStr1 := 'Value="';
						// Find data type string start
						Info.DataOffset2 := brsstrlen(ADR(Info.tmpStr1))+FindInMem(ADR(Info.Buffer)+Info.DataOffset1, Info.FileOpen_1.filelen, ADR(Info.tmpStr1), brsstrlen(ADR(Info.tmpStr1)), FALSE);

						// Found value start
						IF Info.DataOffset2 > -1 THEN
							// Prepare value end string
							Info.tmpStr1 := '"';
							// Find value end string
							Info.DataLen := FindInMem(ADR(Info.Buffer)+Info.DataOffset1+Info.DataOffset2, Info.FileOpen_1.filelen, ADR(Info.tmpStr1), brsstrlen(ADR(Info.tmpStr1)), FALSE);

							// Found value end, copy data to output
							IF Info.DataLen > -1 THEN
								brsmemset(ADR(Value), 0, SIZEOF(Value));
								brsmemcpy(ADR(Value), ADR(Info.Buffer)+Info.DataOffset1+Info.DataOffset2, Info.DataLen);
								
								// Finish when command is reading
								IF ReadWrite = MpCfgRead THEN
									Info.state := stateClose;
								// Insert new data in next step
								ELSE
									Info.state := stateInsertData;
								END_IF
							// Value end was not found
							ELSE
								StatusID := MpCfgValueNotFound;
								Info.state := stateError;
							END_IF
						// Value start was not found
						ELSE
							StatusID := MpCfgValueNotFound;
							Info.state := stateError;
						END_IF
					// Data type end was not found
					ELSE
						StatusID := MpCfgTypeNotFound;
						Info.state := stateError;
					END_IF
				// Data type end was not found
				ELSE
					StatusID := MpCfgTypeNotFound;
					Info.state := stateError;
				END_IF
			// Parameter name was not found
			ELSE
				StatusID := MpCfgParaNotFound;
				Info.state := stateError;
			END_IF

		// -------------------------------------------------------------------------
		// Insert new data
		stateInsertData:
			// Calculate start address for value
			Info.DataOffset3 := ADR(Info.Buffer)+Info.DataOffset1+Info.DataOffset2;
			// Calculate remaining data
			Info.DataLen := Info.FileOpen_1.filelen-(Info.DataOffset1+Info.DataOffset2);

			brsmemmove(Info.DataOffset3+brsstrlen(ADR(ParaValue)), Info.DataOffset3+brsstrlen(ADR(Value)), Info.DataLen-brsstrlen(ADR(Value))+1);
			brsmemcpy(Info.DataOffset3, ADR(ParaValue), brsstrlen(ADR(ParaValue)));
			
			// New value is shorter than old
			IF brsstrlen(ADR(Value)) >= brsstrlen(ADR(ParaValue)) THEN
				Info.FileLen := Info.FileOpen_1.filelen;
				// Fill taling memory with LF if new data is smaller than old
				brsmemset(ADR(Info.Buffer)+Info.FileLen, 10, brsstrlen(ADR(Value))-brsstrlen(ADR(ParaValue)));
			// New value is larger than old
			ELSE
				Info.FileLen := Info.FileOpen_1.filelen+(brsstrlen(ADR(ParaValue))-brsstrlen(ADR(Value)));
			END_IF
			
			Info.state := stateWrite;
			
		// -------------------------------------------------------------------------
		// Close mapp data file
		stateClose:
			Info.FileClose_1.enable		:= TRUE;
			Info.FileClose_1.ident		:= Info.FileOpen_1.ident;
			Info.FileClose_1();
			
			// Success
			IF Info.FileClose_1.status = ERR_OK THEN
				Info.FileOpen_1.enable := FALSE;
				
				// When we read it ends here
				IF ReadWrite = MpCfgRead THEN
					Active := FALSE;
					CommandDone := TRUE;					
					Info.state := stateWait;
				// Import new configuration
				ELSE
					Info.state := stateImport;				
				END_IF
				// Errror
			ELSIF Info.FileClose_1.status <> ERR_FUB_BUSY THEN
				StatusID := Info.FileClose_1.status;
				Info.state := stateError;
			END_IF

		// -------------------------------------------------------------------------
		// Import mapp data
		stateImport:
			Info.MpComConfigManager_1.Enable 		:= TRUE;
			Info.MpComConfigManager_1.MpLink		:= ADR(MpLink);
			Info.MpComConfigManager_1.DeviceName 	:= ADR('MpCfgDev');
			Info.MpComConfigManager_1.FileName 		:= ADR('MpCfg.xml');
			Info.MpComConfigManager_1.Scope			:= mpCOM_CONFIG_SCOPE_COMPONENT;
			Info.MpComConfigManager_1.Export		:= FALSE;
			Info.MpComConfigManager_1.Import		:= TRUE;
			Info.MpComConfigManager_1();
			
			// Success
			IF Info.MpComConfigManager_1.CommandDone AND NOT Info.MpComConfigManager_1.Error THEN
				Active := FALSE;
				CommandDone := TRUE;					
				Info.state := stateWait;
			// Errror
			ELSIF Info.MpComConfigManager_1.Error THEN
				StatusID := Info.MpComConfigManager_1.StatusID;
				Info.state := stateError;
			END_IF
			
		// -------------------------------------------------------------------------
		// Error state
		stateError:
			// Close file when it is open
			IF Info.FileOpen_1.enable THEN
				Info.FileClose_1.enable	:= TRUE;
				Info.FileClose_1.ident	:= Info.FileOpen_1.ident;
				Info.FileClose_1();
			END_IF
			
			// Set flags
			Active := FALSE;
			Error := TRUE;
			CommandDone := TRUE;
		
			// Wait for error reset
			IF ErrorReset THEN
				StatusID := 0;
				Error := FALSE;
				Info.state := stateWait;
			END_IF
	END_CASE;

	ErrorReset := FALSE;
END_FUNCTION_BLOCK
