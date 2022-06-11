//misc functions 


//draw a vector centered on geolocation for target redesignation
//scales with distance from ship for visibility
FUNCTION pos_arrow {
	PARAMETER pos.
	PARAMETEr stringlabel.
	
	LOCAL start IS pos:POSITION.
	LOCAL end IS (pos:POSITION - SHIP:ORBIT:BODY:POSITION).
	
	VECDRAW(
      start,//{return start.},
      end:NORMALIZED*5000,//{return end.},
      RGB(1,0,0),
      stringlabel,
      1,
      TRUE,
      0.5
    ).

}

//draw a vector centered on ship with label
FUNCTION arrow {
	PARAMETER v.
	PARAMETER label.
	
	VECDRAW(
      V(0,0,0),
      v,
      RGB(1,0,0),
      label,
      60,
      TRUE,
      0.01
    ).

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
			SET delta_spd TO SHIP:VELOCITy:SURFACE:MAG - tgtspeed.
		}
		ELSE {
			IF mode=3 {SET tgtspeed TO 220.}
			ELSE IF mode=4 {SET tgtspeed TO 180.}
			ELSE IF mode=5 {SET tgtspeed TO 150.}
			ELSE IF mode=6 {
				SET tgtspeed TO 150.
				IF SHIP:STATUS = "LANDED" {SET tgtspeed TO 0.}
			}
			SET delta_spd TO SHIP:AIRSPEED - tgtspeed.
		}

		//initialise the air brake control pid loop 		
		IF NOT (DEFINED BRAKESPID) {
			LOCAL Kp IS -0.005.
			LOCAL Ki IS 0.
			LOCAL Kd IS -0.02.

			GLOBAL BRAKESPID IS PIDLOOP(Kp,Ki,Kd).
			SET BRAKESPID:SETPOINT TO 0.
		}
		
		LOCAL delta_spdbk IS BRAKESPID:UPDATE(TIME:SECONDS,delta_spd).
		
		SET newval TO newval + delta_spdbk.
		
	}
	ELSE {
		SET newval TO THROTTLE.

	}
	
	


	RETURN CLAMP(newval,0,1).
	
}










//runway and hac functions 



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



//refresh the runway lexicon upon changing runway.
FUNCTION refresh_runway_lex {
	PARAMETER tgtsite.

	RETURN LEXICON(
							"position",tgtsite["position"],
							"elevation",tgtsite["elevation"],
							"heading",tgtsite["heading"],
							"td_pt",LATLNG(0,0),
							"glideslope",0,
							"hac_side","left",	//placeholder choice
							"aiming_pt",LATLNG(0,0),
							"hac",LATLNG(0,0),
							"hac_entry",LATLNG(0,0),
							"hac_exit",LATLNG(0,0),
							"hac_angle",0,
							"upvec",V(0,0,0)

	).
}

//simple wrapper to convert an altitude in metres to altitude above the landing site
FUNCTION runway_alt {
	PARAMETER altt.
	RETURN altt - tgtrwy["elevation"].
}


