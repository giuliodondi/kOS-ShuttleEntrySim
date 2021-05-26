[![License: CC BY 4.0](https://licensebuttons.net/l/by/4.0/80x15.png)](https://creativecommons.org/licenses/by/4.0/)




# Kerbal Space Program Shuttle Entry and Approach Guidance

**PLEASE Read along with watching the demonstration videos at https://youtu.be/5VkAmHpXwn8 and https://youtu.be/oMyd0d86eV4**


# Remarks

These scripts have been tested in Kerbal Space Program 1.8.1 and 1.9.1.
They are designed to do one single thing: to provide deorbit and reentry guidance for the Space Shuttle System in RSS/Realism Overhaul. Only DECQ's Shuttle is supported at the moment. 

The scripts are not calibrated to work in stock KSP or with anything other than the Space Shuttle.
I'm sure they can be modified accordingly but it's not a trivial task. I do not play stock KSP and do not plan on ever releasing a version of these scripts for it. 

This code is provided as is, please keep in mind I am not a professional programmer nor an experienced mod maker. The script has most likely has several bugs within that I didn't discover with enough testing, and is certainly not the most efficient way to implement this kind of functionality. 

I will welcome bug reports or improvement suggestions, although I make no promise to act on them promptly or ever.
I will not be available around the clock to help you get it working, I do not have the time unfortunately.
If you decide to modify the code yourself you do so 100% on your own.

# Installation

**Required mods:**
- A complete install of RSS/Realism Overhaul with Ferram Aerospace Resarch. INCOMPATIBLE WITH FAR 0.16.0.2, use 0.16.0.1 or below.
- Kerbal Operating System
- DECQ's Space Shuttle System mod, this fork seems to be the most up-to-date : https://github.com/DylanSemrau/Space-Shuttle-System
- RO configs that come with the Realism Overhaul package

**NOTE:** the RO configs should have FAR definitions for wing surfaces. The script may still work with other configs that do not define explicitly the FAR parameters, but the aerodynamic behaviour is going to be different and thus the guidance scheme needs some adaptations.

**Mods not required for the script but de-facto needed to use it:**
- Kerbal Konstructs to place runways to land on, they must be at least 2x longer than the stock KSC runway.
- Some mod to display the surface-relative trajectory in the map view. I recomment Trajectories or the (awesome but challenging) Principia mod

You will find two folders: 
- **GameData/kOS-Addons**
- **Scripts**

Make sure to put **kOS-Addons** inside your GameData folder. **WITHOUT THIS THE SCRIPTS WILL NEVER WORK.**
That's the plugin made by me which provides a way for kOS to query aerodynamic data from Ferram Aerospace. 
Documentation available at https://github.com/giuliodondi/kOS-Ferram


Put the contents of the Scripts folder inside Ship/Scripts so that kOS can see all the files.
In particular, you will run two scripts:
- **deorbit.ks** for deorbit targeting
- **entry.ks** for the actual reentry guidance



# Setup

## Setting up the Space Shuttle


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

You need to place two Stock A.I.R.B.R.A.K.E.S. to control airspeed during landing. The split rudder is utterly useless.
They must be Stock A.I.R.B.R.A.K.E.S. and nothing else, otherwise you will need to dig into the script and tell it to look for whatever part you want.
Place them either on the sides of the OMS pods or on the sides of the Engine block. Place them on the surface, do not tuck them inside or KSP will prevent them from deploying. Do not put them on the tail or on the wings or you will introduce a pitching moment.
Make sure to add these A.I.R.B.R.A.K.E.S. to the brakes Action Group.

## Setting up the rest

In the folder **Scripts/Shuttle_entrysim_parameters** you will see a file **landing_sites.ks**. This contains the definition of the Runways available for targeting by the scripts.

You must create the runways wherever you like on Earth using Kerbal Konstructs. You must then write down the coordinates of its halfway point, its length, elevation and heading
and fill in the details in the **landing_sites.ks** folloring the formatting inside. Don't forget the name of the landing site, also.
I provide you with my own landing sites definitions for reference, but I strongly suggest you replace the details with your own measured data for better accuracy.

The file **pitch_profile.ks** specifies the pitch versus surface velocity points that the Entry Guidance will follow. The profile I provide you with is taken directly from the Shuttle technical
documents, remember the Real shuttle had to keep a 38° high angle of attack for thermal control. In KSP we don't _really_ need that, so if you want some extra range you can bring it down to 35°.
Bear in mind that you will be able to adjust the initial pitch value in flight, more about that later.

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

## Entry

Warp until you enter the atmosphere. Immediately have the nose pointed forward and up about 38° and wings level. It's not important to be precise.
Disable the nose cabin RCS jets to save RCS, you don't need them, but keep all the rear RCS jets on for now. Transfer all the RCS fuel in the nose to the OMS pods.

Run **entry.ks*, this opens the main reentry guidance window.  
Select immediately the correct landing site. **DOUBLE CHECK!!**

The script will not take over control immediately.
You will see the two sliders displaying the current input values of pitch and roll. These can be manually adjusted or the script can do it automatically.

The GUI has an "Enable SAS" button, which will engage the sliders and manoeuvre the Shuttle to the attitude specified. If disabled it will try to maintain present attitude.
Set the sliders to 0° roll and 38° pitch and toggle the _Enable SAS_ button. The script will have control of the Shuttle's attitude.


Regardless of what control mode is engaged, the script will run a background trajectory simulation and display the result on the left side of the window. 
The important figures are:
- "Downrange error",  where positive error means overshoot and negative means undershoot,
- "Relative bearing", where positive angle means we will need to turn right to head towards the landing site, and negative to the left.

Theoretically it is possible to fly the reentry manually adjusting the sliders based on the numbers on the left.

Wait until you are below 120 km  and press the "Enable Guidance" button. This will instead create the pitch and roll profiles (angles as functions of surface velocity) and adjust them based on reference values.
The roll reference value is optimized iteration after iteration to try to drive the Downrange Error to zero. The optimal value is displayed as "Reference Roll".

The Pitch reference value is the current pitch value, which is used to adjust the built-in pitch profile. The script basically has a table of velocity-pitch points that define 
a segmented line, then given the current value of velocity the right valie of pitch is extrapolated.
The script, however, leaves the highest velocity-pitch point free, and will update it with whatever value is currently on the slider. 

The point is that if the Shuttle is very far from the runway at the beginning of re-entry, the optimal reference roll value will be low to reduce drag and increase range.
But the roll value must not be too low or the Shuttle will be unable to align itself with the runway. It must be at least 30-35° but a much better margin is 45-50°.

The initial pitch value is then left free so that if the reference roll is too low, the pitch can be decreased to decrease overall drag. The script will automatically adjust 
and find a higher value of roll which is better for cross-range control as I explained.
After the Shuttle slows down below the highest velocity-pitch point, this is frozen and the pitch slider will lock onto the pitch value specified by the profile.


The script is programmed to start banking once the 90km line is crossed. It will keep the commanded roll angle frozen to zero before that.
After this it will handle roll reversals automatically based on the "Relative bearing" value.
**Make sure the KSP SAS (i.e. the "T" key) is OFF and that you have full RCS control (no fine controls). Otherwise kOS will freak out or be unable to keep control during a roll reversal.**

Below 80km, pitch and roll RCS controls should be disabled since the elevons and body flap should have enough authority to handle it. This will save RCS fuel.
Double check that the Body Flap and Elevon trim is actually working, or adjust the values manually if it is not.
Yaw RCS should be left on until 30km and below mach 5, at which point the Shuttle should have pitched down below 20° and the rudder gains enough authority.

## Approach

There is a button to switch to Approach guidance, you must disengage Guidance and SAS prior to switching.

Do not switch to approach until you're below 25 km and ~30 km from the target, for three reasons:
- by that time your pitch will be below 20° and thus the rudder is finally effective
- if you disconnect far away from the site you will most likely not fly the pitch-roll profile exactly and thus the range calculatons are meaningless
- when transitioning between entry and approach guidance, the script calculates which landing site you're closest to and locks it . If you transition far away you might be closest to a different landing site than the one you planned.


Using the buttons, up at the top, choose a combination runway/HAC side based on your inbound heading and how far you are from the actual runway. 
To simulate a real Shuttle approach you should fly over the runway and turn around a HAC on the opposide side of where you came from.
If you're low on energy pick the runway and HAC side nearest to you to reduce the distance to be travelled.

Keep in mind that the approach path is completely dumb and oblivious to your energy state, contrary to the real Space Shuttle Guidance. 

Speedbrakes are controlled either manually using the throttle slider or automatically by the script. A button lets you switch between the modes.
Leave them on manual and closed until you are stabilised on the descent profile and the pipper is mostly centered, you don't want to waste energy until you are sure 
you have plenty to spare.

Needless to say, to fly the shuttle manually it's best to use a flight stick or, at the very least, some kind of gaming controller. 
Even so, following the pipper around the HAC is hard. It doesn't need to be very centered but it should not escape beyond the GUI window. It is especially important to be on profile 
near the end of the HAC turn since during the final descent on glideslope there is not much time to get back on profile. It takes practice.



