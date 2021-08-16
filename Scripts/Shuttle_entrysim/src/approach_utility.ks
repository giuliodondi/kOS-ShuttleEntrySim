//misc functions 


//draw a vector centered on geolocation for target redesignation
//scales with distance from ship for visibility
FUNCTION pos_arrow {
	PARAMETER pos.
	
	LOCAL start IS pos:POSITION.
	LOCAL end IS (pos:POSITION - SHIP:ORBIT:BODY:POSITION).
	
	VECDRAW(
      start,//{return start.},
      end,//{return end.},
      RGB(1,0,0),
      "",
      1000,
      TRUE,
      0.05
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
			SET tgtspeed TO 51.48*tgt_rng^(0.6431).
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










//hac functions 



//called upon changing either the runway or the hac side
//defined the hac centre, the displaced final point (hac exit) and the reference up vector
//also sets the runway elevation
FUNCTION define_hac {
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
	
	update_hac_entry_pt(rwy,params).
	
	//clearvecdraws().
	//pos_arrow(tgtrwy["position"]).
	//pos_arrow(rwy["td_pt"]).
	//pos_arrow(rwy["aiming_pt"]).
	//pos_arrow(rwy["hac"]).
	//pos_arrow(rwy["hac_exit"]).
	



}




//determine which landing site is the closest
FUNCTION get_closest_ldg_site {


	LOCAL pos IS SHIP:GEOPOSITION.

	LOCAL min_dist IS 0.
	LOCAL closest_site IS 0.
	LOCAL k IS 0.

	FOR s in ldgsiteslex:KEYS {
		
		LOCAL site IS ldgsiteslex[s].
		LOCAL sitepos IS site["position"].
		
		LOCAL sitedist IS downrangedist(pos,sitepos).

		IF (min_dist = 0) {
			SET min_dist TO sitedist.
			SET closest_site TO k.
		} ELSE {
			IF (min_dist > sitedist) {
				SET min_dist TO sitedist.
				SET closest_site TO k.
			}
		}
		SET k TO k + 1.
	}
	SET select_tgt:INDEX TO  closest_site.
}


//update the entry point to the HAC
FUNCTION update_hac_entry_pt {
	PARAMETER rwy.
	PARAMETER params.
	
	//now find the hac entry point given the hac position and the ship position relative to it
	//a left hac always entails the entry point is to the right of the ship bearing to the hac centre 
	//and for a right hac the reverse is true 
	
	
	//we need to make the entry point a geoposition,not a vector
	//find the bearing from the hac centre to the ship,
	//add or subtract 	the beta angle accordingly
	//then get the geoposition from the hac given that bearing and the hac radius
	
	LOCAL d IS greatcircledist(rwy["hac"],SHIP:GEOPOSITION).
	LOCAL alpha IS ARCSIN(LIMITARG(params["hac_radius"]/d)).
	LOCAL beta IS 90 - alpha.
	
	//same calculations as the hac definition routine 
	LOCAL ship_bng IS bearingg(SHIP:GEOPOSITION,rwy["hac"]).
	LOCAL hac_entry_sign IS 1.
	IF rwy["hac_side"]="left" {SET hac_entry_sign TO -1.}
	LOCAL entry_bng IS fixangle(ship_bng + hac_entry_sign*beta).
	SET rwy["hac_entry"] TO  new_position(rwy["hac"],params["hac_radius"],entry_bng).

}


//update the glideslope based in current altitude and distance to travel
FUNCTION get_glideslope {
	PARAMETER altt.
	PARAMETER dist.
	
	RETURN ARCTAN2(altt,(1000*dist)). 

}


//angle between an input entry vector and the HAC exit vector around the HAC centre
//FUNCTION get_hac_angle {
//	PARAMETER rwy.
//	PARAMETER entryvec.
//		
//	LOCAL exitvec IS (rwy["hac_exit"]:POSITION - rwy["hac"]:POSITION):NORMALIZED.
//	SET exitvec TO VXCL(rwy["upvec"],exitvec).
//	SET entryvec TO VXCL(rwy["upvec"],entryvec).
//	RETURN signed_angle(exitvec,entryvec,rwy["upvec"],1).
//	
//}
FUNCTION get_hac_angle {
	PARAMETER rwy.
	PARAMETER entryvec.
		
	LOCAL exitvec IS (rwy["hac_exit"]:POSITION - rwy["hac"]:POSITION):NORMALIZED.
	RETURN signed_angle(exitvec,entryvec,rwy["upvec"],1).
	
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
		LOCAL theta IS get_hac_angle(rwy,shipvec).
		print "hac angle:  " + theta at (1,1).
		
		
		//find the groundtrack around the hac
		RETURN params["hac_radius"]*theta*CONSTANT:PI/180.
		
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
	IF (ship_hac_dist>1) { update_hac_entry_pt(rwy,params). }

	
	LOCAL entryvec IS (rwy["hac_entry"]:POSITION - rwy["hac"]:POSITION):NORMALIZED.

	//once we have the entry point find the theta angle
	LOCAL theta IS get_hac_angle(rwy,entryvec).
	print "hac angle:  " + theta at (1,1).
	
	
	//build the vertical profile 
	//find the 18° glideslope altitude at runway intercept
	LOCAL final_alt IS params["final_dist"]*params["glideslope"]["outer"].
	
	//find the groundtrack around the hac
	LOCAL hac_gndtrk IS params["hac_radius"]*theta*CONSTANT:PI/180.
	
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
	
	print "horiz err:  " + (greatcircledist(rwy["hac"],SHIP:GEOPOSITION) - params["hac_radius"])*1000 AT (1,3).

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
	LOCAL theta IS get_hac_angle(rwy,shipvec).
	print "hac angle:  " + theta at (1,1).
	
	//get the vertical profile value at the predicted point 
	LOCAL final_alt IS params["final_dist"]*params["glideslope"]["outer"].
	
	//find the groundtrack around the hac
	LOCAL hac_gndtrk IS params["hac_radius"]*theta*CONSTANT:PI/180.
	
	

	// buld the vertical profile
	//use the last calculated runway glideslope

	LOCAL profile_alt IS  final_alt + (hac_gndtrk)*rwy["glideslope"].
	SET profile_alt TO rwy["elevation"] +  profile_alt*1000.

	print "profile alt:  " +  profile_alt at (1,2).	
	

	//build the target point as described
	//first get the HAC position corresponding to the predicted point
	LOCAL hac_tangentaz IS bearingg(simstate["latlong"],rwy["hac"]).
	LOCAL hac_tangentpos IS new_position(rwy["hac"],params["hac_radius"],hac_tangentaz). 
	
	print "horiz err:  " + (greatcircledist(rwy["hac"],SHIP:GEOPOSITION) - params["hac_radius"])*1000 AT (1,3).

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
FUNCTION mode_switch {
	PARAMETER simstate.
	PARAMETER rwy.
	PARAMETER params.
	
	PARAMETER switch_mode IS FALSE.
	
	IF mode=3 {
			//measure the hac-centered angle bw the hac exit and the predicted point 
			//if it's negative the predicted point is in the hac phase, switch
			//also check distance between that point and the hac entry point
			LOCAL entryvec IS (rwy["hac_entry"]:POSITION - rwy["hac"]:POSITION):NORMALIZED.
			LOCAL shipvec IS (simstate["latlong"]:POSITION - rwy["hac"]:POSITION):NORMALIZED.

			
			LOCAL theta IS unfixangle(get_hac_angle(rwy,shipvec) - get_hac_angle(rwy,entryvec)).

			IF ( theta)<0 AND greatcircledist(rwy["hac_entry"],simstate["latlong"])<2 {SET switch_mode TO TRUE.}
			

			
	} ELSE IF mode=4 {
			//measure the hac-centered angle bw the hac exit and the predicted point  (theta)
			//if it's negative the predicted point has exited the hac and switch
			LOCAL exitvec IS (rwy["hac_exit"]:POSITION - rwy["hac"]:POSITION):NORMALIZED.
			LOCAL shipvec IS (simstate["latlong"]:POSITION - rwy["hac"]:POSITION):NORMALIZED.
			
			//we must wrap theta around the range -180 +180 
			//but theta will be in general >180 upon entering mode 4 
			//therefore we only do it if we're in the quadrants adjacent to
			//the hac exit vector
			LOCAL theta IS get_hac_angle(rwy,shipvec).
			IF ABS(VANG(shipvec,exitvec))<90 {
				SET theta TO unfixangle(theta).
			}
			
			IF theta<1 {
				SET switch_mode TO TRUE.
				//override the previously calculated glideslope value
				SET rwy["glideslope"] TO params["glideslope"]["outer"].
				
				////calculate the new aiming point distance for the middle glideslope
				//LOCAL yp IS params["flare_alt"].
				//LOCAL x IS yp*(1 - TAN(params["glideslope"]["middle"])/TAN(params["glideslope"]["outer"]) )/params["glideslope"]["middle"].
				//SET params["aiming_pt_dist"] TO arams["aiming_pt_dist"] - x.
				//
				////prepare the pre-flare trigger 
				//WHEN SHIP:ALTITUDE<(rwy["elevation"] + params["preflare_alt"]) THEN {
				//	SET rwy["glideslope"] TO params["glideslope"]["middle"].
				//	LOCAL bng IS fixangle(rwy["heading"] - 180).
				//	SET rwy["aiming_pt"] TO  new_position(rwy["td_pt"],params["aiming_pt_dist"],bng).
				//}

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