//called upon changing either the runway or the hac side
//defined the hac centre, the displaced final point (hac exit) and the reference up vector
//also sets the runway elevation
FUNCTION define_hac {
	PARAMETER cur_pos.
	PARAMETER rwy.
	PARAMETER params.
	
	LOCAL bng IS fixangle(rwy["heading"] - 180).
	
	//find the final approach aiming point, common for left and right
	SET rwy["aiming_pt"] TO  new_position(rwy["td_pt"],params["aiming_pt_dist"],bng).
	
	//find the hac exit point, common for left and right
	SET rwy["hac_exit"] TO new_position(rwy["aiming_pt"],params["final_dist"],bng).
	LOCAL hac_angle IS ARCTAN2(params["hac_radius"],params["final_dist"]).
	LOCAL hac_dist IS params["final_dist"]/COS(hac_angle).
	
	//find the hac centre
	IF rwy["hac_side"]="left" {
		SET bng TO fixangle(bng + hac_angle).
	} ELSE IF rwy["hac_side"]="right"  {
		SET bng TO fixangle(bng - hac_angle).
	}
	SET rwy["hac"] TO new_position(rwy["aiming_pt"],hac_dist,bng).
	
	//define the reference up vector, pointing up for a right hac and down for a left one
	SET rwy["upvec"] TO (pos2vec(rwy["hac"])):NORMALIZED.
	IF rwy["hac_side"]="right" { SET rwy["upvec"] TO -rwy["upvec"].}
	
	//initialise the hac entry point
	
	update_hac_entry_pt(cur_pos,rwy,params).
	
	
	//initialise the hac angle 
	
	LOCAL entryvec IS (rwy["hac_entry"]:POSITION - rwy["hac"]:POSITION):NORMALIZED.
	LOCAL exitvec IS (rwy["hac_exit"]:POSITION - rwy["hac"]:POSITION):NORMALIZED.
	SET rwy["hac_angle"] TO signed_angle(exitvec,entryvec,rwy["upvec"],1).
	
	//clearvecdraws().
	//pos_arrow(rwy["position"],"runwaypos").
	//pos_arrow(rwy["td_pt"],"td_pt").
	//pos_arrow(rwy["aiming_pt"],"aiming_pt").
	//pos_arrow(rwy["hac"],"hac").
	//pos_arrow(rwy["hac_exit"],"hac_exit").
	//pos_arrow(rwy["hac_entry"],"hac_entry").

}



//moved closest_site function to navigation library so it could 
//be used by ops1 abort functions



//update the entry point to the HAC
FUNCTION update_hac_entry_pt {
	PARAMETER cur_pos.
	PARAMETER rwy.
	PARAMETER params.
	
	//now find the hac entry point given the hac position and the ship position relative to it
	//a left hac always entails the entry point is to the right of the ship bearing to the hac centre 
	//and for a right hac the reverse is true 
	
	
	//we need to make the entry point a geoposition,not a vector
	//find the bearing from the hac centre to the ship,
	//add or subtract 	the beta angle accordingly
	//then get the geoposition from the hac given that bearing and the hac radius
	
	LOCAL d IS greatcircledist(rwy["hac"],cur_pos).
	LOCAL alpha IS ARCSIN(LIMITARG(params["hac_radius"]/d)).
	LOCAL beta IS 90 - alpha.
	
	//same calculations as the hac definition routine 
	LOCAL ship_bng IS bearingg(cur_pos,rwy["hac"]).
	LOCAL hac_entry_sign IS 1.
	IF rwy["hac_side"]="left" {SET hac_entry_sign TO -1.}
	LOCAL entry_bng IS fixangle(ship_bng + hac_entry_sign*beta).
	SET rwy["hac_entry"] TO  new_position(rwy["hac"],params["hac_radius"],entry_bng).
	
	//clearvecdraws().
	//pos_arrow(rwy["hac_exit"],"hac_exit").
	//pos_arrow(rwy["hac"],"hac").

}

//update the glideslope based in current altitude and distance to travel
FUNCTION get_glideslope {
	PARAMETER altt.
	PARAMETER dist.
	
	RETURN ARCTAN2(altt,(1000*dist)). 

}


//angle between an input entry vector and the HAC exit vector around the HAC centre
//FUNCTION update_hac_angle {
//	PARAMETER rwy.
//	PARAMETER entryvec.
//		
//	LOCAL exitvec IS (rwy["hac_exit"]:POSITION - rwy["hac"]:POSITION):NORMALIZED.
//	SET exitvec TO VXCL(rwy["upvec"],exitvec).
//	SET entryvec TO VXCL(rwy["upvec"],entryvec).
//	RETURN signed_angle(exitvec,entryvec,rwy["upvec"],1).
//	
//}



