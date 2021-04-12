						//DEORBIT GUI FUNCTIONS 

FUNCTION make_global_deorbit_GUI {
	//create the GUI.
	GLOBAL main_gui is gui(400,350).
	SET main_gui:X TO 550.
	SET main_gui:Y TO 350.
	SET main_gui:STYLe:WIDTH TO 400.
	SET main_gui:STYLe:HEIGHT TO 350.

	set main_gui:skin:LABEL:TEXTCOLOR to RGB(167/255,207/255,147/255).


	// Add widgets to the GUI
	GLOBAL title_box is main_gui:addhbox().
	set title_box:style:height to 35. 
	set title_box:style:margin:top to 0.


	GLOBAL text0 IS title_box:ADDLABEL("<b><size=20>SHUTTLE DEORBIT ASSISTANT</size></b>").
	SET text0:STYLE:ALIGN TO "center".


	
	GLOBAL quitb IS  title_box:ADDBUTTON("X").
	set quitb:style:margin:h to 7.
	set quitb:style:margin:v to 7.
	set quitb:style:width to 20.
	set quitb:style:height to 20.
	function quitcheck {
	  SET quitflag TO TRUE.
	}
	SET quitb:ONCLICK TO quitcheck@.


	main_gui:addspacing(7).



	//top popup menus,
	//tgt selection, rwy selection, hac placement
	GLOBAL popup_box IS main_gui:ADDHLAYOUT().
	SET popup_box:STYLE:ALIGN TO "center".
	SET popup_box:STYLE:WIDTH TO 200.	
	set popup_box:style:margin:h to 100.

	GLOBAL select_tgtbox IS popup_box:ADDHLAYOUT().
	GLOBAL tgt_label IS select_tgtbox:ADDLABEL("<size=15>Target : </size>").
	GLOBAL select_tgt IS select_tgtbox:addpopupmenu().
	SET select_tgt:STYLE:WIDTH TO 100.
	SET select_tgt:STYLE:HEIGHT TO 25.
	SET select_tgt:STYLE:ALIGN TO "center".
	FOR site IN ldgsiteslex:KEYS {
		select_tgt:addoption(site).
	}		
	SET select_tgt:ONCHANGE to { 
		PARAMETER lex_key.	
		SET tgtrwy TO ldgsiteslex[lex_key].		
		SET reset_entry_flag TO TRUE.
	}.		


	GLOBAL all_box IS main_gui:ADDVLAYOUT().
	SET all_box:STYLE:WIDTH TO 400.
	SET all_box:STYLE:HEIGHT TO 350.
	SET all_box:STYLE:ALIGN TO "center".
	
	GLOBAL entry_interface_textlabel IS all_box:ADDLABEL("Entry Interface Data").	
	SET entry_interface_textlabel:STYLE:ALIGN TO "left".
	set entry_interface_textlabel:style:margin:h to 80.
	set entry_interface_textlabel:style:margin:v to 5.
	
	GLOBAL entry_interface_databox IS all_box:ADDVBOX().
	SET entry_interface_databox:STYLE:ALIGN TO "center".
	SET entry_interface_databox:STYLE:WIDTH TO 230.
    SET entry_interface_databox:STYLE:HEIGHT TO 80.
	set entry_interface_databox:style:margin:h to 80.
	set entry_interface_databox:style:margin:v to 0.
	
	
	GLOBAL text1 IS entry_interface_databox:ADDLABEL("Time to interface : ").
	set text1:style:margin:v to -4.
	GLOBAL text2 IS entry_interface_databox:ADDLABEL("Azimuth  error    : ").
	set text2:style:margin:v to -4.
	GLOBAL text3 IS entry_interface_databox:ADDLABEL("Flight-path angle : ").
	set text3:style:margin:v to -4.
	GLOBAL text4 IS entry_interface_databox:ADDLABEL("Flight-path angle : ").
	set text4:style:margin:v to -4.
	
	
	
	GLOBAL entry_terminal_textlabel IS all_box:ADDLABEL("Entry terminal data").	
	SET entry_terminal_textlabel:STYLE:ALIGN TO "left".
	set entry_terminal_textlabel:style:margin:h to 80.
	set entry_terminal_textlabel:style:margin:v to 5.
	
	GLOBAL entry_terminal_databox IS all_box:ADDVBOX().
	SET entry_terminal_databox:STYLE:ALIGN TO "center".	
	SET entry_terminal_databox:STYLE:WIDTH TO 230.	
	SET entry_terminal_databox:STYLE:HEIGHT TO 80.	
	set entry_terminal_databox:style:margin:h to 80.
	set entry_terminal_databox:style:margin:v to 0.	
	
	GLOBAL text5 IS entry_terminal_databox:ADDLABEL("Distance to TGT  : ").
	set text5:style:margin:v to -4.
	GLOBAL text6 IS entry_terminal_databox:ADDLABEL("Range error       : ").
	set text5:style:margin:v to -4.
	GLOBAL text7 IS entry_terminal_databox:ADDLABEL("Ref. bank angle   : ").
	set text6:style:margin:v to -4.	

	


	main_gui:SHOW().
}


