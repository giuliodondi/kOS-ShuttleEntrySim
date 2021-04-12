FUNCTION log_data {
	PARAMETER log_lex.
	if not (defined logname) {
		GLOBAL logname is "./aerosim_log/log.txt".
		IF EXISTS(logname)=TRUE {
			DELETEPATH(logname).
		}
		
		
		LOCAL titlestr IS "".
		
		
			FOR key IN log_lex:KEYS {
				SET titlestr TO titlestr + key + "    ".
			}
		
		log titlestr to logname.
		//LOG "time    alt    vspeed    hdot    lat    long    range    range_e    az_err    pitch    roll    range_e_d    roll_corr    guid  "    TO logname.
	} ELSE { 	
		dataLog(logname,log_lex).
	}
}


//	dataLog		outputs all flight information to the log file
//				requires passing a filename parameter of type STRING
FUNCTION dataLog {
	DECLARE PARAMETER filename.
	PARAMETER log_lex.
	
	LOCAL str IS "".
	
	//append to the string the numbers in sequence separated by four spaces
		FOR val IN log_lex:VALUES {
			SET str TO str + val + "    ".
		}
	
	//LOCAL len IS log_lex:LENGTH.
	//FROM {LOCAL k IS 0.} UNTIL k >= len STEP { SET k TO k+1.} DO{
	//	SET str TO str + log_lex[k] + "    ".
	//} 
	
	LOG str TO filename.
}


FUNCTION initial_cond {
	LOCAL ICs IS LEXICON(
						"radius",6508315.84200874,
						"velocity",7883.29797272286,
						"lat", -8.8479260822828,
						"long",-142.935301182093,
						"azimuth",46.6087723368127,
						"fpa",-1.99610858388167 
	).

	LOCAL geopos IS LATLNG(ICs["lat"],ICs["long"]).
	LOCAL pos IS ICs["radius"]*(geopos:POSITION - SHIP:BODY:POSITION):NORMALIZED.
	
	LOCAL northpole IS V(0,1,0).
	LOCAL east IS -VCRS(northpole,pos:NORMALIZED).
	
	
	
	LOCAL north IS -VCRS(pos:NORMALIZED,east).
	
	LOCAL vel IS rodrigues(north,east,-ICs["fpa"]).
	
	
	SET vel TO rodrigues(vel,pos:NORMALIZED,ICs["azimuth"]):NORMALIZED*ICs["velocity"].


	RETURN LIST (pos,vel).
}


FUNCTION pitch_profile {

	PARAMETER alpha0.
	PARAMETER vel.

	//build the normalised pitch profile and
	//compute the output value given the current velocity
	
	
	//and scale it to the reference pitch value
	//which should be either the last value of the pitch profile
	//or the latest detected user-input value
	
	
	LOCAL out IS alpha0.
	LOCAL ref_flag IS FALSE.
		
	
	IF vel<2500 {
		SET out TO 10 + vel*(25 - 10)/2300.
	}
	ELSE IF vel<5300 {
		SET out TO 25.
	}
	ELSE IF vel<6700 {
		SET out TO 25 + (vel-5300)*(alpha0 - 25)/1400.
	}
	ELSE { SET ref_flag TO TRUE.}

	RETURN out.
	RETURN LIST(out,ref_flag).
}


DEclare Function accel {
	Parameter pos.
	Parameter vel.
	PArameter refbody.
	Parameter attitude.
	 
	LOCAL surfvel IS vel - vcrs(refbody:angularvel, pos).
	return gravitacc(pos, refbody) +  aeroforce(pos, surfvel, refbody, attitude)/(ship:mass).

}

declare function gravitacc {
	parameter position is ship:position - ship:orbit:body:position, refbody is ship:body.
	return -refbody:mu * position:normalized / position:sqrmagnitude.
}

declare function aeroforce {
	parameter position.
	parameter surfvel.
	parameter refbody.
	parameter attitude.
	
	LOCAL roll IS attitude[1].
	LOCAL aoa IS attitude[0].
	
	LOCAL altt IS position:mag-refbody:radius.
	
	LOCAL vesselfore IS SHIP:FACING:FOREVECTOR:NORMALIZED.
	LOCAL vesseltop IS SHIP:FACING:TOPVECTOR:NORMALIZED.
	LOCAL vesselright IS VCRS(vesseltop,vesselfore):NORMALIZED.
	
	LOCAL airspeedaoa IS surfvel:MAG*rodrigues(vesselfore,vesselright,aoa):NORMALIZED.
	
	LOCAL totalforce IS ADDONS:FAR:AEROFORCEAT(altt,airspeedaoa).
	
	
	
	//convert the aerodynamic force into the frame defined by the vessel orientation vectors
	 LOCAL localforce IS V( VDOT(vesselright,totalforce) ,VDOT(vesseltop,totalforce)  , VDOT(vesselfore,totalforce) ).
	 
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
	RETURN (pred_vesselright*localforce:X + pred_vesseltop*localforce:Y + pred_vesselfore*localforce:Z ).
	

}




