
FUNCTION TAEM_spdbk {
	SET arbkb:PRESSED TO FALSE.
	SEt SHIP:CONTROL:PILOTMAINTHROTTLE to 0.5.

}



//TAEM transition
FUNCTION TAEM_transition {
	PARAMETER tgt_dist.
	
	IF ((tgt_dist <= 120) AND (SHIP:VELOCITY:SURFACE:MAG <= 950)) {
		RETURN TRUE.
	}
	
	RETURN FALSE.
	
}

//if we're close enough to the HAC entry point switch automatically
FUNCTION apch_transition {
	PARAMETER hac_entry_dist.
	
	IF hac_entry_dist < 10 {
		SET arbkb:PRESSED TO TRUE.
		SET guidb:PRESSED TO FALSE.
		SET sasb:PRESSED TO FALSE.
		WAIT 0.
		SET exitb:PRESSED TO TRUE.
	}


}



//calculate sign and value of bank angle 
// the bank angle value moves on a fixed profile of velocity
FUNCTION TAEM_roll_profile {
	PARAMETER delaz.
	PARAMETER sturn IS FALSE.
	
	//magnify delaz to bank harder
	LOCAL corr_delaz IS 2*ABS(delaz).

	
	LOCAL bank_vel_profile IS LIST(
								LIST(0,40),
								LIST(300,40),
								LIST(335,35),
								LIST(500,25)
								).
	
	LOCAL maxroll IS ABS(INTPLIN(bank_vel_profile,SHIP:VELOCITY:SURFACE:MAG)).
	
	// maxroll IS 40.
	
	IF (sturn) {
		//if doing an s-turn disregard delaz and bank at close to maximum roll
		RETURN maxroll.
	} ELSE {
		//bank proportionallyto delaz but enforce max bank constraint
		RETURN CLAMP(corr_delaz,0,maxroll).
	}
	
	
	
}


//use the full angle when doing the s-turn, if tracking the HAC instead ramp it down
//when the az error is small
FUNCTION TAEM_bank_angle {
	PARAMETER delaz.
	PARAMETER sturn IS FALSE.
	PARAMETER hac_side IS "".
	
	LOCAL bank_angle IS  TAEM_roll_profile(delaz,sturn).

	IF (sturn) {
		//each guidance cycle spent in an s-turn increases the groundtrack to fly
		//the larger delaz is, the larger the increase in groundtrakc and energy dissipation
		//to avoid overshooting we ramp down the bank angle when delaz is great enough 
		//want to ramp it to zero and below so that delaz never gets too high 
		
		LOCAL bank_factor IS MIN(1, 1 - (ABS(delaz)/30 - 1)).
		
		RETURN s_turn_sign(hac_side)*bank_factor*bank_angle.
	} ELSE {
		RETURN SIGN(delaz)*bank_angle.
	}
	
}

//TAEM s-turn direction logic
//the hac side also determines the direction of turn during the HAC
//we want the s-turn to be opposite in sign so that when it reverses we turn 
//in the same directon as the eventual HAc turn and thus the HAc interception angle is as small as possible 
FUNCTION s_turn_sign {
	PARAMETER hac_side.
	
	IF hac_side="left" {
		RETURN 1.
	} ELSE IF hac_side="right"{
		RETURN -1.
	} ELSE {
		//should never be entered
		RETURN 0.
	}
}



FUNCTION TAEM_pitch_profile {
	PARAMETEr ref_pitch.
	PARAMETER ref_roll.
	PARAMETER vel.
	PARAMETER hdot_err.
	
	LOCAL out_pitch IS ref_pitch.

	//correct pitch by a term proportional to the error in hdot
	//if positive error we must pitch down
	
	LOCAL hdotgain IS 1/35.
	SET out_pitch TO out_pitch - hdot_err*hdotgain.

	//clamp to reasonable values.
	RETURN CLAMP(out_pitch,0,20).
}

//put the roll correctin in a separate function so it can be tied to the current roll instead of the roll ref value
FUNCTION TAEM_pitch_roll_cor {
	PARAMETER ref_pitch.
	PARAMETER cur_roll.
	
	//correct the pitch value by the roll angle to keep the vertical 
	//component of lift consistent
	//not too large a correction though
	LOCAL out_pitch IS ref_pitch/COS(ABS(cur_roll/2)).
	
	//clamp to reasonable values.
	RETURN CLAMP(out_pitch,0,20).
	
}


// determines if the s-turn is to be commanded or not
FUNCTION s_turn {
	PARAMETER tgt_range.
	PARAMETER tgtvel.
	PARAMETER srfvel.
	
	//disable the s-turn if we're less than 20km 
	IF (tgt_range < 20) {
		RETURN FALSE.
	}
	
	//trigger s-turn if the final vel is higher than target 
	IF (srfvel > tgtvel) {
		RETURN TRUE.
	} ELSE {
		RETURN FALSE.
	}
	
}





declare function simulate_TAEM {

	
	PARAMETER simsets.
	parameter simstate.
	PARAMETER tgt_rwy.
	PARAMETER apch_params.
	PARAMETER roll0.
	PARAMETER pitch0.
	PARAMETER hdot_ref.
	
	LOCAL initialpos IS simstate["latlong"].
	
	LOCAL pitch_prof IS 0.
	LOCAL roll_prof IS 0.
	
	//sample initial values for proper termination conditions check
	SET simstate["altitude"] TO bodyalt(simstate["position"]).
	SET simstate["surfvel"] TO surfacevel(simstate["velocity"],simstate["position"]).

	LOCAL tgtdist IS greatcircledist(tgt_rwy["hac_entry"],simstate["latlong"]).
	LOCAL tgtdistp IS 2*tgtdist.
	
	//putting the termination conditions here should save an if check per step
	//UNTIL ( greatcircledist(initialpos,simstate["latlong"]) >= greatcircledist(initialpos,tgt_rwy["hac_entry"]) )  {
	UNTIL (( (tgtdistp < tgtdist) AND (tgtdist<5) ) OR simstate["altitude"] < 5000 )  {
			
		//if target distance is less than 1km we no longer update the entry point 
		IF (tgtdist>1) {
			update_hac_entry_pt(simstate["latlong"], tgt_rwy, apch_params). 
		}
		
	
		SET simstate["altitude"] TO bodyalt(simstate["position"]).
		
		SET simstate["surfvel"] TO surfacevel(simstate["velocity"],simstate["position"]).

		LOCAL hdot IS VDOT(simstate["position"]:NORMALIZED,simstate["surfvel"]).
		
		
		LOCAL delaz IS az_error(simstate["latlong"], tgt_rwy["hac_entry"], simstate["surfvel"]).
			
		SET roll0 TO TAEM_roll_profile(delaz).
		SET pitch_prof TO TAEM_pitch_profile(pitch0,roll_prof,simstate["surfvel"]:MAG, hdot - hdot_ref).
		SET roll_prof TO SIGN(delaz)*roll0.
		

		SET simstate["latlong"] TO shift_pos(simstate["position"],simstate["simtime"]).
		
		
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

		//update distance from the current entry point 
		SET tgtdistp TO tgtdist.
		SET tgtdist TO greatcircledist(tgt_rwy["hac_entry"],simstate["latlong"]).
		
	}


	return simstate.
}


