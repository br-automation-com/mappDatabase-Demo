PROGRAM _INIT
END_PROGRAM

PROGRAM _CYCLIC
	
	// Generate a list with all recipe names
	IF EDGEPOS(Recipe.CMD.List) OR EDGEPOS(Database.PAR.IsConnected) THEN
		Database.PAR.QueryName := 'RecipeList';
		Database.CMD.Execute := TRUE;
		Recipe.CMD.List := TRUE;
		idx := 0;
		brsmemset(ADR(Recipe.PAR.RecipeNames), 0, SIZEOF(Recipe.PAR.RecipeNames));
	END_IF
	// Translate recipe names to mappView data providers
	IF Recipe.CMD.List AND (EDGENEG(Database.CMD.Execute) OR EDGENEG(Database.CMD.NextRow)) THEN
		brsstrcpy(ADR(Recipe.PAR.RecipeNames[idx]), ADR('{"value":"'));
		brsstrcat(ADR(Recipe.PAR.RecipeNames[idx]), ADR(Recipe.PAR.RecipeName));
		brsstrcat(ADR(Recipe.PAR.RecipeNames[idx]), ADR('","text":"'));	
		brsstrcat(ADR(Recipe.PAR.RecipeNames[idx]), ADR(Recipe.PAR.RecipeName));
		brsstrcat(ADR(Recipe.PAR.RecipeNames[idx]), ADR('"}'));
		
		// Read next entry as long as we have entries and space
		IF Database.PAR.RowsRemaining > 0 AND idx < SIZEOF(Recipe.PAR.RecipeNames)/SIZEOF(Recipe.PAR.RecipeNames[idx]) THEN
			idx := idx + 1;
			Database.CMD.NextRow := TRUE;
		ELSE
			Recipe.CMD.List := FALSE;
		END_IF
	END_IF

	// Load recipe
	IF Recipe.CMD.Load THEN
		// Reset command
		IF EDGENEG(Database.CMD.Execute) THEN
			Recipe.CMD.Load := FALSE;
		// Trigger database command
		ELSE
			Database.PAR.QueryName := 'RecipeLoad';
			Database.CMD.Execute := TRUE;
		END_IF
	END_IF

	// Save recipe
	IF Recipe.CMD.Save OR Recipe.CMD.Rename THEN
		// Reset command
		IF EDGENEG(Database.CMD.Execute) THEN
			Recipe.CMD.Save := FALSE;
			IF Recipe.CMD.Rename THEN
				Recipe.CMD.Rename := FALSE;
				Recipe.CMD.List := TRUE;
			END_IF
		// Trigger database command
		ELSE
			Database.PAR.QueryName := 'RecipeSave';
			Database.CMD.Execute := TRUE;
		END_IF
	END_IF
	
	// New recipe
	IF Recipe.CMD.New THEN
		// Reset command
		IF EDGENEG(Database.CMD.Execute) THEN
			Recipe.CMD.New := FALSE;
			Recipe.CMD.List := TRUE;
		// Trigger database command
		ELSE
			Database.PAR.QueryName := 'RecipeNew';
			Database.CMD.Execute := TRUE;
		END_IF
	END_IF
	
	// Delete recipe
	IF Recipe.CMD.Delete THEN
		// Reset command
		IF EDGENEG(Database.CMD.Execute) THEN
			Recipe.CMD.Delete := FALSE;
			Recipe.CMD.List := TRUE;
		// Trigger database command
		ELSE
			Database.PAR.QueryName := 'RecipeDelete';
			Database.CMD.Execute := TRUE;
		END_IF
	END_IF

END_PROGRAM


