
PROGRAM _INIT
	(* Insert code here *)
	 
END_PROGRAM

PROGRAM _CYCLIC
	IF create > 0 AND NOT Recipe.CMD.New THEN
		tmpSTR1 := 'TestProduct';
		brsitoa(create, ADR(tmpSTR2));
		brsstrcat(ADR(tmpSTR1), ADR(tmpSTR2));
		Recipe.DATA.product_name := tmpSTR1;
		Recipe.DATA.water := create;
		Recipe.DATA.milk := create;
		Recipe.DATA.sugar := create;
		Recipe.DATA.temperature := create/3.14;
		Recipe.DATA.test1 := UINT_TO_BOOL(create);
		Recipe.DATA.test2 := UINT_TO_SINT(create);
		Recipe.DATA.test3 := UINT_TO_INT(create);
		Recipe.DATA.test4 := UINT_TO_DINT(create);
		Recipe.DATA.test5 := UINT_TO_USINT(create);
		Recipe.DATA.test6 := create;
		Recipe.DATA.test7 := UINT_TO_UDINT(create);
		Recipe.DATA.test8 := UINT_TO_TIME(create);
		Recipe.DATA.test9 := UINT_TO_REAL(create);
		Recipe.DATA.test10 := UINT_TO_LREAL(create);
		Recipe.DATA.test11 := UINT_TO_DATE(create);
		Recipe.DATA.test12 := UINT_TO_DT(create);
		
		create := create - 1;
		Recipe.CMD.New := TRUE;
	END_IF
	 
END_PROGRAM



