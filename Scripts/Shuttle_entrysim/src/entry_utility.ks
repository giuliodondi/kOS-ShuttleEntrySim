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







//navigation and measurement functions

//reference velocity-fpa curve taken from descent guidance paper
FUNCTION FPA_reference {
	PARAMETER vel.
	
	//shallow
	LOCAL p1 IS  -8.396.
	LOCAL p2 IS 64340.
	LOCAL q1 IS -6347.
	
	RETURN (p1*vel + p2) / (vel + q1).
}



//determines if the conditions are right for the reference pitch value (pitch of highest velocity point in 
//the pitch profile) to be set to the pitch slider value
FUNCTION update_ref_pitch {
	PARAMETER new_ref_pitch.
	
	IF ((SHIP:VELOCITY:SURFACE:MAG >= pitchprof_segments[pitchprof_segments:LENGTH-1][0]) AND (new_ref_pitch >=  pitchprof_segments[pitchprof_segments:LENGTH-2][1]) ) {
		RETURN TRUE.
	}
	RETURN FALSE.
	
}


//old strategy : compare curent heading and bearing to target
//prone to angle singularities and weird stuff when flying retrograde or due north
//FUNCTION az_error {
//	PARAMETEr position.
//	PARAMETER tgt_pos.
//	PARAMETER surfv.
//
//
//	//use haversine formula to get the bearings to target and impact point
//	LOCAL tgt_bng IS bearingg(tgt_pos, position).
//
//	local hdg is compass_for(surfv,position).
//	
//
//
//	LOCAL out IS tgt_bng - hdg.
//	IF ABS(out)>90 {
//		SET out TO unfixangle(out + 180).
//	}
//	
//	RETURN out.
//}

//new approach, hopefully more robust
//simply calculate the angle between velocity vector and vector pointing to the target
FUNCTION az_error {
	PARAMETEr pos.
	PARAMETER tgt_pos.
	PARAMETER surfv.
	
	IF pos:ISTYPE("geocoordinates") {
		SET pos TO pos2vec(pos).
	}
	IF tgt_pos:ISTYPE("geocoordinates") {
		SET tgt_pos TO pos2vec(tgt_pos).
	}

		
	//vector normal to vehicle vel and in the same plane as vehicle pos
	//defines the "plane of velocity"
	LOCAL n1 IS VXCL(surfv,pos):NORMALIZED.
	
	//vector pointing from vehicle pos to target, projected "in the plane of velocity"
	LOCAL dr IS VXCL(n1,tgt_pos - pos):NORMALIZED.
	
	//clamp to -180 +180 range
	RETURN signed_angle(
		surfv:NORMALIZED,
		dr,
		n1,
		0
	).

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
		SET roll_sign TO roll_reversal(SIGN(roll_cur),delaz,az_band,roll_ref).
	}
		
	LOCAL roll_prof IS roll_sign*roll_profile(simstate,roll_ref,hddot,delaz).

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




//alternative pitch modulation logic based on range error
//create a profile of acceptable range error values vs velocity
//if the range error is outside this band , increase or decrease pitch to adjust drag 
//the pitch delta is scaled to the current pitch times a gain
FUNCTION pitch_modulation {
	PARAMETER range_err.
	PARAMETER pitchv.
	
	
	LOCAL range_err_profile IS LIST(
								LIST(250,3),
								LIST(8000,40)
								).
	
	LOCAL range_band IS INTPLIN(range_err_profile,SHIP:VELOCITY:SURFACE:MAG).
	
	LOCAL pitch_corr IS 0.
	
	//the pitch correction should have the same sign as the range error
	//i.e. negative if we're short and positive if we're long
	//the correction is scaled to be between 0 and 1 when the range error is between 0.5x and 1.5x the range_band
	IF ABS(range_err) > range_band {
		SET pitch_corr TO SIGN(range_err) * CLAMP((ABS(range_err/range_band) - 1),0,1) * pitchv *  gains["pchmod"].
	}
		
	RETURN pitchv + pitch_corr.
}