//new strategy to ensure the hac angle is a continuous variable
//find the hac vector corresponding to the stored hac angle
//calculate the signed angle bw provided hac entry vector and that one
//add the result to the stored hac angle
FUNCTION update_hac_angle {
	PARAMETER rwy.
	PARAMETER entryvec.
		
	LOCAL exitvec IS (rwy["hac_exit"]:POSITION - rwy["hac"]:POSITION):NORMALIZED.
	LOCAL hac_rot_sign IS 1.
	IF rwy["hac_side"]="right" {SET hac_rot_sign TO -1.}
	LOCAL old_entryvec IS rodrigues(exitvec,rwy["upvec"],hac_rot_sign*rwy["hac_angle"]).
	LOCAL delta_hac_angle IS signed_angle(old_entryvec,entryvec,rwy["upvec"],-1).
	
	SET rwy["hac_angle"] TO rwy["hac_angle"] + delta_hac_angle. 
	
	//LOCAL hac_gndtrk IS get_hac_groundtrack(hac_angle, apch_params).
	
	//calculate profile altitude
	//if we're off by hal a turn's worth of altitude assume that the angle is off by 360° and add another turn around the HAC
	//LOCAL profile_alt IS ( apch_params["final_dist"] + hac_gndtrk)*apch_params["glideslope"]["outer"].
	//SET profile_alt TO rwy["elevation"] +  profile_alt*1000.
	//LOCAL alt_tol IS get_hac_groundtrack(180,apch_params)*apch_params["glideslope"]["outer"]*1000.
	//IF ABS(profile_alt - simstate["altitude"])
	
	//RETURN hac_angle.
	
}


//for now it's a wrapper, but in the future we might want to do something fancy like a conical HAC
FUNCTION get_hac_radius {
	PARAMETER hac_angle.
	PARAMETER params.
	
	RETURN params["hac_radius"].	// + 0.0000283464*hac_angle^2.
}


//for now it's a wrapper, but in the future we might want to do something fancy like a conical HAC
FUNCTION get_hac_groundtrack {
	PARAMETER hac_angle.
	PARAMETER params.
	
	RETURN params["hac_radius"]*hac_angle*CONSTANT:PI/180.
	
	//RETURN (params["hac_radius"] + 0.0000094488*hac_angle^2)*hac_angle/57.
}



//given HAC position calculate entry altitude, target for TAEM guidance
function get_hac_profile_alt {
	PARAMETER rwy.
	PARAMETER apch_params.

	LOCAL entryvec IS (rwy["hac_entry"]:POSITION - rwy["hac"]:POSITION):NORMALIZED.
	update_hac_angle(rwy,entryvec).
	
	LOCAL hac_gndtrk IS get_hac_groundtrack(rwy["hac_angle"], apch_params).
	
	LOCAL profile_alt IS ( apch_params["final_dist"] + hac_gndtrk)*apch_params["glideslope"]["outer"].
	
	print "hac_angle : " + rwy["hac_angle"] at (0,15).
	print "hac_gndtrk : " + hac_gndtrk at (0,16).
	print "profile_alt : " + profile_alt at (0,17).
	
	RETURN rwy["elevation"] +  profile_alt*1000.
}



//give nthe current mode, returns the ground-track distance between the predicted point and 
//the appropriate target point 
FUNCTION mode_dist {
	PARAMETER simstate.
	PARAMETER rwy.
	PARAMETER params.

	IF mode=3 {
		//distance to hac entry point 
		RETURN greatcircledist(rwy["hac_entry"],simstate["latlong"]).
	}
	ELSE IF mode=4 {
		//ground-track distance around the hac
		//find the theta angle
		LOCAL shipvec IS (simstate["latlong"]:POSITION - rwy["hac"]:POSITION):NORMALIZED.
		update_hac_angle(rwy,shipvec).
		print "hac angle:  " + rwy["hac_angle"] at (1,1).
		
		
		//find the groundtrack around the hac
		RETURN get_hac_groundtrack(rwy["hac_angle"],params).
		
	}
	ELSE IF mode=5 OR mode=6{
		RETURN greatcircledist(rwy["td_pt"],simstate["latlong"]).
	}



}




			//guidance functions 
			










//continuously update the hac entrance point based on the ship tangent vector 
//define a guidance point on the tangent to the hac corresponding to the entry point
//and moved a fixed distance ahead 
//calculate the azimuth deviation between the predicted heading and that point
//compare the predicted altitude with the profile and get the deviation from the line
//bw the current position and the hac entry point

