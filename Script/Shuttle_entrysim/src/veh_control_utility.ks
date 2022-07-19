


//control functions






//simulate Control Stick Steering : use pilot input to update steering angles 
FUNCTION update_steering_attitude {
	PARAMETER rollsteer.
	PARAMETER pitchsteer.
	PARAMETER rollguid.
	PARAMETER pitchguid.
	
	IF is_auto_steering() {
		SET rollsteer TO rollsteer + CLAMP(rollguid - rollsteer,-1.5,1.5).
		SET pitchsteer TO pitchsteer + CLAMP(pitchguid - pitchsteer,-1.5,1.5).
	} ELSE {
		LOCAL rollgain IS 1.2.
		LOCAL pitchgain IS 0.5.
		
		LOCAL deltaroll IS rollgain*(SHIP:CONTROL:PILOTROLL - SHIP:CONTROL:PILOTROLLTRIM).
		LOCAL deltapitch IS pitchgain*(SHIP:CONTROL:PILOTPITCH - SHIP:CONTROL:PILOTPITCHTRIM).
		
		IF ABS(deltaroll)>0.1 {
			SET rollsteer TO rollsteer + deltaroll.
		}
		
		IF ABS(deltapitch)>0.1 {
			SET pitchsteer TO pitchsteer + deltapitch.
		}
	}
	
	RETURN LIST(rollsteer,pitchsteer).
}

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
	LOCAL ship_roll IS get_roll_prograde().
		
		
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



//	DOES NOT WORK - KEEP FOR LEGACY
//automatic path tracking, using the lateral and vertical deltas
//pipper deviation must correspond to corrections to the value of angle of attack and bank angle
//clamp corrections so that we never set extreme bank angle or aoa
//adjust pitch and roll input increments based on corrections

FUNCTION autoland {
	PARAMETER deltas.
	PARAMETER mode.		//probably need to adjust the gains based on mode
	
	//get current aoa and roll
	LOCAL cur_rol IS get_roll_lvlh().
	LOCAL cur_aoa IS get_pitch_lvlh().
	
	//transform deltas based on current roll angle
	LOCAL sinr IS SIN(cur_rol).
	LOCAL cosr IS COS(cur_rol).
	LOCAL deltas_rot IS LIST(
		CLAMP(deltas[0]*cosr + deltas[1]*sinr, -100,100),
		CLAMP(deltas[1]*cosr - deltas[0]*sinr,-100,100)
	).
	
	PRINT "( " + round(deltas[0],3) + " , " + round(deltas[1],3) + " )" at (0,20).
	PRINT "( " + round(deltas_rot[0],3) + " , " + round(deltas_rot[1],3) + " )" at (0,21).

	
	
	//calculate correction limits, distinct values for positive/negative aoa
	LOCAL roll_corr_lim IS MAX(0,45 - ABS(cur_rol)).
	LOCAL aoa_corr_lim_pos IS MAX(0,25 - ABS(cur_aoa)).
	LOCAL aoa_corr_lim_neg IS -MAX(0,15 - ABs(cur_aoa)).
	
	LOCAL rol_corr IS CLAMP(deltas_rot[0]*0.5, -roll_corr_lim, roll_corr_lim).
	
	LOCAL aoa_corr IS CLAMP(deltas_rot[1]*0.3, aoa_corr_lim_neg, aoa_corr_lim_pos).
	

	PRINT "( " + round(rol_corr,3) + " , " + round(aoa_corr,3) + " )" at (0,22).

	//initialise the flap control pid loop 
	IF NOT (DEFINED AUTOLPITCHPID) {
		LOCAL Kp IS -0.017.
		LOCAL Ki IS 0.
		LOCAL Kd IS -0.012.
	
		GLOBAL AUTOLPITCHPID IS PIDLOOP(Kp,Ki,Kd).
		SET AUTOLPITCHPID:SETPOINT TO 0.

	}
	
	//initialise the flap control pid loop 
	IF NOT (DEFINED AUTOLROLLPID) {
		LOCAL Kp IS -0.015.
		LOCAL Ki IS 0.
		LOCAL Kd IS 0.005.
	
		GLOBAL AUTOLROLLPID IS PIDLOOP(Kp,Ki,Kd).
		SET AUTOLROLLPID:SETPOINT TO 0.
	}
	
	LOCAL pchctrlcorr IS AUTOLPITCHPID:UPDATE(TIME:SECONDS,aoa_corr).
	LOCAL rolctrlcorr IS AUTOLROLLPID:UPDATE(TIME:SECONDS,rol_corr).
	
	PRINT "( " + round(rolctrlcorr,3) + " , " + round(pchctrlcorr,3) + " )" at (0,23).
	
	SET SHIP:CONTROL:PITCH TO CLAMP( SHIP:CONTROL:PITCH + pchctrlcorr, -0.4, 0.4).
	//SET SHIP:CONTROL:ROLL TO CLAMP( SHIP:CONTROL:ROLL + rolctrlcorr, -0.4, 0.4).

}



