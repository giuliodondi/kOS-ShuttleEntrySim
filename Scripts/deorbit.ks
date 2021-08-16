clearscreen.
SET CONFIG:IPU TO 1500.					//	Required to run the script fast enough.

//load parameters
	RUNPATH("0:/Shuttle_entrysim/constants").

IF (HASNODE = FALSE) {
	PRINT "No deorbit manoeuvre node found. You must create a node.".
} ELSE IF (SHIP:ALTITUDE < constants["atmalt"]){
	PRINT "You are inside the atmosphere. Cannot deorbit at this point.".
} ELSE {

	
	//load parameters
	RUNPATH("0:/Shuttle_entrysim/vessel_dir").
	RUNPATH("0:/Shuttle_entrysim/VESSELS/" + vessel_dir + "/pitch_profile").
	RUNPATH("0:/Shuttle_entrysim/landing_sites").
	RUNPATH("0:/Shuttle_entrysim/parameters").


	GLOBAL tgtrwy IS ldgsiteslex[ldgsiteslex:keys[0]].


	//	Load libraries
	RUNPATH("0:/Libraries/misc_library").	
	RUNPATH("0:/Libraries/maths_library").	
	RUNPATH("0:/Libraries/navigation_library").	
	RUNPATH("0:/Shuttle_entrysim/src/deorbit_main").
	RUNPATH("0:/Shuttle_entrysim/src/simulate_vehicle").
	RUNPATH("0:/Shuttle_entrysim/src/gui_utility").
	RUNPATH("0:/Shuttle_entrysim/src/entry_utility").




	deorbit_main().

}