FUNCTION mode3 {
	PARAMETER simstate.
	PARAMETER rwy.
	PARAMETER params.
	
	//Calculate distance from the current entry point 
	//if it's less than 1km we no longer update the entry point 
	LOCAL ship_hac_dist IS greatcircledist(rwy["hac_entry"],SHIP:GEOPOSITION).
	IF (ship_hac_dist>1) { update_hac_entry_pt(SHIP:GEOPOSITION,rwy,params). }

	
	LOCAL entryvec IS (rwy["hac_entry"]:POSITION - rwy["hac"]:POSITION):NORMALIZED.

	//once we have the entry point find the theta angle and hac radius
	update_hac_angle(rwy,entryvec).
	print "hac angle:  " + rwy["hac_angle"] at (1,1).
	
	LOCAL hac_radius IS get_hac_radius(rwy["hac_angle"], params).
	
	
	//build the vertical profile 
	//find the 18° glideslope altitude at runway intercept
	LOCAL final_alt IS params["final_dist"]*params["glideslope"]["outer"].
	
	//find the groundtrack around the hac
	LOCAL hac_gndtrk IS get_hac_groundtrack(rwy["hac_angle"], params).
	
	//find the distance to the entry point

	LOCAL ship_hac_dist_pred IS greatcircledist(rwy["hac_entry"],simstate["latlong"]).
	
	// buld the vertical profile
	//recalculate the glideslope to final checkpoint based on currnt altitude and distance to fly

	SET rwy["glideslope"] TO (SHIP:ALTITUDE - (rwy["elevation"] + 1000*final_alt))/(1000*(ship_hac_dist + hac_gndtrk) ). 
	

	LOCAL profile_alt IS  final_alt + (hac_gndtrk + ship_hac_dist_pred)*rwy["glideslope"].
	SET profile_alt TO rwy["elevation"] +  profile_alt*1000.
	
	print "profile alt:  " +  profile_alt at (1,2).	
	
	
	//build the target point as described
	//first get the HAC position corresponding to the predicted point
	
	LOCAL hac_tangentaz IS bearingg(rwy["hac_entry"],rwy["hac"]).
	
	print "horiz err:  " + (greatcircledist(rwy["hac"],SHIP:GEOPOSITION) - hac_radius)*1000 AT (1,3).

	//move the current position on the HAC of the ship HAc radius
	//along the tangent direction by an arbtrary distance 
	IF rwy["hac_side"]="left" { 
		SET hac_tangentaz TO fixangle(hac_tangentaz - 90).
	}
	ELSE IF rwy["hac_side"]="right" { 
		SET hac_tangentaz TO fixangle(hac_tangentaz + 90).
	}
	LOCAL x IS 0.5.
	LOCAL guid_pt IS new_position(rwy["hac_entry"],x,hac_tangentaz). 
	
	//find now the azimuth error 
	//negative deviation if the vessel azimuth is greater i.e. to the right
	//of the hac entry relative bearing
	LOCAL hac_targetaz IS bearingg(guid_pt,simstate["latlong"]).
	LOCAL ship_az IS compass_for(simstate["surfvel"],simstate["latlong"]).
	
	LOCAL hac_az_error IS unfixangle( hac_targetaz - ship_az ).

	
	
	//clearvecdraws().
	//pos_arrow(simstate["latlong"]).
	//pos_arrow(rwy["hac_entry"]).

	RETURN LIST(hac_az_error, (profile_alt - simstate["altitude"]) ).
	
}



//turn around the HAC
//take the point on the hac radius corresponding to the predicted point and on the circle
//define a guidance point on the tangent to the hac on that point a fixed distance ahead 
//calculate the azimuth deviation between the predicted heading and that point

