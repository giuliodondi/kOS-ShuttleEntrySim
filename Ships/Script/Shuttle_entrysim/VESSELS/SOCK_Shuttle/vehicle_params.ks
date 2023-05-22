

//define the approach guidance constants

GLOBAL vehicle_params IS LEXICON(
					"rollguess",55,
					"TAEMtgtvel",260,
					"hac_radius",4.5,
					"final_dist",7.5,
					"aiming_pt_dist", 2,
					"glideslope",LEXICON(
								"outer",TAN(20),
								"inner",TAN(3),
								"middle",0	
					),
					"flare_circle",LEXICON(
									"radius",8000,
									"dist",0,
									"alt",0
					),
					"preflare_alt",0,
					"flare_alt",0,
					"postflare_alt",0
).
