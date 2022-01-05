
TYPE
	MpCfgInfoType : 	STRUCT 
		state : MpCfgStateType;
		DevLink_1 : DevLink;
		FileOpen_1 : FileOpen;
		FileRead_1 : FileRead;
		FileWrite_1 : FileWrite;
		FileClose_1 : FileClose;
		MpComConfigManager_1 : MpComConfigManager;
		Buffer : ARRAY[0..MpCfgMaxBufferSize]OF USINT;
		DataOffset1 : DINT;
		DataOffset2 : DINT;
		DataOffset3 : DINT;
		DataLen : DINT;
		FileLen : DINT;
		tmpStr1 : STRING[MpCfgMaxNameSize];
		tmpStr2 : STRING[MpCfgMaxNameSize];
		idx : UDINT;
	END_STRUCT;
	MpCfgStateType : 
		(
		stateWait,
		stateDevLink,
		stateExport,
		stateOpen,
		stateRead,
		stateWrite,
		stateClose,
		stateFindGroup,
		stateFindData,
		stateInsertData,
		stateImport,
		stateError
		);
	MpCfgGroupArray : 	STRUCT 
		Item : ARRAY[0..9]OF STRING[MpCfgMaxNameSize];
	END_STRUCT;
END_TYPE