//if not re-entering in RSS all the parameters in this function need to be changed
FUNCTION roll_profile {
	PARAMETER state.
	PARAMETER roll0.
	PARAMETER hddot.
	PARAMETER delaz.
	
	//wil not command any roll above this altitude
	IF state["altitude"]>constants["firstrollalt"] {
		RETURN 0.
	}
	
	//modulate the base roll based on vertical speed 
	//to try and dampen altitude oscillations
	//not too much since it reduces range a lot
	//this effect decays with velocity
	LOCAL refvel IS 6500.
	LOCAL gain IS gains["Khdot"]*(state["surfvel"]:MAG/refvel)^4.
	LOCAL newroll IS roll0 + gain*hddot.
	
	//let the base roll value decrease linearly with velocity
	SET newroll TO MIN(newroll,(roll0/2)*(state["surfvel"]:MAG + 2500 - 500)/(2500 - 250)).
	
	LOCAL roll_min IS 0.
	//heuristic minimum roll taken from the training manuals
	//min value to still ensure proper lateral guidance even in low-energy situations
	//only enable it if the reference roll is too small
	IF (roll0 < 10) {
		SET roll_min TO 2*ABS(delaz).
	}
	
	RETURN clamp(newroll,roll_min,120).
}




//determine the sign of the roll given the az error and its variation
FUNCTION roll_reversal {
	PARAMETER cur_sign.
	PARAMETER delaz.
	PARAMETER bandwidth.
	PARAMETER roll_ref.
	
	//the 0.9 factor is to compensate for slow roll reversal and tendency to overshoot
	
	//the logic for low energy guidance is to bank towards the target at minimum bank angle but then
	//to disable the roll reversals and fly at zero bank
	//do this by clamping the delaz bandwidth using the roll ref value which is small or even zero in low energy cases
	//divide by 2 because of the same heuristic used for the min bank angle, only the other way around
	LOCAL red_bandwidth IS 0.9*MIN(bandwidth,roll_ref/2).
	
	//the default output is simply set to the current roll sign
	LOCAL out_s IS cur_sign.
	
	IF ABS(delaz) > red_bandwidth {
		//if we're out of the error band we command a reversal
		//we set the bank sign to the same sign as the error.
		//recall that the error is + if the tgt is to our right
		//and - if it's to the left 
		//and the same convention is used for bank angles 
		SET out_s TO SIGN(delaz).
	} 
	RETURN out_s.
}


