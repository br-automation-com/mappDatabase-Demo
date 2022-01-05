
TYPE
    MpDatabaseErrorEnum : 
        ( (* Error numbers of library MpDatabase *)
        mpDATABASE_NO_ERROR := 0, (* No error *)
        mpDATABASE_ERR_ACTIVATION := -1064239103, (* Could not create component [Error: 1, 0xc0910001] *)
        mpDATABASE_ERR_MPLINK_NULL := -1064239102, (* MpLink is NULL pointer [Error: 2, 0xc0910002] *)
        mpDATABASE_ERR_MPLINK_INVALID := -1064239101, (* MpLink connection not allowed [Error: 3, 0xc0910003] *)
        mpDATABASE_ERR_MPLINK_CHANGED := -1064239100, (* MpLink modified [Error: 4, 0xc0910004] *)
        mpDATABASE_ERR_MPLINK_CORRUPT := -1064239099, (* Invalid MpLink contents [Error: 5, 0xc0910005] *)
        mpDATABASE_ERR_MPLINK_IN_USE := -1064239098, (* MpLink already in use [Error: 6, 0xc0910006] *)
        mpDATABASE_ERR_CONFIG_INVALID := -1064239091, (* Invalid Configuration [Error: 13, 0xc091000d] *)
        mpDATABASE_ERR_SQL_SERVER := -1064167424, (* SQL server error (ErrorNumber: {2:ErrorNumber}) [Error: 6144, 0xc0921800] *)
        mpDATABASE_ERR_HTTP_SERVER := -1064167423, (* HTTP server error (ErrorNumber: {2:ErrorNumber}) [Error: 6145, 0xc0921801] *)
        mpDATABASE_ERR_INVALID_QUERY := -1064167422, (* Query "{2:QueryName}" is not configured [Error: 6146, 0xc0921802] *)
        mpDATABASE_ERR_DUPLICATE_QUERY := -1064167421, (* Query "{2:QueryName}" cannot be added because it already exists [Error: 6147, 0xc0921803] *)
        mpDATABASE_INF_NO_DATA := 1083316228, (* There is either no data in response or all data has been copied to PVs [Informational: 6148, 0x40921804] *)
        mpDATABASE_ERR_INVALID_DATATYPE := -1064167419, (* Data type "{2:TypeName}" is not supported [Error: 6149, 0xc0921805] *)
        mpDATABASE_INF_WAIT_CORE_FB := 1083316230, (* Waiting for parent component [Informational: 6150, 0x40921806] *)
        mpDATABASE_WRN_QUERY_RESULT := -2137909241, (* When interpreting SQL result, PV "{2:PvName}" was written with a warning {3:ErrorNumber} [Warning: 6151, 0x80921807] *)
        mpDATABASE_ERR_QUERY_RESULT := -1064167416, (* Error when interpreting SQL result, error number: "{2:ErrorNumber}" [Error: 6152, 0xc0921808] *)
        mpDATABASE_ERR_INVALID_USER := -1064167415, (* Query "{2:QueryName}" can only be executed from a widget [Error: 6153, 0xc0921809] *)
        mpDATABASE_WRN_PV_ARRAY_SIZE := -2137909238 (* The size of the PVs in query "{2:QueryName}" differs between PVs [Warning: 6154, 0x8092180a] *)
        );
END_TYPE