FUNCTION mode4 {
	PARAMETER simstate.
	PARAMETER rwy.
	PARAMETER params.
	
	
	//find the vertical profile first
	
	//find the theta angle
	LOCAL shipvec IS (simstate["latlong"]:POSITION - rwy["hac"]:POSITION):NORMALIZED.
	update_hac_angle(rwy,shipvec).
	print "hac angle:  " + rwy["hac_angle"] at (1,1).
	
	LOCAL hac_radius IS get_hac_radius(rwy["hac_angle"], params).
	
	//get the vertical profile value at the predicted point 
	LOCAL final_alt IS params["final_dist"]*params["glideslope"]["outer"].
	
	//find the groundtrack around the hac
	LOCAL hac_gndtrk IS get_hac_groundtrack(rwy["hac_angle"], params).
	
	

	// buld the vertical profile
	//use the last calculated runway glideslope

	LOCAL profile_alt IS  final_alt + (hac_gndtrk)*rwy["glideslope"].
	SET profile_alt TO rwy["elevation"] +  profile_alt*1000.

	print "profile alt:  " +  profile_alt at (1,2).	
	

	//build the target point as described
	//first get the HAC position corresponding to the predicted point
	LOCAL hac_tangentaz IS bearingg(simstate["latlong"],rwy["hac"]).
	LOCAL hac_tangentpos IS new_position(rwy["hac"],hac_radius,hac_tangentaz). 
	
	print "horiz err:  " + (greatcircledist(rwy["hac"],SHIP:GEOPOSITION) - hac_radius)*1000 AT (1,3).

	//move the current position on the HAC of the ship HAc radius
	//along the tangent direction by an arbtrary distance 
	IF rwy["hac_side"]="left" { 
		SET hac_tangentaz TO fixangle(hac_tangentaz - 90).
	}
	ELSE IF rwy["hac_side"]="right" { 
		SET hac_tangentaz TO fixangle(hac_tangentaz + 90).
	}
	LOCAL x IS 0.5.
	LOCAL guid_pt IS new_position(hac_tangentpos,x,hac_tangentaz). 
	
	//find now the azimuth error 
	//negative deviation if the vessel azimuth is greater i.e. to the right
	//of the hac entry relative bearing
	LOCAL hac_targetaz IS bearingg(guid_pt,simstate["latlong"]).
	LOCAL ship_az IS compass_for(simstate["surfvel"],simstate["latlong"]).
	
	LOCAL hac_az_error IS unfixangle( hac_targetaz - ship_az ).



	//clearvecdraws().
	//pos_arrow(simstate["latlong"]).
	//pos_arrow(guid_pt).
	//pos_arrow(rwy["hac_exit"]).

	RETURN LIST(hac_az_error, (profile_alt - simstate["altitude"]) ).
	

}




//measure deviation from the predicted point t othe runway centreline
//the target point is on centreline ahead of the ship's abeam position by a fixed distance
//the glideslope value is controlled outside this function
FUNCTION mode5 {
	PARAMETER simstate.
	PARAMETER rwy.
	PARAMETER params.
	
	//predicted point distance to touchdown.
	LOCAL dist IS greatcircledist(rwy["td_pt"],simstate["latlong"]).
	
	//abeam point on centeline
	LOCAL rwy_bearing IS bearingg(rwy["td_pt"],simstate["latlong"]).	
	LOCAL rwy_az_error IS unfixangle( rwy_bearing - rwy["heading"] ).
	LOCAL abeam_dist IS dist*COS(rwy_az_error).
	
	//build the guidance point
	LOCAL runway_bng IS FIXANGLE(rwy["heading"] - 180).
	
	LOCAL x IS 0.5.
	LOCAL guid_pt IS new_position(rwy["td_pt"],abeam_dist - x,runway_bng). 
	
	//find the azimuth error between the predicted heading and the bearing to the guidance point
	//negative deviation if the vessel azimuth is greater i.e. to the right
	//of the hac entry relative bearing
	LOCAL hac_targetaz IS bearingg(guid_pt,simstate["latlong"]).
	LOCAL ship_az IS compass_for(simstate["surfvel"],simstate["latlong"]).
	LOCAL hac_az_error IS unfixangle( hac_targetaz - ship_az ).
	
	////first calculate the angular deviation given the current distance
	////the horizontal deviation is calculated relative to the touchdown point 
	//LOCAL guid_pt IS new_position(hac_tangentpos,x,hac_tangentaz). 
	//LOCAL rwy_bearing IS bearingg(rwy["td_pt"],simstate["latlong"]).	
	//LOCAL rwy_az_error IS unfixangle( rwy_bearing - rwy["heading"] ).
	
	
	//build the vertical profile
	SET dist TO greatcircledist(rwy["aiming_pt"] ,simstate["latlong"]).
	
	LOCAL profile_alt IS rwy["elevation"] + dist*rwy["glideslope"]*1000.
	print "profile alt:  " +  profile_alt at (1,2).	

	RETURN LIST(hac_az_error, (profile_alt - simstate["altitude"]) ).
}

