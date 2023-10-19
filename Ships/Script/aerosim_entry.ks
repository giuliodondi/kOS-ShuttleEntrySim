CLEARSCREEN.


RUNPATH("0:/Libraries/misc_library").	
RUNPATH("0:/Libraries/maths_library").	
RUNPATH("0:/Libraries/navigation_library").	

RUNPATH("0:/Shuttle_entrysim/constants").
RUNPATH("0:/Shuttle_entrysim/vessel_dir").
RUNPATH("0:/Shuttle_entrysim/landing_sites").
RUNPATH("0:/Shuttle_entrysim/simulation_params").

RUNONCEPATH("0:/Libraries/aerosim_library").
RUNPATH("0:/Shuttle_entrysim/src/entry_utility").

RUNPATH("0:/Shuttle_entrysim/VESSELS/" + vessel_dir + "/flapcontrol").
RUNPATH("0:/Shuttle_entrysim/VESSELS/" + vessel_dir + "/vehicle_params").
RUNPATH("0:/Shuttle_entrysim/VESSELS/" + vessel_dir + "/pitch_profile").

GLOBAL gains_log_path IS "0:/Shuttle_entrysim/VESSELS/" + vessel_dir + "/gains.ks".
IF EXISTS(gains_log_path) {RUNPATH(gains_log_path).}



//GLOBAL sim_input IS LEXICON(
//						"target", "Vandenberg",
//						"deorbit_apoapsis", 190,
//						"deorbit_periapsis", 30,
//						"deorbit_inclination", -105.5,
//						"entry_interf_eta", 150,
//						"entry_interf_dist", 9500,
//						"entry_interf_xrange", 1500,
//						"entry_interf_offset", "right"
//).

//tal
GLOBAL sim_input IS LEXICON(
						"target", "Istres",
						"deorbit_apoapsis", 115,
						"deorbit_periapsis", -1100,
						"deorbit_inclination", 40,
						"entry_interf_eta", 180,
						"entry_interf_dist", 5000,
						"entry_interf_xrange", 800,
						"entry_interf_offset", "right"
).



//given the deorbit and entry interface parameters, generates the simulation initial conditions
FUNCTION generate_simulation_ics {
	PARAMETER sim_input.
	
	LOCAL tgt_pos IS ldgsiteslex[sim_input["target"]]["position"].
	
	LOCAL tgt_vec IS pos2vec(tgt_pos).
	
	//get the azimuth of the orbit at the launch site
	
	LOCAL orbaz IS get_orbit_azimuth(sim_input["deorbit_inclination"], tgt_pos:LAT, (sim_input["deorbit_inclination"] < 0)).
	
	LOCAL orbvec IS vector_pos_bearing(tgt_vec, orbaz).
	
	//normal vector to the orbital plane
	
	LOCAL norm_vec IS VCRS(orbvec, tgt_vec) : NORMALIZED * BODy:RADIUS.
	
	
	LOCAL x IS dist2degrees(sim_input["entry_interf_xrange"]).
	
	//rotate the orbital plane until the crossrange is within about 1 km of the parameter
	
	LOCAL tgt_vec_proj IS V(0,0,0).
	
	LOCAL rot_sign IS 1.
	
	IF sim_input["entry_interf_offset"] = "left" {
		SET rot_sign TO -1.
	}
	
	UNTIL FALSE {
	
		SET tgt_vec_proj TO VXCL(norm_vec, tgt_vec): NORMALIZED * BODy:RADIUS.
	
		LOCAL xrange_err IS x - VANG(tgt_vec, tgt_vec_proj).
		
		IF xrange_err < 0.01 {BREAK.}
		
		LOCAL rot IS xrange_err * 1.5.
		
		SET norm_vec TO rodrigues(norm_vec, V(0,1,0), rot_sign*rot).
		
		WAIT 0.
	}
	
	LOCAL d IS dist2degrees(sim_input["entry_interf_dist"]).
	
	LOCAL y IS get_c_ab(d, x).
	
	LOCAL ei_vec IS rodrigues(tgt_vec_proj, norm_vec, y).
	
	//scale by entry interface altitude
	LOCAL h IS BODy:RADIUS + constants["interfalt"].
	SET ei_vec TO ei_vec:NORMALIZED * h.
	
	clearvecdraws().
	arrow_body(tgt_vec,"tgt_vec").
	arrow_body(norm_vec,"norm_vec").
	arrow_body(ei_vec,"ei_vec").


	print "x " + x + " d " + d + " y " + y at (0,8).
	print "dist " + greatcircledist( ei_vec , tgt_vec ) at (0,9).
	
	//conditions at entry interface
	
	LOCAL ei_sma IS orbit_appe_sma(sim_input["deorbit_apoapsis"], sim_input["deorbit_periapsis"]).
	LOCAL ei_ecc IS orbit_appe_ecc(sim_input["deorbit_apoapsis"], sim_input["deorbit_periapsis"]).
	
	print "sma " + ei_sma + " ecc " + ei_ecc at (0,10).
	
	LOCAL ei_vel IS orbit_alt_vel(constants["interfalt"] + BODY:RADIUS, ei_sma).
	LOCAL ei_eta IS 180 + orbit_alt_eta(constants["interfalt"] + BODY:RADIUS, ei_sma, ei_ecc).
	LOCAL ei_fpa IS orbit_eta_fpa(ei_eta, ei_sma, ei_ecc).
	
	print "vel " + ei_vel + " eta " + ei_eta + " gamma " + ei_fpa at (0,11).
	
	//now get velocity vector at the entry interface
	LOCAL ei_vel_vec IS VCRs(ei_vec, norm_vec):NORMALIZED.
	
	SET ei_vel_vec TO rodrigues(ei_vel_vec, norm_vec, ei_fpa):NORMALIZED * ei_vel.

	RETURN 	LEXICON(
					 "position",ei_vec,
	                 "velocity",ei_vel_vec
	).
}


