
TYPE
	dbCMD : 	STRUCT 
		Connect : BOOL;
		Disconnect : BOOL;
		Execute : BOOL;
		NextRow : BOOL;
	END_STRUCT;
	dbPAR : 	STRUCT 
		IsConnected : BOOL;
		QueryName : STRING[200];
		RowsTotal : UDINT;
		RowsRead : UDINT;
		RowsRemaining : UDINT;
	END_STRUCT;
	dbERR : 	STRUCT 
		Text : STRING[200];
		No : DINT;
	END_STRUCT;
	dbMAIN : 	STRUCT 
		CMD : dbCMD;
		PAR : dbPAR;
		ERR : dbERR;
	END_STRUCT;
	recCMD : 	STRUCT 
		Load : BOOL;
		Save : BOOL;
		New : BOOL;
		Delete : BOOL;
		Rename : BOOL;
		List : BOOL;
	END_STRUCT;
	recPAR : 	STRUCT 
		RecipeNames : ARRAY[0..9]OF STRING[200];
		RecipeName : STRING[200];
	END_STRUCT;
	recDATA : 	STRUCT 
		product_name : STRING[80];
		sugar : UINT;
		water : UINT;
		milk : UINT;
		temperature : REAL;
		test1 : BOOL;
		test2 : SINT;
		test3 : INT;
		test4 : DINT;
		test5 : USINT;
		test6 : UINT;
		test7 : UDINT;
		test8 : TIME;
		test9 : REAL;
		test10 : LREAL;
		test11 : DATE;
		test12 : DATE_AND_TIME;
	END_STRUCT;
	recMAIN : 	STRUCT 
		CMD : recCMD;
		PAR : recPAR;
		DATA : recDATA;
	END_STRUCT;
END_TYPE
