


//computes time taken from periapsis to given true anomaly
//for differences of true anomalies call twice and subtract times


declare function eta_to_dt {

	parameter etaa.
	parameter sma.
	parameter ecc.

	local COS_ee IS (ecc + COS(fixangle(etaa)))/(1 + ecc*COS(fixangle(etaa))).

	LOCAL ee IS ARCCOS(limitarg(COS_ee)).			

	LOCAL mean_an IS ee*CONSTANT:PI/180  - ecc*SIN(ee).
	
	IF etaa>180 { SET mean_an TO 2*CONSTANT:PI - mean_an.}
	
	LOCAL n IS SQRT(sma^3/(SHIP:ORBIT:BODY:MU)).
	

	RETURN n*mean_an.
}

//given true anomaly at t0 and a time interval, computes new true anomaly
//approximation correct at ecc^3

declare function t_to_eta {
	parameter etaa0.
	parameter dt.
	parameter sma.
	parameter ecc.
	
	
	local COS_ee IS (ecc + COS(fixangle(etaa0)))/(1 + ecc*COS(fixangle(etaa0))). 
	LOCAL ee IS ARCCOS(limitarg(COS_ee)).

	LOCAL mean_an IS ee*CONSTANT:PI/180  - ecc*SIN(ee).
	
	IF etaa0>180 { SET mean_an TO 2*CONSTANT:PI - mean_an.}
	

	LOCAL n IS SQRT(sma^3/(SHIP:ORBIT:BODY:MU)).
	
	SET mean_an TO mean_an + dt/n.
	
	local out is mean_an.
	
	SET mean_an TO  fixangle(mean_an*180/CONSTANT:PI).

	SET out TO out + 2*ecc*SIN(mean_an) + 1.25*ecc^2*SIN(2*mean_an).
	
	RETURN fixangle(out*180/CONSTANT:PI).

}


FUNCTION rotate_site {
	PARAMETER sitevec.
	PARAMETER dT.
	
	LOCAL northpole IS BODY:ANGULARVEL:NORMALIZED.
	LOCAL angle IS 360*dT/BODY:ROTATIONPERIOD.
	
	RETURN rodrigues(sitevec,northpole,angle).

}


