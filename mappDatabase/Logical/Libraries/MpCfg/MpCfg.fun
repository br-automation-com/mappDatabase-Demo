
FUNCTION_BLOCK MpCfgRW
	VAR_INPUT
		MpLink : {REDUND_UNREPLICABLE} MpComIdentType;
		Enable : BOOL;
		ReadWrite : BOOL;
		ErrorReset : BOOL;
		ParaName : STRING[MpCfgMaxNameSize];
		ParaValue : STRING[MpCfgMaxValueSize];
		GroupArray : REFERENCE TO MpCfgGroupArray;
	END_VAR
	VAR_OUTPUT
		Active : BOOL;
		Error : BOOL;
		StatusID : DINT;
		CommandDone : BOOL;
		DataType : STRING[50];
		Value : STRING[MpCfgMaxValueSize];
	END_VAR
	VAR
		Info : MpCfgInfoType;
		zzEdge00000 : BOOL;
		zzEdge00001 : BOOL;
	END_VAR
END_FUNCTION_BLOCK

FUNCTION FindInMem : DINT
	VAR_INPUT
		data1 : UDINT;
		len1 : UDINT;
		data2 : UDINT;
		len2 : UDINT;
		direction : BOOL;
	END_VAR
	VAR
		idx : UDINT;
	END_VAR
END_FUNCTION
