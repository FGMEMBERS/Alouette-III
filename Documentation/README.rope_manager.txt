

The Alouette-III is equiped with a flexible winch rope which has a limited capability to simulate interactions with the ground or with external loads. The model-side part is found in Models/Rope, containing the files

* rope.ac (the 3d mesh)
* longline.png (the texture)
* long-line.xml (the animation declarations for the segments)
* rope_definitions.xml (the parameters for the rope manager)

The actual code to simulate the rope is found in Nasal/ as

* ropeanimation.nas

This file reads the definitions runtime and animates the 90 segments of the rope 3d mesh.

Generally the code provides an artistic rendering in which the parameters have to be tuned by the aircraft manager based on rope and load properties, not an ab-initio simulation of rope physics. The behavior of the rope can be controlled via the following properties (defined in rope_definitions,xml):


under /sim/winch/

* segments-reeled-in
The number of segments which are currently on the winch - increasing this parameter decreases the visible rope length.

* load

The amoung of weight handing on the lowest road segment (in arbitrary units - tune dependent on how much air resistance and how much weight a rope segment has, this will influence how much the rope is swept back by wind and airspeed)

* load-damping

The degree to which transverse excitation waves are suppressed by a load. With a parameter of 1, transverse waves will never be damped, with 0.95 they will reach about halfway through the rope, with a value of 0 no transverse excitations will propagate and the rope will act like a solid rod in transverse space. Tune visuals according to how a load swings in transverse direction.

under /sim/winch/rope/

* coil-flag

Whether the rope will coil when touching the ground or lie straight

* coil-factor

How random a coiled rope will look - with 0.0 it will coil in a perfect circle and when uncoiling lie perfectly straight, with 20 it will show some wiggling.

* factor and offset

Length of one rope segment for ground interaction determination, use together with offset to tune the point at which the rope feels the ground (generally to avoid sinking into the ground, this ought to be a little above the actual surface).

* stiffness

How strongly the rope will try to bend back to a straight line when being bent - a stiffness of 0 gives a rope which does not resist any deformation, a value of 15 is a typical winch rope/cable, more will make for a stiffer material.

* damping

How quickly the rope will absorb pendumum motions. The value tells the amplitude after the first oscillation, so if you set it to 1 the motion will stay indefinitely, if set to 0.4 the second oscillation will just have 40% of the amplitude of the first. When the parameter is set to 0, the rope won't move.

* flex-force

The equilibrium stiffness of the rope (resisting bending) in longitudinal direction - determines the shape of the rope under wind loads.

* bend-force

The strength of the airstream-generated force acting on the rope segments in longitudinal direction

