

									//	NAVIGATION FUNCTIONS


//GEBERAL NAVIGATION FUNCTIONS 


//given a position vector returns altitude above the body datum
FUNCTION bodyalt {
	PARAMETER pos.
	
	RETURN pos:MAG - BODY:RADIUS.

}

//converts an inertial velocity into a body-relative velocity
//alos needs the current position vector
FUNCTION surfacevel {
	PARAMETER orbvel.
	PARAMETER pos.

	RETURN orbvel -  vcrs(BODY:angularvel, pos).
}




//convert earth-fixed longitude TO celestial longitude
FUNCTION convert_long {
	parameter earthlong.
	parameter mode.

	if mode=1 {
	set earthlong TO earthlong + BODY:ROTATIONANGLE.
	}
	ELSE if mode=0 {
	set earthlong TO earthlong +360 - BODY:ROTATIONANGLE.
	}
	RETURN fixangle(earthlong).
}

//converts Geocoordinates to a position vector 
FUNCTION pos2vec {
	PARAMETER pos.

	RETURN pos:POSITION - SHIP:ORBIT:BODY:POSITION.
}

//converts a position vector to Geocoordinates
function vec2pos {
	parameter posvec.
	//sphere coordinates relative to xyz-coordinates
	local lat is 90 - vang(v(0,1,0), posvec).
	//circle coordinates relative to xz-coordinates
	local equatvec is v(posvec:x, 0, posvec:z).
	local phi is vang(v(1,0,0), equatvec).
	if equatvec:z < 0 {
		set phi to 360 - phi.
	}
	//angle between x-axis and geocoordinates
	local alpha is vang(v(1,0,0), latlng(0,0):position - ship:body:position).
	if (latlng(0,0):position - ship:body:position):z >= 0 {
		set alpha to 360 - alpha.
	}
	return latlng(lat, phi + alpha).
}



//moves a position along the surface of the body by a given time 
//mimics the body's rotation on its axis
FUNCTION shift_pos {
	PARAMETER pos.
	PARAMETER dt.
	
	IF pos:ISTYPE("geocoordinates") {
		SET pos TO pos2vec(pos).
	}
	
	LOCAL out IS R(0, BODY:angularvel:mag * dt* constant:RadToDeg, 0)*pos.
	
	RETURN vec2pos(out).


}



//great-circle distance between two positions
FUNCTION greatcircledist {
	parameter tgt_pos.
	parameter pos.
	
	IF tgt_pos:ISTYPE("geocoordinates") {
		SET tgt_pos TO pos2vec(tgt_pos).
	}
	IF pos:ISTYPE("geocoordinates") {
		SET pos TO pos2vec(pos).
	}
	
	LOCAL angle IS deg2rad(VANG(tgt_pos,pos)).
	return angle*(BODY:RADIUS/1000).
	
}


//haverrsne formula for the distance between two 
FUNCTION downrangedist{
	parameter tgt_pos.
	parameter pos.
	
	IF tgt_pos:ISTYPE("Vector") {
		SET tgt_pos TO vec2pos(tgt_pos).
	}
	IF pos:ISTYPE("Vector") {
		SET pos TO vec2pos(pos).
	}
	
	
	local deltalong is abs(pos:LNG - tgt_pos:LNG )/2.
	local deltalat is abs(pos:LAT - tgt_pos:LAT)/2.

	local x is SIN(deltalat)^2 + COS(pos:LAT)*COS(tgt_pos:LAT)*SIN(deltalong)^2.
	set x to deg2rad(ARCSIN(SQRT(x))).
	return x*2*(BODY:RADIUS/1000).
}

//azimuth angle from current position to target position
FUNCTION bearingg{
	parameter tgt_pos.
	parameter pos.
	
	IF tgt_pos:ISTYPE("Vector") {
		SET tgt_pos TO vec2pos(tgt_pos).
	}
	IF pos:ISTYPE("Vector") {
		SET pos TO vec2pos(pos).
	}
	
	set dl TO fixangle(tgt_pos:LNG - pos:LNG).

	return 	fixangle(ARCTAN2( SIN(dl)*COS(tgt_pos:LAT), COS(pos:LAT)*SIN(tgt_pos:LAT) - SIN(pos:LAT)*COS(tgt_pos:LAT)*COS(dl) )).
}



//returns geolocation of point at given distance & bearing from position
FUNCTION new_position {
	PARAMETER pos.
	PARAMETER dist.
	PARAMETER bng.
	
	IF pos:ISTYPE("Vector") {
		SET pos TO vec2pos(pos).
	}
	
	
	LOCAL alpha1 IS rad2deg(dist*1000/BODY:RADIUS).
	
	LOCAL lat2 IS ARCSIN( SIN(pos:LAT)*COS(alpha1) + COS(pos:LAT)*SIN(alpha1)*COS(bng) ).
	LOCAL lng2 IS pos:LNG + ARCTAN2( SIN(bng)*SIN(alpha1)*COS(pos:LAT) , COS(alpha1) - SIN(pos:LAT)*SIN(lat2) ).
	
	RETURN LATLNG(lat2,lng2).

}







//VEHICLE-SPECIFIC FUNCTIONS


//get current vehicle roll angle 
FUNCTION get_roll {
	LOCAL progvec IS SHIP:srfprograde:vector:NORMALIZED.
	LOCAL shiptopvec IS VXCL(progvec,SHIP:FACING:FOREVECTOR:NORMALIZED):NORMALIZED.
	LOCAL surftopvec IS VXCL(progvec,-SHIP:ORBIT:BODY:POSITION:NORMALIZED):NORMALIZED.
	RETURN signed_angle(shiptopvec,surftopvec,progvec,0).
}
//get current pitch angles
FUNCTION get_pitch {
	RETURN signed_angle(SHIP:srfprograde:vector:NORMALIZED,SHIP:FACING:VECTOR,VCRS(SHIP:srfprograde:vector:NORMALIZED,SHIP:FACING:VECTOR),0).

}


//returns the current flight path angle with respect to the local horizontal
function get_fpa {
	parameter vec.
	PARAMETER geopos.
	
	LOCAL up IS pos2vec(geopos):NORMALIZED.
	LOCAL velproj IS VXCL(up,vec).
	
	LOCAL rightvec IS -VCRS(velproj,vec):NORMALIZED.
	
	RETURN signed_angle(velproj:NORMALIZED,vec:NORMALIZED,rightvec,0).
}

//returns the vehicle azimuth angle, north is 0 and east is 90
//function compass_for {
//	parameter vec.
//	PARAMETER geopos.
//	
//	LOCAL upp IS pos2vec(geopos).
//	
//	LOCAL eastt IS VCRS(upp,V(0,1,0)):NORMALIZED.
//
//	//LOCAL pointing IS SHIP:facing:forevector.
//	LOCAL northh IS vcrs(eastt,upp):NORMALIZED.
//	
//	LOCAL trig_x IS vdot(northh, vec).
//	LOCAL trig_y IS vdot(eastt, vec).
//	
//	LOCAL result IS arctan2(trig_y, trig_x).
//	
//	RETURN fixangle(result).
//	
//}


function compass_for {
	parameter vel.
	PARAMETER pos.
	
	IF pos:ISTYPE("geocoordinates") {
		SET pos TO pos2vec(pos).
	}
	
	LOCAL pos IS pos:NORMALIZED.
	
	LOCAL norm IS VCRS(pos,vel):NORMALIZED.
	
	LOCAL newpos IS rodrigues(pos,norm,0.5).
	
	RETURN bearingg(newpos, pos).
	
}