declare function predictlandcoord {

	parameter position.
	parameter velocity.
	PARAMETER targetheight.
	parameter dt is 10.
	PARAMETER roll Is 0.
	
	
	local newgeocoord is convertPosvecToGeocoord(position).
	//does a stepwise simulation until the craft hits the targetheight
	//takes about half a second to compute
	//the only method here that takes drag into account
	local simtime is 0.
	LOCAL refbody IS ship:body.
	LOCAL altt IS position:mag - (refbody:radius + max(0,newgeocoord:terrainheight + targetheight)).
	until altt<targetheight {
	
		
		
		LOCAL surfvel IS velocity - vcrs(refbody:angularvel, position).
		
		LOCAL pitch_prof IS pitch_profile(33,surfvel:MAG).
		
		SET loglex["time"] TO simtime.
		SET loglex["alt"] TO altt/1000.
		SET loglex["speed"] TO surfvel:MAG.
		SET loglex["hdot"] TO VDOT(position:NORMALIZED,surfvel).
		SET loglex["lat"] TO newgeocoord:LAT.
		SET loglex["long"] TO newgeocoord:LNG.
		SET loglex["pitch"] TO pitch_prof.
		SET loglex["roll"] TO roll.
		log_data(loglex).
		
		LOCAL attitude IS LIST(pitch_prof,roll).
		
		// //RK4
		// LOCAL p1 IS position.
		// LOCAL v1 IS velocity.
		// LOCAL a1 IS accel(p1, v1, refbody, attitude).
		 
		// LOCAL  p2 IS  position + 0.5 * v1 * dt.
		// LOCAL  v2 IS velocity + 0.5 * a1 * dt.
		// LOCAL  a2 IS accel(p2, v2, refbody, attitude).
		 
		// LOCAL  p3 IS position + 0.5 * v2 * dt.
		// LOCAL  v3 IS velocity + 0.5 * a2 * dt.
		// LOCAL  a3 IS accel(p3, v3, refbody, attitude).
		 
		// LOCAL  p4 IS position + v3 * dt.
		// LOCAL  v4 IS velocity + a3 * dt.
		// LOCAL  a4 IS accel(p4, v4, refbody, attitude).
		 
		// SET position TO position + (dt / 6) * (v1 + 2 * v2 + 2 * v3 + v4).
		// SET velocity TO velocity + (dt / 6) * (a1 + 2 * a2 + 2 * a3 + a4).
		
		  ///RK3
		LOCAL p1 IS position.
		LOCAL v1 IS velocity.
		LOCAL a1 IS accel(p1, v1, refbody, attitude).
		 
		LOCAL  p2 IS  position + 0.5 * v1 * dt.
		LOCAL  v2 IS velocity + 0.5 * a1 * dt.
		LOCAL  a2 IS accel(p2, v2, refbody, attitude).
		 
		LOCAL  p3 IS position + (2*v2 - v1) * dt.
		LOCAL  v3 IS velocity + (2*a2 - a1) * dt.
		LOCAL  a3 IS accel(p3, v3, refbody, attitude).
		 
		 
		SET position TO position + (dt / 6) * (v1 + 4 * v2 + v3 ).
		SET velocity TO velocity + (dt / 6) * (a1 + 4 * a2 + a3).
		
		// //RK2
		// LOCAL p1 IS position.
		// LOCAL v1 IS velocity.
		// LOCAL a1 IS accel(p1, v1, refbody, attitude).
		 
		// LOCAL  p2 IS  position + 0.5 * v1 * dt.
		// LOCAL  v2 IS velocity + 0.5 * a1 * dt.
		// LOCAL  a2 IS accel(p2, v2, refbody, attitude).

		 
		// SET position TO position + (dt) * (v2  ).
		// SET velocity TO velocity + (dt) * (a2 ).
		
		
		
		//for the geocoordinates, take the rotation of the planet into account
		set newgeocoord to convertPosvecToGeocoord(r(0, refbody:angularvel:mag * simtime * constant:RadToDeg, 0) * position).
		SET altt TO position:mag - (refbody:radius + max(0,newgeocoord:terrainheight + targetheight)).
		IF altt>140000 {BREAK.}
		
		set simtime to simtime + dt.
	}

	return newgeocoord.
}




FUNCTION aero_simulate {
clearscreen.
if  (defined logname) {UNSET logname.}
RUNPATH("0:/Libraries/maths_library").	
RUNPATH("0:/Libraries/navigation_library").	
	
GLOBAL loglex IS LEXICON(
						"time",0,
						"alt",0,
						"speed",0,
						"hdot",0,
						"lat",0,
						"long",0,
						"pitch",0,
						"roll",0
).
log_data(loglex).

	LOCAL ICS IS initial_cond().


	LOCAL simtime is TIME:SECONDS.
	predictlandcoord(
					ICS[0],
					ICS[1],
					15000,
					30,
					33
	).
	
	SET simtime TO TIME:SECONDS - simtime.
	PRINT simtime AT (5,5).

}

aero_simulate().