FUNCTION deorbit_main {
	
	
	make_global_deorbit_GUI().
	
	//flag to stop the program entirely
	GLOBAL quitflag IS FALSE.

	
	
	//flag to reset entry guidance to initial values (e.g. when the target is switched)

	GLOBAL reset_entry_flag Is FALSE.


	//initialise the bank control value
	GLOBAL roll_ref IS constants["rollguess"].
	

	LOCAL pitch_ref IS pitchprof_segments[pitchprof_segments:LENGTH-1][1].
	


	//initialise global internal variables
	
	//initialise gains for PID
	LOCAL gains_log_path IS "./Shuttle_entrysim/parameters/gains.ks".
	IF EXISTS(gains_log_path) {RUNPATH(gains_log_path).}
	ELSE {GLOBAL gains IS LEXICON("Kp",0.006,"Kd",0,"Khdot",0,"Kalpha",0).}

	
	local next is nextnode.
	LOCAL entry_radius IS (constants["interfalt"] + SHIP:BODY:RADIUS).
	
	LOCAL range_err IS 0.
	
	LOCAL last_T Is TIME:SECONDS.


	
	//initialise the position points list
	//inisialise as zero to avoid plotting the trajecory before at least one pass
	//through the simulation loop is made
	LOCAL poslist IS 0.
	
	//add the faster outer loop plotting the trajectory data
	LOCAL trajplot_upd IS TIME:SECONDS.
	WHEN TIME:SECONDS>trajplot_upd + 0.2 THEN {
		SET trajplot_upd TO TIME:SECONDS.
		
		CLEARVECDRAWS().

		IF poslist<>0 {
		
			LOCAL oldpos IS poslist[0].
			
			FROM {LOCAL k IS 1.} UNTIL k >= poslist:LENGTH STEP { SET k TO k+1.} DO{
				
				//LOCAL adjustPos IS simstate["position"] + ((simstate["position"] - SHIP:BODY:POSITION):NORMALIZED * 20) - .
				//LOCAL adjold_pos IS old_pos + ((old_pos - SHIP:BODY:POSITION):NORMALIZED * 20).

				LOCAL newpos IS poslist[k].
				LOCAL adjustPos IS newpos   + ((newpos - SHIP:BODY:POSITION):NORMALIZED * 20) .
				LOCAL adjold_pos IS oldpos  + ((oldpos - SHIP:BODY:POSITION):NORMALIZED * 20).
				
				
				LOCAL vecWidth IS 0.1.//200.
				//IF MAPVIEW { SET vecWidth TO 0.2. }
			
				VECDRAW(adjold_pos,(adjustPos - adjold_pos),red,"",1,TRUE,vecWidth).

				SET oldpos TO newpos.
			
			}
		
		}
		
		PRESERVE.

	}
	
	
	
	UNTIL FALSE{
		
		IF reset_entry_flag {
			SET reset_entry_flag TO FALSE.
			SET roll_ref TO constants["rollguess"]. 
		}
	
		SET shipvec TO - SHIP:ORBIT:BODY:POSITION.
		SET normvec TO VCRS(-SHIP:ORBIT:BODY:POSITION,SHIP:VELOCITY:ORBIT).
	
		IF (nextnode:orbit:periapsis)<constants["interfalt"] {
		
			local normvec IS VCRS(-SHIP:ORBIT:BODY:POSITION,SHIP:VELOCITY:ORBIT).
	
			//time to the node
			LOCAL shipvec IS - SHIP:ORBIT:BODY:POSITION.
			LOCAL t2entry IS  nextnode:ETA.
			
			//position vector of the manoeuvre node
			LOCAL eta1 IS t_to_eta(SHIP:ORBIT:TRUEANOMALY,t2entry,SHIP:ORBIT:SEMIMAJORAXIS,SHIP:ORBIT:ECCENTRICITY) - SHIP:ORBIT:TRUEANOMALY.
			
			SET shipvec TO rodrigues(shipvec,normvec,eta1).
			
			//next patch parameters + altitude at the node
			LOCAL node_radius IS SHIP:ORBIT:SEMIMAJORAXIS*(1-SHIP:ORBIT:ECCENTRICITY^2)/(1 + SHIP:ORBIT:ECCENTRICITY*COS(eta1)).	
			LOCAL nxtorb_sma IS nextnode:orbit:semimajoraxis.
			LOCAL nxtorb_ecc IS nextnode:orbit:eccentricity.
			
			//true anomalies of node and entry point
			LOCAL node_eta IS 0.
			LOCAL entry_eta IS 0.
			IF nxtorb_ecc>0 {		
					//set node_eta to (nxtorb_sma*(1-nxtorb_ecc^2)/node_radius - 1)/nxtorb_ecc.
					//print node_eta at (1,10).
					//set node_eta to ARCCOS(node_eta).
					set node_eta to nextnode:orbit:trueanomaly.
					set entry_eta to (nxtorb_sma*(1-nxtorb_ecc^2)/entry_radius - 1)/nxtorb_ecc.
					set entry_eta to ARCCOS(limitarg(entry_eta)).
					//we will cross the target altitude at 2 different points in the orbit
					//we are interested in the descending one i.e. before periapsis 
					//therefore compute the eta of the ascending one and subtract tit from 360
					//exploiting the symmetry of the ellipse
					
					SET entry_eta TO 360- entry_eta.
			}

			LOCAL eta2 IS fixangle(entry_eta - node_eta).
			print "node_eta" + node_eta at (1,11).
			print "entry_eta" + entry_eta at (1,12).
			//find the vector corresponding to entry interface
			SET shipvec TO rodrigues(shipvec,normvec,eta2):NORMALIZED*entry_radius.
			
			//time from periapsis of next patch to the node true anomaly
			LOCAL t_node IS eta_to_dt(node_eta,nxtorb_sma,nxtorb_ecc).
			//time from periapsis of next patch to the entry true anomaly
			LOCAL t_entry IS eta_to_dt(entry_eta,nxtorb_sma,nxtorb_ecc).
			//time to entry interface
			SET t2entry TO t2entry + ( t_entry - t_node).
			
			
			//find flight-path angle at entry interface
			local phi is nxtorb_ecc*sin(entry_eta)/(1 + nxtorb_ecc*COS(entry_eta)).
			set phi to ARCTAN(phi).
			
			
			//transform the entry interface to coordinates and
			//rotate it backwards by the time to entry,
			LOCAL interfpos IS pos2vec(shift_pos(shipvec,t2entry)):NORMALIZED*entry_radius.
			
				
			
			
			
			//setup the trajectory simulation
			
			
			
			//rotate backwards the normal vector as well
			SET normvec TO pos2vec(shift_pos(normvec,t2entry)):NORMALIZED.
			
			//find the orbital velocity vector at entry interface
			LOCAL interfvel IS VCRS(normvec,interfpos):NORMALIZED.
			LOCAL orbvmag IS SQRT(  BODY:MU*(2/entry_radius - 1/(nxtorb_sma) ) ).
			SET interfvel TO interfvel*orbvmag.
			SET interfvel TO rodrigues(interfvel,-normvec,phi).
			

			//initialise the internal variables
			LOCAL ICS IS LEXICON(
							 "position",interfpos,
							 "velocity",interfvel
			).
			LOCAL end_conditions IS LEXICON(
								"altitude",15000,
								"surfvel",500
			).
			LOCAL sim_settings IS LEXICON(
							"deltat",20,
							"integrator","rk3",
							"log",FALSE
			).
			LOCAL simstate IS blank_simstate(ICS).

			
			//run the vehicle simulation
			
			SET simstate TO  simulate_reentry(
							sim_settings,
							simstate,
							tgtrwy,
							sim_end_conditions,
							az_err_band,
							roll_ref,
							pitch_ref,
							pitchroll_profiles_entry@,
							TRUE
			).
			

			//fetch the position list for plotting
			SET poslist TO simstate["poslist"].
			
			//calculate the range error for bank optimisation
			LOCAL delta_t IS  TIME:SECONDS - last_T.
			SET last_T TO  TIME:SECONDS.
		
			
			//calculate range error//difference of dist bw interf and target 
			//and interf and end point
			LOCAL tgt_range IS downrangedist(tgtrwy["position"], interfpos).
			LOCAL end_range IS downrangedist(simstate["latlong"], interfpos).
			LOCAL range_err_p IS range_err.
			SET range_err TO end_range - tgt_range. 
			
			//adjust the bank with PID
			
			//PID stuff
			LOCAL P IS range_err.
			LOCAL D IS (range_err - range_err_p)/delta_t.
				
			LOCAL delta_roll IS P*gains["Kp"] + D*gains["Kd"].
			
			SET roll_ref TO MAX(0,MIN(120,roll_ref + delta_roll)).
			
			update_deorbit_GUI(
								t2entry,
								az_error(interfpos,tgtrwy["position"],interfvel),
								tgt_range,
								phi,
								downrangedist(tgtrwy["position"], simstate["latlong"]),
								range_err,
								roll_ref
			).


		
		} ELSE {
			PRINTPLACE("Orbit periapsis is not low enough",30,1,1).
		}
		
		
		IF quitflag {BREAK.}
	}
	close_global_GUI().
	clearvecdraws().
	clearscreen.
}

