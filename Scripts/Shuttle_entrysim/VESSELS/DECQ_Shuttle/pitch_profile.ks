
//piecewise reentry pitch profile
//the pitch value of the highest velocity point does not matter 
//it will be updated if the velocity is higher than 
// its vel value and the update_reference flag is true 

////	38/28
//IF NOT (DEFINEd pitchprof_segments) {
//	GLOBAL pitchprof_segments IS LIST(
//								LIST(250,3),
//								LIST(1800,28),
//								LIST(5300,28),
//								LIST(6700,38)
//								).
//}

//	40/30
IF NOT (DEFINEd pitchprof_segments) {
	GLOBAL pitchprof_segments IS LIST(
								LIST(250,3),
								LIST(1800,30),
								LIST(5300,30),
								LIST(6700,40)
								).
}

