clearscreen.
SET CONFIG:IPU TO 1500.					//	Required to run the script fast enough.

//load parameters
RUNPATH("0:/Shuttle_entrysim/constants").



//load parameters
RUNPATH("0:/Shuttle_entrysim/vessel_dir").
RUNPATH("0:/Shuttle_entrysim/landing_sites").
RUNPATH("0:/Shuttle_entrysim/parameters").


//if the global pitch ptofile file is defined, load that one
IF EXISTS(pitchprof_log_path) {RUNPATH(pitchprof_log_path).}
ELSE {
	RUNPATH("0:/Shuttle_entrysim/VESSELS/" + vessel_dir + "/pitch_profile").
}


//	Load libraries
RUNPATH("0:/Libraries/misc_library").	
RUNPATH("0:/Libraries/maths_library").	
RUNPATH("0:/Libraries/navigation_library").	
RUNPATH("0:/Shuttle_entrysim/src/deorbit_main").
RUNPATH("0:/Shuttle_entrysim/src/simulate_vehicle").
RUNPATH("0:/Shuttle_entrysim/src/gui_utility").
RUNPATH("0:/Shuttle_entrysim/src/entry_utility").




deorbit_main().

