
//piecewise reentry pitch profile
//the pitch value of the highest velocity point does not matter 
//it will be updated if the velocity is higher than 
// its vel value and the update_reference flag is true 

//	38/28
//IF NOT (DEFINEd pitchprof_segments) {
//	GLOBAL pitchprof_segments IS LIST(
//								LIST(250,3),
//								LIST(2100,28),
//								LIST(5300,28),
//								LIST(6340,38)
//								).
//

//	35/25	//higher l/d
IF NOT (DEFINEd pitchprof_segments) {
	GLOBAL pitchprof_segments IS LIST(
								LIST(250,3),
								LIST(2100,25),
								LIST(5300,25),
								LIST(6340,35)
								).
}


