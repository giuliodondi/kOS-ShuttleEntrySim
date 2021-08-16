



//main loop
FUNCTION entry_main_loop {


STEERINGMANAGER:RESETPIDS().
STEERINGMANAGER:RESETTODEFAULT().


//SET STEERINGMANAGER:ROLLCONTROLANGLERANGE TO 4.0.
SET STEERINGMANAGER:PITCHTS TO 10.0.
SET STEERINGMANAGER:YAWTS TO 10.0.
SET STEERINGMANAGER:ROLLTS TO 8.0.
SET STEERINGMANAGER:PITCHPID:KD TO 0.01.
SET STEERINGMANAGER:YAWPID:KD TO 0.01.
SET STEERINGMANAGER:ROLLPID:KD TO 0.05.


//unset the PIDs that may still be in memory 
IF (DEFINED BRAKESPID) {UNSET BRAKESPID.}
IF (DEFINED FLAPPID) {UNSET FLAPPID.}







//initialise touchdown points for all landing sites
define_td_points().



GLOBAL mode IS 1.

//flag to stop the program entirely
GLOBAL quitflag IS FALSE.


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
									"roll_ref",0


).



//flag to reset entry guidance to initial values (e.g. when the target is switched)

GLOBAL reset_entry_flag Is FALSE.


make_global_entry_GUI().


//find the airbrakes parts
GLOBAL airbrakes IS LIST().
FOR b IN SHIP:PARTSDUBBED("airbrake1") {
	LOCAL bmod IS b:getmodule("ModuleAeroSurface").
	bmod:SETFIELD("Deploy Angle",0). 
	bmod:DOACTION("EXTEND",TRUE).
	
	airbrakes:ADD(bmod).
}
GLOBAL airbrake_control IS LEXICON(
						"spdbk_val",0
						).


//SHUTDOWN ALL engines and initalise gimbals parts
LISt ENGINES IN englist.
FOR eng in englist {
	IF (eng:IGNITION) {
		IF NOT (DEFINED gimbals) {
			GLOBAL gimbals IS eng:GIMBAL.
		}
		eng:SHUTDOWN.
	}

}
IF NOT (DEFINED gimbals) {
	GLOBAL gimbals IS englist[0]:GIMBAL.
}


//if conducting an ALT this will prevent the entry guidance from running
//the flap trim logic is contained within entry guidance block
IF SHIP:ALTITUDE>constants["apchalt"] {

	IF (NOT check_pitch_prof()) {
		PRINT "Illegal pitch profile detected." at (0,1).
		PRINT "You may only specify positive pitch values to positive velocity values" AT (0,2). 
		RETURN.
	}

	
	gimbals:DOACTION("free gimbal", TRUE).
	//gg:DOEVENT("Show actuation toggles").
	gimbals:DOACTION("toggle gimbal roll", TRUE).
	gimbals:DOACTION("toggle gimbal yaw", TRUE).
	
	RUNPATH("0:/Shuttle_entrysim/VESSELS/" + vessel_dir + "/flapcontrol").

	

	activate_flaps(flap_control["parts"]).


	entry_loop().
	
	deactivate_flaps(flap_control["parts"]).


	//remove entry GUI sections
	clean_entry_gui().

}



SET mode TO 3.
SET CONFIG:IPU TO 1000.


get_closest_ldg_site().



SET loglex["range"] TO 0.
SET loglex["end_range"] TO 0.
SET loglex["range_err"] TO 0.
SET loglex["az_err"] TO 0.
SET loglex["roll_ref"] TO 0. 



approach_loop().

close_global_GUI().

clearscreen.
 
}






