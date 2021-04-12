//misc functions


//prints the PID gains to file
FUNCTION log_gains {
	PARAMETER gains_lex.
	PARAMETER logname.
	
	IF EXISTS(logname) {DELETEPATH(logname).}
	
	LOCAL string IS "GLOBAL gains IS LEXICON(".
	
	LOCAL keylist IS gains_lex:KEYS.
	LOCAL vallist IS gains_lex:VALUES.
	
	FROM {LOCAL k IS 0.} UNTIL k >= (keylist:LENGTH) STEP { SET k TO k+1.} DO{
		LOCAL addstring IS CHAR(34) + keylist[k] + CHAR(34) + "," + vallist[k].
		IF k<(keylist:LENGTH-1) {SET addstring TO addstring + ",".}
		SET string TO string + addstring.
	}
	SET string TO string + ").".

	LOG string TO logname.

}




//calculating average of quantity
//given a list of current and previous readings
//and global indices that track the next value position
FUNCTION average_list {
	PARAMETER value_list.
	LOCAL  avg IS 0.
	FROM {LOCAL k IS 1.} UNTIL k > len STEP { SET k TO k+1.} DO{ SET avg TO avg + value_list[k]/len. }
	RETURN avg.
}



//given runway coordinates, assumed to be centre, and length 
//finds the coordinates of the touchdown points and adds them to the lexicon
FUNCTION define_td_points {

	FUNCTION add_runway_tdpt {
		PARAMETER site.
		PARAMETER bng.
		PARAMETER dist.

		LOCAL rwy_lexicon IS LEXICON(
											"heading",0,
											"td_pt",LATLNG(0,0)
								).
								
								
		LOCAL pos IS site["position"].
		
		local rwy_number IS "" + ROUND(bng/10,0).
		SET rwy_lexicon["heading"] TO bng.
		SET rwy_lexicon["td_pt"] TO new_position(pos,dist,fixangle(bng - 180)).
		
		
		site["rwys"]:ADD(rwy_number,rwy_lexicon).
		
		RETURN site.
	}
	
	FROM {LOCAL k IS 0.} UNTIL k >= (ldgsiteslex:KEYS:LENGTH) STEP { SET k TO k+1.} DO{	
		LOCAL site IS ldgsiteslex[ldgsiteslex:KEYS[k]].
	
	
		LOCAL dist IS site["length"].
		LOCAL head IS site["heading"].
		
		site:ADD("rwys",LEXICON()).
		
		//convert in kilometres
		SET dist TO dist/1000.
		
		//multiply by a hard-coded value identifying the touchdown marks from the 
		//runway halfway point
		SET dist TO dist*0.39.
		
		SET site TO add_runway_tdpt(site,head,dist).
		
		//now get the touchdown point for the opposite side of the runway
		SET head TO fixangle(head + 180).
		SET site TO add_runway_tdpt(site,head,dist).
		
		SET ldgsiteslex[ldgsiteslex:KEYS[k]] TO site.

	}

}






//navigation and measurement functions


//determines if the conditions are right for the reference pitch value (pitch of highest velocity point in 
//the pitch profile) to be set to the pitch slider value
FUNCTION update_ref_pitch {
	PARAMETER new_ref_pitch.
	
	IF ((SHIP:VELOCITY:SURFACE:MAG >= pitchprof_segments[pitchprof_segments:LENGTH-1][0]) AND (new_ref_pitch >=  pitchprof_segments[pitchprof_segments:LENGTH-2][1]) ) {
		RETURN TRUE.
	}
	RETURN FALSE.
	
}



FUNCTION az_error {
	PARAMETEr position.
	PARAMETER tgt_pos.
	PARAMETER surfv.


	//use haversine formula to get the bearings to target and impact point
	set tgt_bng to bearingg(tgt_pos, position).

	local hdg is compass_for(surfv,position).
	


	LOCAL out IS tgt_bng - hdg.
	IF ABS(out)>90 {
		SET out TO unfixangle(out + 180).
	}
	
	RETURN out.
}



