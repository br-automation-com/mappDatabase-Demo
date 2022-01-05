//******************************************************************************************************
// Find second data in first data																		
//******************************************************************************************************
FUNCTION FindInMem
	FindInMem := -1;
	IF (len1 > len2) THEN
		IF(direction) THEN
			idx := len1 - len2; 
			WHILE(idx > 0) DO
				IF (brsmemcmp(data1 + idx, data2, len2) = 0) THEN
					FindInMem := idx;
					EXIT;
				END_IF
				idx := idx - 1;
			END_WHILE;
		ELSE
			FOR idx:=0 TO len1 - len2 DO
				IF (brsmemcmp(data1 + idx, data2, len2) = 0) THEN
					FindInMem := idx;
					EXIT;
				END_IF
			END_FOR;
		END_IF
	END_IF
END_FUNCTION

