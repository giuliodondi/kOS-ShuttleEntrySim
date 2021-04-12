clearscreen.
SET CONFIG:IPU TO 1500.					//	Required to run the script fast enough.


IF (HASNODE = FALSE) {
	PRINT "No deorbit manoeuvre node found. You must create a node.".
} ELSE {

	//load parameters
	RUNPATH("0:/Shuttle_entrysim/parameters/constants").
	RUNPATH("0:/Shuttle_entrysim/parameters/landing_sites").
	RUNPATH("0:/Shuttle_entrysim/parameters/pitch_profile").
	RUNPATH("0:/Shuttle_entrysim/parameters/sim_params").


	GLOBAL tgtrwy IS ldgsiteslex[ldgsiteslex:keys[0]].


	//	Load libraries
	RUNPATH("0:/Libraries/misc_library").	
	RUNPATH("0:/Libraries/maths_library").	
	RUNPATH("0:/Libraries/navigation_library").	
	RUNPATH("0:/Shuttle_entrysim/deorbit_main").
	RUNPATH("0:/Shuttle_entrysim/simulate_vehicle").
	RUNPATH("0:/Shuttle_entrysim/gui_utility").
	RUNPATH("0:/Shuttle_entrysim/entry_utility").




	deorbit_main().

}