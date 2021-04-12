



//fancy function to print stuff to screen in a consistent format
//prints a fixed width of screen in characters at a specified position 
//given by leftcolumn and line .
//pads with blank spaces as needed
FUNCTION PRINTPLACE{
	parameter string.
	parameter width.
	parameter leftcolumn.
	parameter line.
	
	set string to string + "".

	local x is width - string:LENGTH.
	
	IF x<0 {RETURN.}
	
	set x to FLOOR(x/2).
	if x=0 {set x to 0.}
	
	LOCAL blankstr IS "".
	
	FROM {LOCAL k IS 1.} UNTIL k > width STEP { SET k TO k+1.} DO{
		SET blankstr TO blankstr + " ".
	}
	
	PRINT blankstr AT (leftcolumn,line).
	PRINT string AT (leftcolumn + x,line).

}




//log handler function, takes a lexicon as imput
//creates a log file, deleting the file by the same name if it exists
//then creates the column headers by dumping the lexicon keys
//if the log file has already been created just logs the lexicon to file
FUNCTION log_data {
	
	//logs to a file specified by filename the values of a lexicon log_lex
	FUNCTION dataLog {
		DECLARE PARAMETER filename.
		PARAMETER log_lex.
		
		LOCAL str IS "".
		
		//append to the string the numbers in sequence separated by four spaces
		FOR val IN log_lex:VALUES {
			SET str TO str + val + "    ".
		}

		LOG str TO filename.
	}

	PARAMETER log_lex.
	PARAMETER logname_string IS "".
	PARAMETER overwrite IS FALSE.
	
	if not (defined logname) {
	
		IF overwrite {
			GLOBAL logname is logname_string  + ".txt".
			IF EXISTS(logname)=TRUE {
				MOVEPATH(logname,logname_string + "_old" + ".txt").
			}
		} ELSE {
			local logcount is 0.
			GLOBAL logname is logname_string + logcount + ".txt".
			until false {
				set logname to logname_string + logcount + ".txt".
				IF EXISTS(logname)=TRUE {
					set logcount to logcount + 1.
				}
				ELSE {break.}
				
				
			}
		}
		
		LOCAL titlestr IS "".
		
		FOR key IN log_lex:KEYS {
			SET titlestr TO titlestr + key + "    ".
		}
		
		log titlestr to logname.

	} ELSE { 	
		dataLog(logname,log_lex).
	}
}





//draw a vector  with label, bu default its centered on the ship and scaled to 10 times its length
FUNCTION arrow {
	PARAMETER v.
	PARAMETER lab.
	PARAMETER v_centre IS v(0,0,0).
	PARAMETER scl IS 10.
	PARAMETER wdh IS 0.5.
	
	VECDRAW(
      v_centre,
      v,
      RGB(1,0,0),
      lab,
      scl,
      TRUE,
      wdh
    ).

}


//converts a time value into a hours,minutes,seconds string
declare function sectotime {
	parameter t.
	local string is "".
	if t<0 {
		set t to ABS(t).
		set string to string + "-".
	}
	if t<60 {
		set string to string + FLOOR(t) + " s".	
	}
	else {
		local min is FLOOR(t/60).
		if min<60 {
			local sec is FLOOR(t - min*60).
			set string to string + min + " m " + sec+ " s".
		}
		else {
			local sec is FLOOR(t - min*60).	
			local hr is FLOOR(min/60).
			set min to min - hr*60.
			set string to string + hr + " h " + min + " m " + sec+ " s".
		}
	}
	return string.
}