FUNCTION abeam {
	//this is the B spherical angle
	PARAMETER az_err.
	//this is the c side
	PARAMETER  range.
	
	LOCAL p2 IS 180/((SHIP:ORBIT:BODY:RADIUS/1000)*CONSTANT:PI).

	RETURN get_a_cBB(range*p2,ABS(az_err))/p2.
}

FUNCTION cross_error {
	PARAMETEr pos.
	PARAMETER tgt_pos.
	PARAMETER surfv.
	PARAMETER  range. //this is the c side
	
	//this is the B spherical angle
	LOCAL az_err IS az_error(pos,tgt_pos,surfv).
	
	LOCAL p2 IS 180/((SHIP:ORBIT:BODY:RADIUS/1000)*CONSTANT:PI).
	
	RETURN get_b_cBB(range*p2,az_err)/p2.
	
}




//guidance functions 


//check the pitch profile for negative values
FUNCTION check_pitch_prof {
	
	FROM {local k is 0.} UNTIL k = pitchprof_segments:LENGTH STEP {set k to k+1.} DO {
		IF ( (pitchprof_segments[k][0] < 0 ) OR (pitchprof_segments[k][1] < 0 ) ) {
			RETURN FALSE.
		}
	}
	RETURN TRUE.
}



//wrapper for updating both pitch and roll functions 
//gather the calls here so that the simulation function remains agnostic about these functions 
FUNCTION pitchroll_profiles_entry {
	PARAMETER ref_att.
	PARAMETER cur_att.
	PARAMETER simstate.
	PARAMETER hddot.
	PARAMETER delaz.
	PARAMETER az_band.
	
	LOCAL roll_ref IS ref_att[0].
	LOCAL pitch_ref IS ref_att[1].
	
	LOCAL roll_cur IS cur_att[0].
	LOCAL pitch_cur IS cur_att[1].
	
	LOCAL roll_sign IS 1.
	
	IF (roll_cur = 0) {
		SET roll_sign TO SIGN(delaz).
	} ELSE {
		SET roll_sign TO roll_reversal(SIGN(roll_cur),delaz,az_band).
	}
	
	
		
	LOCAL roll_prof IS roll_sign*roll_profile(simstate,roll_ref,hddot).

	LOCAL pitch_prof IS pitch_profile(pitch_ref,simstate["surfvel"]:MAG).

	RETURN LIST(roll_prof, pitch_prof).
}




//new version which expects a global list of vel-pitch points 
// and builds the profile by linear interpolation
//if vel is higher than the highest velocity point it will update the reference 
//pitch to the alpha0 input value
FUNCTION pitch_profile {
	PARAMETER alpha0.
	PARAMETER vel IS 0.
	
	LOCAL out IS alpha0.

	IF (vel >= pitchprof_segments[pitchprof_segments:LENGTH-1][0] ) {
		SET  pitchprof_segments[pitchprof_segments:LENGTH-1][1] TO alpha0.
	} ELSE {
		SET out TO INTPLIN(pitchprof_segments,vel).
	}

	RETURN out.
}



//if not re-entering in RSS all the parameters in this function need to be changed
FUNCTION roll_profile {
	PARAMETER state.
	PARAMETER roll0.
	PARAMETER hddot.
	
	//wil not command any roll above this altitude
	IF state["altitude"]>90000 {
		RETURN 0.
	}
	
	//modulate the base roll based on vertical speed 
	//to try and dampen altitude oscillations
	//not too much since it reduces range a lot
	//this effect decays with velocity
	LOCAL base_gain is 10.
	IF (DEFINED gains) {SET base_gain TO gains["Khdot"].}
	LOCAL refvel IS 6500.
	LOCAL gain IS base_gain*(state["surfvel"]:MAG/refvel)^4.
	LOCAL newroll IS roll0 + gain*hddot.
	
	//let the base roll value decrease linearly with velocity
	SET newroll TO MIN(newroll,(roll0/2)*(state["surfvel"]:MAG + 2500 - 500)/(2500 - 250)).
	
	RETURN clamp(newroll,0,120).
}



