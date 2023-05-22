@LAZYGLOBAL OFF.
clearscreen.
clearvecdraws().
CLEARGUIS().



//hard-coded check to run the script only in atmosphere
If (SHIP:ALTITUDE >= constants["atmalt"]) {
	PRINT "Not yet inside the atmosphere. Aborting." .
} ELSE {

	SET CONFIG:IPU TO 1200.
	//SET TERMINAL:WIDTH TO 40.
	//SET TERMINAL:HEIGHT TO 8.

	//load parameters
	RUNONCEPATH("0:/Shuttle_entrysim/vessel_dir").
	RUNONCEPATH("0:/Shuttle_entrysim/landing_sites").
	RUNONCEPATH("0:/Shuttle_entrysim/simulation_parameters").
	
	//this flag should only ever be defined during GRTLS
	IF NOT (DEFINEd bypass_pitchprof_def) {
		//if the global pitch ptofile file is defined, load that one
		IF EXISTS(pitchprof_log_path) {RUNONCEPATH(pitchprof_log_path).}
		ELSE {
			RUNONCEPATH("0:/Shuttle_entrysim/VESSELS/" + vessel_dir + "/pitch_profile").
		}
	}
	
	RUNONCEPATH("0:/Shuttle_entrysim/VESSELS/" + vessel_dir + "/flapcontrol").
	RUNONCEPATH("0:/Shuttle_entrysim/VESSELS/" + vessel_dir + "/vehicle_params").


	//	Load libraries
	RUNONCEPATH("0:/Libraries/misc_library").	
	RUNONCEPATH("0:/Libraries/maths_library").	
	RUNONCEPATH("0:/Libraries/navigation_library").	
	RUNONCEPATH("0:/Shuttle_entrysim/src/simulate_vehicle").
	RUNONCEPATH("0:/Shuttle_entrysim/src/gui_utility").
	RUNONCEPATH("0:/Shuttle_entrysim/src/entry_utility").
	RUNONCEPATH("0:/Shuttle_entrysim/src/approach_utility").
	RUNONCEPATH("0:/Shuttle_entrysim/src/taem_utility").
	RUNONCEPATH("0:/Shuttle_entrysim/src/veh_control_utility").
			

	RUNONCEPATH("0:/Shuttle_entrysim/src/entry_main").
	entry_main_loop().

}




