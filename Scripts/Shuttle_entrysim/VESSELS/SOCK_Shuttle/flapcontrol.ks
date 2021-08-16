


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
								"flapmod",SHIP:PARTSDUBBED("benjee10.shuttle.bodyFlap")[0]:getmodule("FARControllableSurface"),
								"min_defl",-14,
								"max_defl",25
						)
					)
).

//needed since SOCK has mirrored elevons with the same name

LOCAL elev1 IS SHIP:PARTSDUBBED("benjee10.shuttle.elevon1").
LOCAL elev2 IS SHIP:PARTSDUBBED("benjee10.shuttle.elevon2").

FOR el in elev1 {
	flap_control["parts"]:ADD(
							LEXICON(
									"flapmod",el:getmodule("FARControllableSurface"),
									"min_defl",-25,
									"max_defl",25
							)
	).
}
FOR el in elev2 {
	flap_control["parts"]:ADD(
							LEXICON(
									"flapmod",el:getmodule("FARControllableSurface"),
									"min_defl",-25,
									"max_defl",25
							)
	).
}