FUNCTION update_deorbit_GUI {
	PARAMETER interf_t.
	PARAMETER interf_azerr.
	PARAMETER interf_dist.
	
	PARAMETER fpa.
	PARAMETER term_dist.
	PARAMETER range_err.
	PARAMETER roll0.



		//data output
	SET text1:text TO "Time to interface : " + sectotime(interf_t).
	SET text2:text TO "Azimuth  error    : " + ROUND(interf_azerr,1) + " °".
	SET text3:text TO "Distance to TGT  : " + ROUND(interf_dist,1) + " km".
	SET text4:text TO "Flight-path angle : " + ROUND(fpa,1) + " °".
	SET text5:text TO "Distance to TGT  : " + ROUND(term_dist,1) + " km".
	SET text6:text TO "Range error       : " + ROUND(range_err,1) + " km".
	SET text7:text TO "Ref. bank angle   : " + ROUND(roll0,1) + " °".

}






						//GLOBAL ENTRY GUI FUNCTIONS



FUNCTION make_global_entry_GUI {
	

	//create the GUI.
	GLOBAL main_gui is gui(530,430).
	SET main_gui:X TO 550.
	SET main_gui:Y TO 350.
	SET main_gui:STYLe:WIDTH TO 530.
	SET main_gui:STYLe:HEIGHT TO 430.

	set main_gui:skin:LABEL:TEXTCOLOR to RGB(167/255,207/255,147/255).


	// Add widgets to the GUI
	GLOBAL title_box is main_gui:addhbox().
	set title_box:style:height to 35. 
	set title_box:style:margin:top to 0.


	GLOBAL text0 IS title_box:ADDLABEL("<b><size=20>SHUTTLE ENTRY AND APPROACH ASSISTANT</size></b>").
	SET text0:STYLE:ALIGN TO "center".


	GLOBAL quitb IS  title_box:ADDBUTTON("X").
	set quitb:style:margin:h to 7.
	set quitb:style:margin:v to 7.
	set quitb:style:width to 20.
	set quitb:style:height to 20.
	function quitcheck {
	  SET quitflag TO TRUE.
	}
	SET quitb:ONCLICK TO quitcheck@.


	main_gui:addspacing(7).



	//top popup menus,
	//tgt selection, rwy selection, hac placement
	GLOBAL popup_box IS main_gui:ADDHLAYOUT().
	SET popup_box:STYLE:ALIGN TO "center".
	SET popup_box:STYLE:WIDTH TO 500.	

	GLOBAL select_tgtbox IS popup_box:ADDHLAYOUT().
	GLOBAL tgt_label IS select_tgtbox:ADDLABEL("<size=15>Target : </size>").
	GLOBAL select_tgt IS select_tgtbox:addpopupmenu().
	SET select_tgt:STYLE:WIDTH TO 100.
	SET select_tgt:STYLE:HEIGHT TO 25.
	SET select_tgt:STYLE:ALIGN TO "center".
	FOR site IN ldgsiteslex:KEYS {
		select_tgt:addoption(site).
	}		
	SET select_tgt:ONCHANGE to { 
		PARAMETER lex_key.	
		SET tgtrwy TO ldgsiteslex[lex_key].
		select_rwy:CLEAR.
		FOR rwy IN tgtrwy["rwys"]:KEYS {
			select_rwy:addoption(rwy).
		}	

		
	}.		



	GLOBAL select_rwybox IS popup_box:ADDHLAYOUT().
	//SET select_rwybox:STYLE:ALIGN TO "left".
	GLOBAL select_rwy_text IS select_rwybox:ADDLABEL("<size=15>Runway : </size>").
	GLOBAL select_rwy IS select_rwybox:addpopupmenu().
	SET select_rwy:STYLE:WIDTH TO 50.
	SET select_rwy:STYLE:HEIGHT TO 25.
	SET select_rwy:STYLE:ALIGN TO "center".
	FOR rwy IN tgtrwy["rwys"]:KEYS {
		select_rwy:addoption(rwy).
	}	


	GLOBAL select_sidebox IS popup_box:ADDHLAYOUT().
	//SET select_sidebox:STYLE:ALIGN TO "right".
	GLOBAL select_side_text IS select_sidebox:ADDLABEL("<size=15>HAC Position : </size>").
	GLOBAL select_side IS select_sidebox:addpopupmenu().
	SET select_side:STYLE:WIDTH TO 60.
	SET select_side:STYLE:HEIGHT TO 25.
	SET select_side:STYLE:ALIGN TO "center".
	select_side:addoption("Right" ).
	select_side:addoption("Left" ).




	GLOBAL toggles_box IS main_gui:ADDHLAYOUT().
	toggles_box:addspacing(150).	
	SET toggles_box:STYLE:ALIGN TO "center".
	GLOBAL logb IS  toggles_box:ADDCHECKBOX("Log Data",false).
	toggles_box:addspacing(20).	
	GLOBAL arbkb IS  toggles_box:ADDCHECKBOX("Manual Airbrake",false).


	//modify the speedbrake button 
	IF arbkb:PRESSED {
		SET arbkb:text TO " Auto Airbrake".
		} ELSE {
			SET arbkb:text TO "Manual Airbrake".
		}
		SET arbkb:ONTOGGLE TO {
			parameter b. 
			IF b {
				SET arbkb:text TO " Auto  Airbrake".
			}
			ELSE {
				SET arbkb:text TO "Manual Airbrake".
			}

	}.






	main_gui:SHOW().
}