FUNCTION entry_loop{

IF quitflag {RETURN.}

//SET STEERINGMANAGER:MAXSTOPPINGTIME TO 8. 

//steer towards an initial direction before starting the whole thing
//the direction is defined by the first profile pithch value and zero roll
//reference prograde vector about which everything is rotated
LOCAL initial_dir IS create_steering_dir(
					SHIP:srfprograde:vector:NORMALIZED,
					VXCL(SHIP:srfprograde:vector:NORMALIZED,-SHIP:ORBIT:BODY:POSITION:NORMALIZED),
					pitchprof_segments[pitchprof_segments:LENGTH-1][1],
					0
					).

//SEt STEERING TO initial_dir.
//
//UNTIL FALSE {
//	IF (VANG(SHIP:FACING:FOREVECTOR , initial_dir:FOREVECTOR) < 5 ) { BREAK.}
//	WAIT 0.1.
//}

UNLOCK STEERING.
SAS  ON.


//internal variables
GLOBAL P_att IS SHIP:FACING.


//flag to signal that roll guidance has converged
IF NOT (DEFINED start_guid_flag) {
	GLOBAL start_guid_flag IS FALSE.
}


//flag to stop the entry loop and transition to approach
GLOBAL stop_entry_flag IS FALSE.


//initialise pitch and roll values .

LOCAL pitchv IS  pitchprof_segments[pitchprof_segments:LENGTH-1][1].
LOCAL rollv IS 0.


SET pitchprof_segments[pitchprof_segments:LENGTH - 1][1] TO pitchv.


//initialise gains for PID
GLOBAL gains_log_path IS "0:/Shuttle_entrysim/VESSELS/" + vessel_dir + "/gains.ks".
IF EXISTS(gains_log_path) {RUNPATH(gains_log_path).}
ELSE {GLOBAL gains IS LEXICON("Kp",0.008,"Kd",0.001,"Khdot",2,"Kalpha",0,"strmgr",8).}
 
 
make_entry_GUI(pitchv,rollv).



//trajectory simulation variables
LOCAL step_num IS 0.

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



//navigation variables
LOCAL az_err IS az_error(SHIP:GEOPOSITION,tgtrwy["position"],SHIP:VELOCITY:SURFACE).
LOCAL range_err IS 0.


LOCAL tgt_range IS 0.

LOCAL last_T Is TIME:SECONDS.
LOCAL last_hdot IS 0.



//roll ref is the base roll value that gets updated by guidance 
//the actual roll value is determined by the roll profile routine
//it's zero above 90 km and it's roll_ref plus hdot modulation below that.
//initialise it to 45 arbitrarily
LOCAL roll_ref IS constants["rollguess"].
LOCAL roll_ref_p IS 0.





// control variables
//initialise the roll sign to the azimuth error sign
LOCAL roll_sign IS SIGN(az_err).
LOCAL pitch_ref IS pitchv.
LOCAL update_reference IS true.


//initialise the running average for the pitch control values
GLOBAL count IS 1.
GLOBAL len IS 20.
FROM {LOCAL k IS 1.} UNTIL k > len STEP { SET k TO k+1.} DO{
	flap_control["pitch_control"]:ADD(0).
}
SET len TO 1.




//run the control loop 
//faster than the main loop 
LOCAL attitude_time_upd IS TIME:SECONDS.
WHEN TIME:SECONDS>attitude_time_upd + 0.5 THEN {
	SET attitude_time_upd TO TIME:SECONDS.
	//steer to the new pitch and roll 
	SET P_att TO update_attitude(P_att,pitchv,rollv).


	//calculate trim deflection and speedbrake deflection
	//read off the gimbal angle to get the pitch control input 
	SET flap_control["pitch_control"][count] TO  -gimbals:PITCHANGLE.
	SET flap_control["pitch_control"][0] TO average_list(flap_control["pitch_control"]).

	//update the flaps trim setting 
	SET flap_control TO flaptrim_control( flap_control).
		
	
	
	SET airbrake_control["spdbk_val"] TO speed_control(arbkb:PRESSED,airbrake_control["spdbk_val"],mode).
	
	FOR b IN airbrakes {
		b:SETFIELD("Deploy Angle",50*airbrake_control["spdbk_val"]). 
	}
	
	PRESERVE.
}

 
UNTIL FALSE {

	IF reset_entry_flag {
		SET reset_entry_flag TO FALSE.
		SET roll_ref TO constants["rollguess"]. 
	}
	
	//wil not command any roll above this altitude
	IF (SHIP:ALTITUDE < constants["firstrollalt"]) AND (SAS) {
		SAS OFF.
	}

	//initialise roll and pitch values to the sliders
	SET rollv TO get_roll_slider().
	SEt pitchv TO get_pitch_slider().
	//determine if reference pitch is to be updated
	SET update_reference TO update_ref_pitch(pitchv).
	IF update_reference {
		SET pitch_ref TO pitchv.
	}
	
	//calculte azimuth error
	SET az_err TO az_error(SHIP:GEOPOSITION,tgtrwy["position"],SHIP:VELOCITY:SURFACE).
	
	//distance to target
	set tgt_range to greatcircledist(tgtrwy["position"], SHIP:GEOPOSITION).
	
	
	//run the vehicle simulation
	LOCAL ICS IS LEXICON(
					 "position",-SHIP:ORBIT:BODY:POSITION,
	                 "velocity",SHIP:VELOCITY:ORBIT
	).
	LOCAL simstate IS blank_simstate(ICS).
		
	SET simstate TO  simulate_reentry(
					sim_settings,
					simstate,
					tgtrwy,
					sim_end_conditions,
					az_err_band,
					roll_ref,
					pitch_ref,
					pitchroll_profiles_entry@
	).
	
	
	//get great-circle distance from current position to impact pt
	LOCAL end_range IS greatcircledist(simstate["latlong"], SHIP:GEOPOSITION).
	

	//calculate the range error
	LOCAL range_err_p IS range_err.
	SET range_err TO end_range - tgt_range - sim_end_conditions["range_bias"]. 
	
	
	//calculate time elapsed since last cycle
	LOCAL delta_t IS  TIME:SECONDS - last_T.
	SET last_T TO TIME:SECONDS.
	
	
	//adjust the timestep adaptively
	//the idea is to keep the number of steps roughly constant
	//and to account for the fact that the simulation time
	//becomes shorter and shorter as we fly the reentry profile.
	
	//first compute the number of steps of last simulation.
	SET step_num TO clamp(ROUND(simstate["simtime"]/sim_settings["deltat"],0),50,100).
	
	//predict the next simulation time by reducing it by the cycle time
	LOCAL next_simtime IS simstate["simtime"] - delta_t.
	//obtain the new timestep , only update is it's smaller
	LOCAL new_timestep IS next_simtime/step_num.
	IF sim_settings["deltat"]>new_timestep {
		SET sim_settings["deltat"] TO new_timestep.
	}
	
	clearscreen.
	print "simulation steps: " + step_num at (1,2).
	print "timestep: " + sim_settings["deltat"] at (1,3).
	
	
	IF is_guidance() {
		//register guidance enabled 
		SET mode TO 2.
	
		//PID stuff
		LOCAL P IS range_err.
		LOCAL D IS (range_err - range_err_p)/delta_t.

		LOCAL delta_roll IS  P*gains["Kp"] + D*gains["Kd"].
		
		SET roll_ref_p TO roll_ref.
		//update the reference roll value and clamp it
		SET roll_ref TO clamp( roll_ref + delta_roll, 0.5, 120) .
		
		//measure vertical acceleration
		//will be used for roll modulation
		local hddot is (SHIP:VERTICALSPEED - last_hdot)/delta_t.	
		SET last_hdot TO SHIP:VERTICALSPEED.
		
		//get updated pitch and roll from the profiles
		LOCAL out IS pitchroll_profiles_entry(LIST(roll_ref,pitch_ref),LIST(rollv,pitchv),current_simstate(),hddot,az_err,az_err_band).
		LOCAL new_roll IS out[0].
		SET pitchv TO out[1].
			
		
		//use it only if the reference roll value is converged
		IF (NOT start_guid_flag AND ABS(roll_ref - roll_ref_p) <constants["rolltol"]) OR start_guid_flag {
			SET rollv TO new_roll.
			SET start_guid_flag TO TRUE.
		}
		
		
	
	} ELSE {
		SET mode TO 1.
		//in this case we use the current commanded roll value for the trajectory prediction
		SET roll_ref TO ABS(rollv).
		//reset the start guidance flag 
		SET start_guid_flag TO FALSE.
	}
	
	
	update_entry_GUI(rollv, pitchv, az_err, tgt_range, range_err, roll_ref , is_guidance(), update_reference ).
	
	
	if is_log() {
	
		
		//prepare list of values to log.
		
		SET loglex["mode"] TO mode.
		SET loglex["time"] TO TIME:SECONDS.
		SET loglex["alt"] TO SHIP:ALTITUDE/1000.
		SET loglex["speed"] TO SHIP:VELOCITY:SURFACE:MAG. 
		SET loglex["hdot"] TO SHIP:VERTICALSPEED.
		SET loglex["range"] TO tgt_range.
		SET loglex["lat"] TO SHIP:GEOPOSITION:LAT.
		SET loglex["long"] TO SHIP:GEOPOSITION:LNG.
		SET loglex["pitch"] TO get_pitch().
		SET loglex["roll"] TO get_roll().
		SET loglex["tgt_range"] TO tgt_range.
		SET loglex["range_err"] TO range_err.
		SET loglex["az_err"] TO az_err.
		SET loglex["roll_ref"] TO roll_ref. 
			
			

		log_data(loglex,"0:/Shuttle_entrysim/LOGS/entry_log").
	}
	IF quitflag OR stop_entry_flag {BREAK.}
	wait 0.
}


}














