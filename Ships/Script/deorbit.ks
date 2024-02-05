clearscreen.
SET CONFIG:IPU TO 1500.					//	Required to run the script fast enough.

//load parameters
RUNONCEPATH("0:/Shuttle_entrysim/vessel_dir").
RUNONCEPATH("0:/Shuttle_entrysim/landing_sites").
RUNONCEPATH("0:/Shuttle_entrysim/constants").
RUNONCEPATH("0:/Shuttle_entrysim/simulation_params").


//if the global pitch ptofile file is defined, load that one
IF EXISTS(pitchprof_log_path) {RUNONCEPATH(pitchprof_log_path).}
ELSE {
	RUNONCEPATH("0:/Shuttle_entrysim/VESSELS/" + vessel_dir + "/pitch_profile").
}

//delete global profile file
IF EXISTS(pitchprof_log_path) {DELETEPATH(pitchprof_log_path).}

RUNONCEPATH("0:/Shuttle_entrysim/VESSELS/" + vessel_dir + "/vehicle_params").

//	Load libraries
RUNONCEPATH("0:/Libraries/misc_library").	
RUNONCEPATH("0:/Libraries/maths_library").	
RUNONCEPATH("0:/Libraries/navigation_library").
RUNONCEPATH("0:/Libraries/aerosim_library").
RUNPATH("0:/Libraries/vehicle_library").	

RUNONCEPATH("0:/Shuttle_entrysim/src/deorbit_main").
RUNONCEPATH("0:/Shuttle_entrysim/src/gui_utility").
RUNONCEPATH("0:/Shuttle_entrysim/src/entry_utility").




deorbit_main().

