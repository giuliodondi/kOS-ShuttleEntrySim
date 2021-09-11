@LAZYGLOBAL OFF.
clearscreen.
clearvecdraws().
CLEARGUIS().


//load parameters
RUNPATH("0:/Shuttle_entrysim/constants").


//hard-coded check to run the script only in atmosphere
If (SHIP:ALTITUDE >= constants["atmalt"]) {
	PRINT "Not yet inside the atmosphere. Aborting." .
} ELSE {

	SET CONFIG:IPU TO 1200.
	//SET TERMINAL:WIDTH TO 40.
	//SET TERMINAL:HEIGHT TO 8.

	//load parameters
	RUNPATH("0:/Shuttle_entrysim/vessel_dir").
	RUNPATH("0:/Shuttle_entrysim/VESSELS/" + vessel_dir + "/pitch_profile").
	RUNPATH("0:/Shuttle_entrysim/landing_sites").
	RUNPATH("0:/Shuttle_entrysim/parameters").
	RUNPATH("0:/Shuttle_entrysim/VESSELS/" + vessel_dir + "/flapcontrol").


	//	Load libraries
	RUNPATH("0:/Libraries/misc_library").	
	RUNPATH("0:/Libraries/maths_library").	
	RUNPATH("0:/Libraries/navigation_library").	
	RUNPATH("0:/Shuttle_entrysim/src/simulate_vehicle").
	RUNPATH("0:/Shuttle_entrysim/src/gui_utility").
	RUNPATH("0:/Shuttle_entrysim/src/entry_utility").
	RUNPATH("0:/Shuttle_entrysim/src/approach_utility").



	//this is the default initialised landing site 
	//can be changed with the GUI
	GLOBAL tgtrwy IS ldgsiteslex[ldgsiteslex:keys[0]].





			

	RUNPATH("0:/Shuttle_entrysim/src/entry_main").
	entry_main_loop().

}