FUNCTION close_global_GUI {
	main_gui:HIDE().
}

//interface functions between the main loops and the GUI

//generic GUI 

FUNCTION is_autoairbk {
	RETURN arbkb:PRESSED.
}

FUNCTION is_log {
	RETURN logb:PRESSED.
}





					//ENTRY SPECIFIC GUI FUNCTIONS


FUNCTION make_entry_GUI {

					   
	GLOBAL all_box IS main_gui:ADDHLAYOUT().
	SET all_box:STYLE:WIDTH TO 650.
	SET all_box:STYLE:HEIGHT TO 200.


	GLOBAL leftbox IS all_box:ADDVLAYOUT().
	SET leftbox:STYLE:WIDTH TO 220.
	all_box:addspacing(30).	
	GLOBAL rightbox IS all_box:ADDVLAYOUT().
	SET rightbox:STYLE:WIDTH TO 220.
	SET rightbox:STYLE:ALIGN TO "center".


		
	SET main_gui:skin:horizontalsliderthumb:width TO 13.
	SET main_gui:skin:horizontalsliderthumb:HEIGHT TO 13.


	GLOBAL databox IS leftbox:ADDVBOX().
	SET databox:STYLE:ALIGN TO "left".
	set databox:style:padding:h to 10.
	SET databox:STYLE:WIDTH TO 230.
	SET databox:STYLE:HEIGHT TO 120.

	GLOBAL text1 IS databox:ADDLABEL("Relative Bearing : ").
	GLOBAL text2 IS databox:ADDLABEL("Distance to TGT  : ").
	GLOBAL text3 IS databox:ADDLABEL("Downrange error  : ").
	GLOBAL text4 IS databox:ADDLABEL("Reference Roll   : ").

	SET text1:STYLE:ALIGN TO "left".
	SET text2:STYLE:ALIGN TO "left".
	SET text3:STYLE:ALIGN TO "left".
	SET text4:STYLE:ALIGN TO "left".


	leftbox:addspacing(6).	
	GLOBAL switchbox IS leftbox:ADDVLAYOUT().
	GLOBAL switchtext1 IS switchbox:ADDLABEL("        Disable SAS and Guidance").
	GLOBAL switchtext2 IS switchbox:ADDLABEL("              prior to switching   ").
	GLOBAL buttonbox IS switchbox:ADDHLAYOUT().
	buttonbox:addspacing(40).	


	GLOBAL exitb IS  buttonbox:ADDBUTTON("<Size=16>Switch to Approach</Size>").
	set exitb:style:width to 170.
	set exitb:style:height to 30.
	function exitcheck {
		IF (NOT sasb:PRESSED) AND (NOT guidb:PRESSED) { 
			SET stop_entry_flag TO TRUE.
		}
	}
	SET exitb:ONCLICK TO exitcheck@.



	GLOBAL sasbox IS rightbox:ADDHLAYOUT().
	SET sasbox:STYLE:ALIGN TO "center".
	GLOBAL sasb IS  sasbox:ADDCHECKBOX("Enable SAS",false).
	SET sasb:ONTOGGLE TO {
		parameter b. 
		IF b {
			SAS OFF.
			LOCK STEERING TO P_att.
		}
		ELSE {
			UNLOCK STEERING.
			SAS ON.
		}

	}.



	GLOBAL guidb IS  sasbox:ADDCHECKBOX("Enable Guidance",false).


	GLOBAL sliderbox IS rightbox:ADDVLAYOUT().
	SET sliderbox:STYLE:ALIGN TO "center".
	GLOBAL rollslider IS sliderbox:ADDVLAYOUT().
	SET rollslider:STYLE:ALIGN TO "center".
	GLOBAL rolltext IS rollslider:ADDLABEL("Roll:" + ROUND(get_roll(),0)).
	SET rolltext:STYLE:ALIGN TO "center".
	GLOBAL roll_slider IS rollslider:ADDHLAYOUT().
	SET roll_slider:STYLE:ALIGN TO "center".
	GLOBAL rollmin IS roll_slider:ADDBUTTON("<size=18>-</size>").
	GLOBAL slider1 is roll_slider:addhslider(get_roll(),-120,120).
	GLOBAL rollplus IS roll_slider:ADDBUTTON("<size=18>+</size>").
	SET slider1:STYLE:WIDTH TO 210.
	SET slider1:STYLE:HEIGHT TO 13.
	set slider1:onchange to { parameter val.  SET rolltext:TEXT TO "Roll:" + ROUND(val,0). }.


	SET rollmin:STYLE:ALIGN TO "center".
	SET rollmin:STYLE:WIDTH TO 20.
	SET rollmin:STYLE:HEIGHT TO 20.
	SET rollplus:STYLE:ALIGN TO "center".
	SET rollplus:STYLE:WIDTH TO 20.
	SET rollplus:STYLE:HEIGHT TO 20.
	SET rollmin:ONCLICK TO {SET slider1:VALUE TO slider1:VALUE - 1.}.
	SET rollplus:ONCLICK TO {SET slider1:VALUE TO slider1:VALUE + 1.}.



	GLOBAL pchslider IS sliderbox:ADDVLAYOUT().
	SET pchslider:STYLE:ALIGN TO "center".
	GLOBAL pchtext IS pchslider:ADDLABEL("Pitch:" + ROUND(get_pitch(),0)).
	SET pchtext:STYLE:ALIGN TO "center".

	GLOBAL pch_slider IS pchslider:ADDHLAYOUT().
	SET pch_slider:STYLE:ALIGN TO "center".
	GLOBAL pchmin IS pch_slider:ADDBUTTON("<size=18>-</size>").
	GLOBAL slider2 is pch_slider:addhslider(get_pitch(),0,90).
	GLOBAL pchplus IS pch_slider:ADDBUTTON("<size=18>+</size>").
	SET slider2:STYLE:WIDTH TO 210.
	SET slider2:STYLE:HEIGHT TO 13.
	set slider2:onchange to { 
		parameter val.
		//SET pitchv TO val.
		//IF update_reference {
		//	SET pitch_ref TO val.
		//}
		SET pchtext:TEXT TO "Pitch:" + ROUND(val,0). 
	}.


	SET pchmin:STYLE:ALIGN TO "center".
	SET pchmin:STYLE:WIDTH TO 20.
	SET pchmin:STYLE:HEIGHT TO 20.
	SET pchplus:STYLE:ALIGN TO "center".
	SET pchplus:STYLE:WIDTH TO 20.
	SET pchplus:STYLE:HEIGHT TO 20.
	SET pchmin:ONCLICK TO {SET slider2:VALUE TO slider2:VALUE - 1.}.
	SET pchplus:ONCLICK TO {SET slider2:VALUE TO slider2:VALUE + 1.}.



	rightbox:addspacing(30).	
	GLOBAL gainsbox IS rightbox:ADDHLAYOUT().
	//SET gainsbox:STYLE:WIDTH TO 300.
	//SET gainsbox:STYLE:HEIGHT TO 50.
	SET gainsbox:STYLE:ALIGN TO "Center".
	gainsbox:addspacing(30).	
	GLOBAL gains_but IS  gainsbox:ADDBUTTON("<size=16>Modify Controller Gains</size>").
	SET gains_but:STYLE:WIDTH TO 230.
	SET gains_but:STYLE:ALIGN TO "Center".



	function gainsgui {
	  //create the gains gui
		GLOBAL gains_gui is gui(150,130).
		SET gains_gui:X TO main_gui:X.
		SET gains_gui:Y TO main_gui:Y + 500.
		GLOBAL text0 IS gains_gui:ADDLABEL("<size=18>Controller Gains</size>").
		SET text0:STYLE:ALIGN TO "center".
		
		GLOBAL gainsbox IS gains_gui:ADDVLAYOUT().
		SET gainsbox:STYLE:ALIGN TO "center".
		SET gainsbox:STYLE:WIDTH TO 150.
		GLOBAL p_gain IS gainsbox:addhlayout().
		GLOBAL p_gain_text IS p_gain:addlabel("Kp Gain: ").
		GLOBAL Kp_box is p_gain:addtextfield(gains["Kp"]:tostring).
		set Kp_box:style:width to 60.
		set Kp_box:style:height to 18.
		GLOBAL d_gain IS gainsbox:addhlayout().
		GLOBAL d_gain_text IS d_gain:addlabel("Kd Gain: ").
		GLOBAL Kd_box is d_gain:addtextfield(gains["Kd"]:tostring).
		set Kd_box:style:width to 60.
		set Kd_box:style:height to 18.
		GLOBAL hdot_gain IS gainsbox:addhlayout().
		GLOBAL hdot_gain_text IS hdot_gain:addlabel("Khdot Gain: ").
		GLOBAL Khdot_box is hdot_gain:addtextfield(gains["Khdot"]:tostring).
		set Khdot_box:style:width to 60.
		set Khdot_box:style:height to 18.
		GLOBAL alpha_gain IS gainsbox:addhlayout().
		GLOBAL alpha_gain_text IS alpha_gain:addlabel("Kalpha Gain: ").
		GLOBAL Kalpha_box is alpha_gain:addtextfield(gains["Kalpha"]:tostring).
		set Kalpha_box:style:width to 60.
		set Kalpha_box:style:height to 18.
		GLOBAL strmgr_gain IS gainsbox:addhlayout().
		GLOBAL strmgr_gain_text IS strmgr_gain:addlabel("Stopping T: ").
		GLOBAL strmgr_box is strmgr_gain:addtextfield(gains["strmgr"]:tostring).
		set strmgr_box:style:width to 60.
		set strmgr_box:style:height to 18.
		
		set Kp_box:onconfirm to { 
		parameter val.
		set val to val:tonumber(gains["Kp"]).
		if val < 0 set val to 0.
		set gains["Kp"] to val.
		log_gains(gains,gains_log_path).
		}.
		set Kd_box:onconfirm to { 
			parameter val.
			set val to val:tonumber(gains["Kd"]).
			if val < 0 set val to 0.
			set gains["Kd"] to val.
			log_gains(gains,gains_log_path).
		}.
		set Khdot_box:onconfirm to { 
			parameter val.
			set val to val:tonumber(gains["Khdot"]).
			if val < 0 set val to 0.
			set gains["Khdot"] to val.
			log_gains(gains,gains_log_path).
		}.
		set Kalpha_box:onconfirm to { 
			parameter val.
			set val to val:tonumber(gains["Kalpha"]).
			if val < 0 set val to 0.
			set gains["Kalpha"] to val.
			log_gains(gains,gains_log_path).
		}.
		set strmgr_box:onconfirm to { 
			parameter val.
			set val to val:tonumber(gains["strmgr"]).
			if val < 0 set val to 0.
			set gains["strmgr"] to val.
			log_gains(gains,gains_log_path).
			SET STEERINGMANAGER:MAXSTOPPINGTIME TO val.
		}.
		
		
		GLOBAL gains_close IS  gains_gui:ADDBUTTON("<size=16>Close</size>").
		SET gains_close:STYLE:WIDTH TO 50.
		SET gains_close:STYLE:ALIGN TO "center".
		//SET quitb:style:width TO 80.
		function gainsclosecheck {
		  gains_gui:HIDE().
		}
		SET gains_close:ONCLICK TO gainsclosecheck@.
		gains_gui:SHOW().
	}
	SET gains_but:ONCLICK TO gainsgui@.


}