//automatic speedbrake control
FUNCTION speed_control {
	PARAMETER auto_flag.
	PARAMETER previous_val.
	PARAMETER mode.
	
	LOCAL newval IS previous_val.
	
	//automatic speedbrake control
	If auto_flag {

		//above 3000 m/s the autobrake is disabled
		IF SHIP:VELOCITy:SURFACE:MAG>2500 { RETURN previous_val.}


		LOCAL tgtspeed IS 0.
		LOCAL delta_spd IS 0.
		
		IF (mode=1 OR mode=2) {
			LOCAL tgt_rng IS greatcircledist(tgtrwy["position"], SHIP:GEOPOSITION).
			SET tgtspeed TO MAX(250,51.48*tgt_rng^(0.6)).
			LOCAL airspd IS SHIP:VELOCITy:SURFACE:MAG.
			SET delta_spd TO airspd - tgtspeed.
		}
		ELSE {
			IF mode=3 {
				SET delta_spd TO airspd - 220.
			}
			ELSE IF mode=4 {
				SET delta_spd TO airspd - 180.
			}
			ELSE IF mode=5 {
				SET delta_spd TO airspd - 145.
			}
			ELSE IF mode>=6 {
				SET delta_spd TO airspd - 130.		
			
				IF SHIP:STATUS = "LANDED" {
					SET delta_spd TO airspd.
					
					IF airspd < 65 {
						BRAKES ON.
					}
				}
			}
			
		}

		//initialise the air brake control pid loop 		
		IF NOT (DEFINED BRAKESPID) {
			LOCAL Kp IS -0.005.
			LOCAL Ki IS 0.
			LOCAL Kd IS -0.02.

			GLOBAL BRAKESPID IS PIDLOOP(Kp,Ki,Kd).
			SET BRAKESPID:SETPOINT TO 0.
		}
		
		LOCAL delta_spdbk IS CLAMP(BRAKESPID:UPDATE(TIME:SECONDS,delta_spd), -2, 2).
		
		SET newval TO newval + delta_spdbk.
		
	}
	ELSE {
		SET newval TO THROTTLE.

	}
	
	


	RETURN CLAMP(newval,0,1).
	
}





//automatic flap control
FUNCTION  flaptrim_control{
	PARAMETER auto_flag.
	PARAMETER flap_control.

	
	
	If auto_flag {
	
		//initialise the flap control pid loop, pid gains rated for deflection as percentage of maximum
		IF NOT (DEFINED FLAPPID) {
			LOCAL Kp IS -0.0375.	//-1.05.
			LOCAL Ki IS 0.
			LOCAL Kd IS 0.0214.	//0.6.

			GLOBAL FLAPPID IS PIDLOOP(Kp,Ki,Kd).
			SET FLAPPID:SETPOINT TO 0.
		}

		
		LOCAL controlavg IS flap_control["pitch_control"]:average().
		LOCAL flap_incr IS  FLAPPID:UPDATE(TIME:SECONDS,controlavg).
		SET flap_control["deflection"] TO CLAMP(
			flap_control["deflection"] + flap_incr,
			-1,
			1
		).

	} ELSE {
		SET flap_control["deflection"] TO  SHIP:CONTROL:PILOTPITCHTRIM.
	}
	
	deflect_flaps(flap_control["parts"] , -flap_control["deflection"]).
	
	RETURN flap_control.
}

FUNCTION null_flap_deflection {

	SET flap_control["deflection"] TO  0.
	deflect_flaps(flap_control["parts"] , flap_control["deflection"]).

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


FUNCTION deflect_flaps{
	PARAMETER flap_parts.
	PARAMETER deflection.
	
	FOR f in flap_parts {
		LOCAL defl IS deflection*ABS(f["max_defl"]).
		IF (deflection<0) {
			SET defl TO deflection*ABS(f["min_defl"]).
		}
	
		f["flapmod"]:SETFIELD("Flp/Splr dflct",CLAMP(defl,f["min_defl"],f["max_defl"])).
		
	}

}.


//activates the ferram aoa feedback
FUNCTION flaps_aoa_feedback {
	PARAMETER flap_parts.
	
	FOR f in flap_parts {
		LOCAL fmod IS f["flapmod"].
		IF NOT fmod:GETFIELD("std. ctrl"). {fmod:SETFIELD("std. ctrl",TRUE).}
		wait 0.
		fmod:SETFIELD("aoa %",40).  	
	}

}
