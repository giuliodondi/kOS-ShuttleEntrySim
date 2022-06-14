[![License: CC BY 4.0](https://licensebuttons.net/l/by/4.0/80x15.png)](https://creativecommons.org/licenses/by/4.0/)



# Kerbal Space Program Shuttle Entry and Approach Guidance

## updated June 13th 2022

**PLEASE Read along with watching the demonstration videos at https://youtu.be/5VkAmHpXwn8 and https://youtu.be/oMyd0d86eV4 and https://www.youtube.com/watch?v=sIiksBwYEZI&t=2s**


# Remarks

These scripts have been tested in Kerbal Space Program 1.8.1 and 1.9.1.
They are designed to provide deorbit and reentry guidance for the Space Shuttle System in RSS/Realism Overhaul.
The script was originally engineered for DECQ's Shuttle. Support was added for different spacecraft by means of configuration files in the **Scripts/Shuttle_entrysim/VESSELS** directory.

The scripts are not calibrated to work in stock KSP or with anything other than Space Shuttle-like vehicles.
I'm fairly sure they can be modified accordingly but it's not a trivial task. I do not play stock KSP and do not plan on ever releasing a version of these scripts for it. 

This code is provided as is, it is not the most elegant or efficient way to implement this functionality and it is not as robust as I'd like, meaning your mileage will vary depending on how you set everything up. Even I occasionally see some surprises

I encourage bug reports or improvement suggestions, although I make no promise to act on them promptly or ever.
I will not be available around the clock to help you get it working, I do not have the time unfortunately.
If you decide to modify the code yourself you do so 100% on your own.

# Installation

**Required mods:**
- A complete install of RSS/Realism Overhaul with Ferram Aerospace Resarch. Confrmed to work with FAR 0.16.0.1, should now also work with 0.16.0.4
- Kerbal Operating System
- Space Shuttle System mod, SpaceODY's version seems to be the most up-to-date : https://github.com/SpaceODY/Space-Shuttle-System-Expanded.  
  The script is configurable to work with SOCK too and in principle it should work just as well, but I don't fly it often so **YMMV**
- RO configs that come with the Realism Overhaul package, although SpaceODY will overwrite some of them (it's fine)


**Mods not required for the script but de-facto needed to use it:**
- Kerbal Konstructs to place runways to land on, they must be at least 2x longer than the stock KSC runway.
- Some mod to display the surface-relative trajectory in the map view. I recomment Trajectories or the (awesome but challenging) Principia mod
- Tweakscale to adjust the size of the A.I.R.B.R.A.K.E.S. you need to add

You will find two folders: 
- **GameData/kOS-Addons**
- **Script**

Make sure to put **kOS-Addons** inside your GameData folder. **WITHOUT THIS THE SCRIPTS WILL NEVER WORK.**
That's the plugin made by me which provides a way for kOS to query aerodynamic data from Ferram Aerospace. 
Documentation available at https://github.com/giuliodondi/kOS-Ferram


Put the contents of the Scripts folder inside Ship/Script so that kOS can see all the files.
In particular, you will run two scripts:
- **deorbit.ks** for deorbit targeting
- **entry.ks** for the actual reentry guidance



# Setup

## KSP settings

Modify the control mappings in this way:
- pitch axis controlled by the W-S keys
- roll axis controlled with A-D
- yaw axis controlled by Q-E

## Setting up the Space Shuttle in the VAB

**IMPORTANT**  
These scripts are not magic and rely on the Shuttle being easy to control. I can give you hints on what to look out for but ultimately it will be
up to you to ensure that your Shuttle is controllable.
I strongly advise to test controllability by flying a manual reentry and seeing how easy/difficult it is for you to keep a high pitch angle
or lateral stability all the way down


In the VAB adjust the FAR control surface mappings like this: 
- The tail control surface should have +100% yaw authority and +50% roll authority, 23 deflection and the rest to zero. Flap and Spoiler disabled.
- The elevons should have +100% pitch authority, +60% roll authority, -25% AOA authority, 20 deflection and the rest to zero. Flaps enabled, spoilers disabled
- The body flap must have zero authority on everything.  Flaps enabled, spoilers disabled.

Still in the VAB, enable all actuation toggles on the Crew Cabin and both OMS pods. This will give you full control on which RCS jets are active for which attitude direction.

You need to place two Stock A.I.R.B.R.A.K.E.S. re-scaled up to 150% to control airspeed during landing. The split rudder is utterly useless.  
They must be Stock A.I.R.B.R.A.K.E.S. and nothing else, otherwise you will need to dig into the script and tell it to look for whatever part you want.  
Place them either on the sides of the OMS pods or on the sides of the Engine block. Place them on the surface, do not tuck them inside or KSP will prevent them from deploying. Do not put them on the tail or on the wings or you will introduce a pitching moment.
Make sure to add these A.I.R.B.R.A.K.E.S. to the brakes Action Group.

## Setting up the script config files and runways

The folder **Scripts/Shuttle_entrysim/VESSELS** contains the different vehicle config files. By default I provide the **DECQ_Shuttle** folder with the files that I use.  
There are three vehicle config files:
- **gains.ks** which I do not advise touching unless you know what you are doing.
- **pitch_profile.ks** which specifies the pitch versus surface velocity points that the Entry Guidance will follow. The profile I provide you with is taken directly from early Shuttle technical
documents, therefore it as designed to respect the Shuttle's thermal limits. During flight you can take manual control and adjust the pitch to increase or decrease drag, more on this later.
Bear in mind that you will be able to adjust the initial pitch value in flight, more about that later.
- **flapcontrol.ks** which specifies which parts allow for flap control and the angle ranges of motion of each. Here you specify the names of your elevon and body flap parts. The file provided is already good for DECQ shuttle so leave it alone.

In the main folder **Scripts/Shuttle_entrysim** you will see more configuration files. The only one you should pay attention to is **landing_sites.ks**. This contains the definition of the Runways available for targeting by the scripts.

You must create the runways wherever you like on Earth using Kerbal Konstructs. You must then write down the coordinates of its halfway point, its length, elevation and heading
and fill in the details in the **landing_sites.ks** folloring the formatting inside. Don't forget the name of the landing site, also.
I provide you with my own landing sites definitions for reference, but I strongly suggest you replace the details with your own measured data for better accuracy.



# How to use

Refer to this video I made for an actual demonstration :  https://www.youtube.com/watch?v=5VkAmHpXwn8

## Space Shuttle Aerodynamics 101  

The Shuttle has two main aerodynamic quirks: 
- It has a relatively narrow pitch stability region, meaning that proper CG position makes the difference between a Shuttle that can't hold the nose up and a Shuttle that spins like a boomerang.
  You must deplete about 75% of your OMS fuel before reentering or you might be too tail heavy. You must keep 2-3 tonnes for reentry RCS though. If you want to land with payload in the bay,
  where you position it will make all the difference.
  The ultimate authority on whether the Shuttle will be stable and controllable is the FAR Stability Analysis window in the Spaceplane Hangar. I suggest you learn how to read it.
- At a high angle of attack, the tail is completely occluded by the Shuttle's wake and is ineffective. At high mach number the Shuttle is then unstable in Yaw, so You will need a lot of yaw RCS 
  to maintain lateral stability or else you will start rolling around the velocity vector without control. Therefore you must be able to balance pitch well so you save all the RCS for yaw. 
  This effect is only present above about 20° of angle of attack. Below that the tail should be exposed to the air and the rudder effective.

The Entry Guidance has a (experimental) auto-trim functionality that sets the deflection for the Elevons and Body Flap pased on average control surface deflection. For this to work you need to have enabled
Flaps on both Elevons and Body Flap.
Also do not mess with the engines on reentry. The script uses the Gimbal deflection of one of them to deduce how much flap trim is required.

If you did everything correctly you should be able to control the Shuttle below 90km altitude and hold a 40° angle of attack using only the flaps and no pitch RCS.
I will repeat once again the most important thing: **without yaw RCS above 20° pitch you will lose control. Guaranteed.**


## Deorbit


You need to wait until your next orbit trajectory passes reasonably close to the landing site using surface-relative prediction. Use Principia or Trajectories to see that.
The distance between the trajectory and the landing site at the point where they are closest is your _crossrange error_, which you can't really measure in flight.
It's not a stupid idea to eyeball it using Google Earth in a separate window. If you keep it below 700 km the entry guidance should be able to bring you home.
Make sure not to have more than about 4 tons or 180 m/s deltaV worth of OMS propellant before the deorbit burn.

One orbit before your desired landing pass, create a manoeuvre node and adjust it so your periapsis is about 20km high and about 1000km after the landing site.
The program will still display deorbit predictions even if there is no manoeuvre node, as long as your current trajectory brings you deep into the atmosphere.

Then, run **deorbit.ks**. In the GUI window that opens select immediately your desired landing site from the list.
This script extrapolates the conic trajectory from the manoeuvre node to the **Entry Interface** point, where you cross the 122km altitude line. It displays several pieces of data about your
predicted state at entry interface. From there, it simulates the reentry trajectory using the Guidance algorithm and the specified profiles, drawing the trajectory in the Map view and displaying 
data about the final point.
You can then adjust the deorbit burn to set the trajectory the way you like it. Ideally you should aim for a distance between Entry Interace and target of 6500km and the predicted Reference Roll angle should 
be 50° or so.
Sometimes the deorbit simulation predicts too little drag, which means the actual Reference Roll angle you will obtain during reentry might end up being lower. If it's below 35° you will lose the ability to control
cross-range independently from range error and you will miss the target. A 50° angle should leave you with plenty of margin.

Once the deorbit burn is adjusted, close the deorbit planner and perform the burn manually. Remember that the Shuttle engines are angled upwards relative to the nose centreline. Take that into account for a more
accurate burn.

## Entry and TAEM

### Never, ever, EVER engage SAS during Entry and TAEM

Warp until you enter the atmosphere. If your CG is close to the empty Orbiter transfer all the RCS fuel in the nose to the OMS pods,
If you carry payload that shifts the CG aft you might want to keep fuel in the nose tank to balance out. You can see how payloads affect the CG in the Spaceplane Hangar (take away some OMS fuel since you will presumably have burned it suring your mission).

Run **_entry.ks_**, this opens the main reentry guidance window and the HUD.** Move them around to your liking.

### Entry GUI window:
![gui_example](https://github.com/giuliodondi/kOS-ShuttleEntrySim/blob/master/gui_entry.png)

- In the top row you find a button to select the landing site form the list you specified in **landing_sites.ks**
- Next button selects the landing runway. Upon choosing a new landing site, the script will select a random runway to simulate weather variations.
- Next button selects the HAC position. This is also chosen automatically, disregard for now.
- _Log Data_ will write telemetry information in a file in the **Scripts/Shuttle_entrysim/LOGS** folder, once every guidance pass.
- The _Airbrake_ button is a toggle between Manual (off) and Automatic (on) airbrake control. You won't need it until TAEM gidance.
- _Switch to Approach_ forces the program to break out of automatic guidance and take you to Approach. In normal operation you shouldn't need it as the program decides automatically when to switch. Do not press this button above Mach 2 or 20km or you may lose control.
- _Auto Steering_ switches between manual and automatic control of the Orbiter's attitude during reentry. More on this later.
- _Guidance_ turns on the background trajectory optimisation given the landing site you chose
- _Modify Controller Gains_ should **never** be touched unless you read and understood the code and know what you're doing

### After running the script, select and DOUBLE CHECK your landing site!!  
Leave the runway and HAC selection alone unless you want to land on a specific runway.  
Wait until you're below 120km, then enable _Guidance_ and focus on the HUD.

### Entry HUD window:

![entry_hud_example](https://github.com/giuliodondi/kOS-ShuttleEntrySim/blob/master/hud_entry.png)

- _AZ ERROR_ is the angle between your trajectory and the bearing to the target. When it's 0 you are flying directly towards the target. If it's positive the target is to the right, if negative it's to the left
- The square at the centre indicates the nose of the Orbiter. 
- _AOA_ is Angle of Attack, the angle between the nose of the orbiter and the prograde velocity vector. It is always positive even if the nose points below the horizon
- _BANK_ is the angle between the local vertical vector and the plane containing both your prograde and pointing vectors. **When the Shuttle is flying at zero sideslip** it is the angle between the lift vector and the local vertical
- The _PIPPER_ moves around to indicate the values of bank and AOA that Guidance would like to fly right now
- _WING LOAD_ is the lift generated by the wings measured in units of G
- _MACH_ is self-explanatory, above 100km it is not a reliable measurement of speed. 
- _FLAP TRIM_ indicates the flap deflection commanded by the automatic trim controller. The scale depends on the motion range specified in **flapcontrol.ks**. **It does not indicate the KSP controller trim**
- _ALT_ is calculated above the elevation of the landing site (crucial to keep in mind if you're landing at Edwards)
- _VERT SPEED_ is measured in increments of 100 m/s, the slider tops off at +-200 m/s
- _TARGET_DIST_ is in km
- _CONTROL MODE_ changes between **AUTO** when Auto Steering is enabled and **CSS** (Control Stick Steering) when it's on Manual


### On Steering modes

Even when steering is set to manual, it is never _really_ manual like you may be used to flying planes in KSP. Instead the program implements a sort of Fly-By-Wire mechanism.    
The Shuttle's attitude during reentry is determined by Bank and AOA angles. AOA will largely follow the pitch profile you specified in **pitch_profile.ks**, while Bank is optimised by the trajectory simulation to control range.  

When Steering is set to manual, the values of bank and AOA calculated by guidance are **NOT** automatically used to steer the Shuttle, the actual steering bank and AOA are controlled by you the Pilot using WASD or your favourite joystick. If you move the controls around you should see the Shuttle changing slowly its attitude using RCS and the HUD angles reflecting the change in attitude. Do NOT look at the control input indicators in the bottom left as the control surfaces are actuated by kOS accoding to its own steering manager. If you see no movement, click repeatedly on the main KSP window as the cursor may be stuck on a GUI or the kOS terminal.  

When Steering is Automatic, the Shuttle steering angles are wired to the Guidance computed values and so you will see the nose indicator chase the pipper around as it moves. The Manual setting lets you achieve this by hand adjusting the steering to follow the Pipper commands, so you can feel like Joe Engle during STS-2.  
I've seen that there are actually a few benefits to keeping manual control of the Shuttle Steering which I'll explain later on.

### Reentry guidance

The script runs a background trajectory simulation using specified profiles of pitch (AOA) and roll (Bank) angles versus Velocity. The Velocity profile is fixed, while the  Roll profile depends on a parameter "roll_ref" that gets adjusted to drive the range error to zero.  
**Important:** The bank angle commanded by Guidance is _not_ identical to the reference roll parameter, it is designed to ramp down as the Shuttle slows down plus there is a vertical speed modulation logic going on to try to dampen the phugoid behaviour of the trajectory.  

Guidance will command the first roll angle below 100km. The bank is to the same side of the target, so it depends on the sign of the Azimuth error. You will see the pipper shoot off left or right, move your joystick in the same direction to aligh the nose indicator with the pipper.  
Bank angles of 70+ degrees are a bit extreme and indicative of a high-energy reentry (you did your deorbit burn a bit too close to the landing site).  
You can force Guidance to lower the reference bank angle by increasing drag through pitch. When your speed is above the speed of the first velocity-pitch point in the profile you specified, the program will overwrite the pitch value to the one you are flying right now. You can add 2-3° of pitch and hopefully see the bank angle decrease a bit. Conversely, if guidance commands a bank angle of 40- degrees that is indicative of low-energy conditions, so you can decrease pitch to lower drag. Keep in mind the shuttle needs at least 35° of bank to control crossrange, even more if the crossrange is high.  

After the Shuttle slows down below the first pitch-velocity point, the pitch is locked in place, but if you use manual control you can still fly whatever pitch you want to "nudge" reference roll.  
The standard pitch profile used by the Shuttle will ramp down to 28° between Mach 22 and 16, and then down to 16° betwene Mach 6 and 3.

Keep an eye on Azimuth Error, it should move towards zero and then pick up on the other side as the Shuttle continues to bank in the same direction. When the absolute value comes close to 15°, a **roll reversal** is commanded, the pipper will shoot on the opposite side and, if flying manual, you must be ready to adjust attitude quickly.  
As the Shuttle does the roll reversal it passes through zero bank, meaning all the lift is directed upwards for a few moments. You will see vertical speed shoot up and even go positive. The pipper may command an adjustment in pitch when this happens. This is the Pitch Modulation mechanism which tries to quickly change drag if the calculated range error is too large.  
The other advantage of flying manual is that you can always modulate AOA and bank a bit to alter the trajectory. Of course you need to have a feel for how the Shuttle flies during hypersonic entry, in doubt stay close to the pipper. 

Below 80km you theoretically only need Yaw RCS, you can use the actuation toggles to disable the other axes and save RCS if you are low on fuel. **Do NOT run out of RCS or you will lose yaw control**. The Script is much gentler on the controls compared to previous versions but it's not perfect.  
You can also use fine controls to save RCS fuel, but **disengage fine controls during a Roll Reversal or you may lose control.** Below about 18° of pitch, the Rudder is no longer obstructed and becomes effective, you can (and should) disable RCS at this point, unless for some reason the Shuttle is hard to control.


### The Heading Alignment Cilindres (HACs)

![hac](https://github.com/giuliodondi/kOS-ShuttleEntrySim/blob/master/hac.png)

When planning TAEM and approach, you need to have a mental image like this one above. A HAC is a cilinder around which your trajectory wraps to align you with the runway. There is one on either side of the runway centerline. Right/Left are intended looking from the HACs towards the runway, NOT from the runway looking towards the HACs. 
Entry guidance, as stated, selects the runway at random. Then it selects the HAC opposite from your inbound direction, it would be the Right one in the image example. This is to give you margin to manually select a closer HAC if you're low on energy.  
If you're really low on energy, keep in mind you can manually select the closest runway end and the closest HAC to you. This will reduce the distance to fly by 20-30 km.

Given a HAC, the entrance point is calculated as the point whose tangent crosses your present position. During TAEM and approach this point is continuously updated. The entrance point determines how much you have to "sweep around" the HAC and entails a longer or shorter groundtrack. Since the glideslope is a constant (at least during TAEM) a longer HAC groundtrack means the altitude at HAC entrance is also higher.

### TAEM guidance

### This mode is EXPERIMENTAL and doesn't work as well as I would like, nevertheless I find it useful so I kept it in

As mentioned, you need to hit the HAC aiming point at the correct altitude, at least within 100m or so. Additionally you need to be subsonic, as the Shuttle cannot turn around a HAC this tight at M1+.

_Terminal Area Energy Management (TAEM)_ guidance attempts to hit these targets, taking over from Entry guidance which is not accurate enough for this.  
It is entered automatically from Entry guidance at about 100km and Mach 3. From the standpoint of you the Pilot hardly anything changes, you still have a HUD to look at and a pipper to follow with your controls. A minor difference is that the target site is now frozen, although you can still choose runway and HAC.  

There is still a trajectory simulation done in the background and pitch-roll guidance values sent to the HUD, although now the guidance law is different.  
The script no longer uses bank to control range directly as it assumes it has excess energy. Instead the script now uses pitch to control altitude at the end of simulation to drive it to the HAC entrance altitude. Bank angle is simply used to align the trajectory with the HAC entrance point, with a roll angle that depends on the Az error up to a maximum roll.  
Guidance also measures the final velocity, if it's too high then there is some energy to dissipate. In this case, the program will not command a steering roll angle that turns towards the HAC entrance point but _away from it_ instead. By doing this, the next simulation pass will take longer to align itself to the HAC and reach the entrance point, giving the simulated Shuttle time to slow down further. When the HAC entrance speed is low enough, we invert the bank and finally start turning towards the HAC. This behaviour is called **S-Turns** because of the shape of the resulting trajectory.  
TAEM guidance leaves speedbrake on manual control and sets 50% as a default value to generate some more drag. If you see you're not bleeding energy fast enough (say you're 40km away and still going Mach 2) either extend them fully or set them to Auto

This phase is much more iffy than Entry guidance as the more energy there is to dissipate the more likely it is for the Shuttle to do phugoids as the S-turn is started and stopped. In fact I had to use low bank angle limits to prevent Guidance from stalling out the Shuttle. Taking manual control and adjusting pitch and speedbrake a bit suring S-turns helps somewhat.

Assuming everything goes to plan, TAEM will take the Shuttle to a gentle glide, wings mostly level, heading straight towards the HAC entry point at a manageable speed.

If things go bad, remember you have a button to force the program out of TAEM into Approach guidance, remember ot disable auto steer and Guidance or it won't activate.



## Approach

Transitioning into Approach guidance will get rid of some now irrelevant items in the main GUI.  
The HUD is identical to Entry/TAEM but the meaning of some symbols is now different:

![hud_apch](https://github.com/giuliodondi/kOS-ShuttleEntrySim/blob/master/hud_apch.png)

- _VERT SPEED_ is now measured in increments of 20 m/s, the slider tops off at +-40 m/s
- _PITCH_ is the pitch angle between your nose and the horizon, **not the Angle of Attack**
- _ROLL_ is the angle between the lift vector and the local vertical vector. 
- _PITCH TRIM_ now indicates the KSP pitch trim that you set manually with keyboard controls. **There is no auto trim in this phase**
- _APCH PHASE_ indicates which segmet of the approash you are in. ACQ for HAC acquisition, HDG for the turn sround the HAC. OGS for the final descent into the runway and FLARE just before the landing flare
- _PHASE DIST_ is the distance in km to the guidance point for the current approach phase. It is useful to know when the script is abotu to switch phases

The goald of the approach phase is to guide you around the HAC cilindres (see a couple images above) and align you with the runway on the correct glideslope.
Keep in mind that the approach path is completely dumb and oblivious to your energy state, contrary to TAEM guidance or the real Space Shuttle Guidance.   

The program will simulate the Shuttle a couple seconds in the future and measure the deviations from the guidance profile. The diamond-shaped pipper displays this deviation in a way that suggests where the nose should be pointed to correct the error.
Your focus should be on following the pipper diamond around with gentle commands. The pipper will guide you through several approach phases that align the Shuttle with the runway and settle it on the proper glideslope for landing.

Speedbrakes are controlled either manually using the throttle slider or automatically by the script. A button lets you switch between the modes.
Leave them on manual and closed until you are stabilised on the descent profile and the pipper is mostly centered, you don't want to waste energy until you are sure 
you have plenty to spare.

You can (and should) use a little pitch trim to help you during approach. The elevons and body flap will deflect according to the pitch trim setting, you will only need a little.

Needless to say, to fly the shuttle manually it's best to use a flight stick or, at the very least, some kind of gaming controller. 
Even so, following the pipper around the HAC is hard. The pipper is sensitive to control surface deflections and will jitter around if you're hard on the control inputs, that's why you need to be gentle and trim your controls.
The pipper doesn't need to be very centered but it should not escape beyond the GUI window. It is especially important to be on profile 
near the end of the HAC turn since during the final descent on glideslope there is not much time to get back on profile. It takes practice.