//identical to mode5 
//except the aiming point is now the touchdown point on the runway 
//and the vertical profile is now a 3° glideslope 
//plus the exponential function modelling the flare profile
FUNCTION mode6 {
	PARAMETER simstate.
	PARAMETER rwy.
	PARAMETER params.
	
	//predicted point distance to touchdown.
	LOCAL dist IS greatcircledist(rwy["td_pt"],simstate["latlong"]).
	
	//abeam point on centeline
	LOCAL rwy_bearing IS bearingg(rwy["td_pt"],simstate["latlong"]).	
	LOCAL rwy_az_error IS unfixangle( rwy_bearing - rwy["heading"] ).
	LOCAL abeam_dist IS dist*COS(rwy_az_error).
	
	//build the guidance point
	LOCAL runway_bng IS FIXANGLE(rwy["heading"] - 180).
	
	LOCAL x IS 0.5.
	LOCAL guid_pt IS new_position(rwy["td_pt"],abeam_dist - x,runway_bng). 
	
	//find the azimuth error between the predicted heading and the bearing to the guidance point
	//negative deviation if the vessel azimuth is greater i.e. to the right
	//of the hac entry relative bearing
	LOCAL hac_targetaz IS bearingg(guid_pt,simstate["latlong"]).
	LOCAL ship_az IS compass_for(simstate["surfvel"],simstate["latlong"]).
	LOCAL hac_az_error IS unfixangle( hac_targetaz - ship_az ).
	
	
	////first calculate the angular deviation given the current distance
	////the horizontal deviation is calculated relative to the touchdown point 
	//LOCAL rwy_bearing IS bearingg(rwy["td_pt"],simstate["latlong"]).	
	//LOCAL rwy_az_error IS unfixangle( rwy_bearing - rwy["heading"] ).
	
	//build the vertical profile

	//measure the predicted altitude above the site elevation
	LOCAL altt IS simstate["altitude"] - rwy["elevation"].
	IF altt > params["flare_alt"] {
		SET dist TO greatcircledist(rwy["aiming_pt"] ,simstate["latlong"]).
	}
	
	LOCAL profile_alt IS rwy["elevation"].
	
	
	IF altt > params["flare_alt"] {
		//use the outer glideslope 
		SET profile_alt TO profile_alt + dist*params["glideslope"]["outer"]*1000.
	} ELSE {
		IF altt > params["postflare_alt"]  {
			//use the flare circle equation
			
			SET profile_alt TO profile_alt + params["flare_circle"]["alt"] - 
				SQRT( params["flare_circle"]["radius"]^2 - ( dist*1000 - params["flare_circle"]["dist"] )^2 ).
		
		} ELSE {
			//use the inner glideslope 
			SET profile_alt TO profile_alt + dist*params["glideslope"]["inner"]*1000.
		
		}
	}
	print "profile alt:  " +  profile_alt at (1,2).	

	RETURN LIST(hac_az_error, (profile_alt - simstate["altitude"]) ).
	

}


//logic to determine when to switch modes
//given the current mode, do the appropriate test and increment if required
//overhauled - simplified logic to switch modes 3 and 4 based on distance
FUNCTION mode_switch {
	PARAMETER simstate.
	PARAMETER rwy.
	PARAMETER params.
	
	PARAMETER switch_mode IS FALSE.
	
	IF mode=3 {
			IF (mode_dist(simstate,tgtrwy,apch_params) < 0.1) {SET switch_mode TO TRUE.}
			
	} ELSE IF mode=4 {
			IF (mode_dist(simstate,tgtrwy,apch_params) < 0.1) {
				SET switch_mode TO TRUE.
				//override the previously calculated glideslope value
				SET rwy["glideslope"] TO params["glideslope"]["outer"].
				
			}
		
	
	} ELSE IF mode=5 {
			//measure the predicted altitude above the site elevation
			LOCAL altt IS simstate["altitude"] - rwy["elevation"].
			
			//below the flare threshold switch
			
			IF altt<=params["preflare_alt"]{
				SET switch_mode TO TRUE.
			}
	
	}
	
	IF switch_mode {SET mode TO mode + 1.}
	RETURN mode.

}






