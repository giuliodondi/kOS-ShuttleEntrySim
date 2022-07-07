

//define the approach guidance constants

GLOBAL apch_params IS LEXICON(
					"hac_radius",4.26,
					"hac_r2",0.0000283,
					"final_dist",7.5,
					"aiming_pt_dist", 2,
					"glideslope",LEXICON(
								"outer",TAN(20),
								"inner",TAN(3),
								"middle",0	
					),
					"flare_circle",LEXICON(
									"radius",7000,
									"dist",0,
									"alt",0
					),
					"preflare_alt",0,
					"flare_alt",0,
					"postflare_alt",0
).
