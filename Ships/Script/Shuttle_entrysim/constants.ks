

//put these constants in their own file to enable checking of deorbit/entry conditions
//without cluttering the memory in case they fail

GLOBAL constants is LEXICON(
					"atmalt",140000,
					"interfalt",122000,
					"firstrollalt",100000,
					"apchalt",20000,
					"rolltol",2,
					"rollguess",55,
					"TAEMtgtvel",260
).