//given the outer and inner glideslope and the radius 
//find the centre of the flare circle, the flare altitudes and the middle glideslope
FUNCTION define_flare_circle {
	PARAMETEr params.
	
	//all calculations in metres
	LOCAL xp IS params["aiming_pt_dist"]*1000.
	//coordinates of the glideslopes intersection pt
	LOCAL xpp IS  (params["glideslope"]["outer"]*xp)/(  params["glideslope"]["outer"] -  params["glideslope"]["inner"] ).
	LOCAL ypp IS xpp*params["glideslope"]["inner"].
	
	LOCAL ogs IS ARCTAN(params["glideslope"]["outer"]).
	LOCAL igs IS  ARCTAN(params["glideslope"]["inner"]).
	
	//half-angle described by the glideslope straight lines
	LOCAL beta IS 90 - 0.5*( ogs - igs ).

	
	
	LOCAL gamma IS beta - igs .
	LOCAL s2 IS params["flare_circle"]["radius"]/SIN(beta).
	LOCAL s3 IS s2*COS(beta).
	
	
	//flare and post-flare altitudes
	SET params["flare_alt"] TO ypp + s3*SIN(ogs).
	SET params["postflare_alt"] TO ypp - s3*SIN(igs).
	//centre of circle
	SET params["flare_circle"]["dist"] TO xpp - s2*COS(gamma).
	SET params["flare_circle"]["alt"] TO ypp + s2*SIN(gamma).
	
	//at the intersection between the flare circle and the outer glideslope
	//the derivative of the circle profile is nearly linear 
	//which means the pitch increase will also be linear 
	//to describe the rising cue in mode 6 we use a lower glideslope 
	//called the middle gs, with angular coeff. corresponding to the second derivative 
	//of the circle equation at the tangent point

	
	////first find the x coordinate of the tangent point 
	//LOCAL xtg_out IS xp + params["flare_alt"]/ TAN( params["glideslope"]["outer"]).
	//print xtg_out.
	////calculate the 2nd derivative 
	//LOCAL curv_tg IS  (params["flare_circle"]["radius"]^2)/( params["flare_circle"]["radius"]^2 - (xtg_out - params["flare_circle"]["dist"])^2 )^(1.5).
	//SET params["glideslope"]["middle"] TO ARCTAN( curv_tg).
	//
	////calculate now the pre-flare altitude 
	////we define it as the altitude where the vertical deviation between the outer and middle glideslopes
	////equals the altitude deadband for the diamond cue on the hud.
	////we use the hard-coded value of 300 metres
	
	SET params["preflare_alt"] TO params["flare_alt"] + 100.

}

FUNCTION flaptrim_control_apch {
	PARAMETER flap_control.
	
	SET flap_control["deflection"] TO  SHIP:CONTROL:PILOTPITCHTRIM..
	
	deflect_flaps(flap_control["parts"] , -flap_control["deflection"]*25).
	
	
	RETURN flap_control.

}

FUNCTION update_nz {
	Parameter pos.
	Parameter surfvel.
	Parameter attitude.
	
	LOCAL g0 IS 9.80665.
	
	//sample lift force
	LOCAL outlex IS aeroforce(pos, surfvel, attitude).

	return outlex["lift"]/g0.
}


FUNCTION update_g_force {
	PARAMETER nz.
	
	LOCAL g0 IS 9.80665.
	LOCAL cur_t IS TIME:SECONDS.
	LOCAL cur_hdot IS SHIP:VERTICALSPEED.
	SET nz["dt"] TO cur_t - nz["cur_t"].
	
	IF nz["dt"]>0 {
		SET nz["cur_nz"] TO (cur_hdot- nz["cur_hdot"])/(g0*nz["dt"]) + 1.
	}
	SET nz["cur_hdot"] TO cur_hdot.
	SET nz["cur_t"] TO cur_t.

	RETURN nz.
}