//determine the sign of the roll given the error and its variation
FUNCTION roll_reversal {

	PARAMETER cur_sign.
	PARAMETER az_err.
	PARAMETER bandwidth.
	
	//the default output is simply set to the current roll sign
	LOCAL out_s IS cur_sign.
	
	
	IF ABS(az_err) > 0.9*bandwidth{
		//if we're out of the error band we command a reversal
		//we set the bank sign to the same sign as the error.
		//recall that the error is + if the tgt is to our right
		//and - if it's to the left 
		//and the same convention is used for bank angles 
		SET out_s TO SIGN(az_err).
	} 
	RETURN out_s.
}













//control functions

//create KSP direction based on AOA and bank angle wrt two specified vectors
FUNCTION create_steering_dir {
		PARAMETER refv.
		PARAMETER upv.
		PARAMETER pch.
		PARAMETER rll.
		
		//rotate the up vector by the new roll anglwe
		SET upv TO rodrigues(upv,refv,-rll).
		//create the pitch rotation vector
		LOCAL nv IS VCRS(refv,upv).
		//rotate the prograde vector by the pitch angle
		LOCAL aimv IS rodrigues(refv,nv,pch).
		
		RETURN LOOKDIRUP(aimv, upv).
	}


//handles vehicle attitude
FUNCTION update_attitude {

	


	PARAMETER cmd_dir.
	PARAMETER tgt_pitch.
	PARAMETER tgt_roll.
	
	LOCAL roll_tol IS 5.

	
	//reference prograde vector about which everything is rotated
	LOCAL PROGVEC is SHIP:srfprograde:vector:NORMALIZED.
	//vector pointing to local up and normal to prograde
	LOCAL upvec IS -SHIP:ORBIT:BODY:POSITION:NORMALIZED.
	SET upvec TO VXCL(PROGVEC,upvec).
	
	LOCAL cmd_vec IS cmd_dir:VECTOR.
	LOCAL ship_vec IS SHIP:FACING:VECTOR.
	

	//measure the current ship roll angle 
	LOCAL ship_roll IS get_roll().
		
		
	//is the current ship direction too far from the target direction in the roll plane?
	IF ABS( ship_roll - tgt_roll )>roll_tol {
		//target roll angle is too far to be set directly
		//use the current commanded roll angle as an intermediate roll angle
		// if we're close enough to it we need to update it 
		//to move it closer to the true target direction
		
		
		//we initialise the roll correction sign to minus the sign of the current ship roll
		//because that's the correct sign in case of a roll reversal condition
		//i.e. when the target roll is of opposite sign to the current roll.
		//in this case the absolute value of the roll needs to be decreased in either case
		//we actually want minus if the current roll is below 90 but plus if it's above 90
		
		LOCAL s_roll IS SIGN(ship_roll)*SIGN(ABS(ship_roll)-90).
		//if we're not in a reversal they'll have the same sign
		//and in that case work out if the roll needs to be increased or decreased
		IF SIGN(ship_roll)=SIGN(tgt_roll) {
			SET s_roll TO -SIGN(ship_roll - tgt_roll ).
		}
		
		SET new_roll TO ship_roll +  s_roll*roll_tol.
		
		IF ABS( tgt_roll - new_roll )<roll_tol {
			SET new_roll TO tgt_roll.
		}
		
		//set the target roll to the current commanded roll
		SET tgt_roll TO new_roll.

	}

	
	//create the target direction given pitch and roll values as givne or computed.
	RETURN create_steering_dir(PROGVEC,upvec,tgt_pitch,tgt_roll).
}







//automatic body flap control
FUNCTION  flaptrim_incr{
	PARAMETER pitch_input.
	PARAMETER flapval.
	
	
	
	//initialise the flap control pid loop 
	IF NOT (DEFINED FLAPPID) {
		LOCAL Kp IS -2.5.
		LOCAL Ki IS 0.
		LOCAL Kd IS 0.8.

		GLOBAL FLAPPID IS PIDLOOP(Kp,Ki,Kd).
		SET FLAPPID:SETPOINT TO 0.
	}

	LOCAL flap_incr IS  FLAPPID:UPDATE(TIME:SECONDS,pitch_input).
	

	RETURN flapval + flap_incr.
}



