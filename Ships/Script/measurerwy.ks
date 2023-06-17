clearscreen.

RUNONCEPATH("0:/Libraries/misc_library").	
RUNONCEPATH("0:/Libraries/maths_library").	
RUNONCEPATH("0:/Libraries/navigation_library").



print "press AG9 to confirm geoposition 1...." at (0,1).

LOCAL stop IS false.
ON AG9 {
	set stop to true.
}
UNTIL stop{
	WAIT 0.1.
}
LOCAL pos1 IS SHIP:GEOPOSITION.

print "press AG9 to confirm geoposition 2...." at (0,3).

LOCAL stop IS false.
ON AG9 {
	set stop to true.
}
UNTIL stop{
	WAIT 0.1.
}
LOCAL pos2 IS SHIP:GEOPOSITION.

local dist is greatcircledist(pos1, pos2).
local bng is bearingg(pos1, pos2).
local mid IS new_position(pos2,dist/2, bng).

pos_arrow(pos1, "1").
pos_arrow(pos2, "2").
pos_arrow(mid, "mid").

print "distance between locations : " + round(dist*1000,2) at (0,5).
print "bearing between locations : " + round(bng,2) at (0,6).
print "midpoint : " + mid at (0,7).
print "elevation : " + SHIP:ALTITUDE at (0,7).





//draw a vector centered on geolocation for target redesignation
//scales with distance from ship for visibility
FUNCTION pos_arrow {
	PARAMETER pos.
	PARAMETEr stringlabel.
	
	LOCAL start IS pos:POSITION.
	LOCAL end IS (pos:POSITION - SHIP:ORBIT:BODY:POSITION).
	
	VECDRAW(
      start,//{return start.},
      end:NORMALIZED*5000,//{return end.},
      RGB(1,0,0),
      stringlabel,
      1,
      TRUE,
      3
    ).

}