declare function simulate_reentry {

	
	PARAMETER simsets.
	parameter simstate.
	PARAMETER tgt_rwy.
	PARAMETER end_conditions.
	PARAMETER az_err_band .
	PARAMETER roll0.
	PARAMETER pitch0.
	PARAMETER pitchroll_profiles.
	PARAMETER plot_traj IS FALSE.
	
	LOCAL tgtpos IS tgt_rwy["position"].
	LOCAL tgtalt IS tgt_rwy["elevation"] + end_conditions["altitude"].


	LOCAL hdotp IS 0.
	LOCAL hddot IS 0.
	
	LOCAL pitch_prof IS 0.
	LOCAL roll_prof IS 0.
	
	
	LOCAL poslist IS LIST().
	
	//sample initial values for proper termination conditions check
	SET simstate["altitude"] TO bodyalt(simstate["position"]).
	SET simstate["surfvel"] TO surfacevel(simstate["velocity"],simstate["position"]).

	
	//putting the termination conditions here should save an if check per step
	UNTIL (( simstate["altitude"]< tgtalt AND simstate["surfvel"]:MAG < end_conditions["surfvel"] ) OR simstate["altitude"]>140000)  {
	
		SET simstate["altitude"] TO bodyalt(simstate["position"]).
		
		SET simstate["surfvel"] TO surfacevel(simstate["velocity"],simstate["position"]).
		
		LOCAL hdot IS VDOT(simstate["position"]:NORMALIZED,simstate["surfvel"]).
		SET hddot TO (hdot - hdotp)/simsets["deltat"].
		SET hdotp TO hdot.

	
		LOCAL delaz IS az_error(simstate["latlong"],tgtpos,simstate["surfvel"]).
		
		
		
		LOCAL out IS pitchroll_profiles(LIST(roll0,pitch0),LIST(roll_prof,pitch_prof),simstate,hddot,delaz,az_err_band).
		SET roll_prof TO out[0].
		SET pitch_prof TO out[1].
		


		SET simstate["latlong"] TO shift_pos(simstate["position"],simstate["simtime"]).
		
		IF plot_traj {
			poslist:ADD( simstate["latlong"]:ALTITUDEPOSITION(simstate["altitude"]) ).
		}
		
		IF simsets["log"]= TRUE {
			
			
			SET loglex["time"] TO simstate["simtime"].
			SET loglex["alt"] TO simstate["altitude"]/1000.
			SET loglex["speed"] TO simstate["surfvel"]:MAG.
			SET loglex["hdot"] TO hdot.
			SET loglex["lat"] TO simstate["latlong"]:LAT.
			SET loglex["long"] TO simstate["latlong"]:LNG.
			SET loglex["pitch"] TO pitch_prof.
			SET loglex["roll"] TO roll_prof.
			SET loglex["az_err"] TO delaz.
			log_data(loglex).
		}
		
		SET simstate TO simsets["integrator"]:CALL(simsets["deltat"],simstate,LIST(pitch_prof,roll_prof)).

	}
	
	IF plot_traj {
		SET simstate["poslist"] TO poslist.
	}
	

	return simstate.
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
FUNCTION  flaptrim_control{
	PARAMETER flap_control.
	
	
	//initialise the flap control pid loop 
	IF NOT (DEFINED FLAPPID) {
		LOCAL Kp IS -2.5.
		LOCAL Ki IS 0.
		LOCAL Kd IS 0.8.

		GLOBAL FLAPPID IS PIDLOOP(Kp,Ki,Kd).
		SET FLAPPID:SETPOINT TO 0.
	}

	LOCAL flap_incr IS  FLAPPID:UPDATE(TIME:SECONDS,flap_control["pitch_control"][0]).
	SET flap_control["deflection"] TO  flap_control["deflection"] + flap_incr.
	
	print flap_control["pitch_control"][0] at (0,10).
	
	deflect_flaps(flap_control["parts"] , flap_control["deflection"]).
	
	
	RETURN flap_control.
}

FUNCTION activate_flaps {
	PARAMETER flap_parts.
	

	
	FOR f in flap_parts {
		LOCAL fmod IS f["flapmod"].
		IF NOT fmod:GETFIELD("Flp/Splr"). {fmod:SETFIELD("Flp/Splr",TRUE).}
		wait 0.
		fmod:SETFIELD("Flp/Splr Dflct",0). 
		IF NOT fmod:GETFIELD("Flap"). {fmod:SETFIELD("Flap",TRUE).}
		wait 0.
		LOCAL flapset IS fmod:GETFIELD("Flap Setting").
		FROM {local k is flapset.} UNTIL k>3  STEP {set k to k+1.} DO {
			fmod:DOACTION("Increase Flap Deflection", TRUE).
		}
	}
}


FUNCTION deactivate_flaps {
	PARAMETER flap_parts.
	
	deflect_flaps(flap_parts , 0).
	
	//leave the flaps enabled to let the user manipulate them manually
	//FOR f in flap_parts {
	//	LOCAL fmod IS f["flapmod"].
	//	fmod:SETFIELD("Flp/Splr dflct",0).
	//	wait 0.
	//	LOCAL flapset IS fmod:GETFIELD("Flap Setting").
	//	FROM {local k is flapset.} UNTIL k=0  STEP {set k to k-1.} DO {
	//		fmod:DOACTION("Decrease Flap Deflection", TRUE).
	//	}
	//}
}

FUNCTION deflect_flaps{
	PARAMETER flap_parts.
	PARAMETER deflection.
	
	FOR f in flap_parts {
		f["flapmod"]:SETFIELD("Flp/Splr dflct",CLAMP(deflection,f["min_defl"],f["max_defl"])).
		
	}

}.