FUNCTION aero_simulate {.
	SET CONFIG:IPU TO 1500.					//	Required to run the script fast enough.
	if  (defined logname) {UNSET logname.}

	
	
	LOCAL target IS ldgsiteslex[sim_input["target"]].
		
	//Initialise log lexicon 
	GLOBAL loglex IS LEXICON(
										"mode",1,
										"time",0,
										"alt",0,
										"speed",0,
										"hdot",0,
										"range",0,
										"lat",0,
										"long",0,
										"pitch",0,
										"roll",0,
										"tgt_range",0,
										"range_err",0,
										"az_err",0,
										"roll_ref",0,
										"l_d",0


	).
	
	log_data(loglex,"0:/aerosim_log/log_" + sim_input["target"] + "_" + sim_input["deorbit_inclination"] + "_" + sim_input["entry_interf_xrange"] , TRUE).
	
	//define the delegate to the integrator function, saves an if check per integration step
	IF sim_settings["integrator"]= "rk2" {
		SET sim_settings["integrator"] TO rk2@.
	}
	ELSE IF sim_settings["integrator"]= "rk3" {
		SET sim_settings["integrator"] TO rk3@.
	}
	ELSE IF sim_settings["integrator"]= "rk4" {
		SET sim_settings["integrator"] TO rk4@.
	}
	

	constants:ADD("prebank_angle",0).
	
	LOCAL ICS_0 IS generate_simulation_ics(sim_input).


	LOCAL ICS IS ICS_0.
	
	LOCAL state0 IS blank_simstate(ICS).
	
	LOCAL init_pos IS  vec2pos(state0["position"]).
	
	 
	LOCAL roll_ref IS vehicle_params["rollguess"].
	LOCAL pitch_ref IS  pitchprof_segments[pitchprof_segments:LENGTH-1][1].


	
	LOCAL range_err IS 0.
	
	LOCAL last_T Is TIME:SECONDS.
	
	local count is 0.
	
	UNTIL FALSE {
		
		SET ICS TO ICS_0.
		SET state0 TO blank_simstate(ICS).
		
		//create roll function delegate 
		//update
		
		
		LOCAL simstate IS simulate_reentry(
						sim_settings,
						state0,
						target,
						sim_end_conditions,
						roll_ref,
						pitch_ref,
						pitchroll_profiles_entry@
		).

		LOCAL delta_t IS  TIME:SECONDS - last_T.
		print "delta_t : " + delta_t at (1,1).
		SET last_T TO  TIME:SECONDS.
		
		LOCAL tgt_range IS greatcircledist( target["position"] , init_pos ).
		LOCAL end_range IS greatcircledist( simstate["latlong"] , init_pos ).
		
		LOCAL range_err_p IS range_err.
		SET range_err TO end_range - tgt_range - sim_end_conditions["range_bias"]. 
		print "range_err : " + range_err at (1,2).
		
		//PID stuff
		LOCAL P IS range_err.
		LOCAL D IS (range_err - range_err_p)/delta_t.
			
		//LOCAL delta_roll IS MAX(-2,MIN(2,P*0.005 + D*0)).
		LOCAL delta_roll IS  P*gains["rangeKP"] + D*gains["rangeKD"].
		
		LOCAL roll_ref_p IS roll_ref.
		//update the reference roll value and clamp it
		SET roll_ref TO clamp( roll_ref + delta_roll, 0, 120) .
		
		print "delta_roll : " + delta_roll at (1,3).
		
		print "roll_ref : " + roll_ref at (1,4).
		
		IF (ABS(roll_ref - roll_ref_p) < 0.25)  {
			break.
		}
		
		wait 0.01.

	}
	
	print ("done optimising") at (0,12).

	SET sim_settings["log"] TO TRUE.
	
	
	SET ICS TO ICS_0.
	SET state0 TO blank_simstate(ICS).
	
	LOCAL simstate IS simulate_reentry(
						sim_settings,
						state0,
						target,
						sim_end_conditions,
						roll_ref,
						pitch_ref,
						pitchroll_profiles_entry@,
						TRUE
		).
	
}



aero_simulate().