

FUNCTION blank_simstate {
	PARAMETER ICs.

	
	RETURN 	LEXICON(
		"simtime",0,
		"position",ICS["position"],
		"velocity",ICS["velocity"],
		"surfvel",surfacevel(ICS["velocity"],ICS["position"]),
		"altitude",bodyalt(ICS["position"]),
		"latlong",vec2pos(ICS["position"]),//LATLNG(0,0),
		"aero",LEXICON()
	
	).

}


FUNCTION current_simstate {
	RETURN 	LEXICON(
		"simtime",0,
		"position",-SHIP:ORBIT:BODY:POSITION,
		"velocity",SHIP:VELOCITY:ORBIT,
		"surfvel",SHIP:VELOCITY:SURFACE,
		"altitude",SHIP:ORBIT:BODY:POSITION:MAG - BODY:RADIUS,
		"latlong",SHIP:GEOPOSITION,
		"aero",LEXICON()
	
	).


}




DEclare Function accel {
	Parameter pos.
	Parameter vel.
	Parameter attitude.
	
	 
	LOCAL surfvel IS vel - vcrs(BODY:angularvel, pos).
	LOCAL outlex IS aeroforce(pos, surfvel, attitude).
	
	LOCAL acceltot TO outlex["load"] + gravitacc(pos).
	return LIST(acceltot,outlex).

}

declare function gravitacc {
	parameter position.
	return -BODY:mu * position:normalized / position:sqrmagnitude.
}

declare function aeroforce {
	parameter position.
	parameter surfvel.
	parameter attitude.
	
	LOCAL roll IS attitude[1].
	LOCAL aoa IS attitude[0].
	
	LOCAL out IS LEXICON(
						"load",v(0,0,0),
						"lift",0,
						"drag",0
						).
	
	LOCAL altt IS position:mag-BODY:radius.
	
	LOCAL vesselfore IS SHIP:FACING:FOREVECTOR:NORMALIZED.
	LOCAL vesseltop IS SHIP:FACING:TOPVECTOR:NORMALIZED.
	LOCAL vesselright IS VCRS(vesseltop,vesselfore):NORMALIZED.
	
	LOCAL airspeedaoa IS surfvel:MAG*rodrigues(vesselfore,vesselright,aoa):NORMALIZED.
	
	LOCAL totalforce IS ADDONS:FAR:AEROFORCEAT(altt,airspeedaoa).
	
	
	
	//convert the aerodynamic force into the frame defined by the vessel orientation vectors
	//divide by the ship mass to get acceleration
	 LOCAL localforce IS V( VDOT(vesselright,totalforce) ,VDOT(vesseltop,totalforce)  , VDOT(vesselfore,totalforce) )/(ship:mass).
	 
	//build a frame of reference centered about the survace velocity and the local up direction
	LOCAL velforward IS surfvel:NORMALIZED.
	LOCAL velup IS position:NORMALIZED.
	LOCAL velright IS VCRS( velup, velforward).
	IF (velright:MAG < 0.001) {
		SET velright TO VCRS( vesseltop, velforward).
		IF (velright:MAG < 0.001) {
			SET velright TO VCRS( vesselfore, velforward):NORMALIZED.
		}
		ELSE {
			SET velright TO velright:NORMALIZED.
		}
	}
	ELSE {
		SET velright TO velright:NORMALIZED.
	}
	SET velup TO VCRS( velforward, velright):NORMALIZED.
	
	//build the pedicted vessel orientation vectors using aoa and roll information
	LOCAL pred_vesseltop IS rodrigues(velup,velforward,-roll).
	LOCAL pred_vesselright IS VCRS(pred_vesseltop,velforward):NORMALIZED.
	LOCAL pred_vesselfore IS rodrigues(velforward,pred_vesselright,-aoa).
	SET pred_vesseltop TO rodrigues(pred_vesseltop,pred_vesselright,-aoa).
	

	
	//rotate the local force vector to the new frame
	SET out["load"] TO (pred_vesselright*localforce:X + pred_vesseltop*localforce:Y + pred_vesselfore*localforce:Z ).
	//compute lift asnd drag components
	SET out["lift"] TO VXCL(velforward,out["load"]):MAG.
	SET out["drag"] TO localforce:Z .

	RETURN out.
	

}

