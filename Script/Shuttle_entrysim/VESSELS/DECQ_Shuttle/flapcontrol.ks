


//initialise the flap control params
//initialise flaps parts, (body flap + elevons for the Space Shuttle)
//DO NOT CHANGE ANYTHING OTHER THAN THE "parts" SUFFIX!!!
//FLAP PARTS MUST BE FAR CONTROLLABLE SURFACES
//deflection is defined positive downwards
GLOBAL flap_control IS LEXICON(
					"deflection",0,
					"pitch_control",LIST(0),
					"parts", LIST(
						LEXICON(
								"flapmod",SHIP:PARTSDUBBED("ShuttleElevonL")[0]:getmodule("FARControllableSurface"),
								"min_defl",-35,
								"max_defl",35
						),
						LEXICON(
								"flapmod",SHIP:PARTSDUBBED("ShuttleElevonR")[0]:getmodule("FARControllableSurface"),
								"min_defl",-35,
								"max_defl",35
						),
						LEXICON(
								"flapmod",SHIP:PARTSDUBBED("ShuttleBodyFlap")[0]:getmodule("FARControllableSurface"),
								"min_defl",-22,
								"max_defl",28
						)
					)
).