FUNCTION clean_entry_gui {
	SET leftbox:STYLE:HEIGHT TO 0.
	SET rightbox:STYLE:HEIGHT TO 0.
	leftbox:DISPOSE().
	rightbox:DISPOSE().
	all_box:DISPOSE().
	//freeze the target site selection 
	SET select_tgt:ENABLED to FALSE.
}

FUNCTION is_guidance {
	RETURN guidb:PRESSED.
}



FUNCTION get_roll_slider {
	RETURN slider1:VALUE.
}

FUNCTION get_pitch_slider {
	RETURN slider2:VALUE.
}


FUNCTION update_entry_GUI {
	PARAMETER rollv.
	PARAMETER pitchv.
	PARAMETER az_err.
	PARAMETER tgt_range.
	PARAMETER range_err.
	PARAMETER roll_ref.
	PARAMETER isguidance.	
	PARAMETER update_reference.

	If isguidance {
		//update the displayed values of roll and pitch
		SET slider1:VALUE TO  rollv.
		IF NOT update_reference {
			SET slider2:VALUE TO  pitchv.
		}
	}
	
	//data output
	SET text1:text TO "<size=15>Relative Bearing :  " + ROUND(az_err,1) + " °</size>".
	SET text2:text TO "<size=15>Distance to TGT  :  " + ROUND(tgt_range,1) + " km</size>".
	SET text3:text TO "<size=15>Downrange error  :  " + ROUND(range_err,1) + " km</size>".
	SET text4:text TO "<size=15>Reference roll   :  " + ROUND(roll_ref,1) + " °</size>".

}










								//APPROACH GUI FUNCTIONS 
								
								
								

