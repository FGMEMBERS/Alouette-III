
# animations for walker-based models
# and co-piloting scripts 
# Thorsten Renk 2017

var movement = {
	new: func (prop_path, speed) {

	 	var m = { parents: [movement] };
	
		m.prop_path = prop_path;
		m.nd_ref_ang =   props.globals.getNode(m.prop_path, 1);
		m.speed = speed;
		m.nd_ref_time = props.globals.getNode("/sim/time/delta-sec", 1);
		m.active = 0;
		m.cur = 0;
		m.tgt = 0;
		return m;
	},

	set_speed: func (speed) {

		me.speed = speed;

	},

	execute: func (target) {

		me.cur = me.nd_ref_ang.getValue();
		me.tgt = target;

		me.active = 1;
		me.execute_loop();

	},


	execute_loop: func {

		var delta = me.nd_ref_time.getValue();
		var inc_max = me.speed * delta;

		var diff = me.tgt - me.cur;

		if (math.abs(diff) < inc_max)
			{
			me.cur = me.tgt;
			me.nd_ref_ang.setValue(me.tgt);
			me.active = 0;
			return;
			}
		else
			{
			if (diff < 0.0)
				{
				me.cur = me.cur - inc_max;
				}
			else
				{
				me.cur = me.cur + inc_max;
				}

			me.nd_ref_ang.setValue(me.cur);

			}
			
		settimer( func {me.execute_loop();} , 0.0);
	},

};