DECLARE FUNCTION integrate {
	PARAMETER simsets.
	PARAMETER state.
	PARAMETER attitude.
	
	LOCAL position IS state["position"].
	LOCAL velocity IS state["velocity"].
	LOCAL dt IS simsets["deltat"].
	
	set state["simtime"] to state["simtime"] + dt.
	
	LOCAL out IS LIST().
	
	IF simsets["integrator"]= "rk2" {
		//RK2
		LOCAL p1 IS position.
		LOCAL v1 IS velocity.
		SET out TO accel(p1, v1, refbody, attitude).
		LOCAL a1 IS out[0].
		SET state["aero"] TO out[1].
		 
		LOCAL  p2 IS  position + 0.5 * v1 * dt.
		LOCAL  v2 IS velocity + 0.5 * a1 * dt.
		SET out TO accel(p2, v2, refbody, attitude).
		LOCAL  a2 IS out[0].

		 
		SET position TO position + (dt) * (v2  ).
		SET velocity TO velocity + (dt) * (a2 ).
	}
	ELSE IF simsets["integrator"]= "rk3" {
		//RK3
		LOCAL p1 IS position.
		LOCAL v1 IS velocity.
		SET out TO accel(p1, v1, attitude).
		LOCAL a1 IS out[0].
		SET state["aero"] TO out[1].
		 
		LOCAL  p2 IS  position + 0.5 * v1 * dt.
		LOCAL  v2 IS velocity + 0.5 * a1 * dt.
		SET out TO accel(p2, v2, attitude).
		LOCAL a2 IS out[0].
		 
		LOCAL  p3 IS position + (2*v2 - v1) * dt.
		LOCAL  v3 IS velocity + (2*a2 - a1) * dt.
		SET out TO accel(p3, v3, attitude).
		LOCAL a3 IS out[0].
		 
		 
		SET position TO position + (dt / 6) * (v1 + 4 * v2 + v3 ).
		SET velocity TO velocity + (dt / 6) * (a1 + 4 * a2 + a3).
	}
	ELSE IF simsets["integrator"]= "rk4" {
		//RK4
		LOCAL p1 IS position.
		LOCAL v1 IS velocity.
		SET out TO accel(p1, v1, attitude).
		LOCAL a1 IS out[0].
		SET state["aero"] TO out[1].
		 
		LOCAL  p2 IS  position + 0.5 * v1 * dt.
		LOCAL  v2 IS velocity + 0.5 * a1 * dt.
		SET out TO accel(p2, v2, attitude).
		LOCAL a2 IS out[0].
		 
		LOCAL  p3 IS position + 0.5 * v2 * dt.
		LOCAL  v3 IS velocity + 0.5 * a2 * dt.
		SET out TO accel(p3, v3, attitude).
		LOCAL a3 IS out[0].
		 
		LOCAL  p4 IS position + v3 * dt.
		LOCAL  v4 IS velocity + a3 * dt.
		SET out TO accel(p4, v4, attitude).
		LOCAL a4 IS out[0].
		 
		SET position TO position + (dt / 6) * (v1 + 2 * v2 + 2 * v3 + v4).
		SET velocity TO velocity + (dt / 6) * (a1 + 2 * a2 + 2 * a3 + a4).
		
	}
	
	SET state["position"] TO position.
	SET state["velocity"] TO velocity.
	
	RETURN state.

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
	
	LOCAL tgtpos IS tgtrwy["position"].
	LOCAL tgtalt IS tgtrwy["elevation"] + end_conditions["altitude"].


	LOCAL hdotp IS 0.
	LOCAL hddot IS 0.
	
	LOCAL pitch_prof IS 0.
	LOCAL roll_prof IS 0.
	
	
	LOCAL poslist IS LIST().


	UNTIL FALSE  {
	
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
		
		//do the termination checks 
		
		IF ( simstate["altitude"]< tgtalt AND simstate["surfvel"]:MAG < end_conditions["surfvel"] ) OR simstate["altitude"]>140000 {
			BREAK.
		}
		
		SET simstate TO integrate(simsets,simstate,LIST(pitch_prof,roll_prof)).
		
		
		
		
	}
	
	IF plot_traj {
		SET simstate["poslist"] TO poslist.
	}
	

	return simstate.
}