FUNCTION make_apch_GUI {

	
	SET select_rwy:ONCHANGE to { 
		PARAMETER rwy.	
		SET runway["heading"] TO tgtrwy["rwys"][rwy]["heading"].
		SET runway["td_pt"] TO tgtrwy["rwys"][rwy]["td_pt"].
		define_hac(runway,apch_params).
	}.
	SET select_side:ONCHANGE to { 
		PARAMETER side.	
		SET runway["hac_side"] TO side.
		define_hac(runway,apch_params).
	}.


	set main_gui:skin:horizontalslider:BG to "Shuttle_entrysim/gui_images/brakeslider.png".
	set main_gui:skin:horizontalsliderthumb:BG to "Shuttle_entrysim/gui_images/hslider_thumb.png".
	set main_gui:skin:horizontalsliderthumb:HEIGHT to 17.
	set main_gui:skin:horizontalsliderthumb:WIDTH to 20.
	set main_gui:skin:verticalslider:BG to "Shuttle_entrysim/gui_images/vspdslider2.png".
	set main_gui:skin:verticalsliderthumb:BG to "Shuttle_entrysim/gui_images/vslider_thumb.png".
	set main_gui:skin:verticalsliderthumb:HEIGHT to 20.
	set main_gui:skin:verticalsliderthumb:WIDTH to 17.


	GLOBAL hud_container IS main_gui:ADDHLAYOUT().
	SET hud_container:STYLE:ALIGN TO "Center".
	SET hud_container:STYLE:WIDTH TO 550.
	SET hud_container:STYLE:HEIGHT TO 350.
	SET hud_container:STYLE:MARGIN:top TO 0.
	hud_container:addspacing(50).


	GLOBAL hud IS hud_container:ADDVLAYOUT().

	GLOBAL hdg IS hud:ADDHLAYOUT().
	SET hdg:STYLE:ALIGN TO "Center".
	SET hdg:STYLe:HEIGHT TO 20.
	hdg:addspacing(150).
	GLOBAL hdg_box IS hdg:ADDHLAYOUT().
	SET hdg_box:STYLe:WIDTH TO 60.
	SET hdg_box:STYLe:HEIGHT TO 20.
	GLOBAL hdg_text IS hdg_box:ADDLABEL("").
	SET hdg_text:STYLE:ALIGN TO "Center".



	GLOBAL hud_main IS hud:ADDHLAYOUT().
	SET hud_main:STYLe:WIDTH TO 400.
	SET hud_main:STYLe:HEIGHT TO 240.
	SET hud_main:STYLE:ALIGN TO "Center".
	hud_main:addspacing(0).


	GLOBAL hud_spd IS hud_main:ADDVLAYOUT().
	SET hud_spd:STYLe:WIDTH TO 60.
	SET hud_spd:STYLE:ALIGN TO "Center".
	hud_spd:addspacing(105).
	GLOBAL spdbox IS hud_spd:ADDHLAYOUT().
	SET spdbox:STYLe:WIDTH TO 60.
	SET spdbox:STYLe:HEIGHT TO 30.
	GLOBAL spd_text IS spdbox:ADDLABEL("").
	SET spd_text:STYLE:ALIGN TO "Center".



	GLOBAL pointbox IS hud_main:addhbox().
	SET pointbox:STYLE:ALIGN TO "Center".
	SET pointbox:STYLe:WIDTH TO 240.
	SET pointbox:STYLe:HEIGHT TO 240.
	set pointbox:style:margin:top to 0.
	set pointbox:style:margin:left to 0.
	SET  pointbox:style:BG to "Shuttle_entrysim/gui_images/bg_marker_square.png".

	GLOBAL diamond IS pointbox:ADDLABEL().
	SET diamond:IMAGE TO "Shuttle_entrysim/gui_images/diamond.png".
	SET diamond:STYLe:WIDTH TO 25.
	SET diamond:STYLe:HEIGHT TO 25.

	//GLOBAL diamond_hmargin IS  pointbox:STYLe:WIDTH*0.458 .
	//GLOBAL diamond_vmargin IS pointbox:STYLE:HEIGHT*0.447.
	SET diamond:STYLE:margin:h TO pointbox:STYLe:WIDTH*0.458 .
	SET diamond:STYLE:margin:v TO pointbox:STYLE:HEIGHT*0.447.



	GLOBAL hud_alt IS hud_main:ADDVLAYOUT().
	SET hud_alt:STYLe:WIDTH TO 60.
	SET hud_alt:STYLE:ALIGN TO "Center".
	hud_alt:addspacing(105).
	GLOBAL altbox IS hud_alt:ADDHLAYOUT().
	SET altbox:STYLe:WIDTH TO 60.
	SET altbox:STYLe:HEIGHT TO 30.
	GLOBAL alt_text IS altbox:ADDLABEL("").
	SET alt_text:STYLE:ALIGN TO "Center".


	GLOBAL vspd_sliderbox IS hud_main:ADDHLAYOUT().
	SET vspd_sliderbox:STYLe:WIDTH TO 20.
	SET vspd_sliderbox:STYLE:ALIGN TO "Center".
	GLOBAL vspd_slider is vspd_sliderbox:addvslider(0,-20,20).
	SET vspd_slider:STYLE:ALIGN TO "Center".
	SET vspd_slider:style:vstretch to false.
	SET vspd_slider:style:hstretch to false.
	SET vspd_slider:STYLE:WIDTH TO 20.
	SET vspd_slider:STYLE:HEIGHT TO 230.




	GLOBAL bottom_box IS hud:ADDHLAYOUT().
	SET bottom_box:STYLe:WIDTH TO 400.
	//SET bottom_box:STYLE:ALIGN TO "left".

	bottom_box:addspacing(30).

	GLOBAL bottom_txtbox IS bottom_box:ADDHLAYOUT().
	SET bottom_txtbox:STYLe:WIDTH TO 185.
	GLOBAL mode_txt IS bottom_txtbox:ADDLABEL("<size=20> ACQ</size>").

	GLOBAL mode_dist_text IS  bottom_txtbox:ADDLABEL( "<size=18>"+"</size>" ).

	bottom_box:addspacing(0).

	GLOBAL spdbk_slider_box IS bottom_box:ADDHLAYOUT().
	GLOBAL spdbk_slider is spdbk_slider_box:addhslider(0,0,1).
	SET spdbk_slider:style:vstretch to false.
	SET spdbk_slider:style:hstretch to false.
	SET spdbk_slider:STYLE:WIDTH TO 110.
	SET spdbk_slider:STYLE:HEIGHT TO 20.





	//gui-related actions for mode switching
	WHEN mode=4 THEN {
		SET select_rwy:ENABLED to FALSE.
		SET select_side:ENABLED to FALSE.
		SET mode_txt:text TO "<size=20> HDG</size>".
		
		
		WHEN mode=5 THEN {
			SET sim_settings["delta_t"] TO 1.
			SET  pointbox:style:BG to "Shuttle_entrysim/gui_images/bg_marker_round.png".
			SET mode_txt:text TO "<size=20> OGS</size>".
		
			
			WHEN mode=6 THEN {
				SET mode_txt:text TO "<size=20>FLARE</size>".
				WHEN ALT:RADAR<200 THEN {
					SET mode_txt:text TO "".
				}
			}
		}
	}

}



