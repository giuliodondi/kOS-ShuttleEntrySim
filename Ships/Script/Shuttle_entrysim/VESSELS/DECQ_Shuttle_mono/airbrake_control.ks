

FUNCTION airbrake_control_factory {

	LOCAL this IS LEXICON().
	
	this:ADD("rudders",LIST(
						SHIP:PARTSDUBBED("ShuttleTailControl")[0]:MODULESNAMED("ModuleControlSurface")[0],
						SHIP:PARTSDUBBED("ShuttleTailControl")[0]:MODULESNAMED("ModuleControlSurface")[1]
					)
	).
	
	this:ADD("bodyflap", SHIP:PARTSDUBBED("ShuttleBodyFlap")[0]:MODULESNAMED("FARControllableSurface")[0]).
	
	this:ADD("max_deploy_rudder", 48).
	this:ADD("max_deploy_bodyflap", -9).
	
	this:ADD("deflection", 0).
	
	this:ADD("activate", {
		FOR bmod IN this["rudders"] {
			bmod:SETFIELD("deploy",TRUE).
		}
		
		IF NOT this["bodyflap"]:GETFIELD("Flp/Splr"). {
			this["bodyflap"]:SETFIELD("Flp/Splr",TRUE).
		}
		wait 0.
		this["bodyflap"]:DOACTION("Activate Spoiler", TRUE).
		WAIT 0.
	}).
	
	this:ADD("deflect",{
		PARAMETER new_deflection.
		
		SET this["deflection"] TO new_deflection.
		
		FOR bmod IN this["rudders"] {
			bmod:SETFIELD("Deploy Angle",this["max_deploy_rudder"]*this["deflection"]). 
		}
		
		this["bodyflap"]:SETFIELD("Flp/Splr dflct",this["max_deploy_bodyflap"]*this["deflection"]).
	}).
	
	this:ADD("deactivate",{
		FOR bmod IN this["rudders"] {
			bmod:SETFIELD("deploy",FALSE).
		}
		
		this["bodyflap"]:DOACTION("Activate Spoiler", FALSE).
	}).

	this["activate"]().
	
	RETURN this.
}