var amelia = {

	init: func {

		# movement-related flags

		me.running_flag = 0;

		me.random_motion = 1;

		me.breath_state = 0.0;
		me.breath_flag = 1;

		# movements

		me.headshake = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[2]/z-deg", 30.0);
		me.nod = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[2]/y-deg", 30.0);

		me.shrug = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[1]/shrug", 0.05);
		me.breath = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[1]/breath", 0.05);


		me.hip_bend = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[1]/y-deg", 30.0);
		me.hip_side = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[1]/z-deg", 30.0);

		me.shoulder_right_x = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[3]/x-deg", 20.0);
		me.shoulder_right_y = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[3]/y-deg", 20.0);
		me.shoulder_right_z = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[3]/z-deg", 20.0);

		me.elbow_right_bend = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[4]/z-deg", 20.0);
		me.elbow_right_twist = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[4]/y-deg", 20.0);

		me.shoulder_left_x = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[6]/x-deg", 20.0);
		me.shoulder_left_y = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[6]/y-deg", 20.0);
		me.shoulder_left_z = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[6]/z-deg", 20.0);

		me.elbow_left_bend = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[7]/z-deg", 20.0);
		me.elbow_left_twist = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[7]/y-deg", 20.0);



		me.upper_right_leg = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[9]/y-deg",  60.0);
		me.lower_right_leg = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[10]/y-deg", 60.0);
		me.right_foot = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[11]/y-deg", 60.0);

		me.upper_left_leg = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[12]/y-deg",  60.0);
		me.lower_left_leg = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[13]/y-deg", 60.0);
		me.left_foot = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[14]/y-deg", 60.0);

		# property node references

		me.nd_ref_acc_x = props.globals.getNode("/accelerations/pilot/x-accel-fps_sec");
		me.nd_ref_acc_y = props.globals.getNode("/accelerations/pilot/y-accel-fps_sec");
		me.nd_ref_delta_t = props.globals.getNode("/sim/time/delta-sec");

		# piloting-related flags

		me.hover_loop_flag = 0;
		me.collective = 1;
		me.collective_step = 0.005;
		me.hover_alt_bias = 0.0;
		me.collective_damping_bias = 0.0;
		me.landing_flag = 0;
		me.hover_speed_fwd = 0.0;
		me.hover_speed_lr = 0.0;

	},

	stop: func {

		if (me.running_flag > 0) {print("Stopping Amelia");}
		me.running_flag = 0;
		gui.menuEnable("amelia-mnu", 0);

	},

	
	start: func {

		if (me.running_flag == 1){return;}

		print("Starting Amelia");
		me.running_flag = 1;
		
		me.run();
		me.run_fast();

		gui.menuEnable("amelia-mnu", 1);
	},

	
	take_controls: func {
		
		setprop("/fdm/jsbsim/systems/amelia/amelia-active", 1);
		me.speak("I'm taking controls!");

		me.hip_bend.execute(10.0);
		me.hip_side.execute(0.0);

		me.shoulder_right_x.execute(-75.0);
		me.shoulder_right_y.execute(-25.0);
		me.shoulder_right_z.execute(-20.0);

		me.elbow_right_bend.execute(60.0);
		me.elbow_right_twist.execute(-5);

		me.elbow_right_twist.set_speed(80.0);

		me.shoulder_left_x.execute(-70.0);
		me.shoulder_left_y.execute(10.0);
		me.shoulder_left_z.execute(0.0);

		me.elbow_left_bend.execute(10.0);
		me.elbow_left_twist.execute(30.0);

		me.upper_right_leg.execute(-120.0);
		me.lower_right_leg.execute(70.0);
		me.right_foot.execute(0.0);

		me.upper_left_leg.execute(-120.0);
		me.lower_left_leg.execute(70.0);
		me.left_foot.execute(0.0);


		setprop("/sim/model/crew/pilot[1]/pose/position/limb[5]/hand-pose", 1);

		me.random_motion = 0;

	},

	relinquish_controls: func {

		setprop("/fdm/jsbsim/systems/amelia/amelia-active", 0);
		me.speak("Your controls!");	

		me.shoulder_right_x.execute(-90.0);
		me.shoulder_right_y.execute(-30.0);
		me.shoulder_right_z.execute(0.0);

		me.elbow_right_twist.set_speed(20.0);

		me.upper_right_leg.execute(-90.0);
		me.lower_right_leg.execute(40.0);
		me.right_foot.execute(0.0);

		me.upper_left_leg.execute(-90.0);
		me.lower_left_leg.execute(40.0);
		me.left_foot.execute(0.0);

		me.hover_speed_lr = 0.0;
		me.hover_speed_fwd = 0.0;

		me.landing_flag = 0;
		me.hover_loop_flag = 0;

		setprop("/fdm/jsbsim/systems/amelia/hover/v-north-tgt", 0.0);
		setprop("/fdm/jsbsim/systems/amelia/hover/v-east-tgt", 0.0);

		me.random_motion = 1;

	},



	run: func {

	if (me.running_flag == 0) {return;}

	# Amelia looks around
	
	var rn = rand();

	if (rn > 0.80)
		{
		var ang1 = (rand() - 0.5) * 60.0;
		var ang2 = (rand() - 0.5) * 10.0 - 10.0;

		if (me.random_motion == 0)
			{
			ang1 = 0.5 * ang1;
			ang2 = ang2 - 10.0;
			}

		me.headshake.execute(ang1);
		me.nod.execute(ang2);
		}


	# Amelia fidgets

	rn = rand();

	if ((rn > 0.6) and (me.random_motion == 1)) 
		{
		var ang = 40.0 + rand() * 10.0;

		me.elbow_right_bend.execute(ang);
		}

	rn = rand();

	if ((rn > 0.6) and (me.random_motion == 1))
		{
		var ang = (rand() - 0.5) * 20.0 + 30.0;

		me.elbow_left_bend.execute(ang);
		}

	# Amelia changes seat position

	rn = rand();

	if ((rn > 0.9) and (me.random_motion == 1))
		{
		var ang = rand() * 10.0;
		me.hip_side.execute(ang);
		}

	# Amelia shrugs
	
	rn = rand();

	if (rn > 0.9)
		{
		me.shrug.execute(1.01);

		settimer (func {me.shrug.execute(1.0); }, 0.5);
		}

	# Amelia taps feet

	rn = rand();

	if ((rn > 0.95) and (me.random_motion == 1))
		{


		me.upper_right_leg.execute(-90.0 - 4.0);
		me.lower_right_leg.execute(40.0 + 6.0);
		settimer (
			  func {
				me.upper_right_leg.execute(-90.0);
				me.lower_right_leg.execute(40.0);
				}, 0.2);
		settimer (
			  func {
				me.upper_right_leg.execute(-90.0 - 4.0);
				me.lower_right_leg.execute(40.0 + 6.0);
				}, 0.4);
		settimer (
			  func {
				me.upper_right_leg.execute(-90.0);
				me.lower_right_leg.execute(40.0);
				}, 0.6);
		settimer (
			  func {
				me.upper_right_leg.execute(-90.0 - 4.0);
				me.lower_right_leg.execute(40.0 + 6.0);
				}, 0.8);
		settimer (
			  func {
				me.upper_right_leg.execute(-90.0);
				me.lower_right_leg.execute(40.0);
				}, 1.0);

		}

	# Amelia moves hands


	rn = rand();

	if ((rn > 0.9) and (me.random_motion == 1))
		{
		var handpos = int(rand() * 3);

		setprop("/sim/model/crew/pilot[1]/pose/position/limb[5]/hand-pose", handpos);

		}
	else if ((rn > 0.8) and (me.random_motion == 1))
		{
		var handpos = int(rand() * 3);

		setprop("/sim/model/crew/pilot[1]/pose/position/limb[8]/hand-pose", handpos);
		}
		
		


	settimer (func {me.run ();}, 1.0);

	},

	run_fast: func {

	if (me.running_flag == 0) {return;}

	# Amelia follows accelerations

		var acc_x = me.nd_ref_acc_x.getValue() - 1.0;		
		if (acc_x > 5.0) {acc_x = 5.0;}
		else if (acc_x < -5.0) {acc_x = -5.0;}	

		me.hip_bend.execute(10.0 - acc_x);


	# Amelia breathes

		me.breath_state = me.breath_state + me.breath_flag * 0.6 * me.nd_ref_delta_t.getValue();
		if (me.breath_state > 1.0) {me.breath_state = 1.0; me.breath_flag = -1;}
		else if (me.breath_state < 0.0) {me.breath_state = 0.0; me.breath_flag = 1;}

		me.breath.execute(1.0 + 0.03 * me.breath_state);

	# Amelia moves stick and pedals

		if (me.random_motion == 0)
			{
			var stick_lateral = getprop("/fdm/jsbsim/animation/lateral-stick-deflection-deg");
	
			me.elbow_right_twist.execute(-5.0 -5.0 * stick_lateral);

			var pedal = getprop("/fdm/jsbsim/animation/pedal-deflection-deg");

			me.left_foot.execute(pedal * 40.0/27.0);
			me.right_foot.execute(pedal * -40.0/27.0);

			}


	settimer (func {me.run_fast ();}, 0.0);
	},


	hover: func {



		me.take_controls();

		var current_heading = getprop("/orientation/heading-deg");

		setprop("/fdm/jsbsim/systems/amelia/yaw/heading-tgt", current_heading);

		me.collective = getprop("/controls/engines/engine[0]/throttle");

		me.hover_loop_flag = 1;
		me.hover_loop();

		#settimer( func {controls.centerFlightControls();}, 0.5);

	},

	hover_end: func {

		me.relinquish_controls();

		me.hover_loop_flag = 0;

		


	},

	land: func {

		setprop("/fdm/jsbsim/systems/amelia/hover/v-north-tgt", 0.0);
		setprop("/fdm/jsbsim/systems/amelia/hover/v-east-tgt", 0.0);

 		me.hover_speed_fwd = 0.0;
		me.hover_speed_lr = 0.0;

		me.landing_flag = 1;

	},

	hover_loop: func {

		if (me.hover_loop_flag == 0) {return;}

		if (getprop("/fdm/jsbsim/animation/rotor0-rotation") > 250.0)
			{
			var alt_agl = 	getprop("/position/altitude-agl-ft");	

			if (alt_agl > 2.75) 
				{
				if (me.landing_flag == 0)
					{me.collective_step = 0.0005;}
				else
					{me.collective_step = 0.0001;}
				}
			else 
				{
				if (me.collective > 0.6) {me.collective_step = 0.02;}
				else {me.collective_step = 0.005;} 

				}

			if (me.landing_flag == 0)
				{

				if (alt_agl < 5.0 + me.hover_alt_bias)
		
					{
					me.collective = me.collective - me.collective_step;
					me.collective_damping_bias = 0.0;
					}
				else if (alt_agl > 30.0 + me.hover_alt_bias)
					{
					var vspeed = getprop("/fdm/jsbsim/velocities/v-down-fps");

					if (vspeed < 0.0)
						{
						me.collective = me.collective + me.collective_step;
						}
					else if (vspeed > 5.0)
						{
						me.collective = me.collective - me.collective_step;
						}
					}
				else if (alt_agl > 15.0 + me.hover_alt_bias)
					{
					me.collective = me.collective + me.collective_step;
					me.collective_damping_bias = 0.0;
					}
				else
					{
					var vspeed = getprop("/fdm/jsbsim/velocities/v-down-fps");
			

					if (vspeed < -3.0)
						{
						me.collective_damping_bias = 0.01;
						}
					else if (vspeed < -2.0)
						{
						me.collective_damping_bias = 0.015;
						}
					else if (vspeed < -1.0)
						{
						me.collective_damping_bias = 0.005;
						}
					else if (vspeed > 3.0)
						{
						me.collective_damping_bias = -0.01;
						}
					else if (vspeed > 2.0)
						{
						me.collective_damping_bias = -0.015;
						}
					else if (vspeed > 1.0)
						{
						me.collective_damping_bias = -0.005;
						}
	
					}

				}

			else # landing is commanded

				{
				me.collective_damping_bias = 0;
				me.collective = me.collective + me.collective_step;


				if (me.collective > 1.0)
					{
					me.collective = 1.0;
					me.hover_loop_flag = 0;

					me.speak("Here we are.");
					
					me.relinquish_controls();

					}

				}

			setprop("/controls/engines/engine[0]/throttle", me.collective + me.collective_damping_bias - 0.005 * me.hover_alt_bias);

			}
		
		settimer (func {me.hover_loop ();}, 0.2);


	},

	request_parse: func {


		var request = getprop("/sim/model/crew/pilot[1]/request-string");


		if (request == "... take off?")
			{
			var alt_agl = getprop("/position/altitude-agl-ft");
			
			if (alt_agl < 3.0)
				{
				if (crew.amelia.hover_loop_flag == 0)
					{
					crew.amelia.hover();
					}
				}
			else
				{
				me.speak("In case you didn't notice, we are in the air.");
				}
			

			}
		else if (request == "... hover lower?")
			{
			var alt_agl = getprop("/position/altitude-agl-ft");
			
			if (alt_agl < 3.0)
				{
				if (crew.amelia.hover_loop_flag == 0)
					{
					me.speak("Shouldn't we take off first?");
					return;

					}
				}
			else
		   		{
				if (me.hover_alt_bias <  0.0)
					{
					me.speak("Do you want to land? Then say so.");
					}
				else
					{
					me.speak(me.get_affirm_string());
					me.hover_alt_bias = crew.amelia.hover_alt_bias - 2.0;
					}
				}

				

			}
		else if (request == "... hover higher?")
			{
			var alt_agl = getprop("/position/altitude-agl-ft");
			
			if (alt_agl < 3.0)
				{
				if (me.hover_loop_flag == 0)
					{
					me.speak("Shouldn't we take off first?");
					return;

					}
				}
			else
		   		{
				if (me.hover_alt_bias >  13.8)
					{
					me.speak( "High enough for hover flight I think...");
					}
				else
					{
					me.speak(me.get_affirm_string());
					me.hover_alt_bias = me.hover_alt_bias + 2.0;
					}
				}

				

			}
		else if (request == "... land?")
			{
			var alt_agl = getprop("/position/altitude-agl-ft");
			
			if (alt_agl < 2.6)
				{
				me.speak("We seem to be on the ground.");
				return;
				}

			if (me.hover_loop_flag == 0)
				{
				me.speak("We need to hover before we can land.");
				return;
				}

			else
				{
				me.speak(me.get_affirm_string());
				me.land();
				}


			}
		else if (request == "... give me controls?")
			{
			if (me.hover_loop_flag == 1)
				{
				me.speak(me.get_affirm_string());

				me.relinquish_controls();
				}
			else
				{
				me.speak("You are already flying - how did you miss that?");
				}

			}

		else if (request == "... take controls?")
			{
			if (me.hover_loop_flag == 0)
				{
				me.speak(me.get_affirm_string());

				me.hover();
				}
			else
				{
				me.speak("I am already flying, genius.");
				return;
				}

			}
		else if (request == "... hover more forward?")
			{

			if (me.hover_loop_flag == 0)
				{
				me.speak("You are in control right now.");
				return;
				}
			else if (me.landing_flag == 1)
				{
				me.speak("Not while we're landing.");
				return;
				}

			var heading = getprop("/orientation/heading-deg") * math.pi/180.0;

			var sh = math.sin(heading);
			var ch = math.cos(heading);

			me.hover_speed_fwd = me.hover_speed_fwd + 1.0;

			me.speak(me.get_affirm_string());
		
			setprop("/fdm/jsbsim/systems/amelia/hover/v-north-tgt", me.hover_speed_fwd * ch -me.hover_speed_lr * sh);
			setprop("/fdm/jsbsim/systems/amelia/hover/v-east-tgt", me.hover_speed_fwd * sh + me.hover_speed_lr * ch);
			}
		else if (request == "... hover more backward?")
			{

			if (me.hover_loop_flag == 0)
				{
				me.speak("You are in control right now.");
				return;
				}
			else if (me.landing_flag == 1)
				{
				me.speak("Not while we're landing.");
				return;
				}

			var heading = getprop("/orientation/heading-deg") * math.pi/180.0;

			var sh = math.sin(heading);
			var ch = math.cos(heading);

			me.hover_speed_fwd = me.hover_speed_fwd - 1.0;

			me.speak(me.get_affirm_string());
		
			setprop("/fdm/jsbsim/systems/amelia/hover/v-north-tgt", me.hover_speed_fwd * ch -me.hover_speed_lr * sh);
			setprop("/fdm/jsbsim/systems/amelia/hover/v-east-tgt", me.hover_speed_fwd * sh + me.hover_speed_lr * ch);
			}
		else if (request == "... hover more left?")
			{

			if (me.hover_loop_flag == 0)
				{
				me.speak("You are in control right now.");
				return;
				}
			else if (me.landing_flag == 1)
				{
				me.speak("Not while we're landing.");
				return;
				}

			var heading = getprop("/orientation/heading-deg") * math.pi/180.0;

			var sh = math.sin(heading);
			var ch = math.cos(heading);

			me.hover_speed_lr = me.hover_speed_lr - 1.0;

			me.speak(me.get_affirm_string());
		
			setprop("/fdm/jsbsim/systems/amelia/hover/v-north-tgt", me.hover_speed_fwd * ch - me.hover_speed_lr * sh);
			setprop("/fdm/jsbsim/systems/amelia/hover/v-east-tgt", me.hover_speed_fwd * sh + me.hover_speed_lr * ch);
			}
		else if (request == "... hover more right?")
			{

			if (me.hover_loop_flag == 0)
				{
				me.speak("You are in control right now.");
				return;
				}
			else if (me.landing_flag == 1)
				{
				me.speak("Not while we're landing.");
				return;
				}

			var heading = getprop("/orientation/heading-deg") * math.pi/180.0;

			var sh = math.sin(heading);
			var ch = math.cos(heading);

			me.hover_speed_lr = me.hover_speed_lr + 1.0;

			me.speak(me.get_affirm_string());

		
			setprop("/fdm/jsbsim/systems/amelia/hover/v-north-tgt", me.hover_speed_fwd * ch - me.hover_speed_lr * sh);
			setprop("/fdm/jsbsim/systems/amelia/hover/v-east-tgt", me.hover_speed_fwd * sh + me.hover_speed_lr * ch);
			}
		else if (request == "... hover still?")
			{

			if (me.hover_loop_flag == 0)
				{
				me.speak("You are in control right now.");
				return;
				}

			me.speak(me.get_affirm_string());

			me.hover_speed_lr = 0.0;
			me.hover_speed_fwd = 0.0;
		
			setprop("/fdm/jsbsim/systems/amelia/hover/v-north-tgt", 0.0);
			setprop("/fdm/jsbsim/systems/amelia/hover/v-east-tgt", 0.0);
			}
		else if (request == "... yaw left?")
			{
			print ("Yaw left");
			if (me.hover_loop_flag == 0)
				{
				me.speak("You are in control right now.");
				return;
				}
			var alt_agl = getprop("/position/altitude-agl-ft");
			
			if (alt_agl < 2.6)
				{
				me.speak("Not while we're on the ground.");
				return;
				}

			var current_tgt = getprop("/fdm/jsbsim/systems/amelia/yaw/heading-tgt");

			me.speak(me.get_affirm_string());

			current_tgt = current_tgt - 5.0;
			if (current_tgt < 0.0) {current_tgt = current_tgt + 360.0;}

			setprop("/fdm/jsbsim/systems/amelia/yaw/heading-tgt", current_tgt);
	

			}
		else if (request == "... yaw right?")
			{
			print ("Yaw right");
			if (me.hover_loop_flag == 0)
				{
				me.speak("You are in control right now.");
				return;
				}
			var alt_agl = getprop("/position/altitude-agl-ft");
			
			if (alt_agl < 2.6)
				{
				me.speak("Not while we're on the ground.");
				return;
				}
			

			var current_tgt = getprop("/fdm/jsbsim/systems/amelia/yaw/heading-tgt");

			me.speak(me.get_affirm_string());

			current_tgt = current_tgt + 5.0;
			if (current_tgt > 360.0) {current_tgt = current_tgt - 360.0;}

			setprop("/fdm/jsbsim/systems/amelia/yaw/heading-tgt", current_tgt);
			}

	},

	takeover_request: func {

		if (getprop("/fdm/jsbsim/animation/amelia") == 0) {return;}

		if (me.hover_loop_flag == 0)
			{

			var alt_agl = getprop("/position/altitude-agl-ft");

			if (alt_agl > 10.0)
				{
				if (getprop("/velocities/groundspeed-kt") > 15.0)
					{
					me.speak("Negative - at least make an attempt to hover first.");
					return;
					}


				me.hover_alt_bias = 12.0; 
				}
			else
				{
				me.hover_alt_bias = 0.0;

				}

			me.hover();

			}
		else
		   	{me.hover_end();}

	},

	get_affirm_string: func {

		var rn = rand();

		if (rn < 0.2)
			{return "Wilco.";}
		else if (rn < 0.4)
			{return "Sure thing.";}
		else if (rn < 0.6)
			{return "Affirmative.";}
		else if (rn < 0.8)
			{return "Okay.";}
		else
			{return "Roger.";}


	},

	get_deny_string: func {

		var rn = rand();

		if (rn < 0.2)
			{return "Negative.";}
		else if (rn < 0.4)
			{return "Can't do that.";}
		else if (rn < 0.6)
			{return "No way.";}
		else if (rn < 0.8)
			{return "Not now.";}
		else
			{return "Impossible.";}


	},

	speak: func (string) {

		me.headshake.set_speed(80.0);
		me.headshake.execute(45.0);
		me.nod.execute(-10.0);

		settimer ( func { me.headshake.set_speed(30.0);}, 2.0);
		
		setprop("/sim/messages/copilot", string);

	},
	

};



amelia.init();