//scales the deltas by the right amount for display
//accounting for the diamond window width
FUNCTION diamond_deviation {

	PARAMETER deltas.
	PARAMETER mode.
	
	LOCAL hmargin IS pointbox:STYLe:WIDTH*0.458.
	LOCAL  vmargin IS pointbox:STYLE:HEIGHT*0.447.
	
	LOCAL vdelta IS deltas[1].
	LOCAL hdelta IS deltas[0].
	
	//the vertical multiplier needs to be negative to simulate an ils needle.
	LOCAL vmult iS -1/320.
	
	LOCAL hmult iS 0.04.
	//IF mode=4 {SET hmult TO 2.}
	//IF mode>=5 {SET hmult TO 0.10.}
	
	LOCAL horiz IS hmult*hdelta.
	LOCAL vert IS  vmult*vdelta.


	//transpose the deltas to the interval [0, 1] times the window widths
	LOCAL diamond_horiz IS hmargin*(1 + horiz).
	LOCAL diamond_vert IS vmargin*(1 + vert).

	//clamp them 
	SET diamond_horiz TO CLAMP(diamond_horiz,0,2*hmargin).
	SET diamond_vert TO CLAMP(diamond_vert,0,2*vmargin). 
	

	RETURN LIST(diamond_horiz,diamond_vert).

}



FUNCTION update_apch_GUI {
	PARAMETER pipper_pos.
	PARAMETEr modedist.
	PARAMETER spdbk_val.

	SET diamond:STYLE:margin:h TO pipper_pos[0].
	SET diamond:STYLE:margin:v TO pipper_pos[1]. 
	
	SET vspd_slider:VALUE TO CLAMP(-SHIP:VERTICALSPEED/2,vspd_slider:MIN,vspd_slider:MAX).
	
	SET hdg_text:text TO "<size=18>" + ROUND(compass_for(SHIP:SRFPROGRADE:VECTOR,SHIP:GEOPOSITION),0) + "</size>".
	SET spd_text:text TO "<size=18>" + ROUND(ADDONS:FAR:IAS,0) + "</size>".
	IF SHIP:ALTITUDE>1000 {
		SET alt_text:text TO "<size=18>" + ROUND(SHIP:ALTITUDE/1000,1) + "</size>".
	} ELSE {
		SET alt_text:text TO "<size=18>" + ROUND(SHIP:ALTITUDE,0) + "</size>".
	}	
	
	SET mode_dist_text:text TO "<size=18>" + ROUND(modedist,1) + "</size>".
		
	SET spdbk_slider:VALUE TO spdbk_val.

}