

GLOBAL constants is LEXICON(
					"atmalt",140000,
					"interfalt",122000,
					"firstrollalt",90000,
					"apchalt",20000,
					"rolltol",2,
					"rollguess",45
).

//define the approach guidance constants

GLOBAL apch_params IS LEXICON(
					"hac_radius",5,
					"final_dist",8,
					"aiming_pt_dist", 3,
					"glideslope",LEXICON(
								"outer",TAN(19),
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