FUNCTION approach_loop {

IF quitflag {RETURN.}




define_flare_circle(apch_params).


GLOBAL sim_settings IS LEXICON(
					"deltat",1.2,//was 2, set to 1.2 to try and make the pipper less jumpy
					"integrator","rk3",
					"log",FALSE
).




//ths lexicon contains all the necessary guidance objects 
GLOBAL runway IS LEXICON(
						"elevation",tgtrwy["elevation"],
						"heading",tgtrwy["rwys"][select_rwy:VALUE]["heading"],
						"td_pt",tgtrwy["rwys"][select_rwy:VALUE]["td_pt"],
						"glideslope",0,
						"hac_side",select_side:VALUE,
						"aiming_pt",LATLNG(0,0),
						"hac",LATLNG(0,0),
						"hac_entry",LATLNG(0,0),
						"hac_exit",LATLNG(0,0),
						"upvec",V(0,0,0)

).



define_hac(runway,apch_params).


make_apch_GUI().



//gear and brakes trigger
WHEN mode=6 THEN {
	WHEN ALT:RADAR<200 THEN {
		GEAR ON.
	}
	WHEN SHIP:STATUS = "LANDED" THEN {BRAKES ON.}
}
		
		
//define the delegate to the integrator function, saves an if check per integration step
LOCAL integrate IS 0.
IF sim_settings["integrator"]= "rk2" {
	SET integrate TO rk2@.
}
ELSE IF sim_settings["integrator"]= "rk3" {
	SET integrate TO rk3@.
}
ELSE IF sim_settings["integrator"]= "rk4" {
	SET integrate TO rk4@.
}


UNTIL FALSE{
	//need this to move the spoilers
	BRAKES ON.

	//distance to target runway
	LOCAL tgt_range IS greatcircledist(tgtrwy["position"], SHIP:GEOPOSITION).
	
	
	
	//predict vehicle position some time ahead
	
	LOCAL ICS IS LEXICON(
					 "position",-SHIP:ORBIT:BODY:POSITION,
	                 "velocity",SHIP:VELOCITY:ORBIT
	).
	LOCAL simstate IS blank_simstate(ICS).
	SET simstate TO rk3(sim_settings["deltat"],simstate,LIST(get_pitch(),get_roll())).
	
	
	SET simstate["altitude"] TO bodyalt(simstate["position"]).
	SET simstate["surfvel"] TO surfacevel(simstate["velocity"],simstate["position"]).
	SET simstate["latlong"] TO shift_pos(simstate["position"],simstate["simtime"]).
	
	SET mode tO mode_switch(simstate,runway,apch_params).
	
	LOCAL deltas IS LIST(0,0).
	
	
	IF mode=3 {
		SET deltas TO mode3(simstate,runway,apch_params).
	}
	ELSE IF mode=4 {
		
		SET deltas TO mode4(simstate,runway,apch_params).
	}
	ELSE IF mode=5  {
		
		SET deltas TO mode5(simstate,runway,apch_params).
	}
	ELSE IF mode=6 {
		
		SET deltas TO mode6(simstate,runway,apch_params).
	}
	
	SET airbrake_control["spdbk_val"] TO speed_control(is_autoairbk(),airbrake_control["spdbk_val"],mode).

	update_apch_GUI(
		diamond_deviation(deltas,mode),
		mode_dist(simstate,runway,apch_params),
		airbrake_control["spdbk_val"]
	).
	
	
	FOR b IN airbrakes {
		b:SETFIELD("Deploy Angle",50*airbrake_control["spdbk_val"]). 
	}

	

	if is_log() {

		//prepare list of values to log.
		
		SET loglex["mode"] TO mode.
		SET loglex["time"] TO TIME:SECONDS.
		SET loglex["alt"] TO SHIP:ALTITUDE/1000.
		SET loglex["speed"] TO SHIP:VELOCITY:SURFACE:MAG. 
		SET loglex["hdot"] TO SHIP:VERTICALSPEED.
		SET loglex["lat"] TO SHIP:GEOPOSITION:LAT.
		SET loglex["long"] TO SHIP:GEOPOSITION:LNG.
		SET loglex["pitch"] TO get_pitch().
		SET loglex["roll"] TO get_roll().
		SET loglex["tgt_range"] TO tgt_range.
		
			
			

		log_data(loglex,"0:/Shuttle_entrysim/LOGS/entry_log").
	}

	IF quitflag {BREAK.}
	wait 0.

}


}
