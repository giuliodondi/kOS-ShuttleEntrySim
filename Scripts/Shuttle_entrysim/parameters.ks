


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


//bandwidth of azimuth error that triggers a roll reversal
IF NOT (DEFINED az_err_band) {
	GLOBAL az_err_band IS 11.
}


//reference timestep value, type of integrator function and flag for logging
IF (DEFINED sim_settings) {
	UNSET sim_settings.
}
GLOBAL sim_settings IS LEXICON(
					"deltat",20,
					"integrator","rk3",
					"log",FALSE
	).


//simulation termination conditions
//set these to the values of altitude and velocity you would like to find yourself at 
//when disengaging entry guidance
//range bias should be a small positive value to ensure a good margin of error for ranging
IF NOT (DEFINED sim_end_conditions) {
	GLOBAL sim_end_conditions IS LEXICON(
							"altitude",15000,
							"surfvel",400,
							"range_bias",0
	).
}




