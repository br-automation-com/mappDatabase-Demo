
TYPE
	dbCMD : 	STRUCT  (*Database command structure*)
		Connect : BOOL; (*Connect to database*)
		Disconnect : BOOL; (*Disconnect from database*)
		Execute : BOOL; (*Execute SQL command*)
		NextRow : BOOL; (*Get next response row*)
	END_STRUCT;
	dbPAR : 	STRUCT  (*Database parameter structure*)
		IsConnected : BOOL; (*Shows if database connection is active*)
		CanPing : BOOL; (*Shows if database connection is active*)
		QueryName : STRING[200]; (*Name of the SQL query define under mappServices*)
		RowsTotal : UDINT; (*Total number of response rows*)
		RowsRead : UDINT; (*Rows already reqeusted*)
		RowsRemaining : UDINT; (*Rows remaining*)
	END_STRUCT;
	dbERR : 	STRUCT  (*Database error structure*)
		Text : STRING[200]; (*Error text*)
		No : DINT; (*Error number*)
	END_STRUCT;
	dbMAIN : 	STRUCT  (*Database main structure*)
		CMD : dbCMD;
		PAR : dbPAR;
		ERR : dbERR;
	END_STRUCT;
	recCMD : 	STRUCT  (*Recipe command structure*)
		Load : BOOL; (*Load recipe*)
		Save : BOOL; (*Save recipe*)
		New : BOOL; (*Create new recipe*)
		Delete : BOOL; (*Delete recipe*)
		Rename : BOOL; (*Rename recipe*)
		List : BOOL; (*Get list of all recipes*)
	END_STRUCT;
	recPAR : 	STRUCT  (*Recipe parameter structure*)
		RecipeNames : ARRAY[0..9]OF STRING[200]; (*List of all recipes formated for mappView*)
		RecipeName : STRING[200]; (*Current recipe name for command*)
	END_STRUCT;
	recDATA : 	STRUCT  (*Recipe data structure*)
		product_name : STRING[80];
		sugar : UINT;
		water : UINT;
		milk : UINT;
		temperature : REAL;
	END_STRUCT;
	recMAIN : 	STRUCT  (*Recipe main structure*)
		CMD : recCMD;
		PAR : recPAR;
		DATA : recDATA;
	END_STRUCT;
END_TYPE
