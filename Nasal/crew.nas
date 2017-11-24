
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

		me.running_flag = 0;

		me.breath_state = 0.0;
		me.breath_flag = 1;

		me.headshake = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[2]/z-deg", 30.0);
		me.nod = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[2]/y-deg", 30.0);

		me.shrug = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[1]/shrug", 0.05);
		me.breath = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[1]/breath", 0.05);
	
		me.hip_bend = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[1]/y-deg", 30.0);
		me.hip_side = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[1]/z-deg", 30.0);

		me.elbow_right_bend = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[4]/z-deg", 20.0);
		me.elbow_left_bend = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[7]/z-deg", 20.0);

		me.upper_right_leg = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[9]/y-deg",  60.0);
		me.lower_right_leg = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[10]/y-deg", 60.0);

		me.nd_ref_acc_x = props.globals.getNode("/accelerations/pilot/x-accel-fps_sec");
		me.nd_ref_acc_y = props.globals.getNode("/accelerations/pilot/y-accel-fps_sec");
		me.nd_ref_delta_t = props.globals.getNode("/sim/time/delta-sec");


		me.hover_loop_flag = 0;
		me.collective = 1;
		me.collective_step = 0.005;
		me.hover_alt_bias = 0.0;
		me.collective_damping_bias = 0.0;

	},

	stop: func {

		if (me.running_flag > 0) {print("Stopping Amelia");}
		me.running_flag = 0;

	},

	
	start: func {

		if (me.running_flag == 1){return;}

		print("Starting Amelia");
		me.running_flag = 1;
		
		me.run();
		me.run_fast();

	},



	run: func {

	if (me.running_flag == 0) {return;}

	# Amelia looks around
	
	var rn = rand();

	if (rn > 0.80)
		{
		var ang1 = (rand() - 0.5) * 60.0;
		var ang2 = (rand() - 0.5) * 10.0 - 10.0;

		me.headshake.execute(ang1);
		me.nod.execute(ang2);
		}


	# Amelia fidgets

	rn = rand();

	if (rn > 0.6)
		{
		var ang = 40.0 + rand() * 10.0;

		me.elbow_right_bend.execute(ang);
		}

	rn = rand();

	if (rn > 0.6)
		{
		var ang = (rand() - 0.5) * 20.0 + 30.0;

		me.elbow_left_bend.execute(ang);
		}

	# Amelia changes seat position

	rn = rand();

	if (rn > 0.9)
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

	if (rn > 0.95)
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

	if (rn > 0.9)
		{
		var handpos = int(rand() * 3);

		setprop("/sim/model/crew/pilot[1]/pose/position/limb[5]/hand-pose", handpos);

		}
	else if (rn > 0.8)
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

	settimer (func {me.run_fast ();}, 0.0);
	},


	hover: func {

		setprop("/fdm/jsbsim/systems/amelia/amelia-active", 1);
		setprop("/sim/messages/copilot", "I'm taking controls!");

		var current_heading = getprop("/orientation/heading-deg");

		setprop("/fdm/jsbsim/systems/amelia/yaw/heading-tgt", current_heading);

		me.hover_loop_flag = 1;
		me.hover_loop();

	},

	hover_end: func {

		setprop("/fdm/jsbsim/systems/amelia/amelia-active", 0);
		me.hover_loop_flag = 0;
		setprop("/sim/messages/copilot", "Your controls!");

	},

	hover_loop: func {

		if (me.hover_loop_flag == 0) {return;}

		if (getprop("/fdm/jsbsim/animation/rotor0-rotation") > 250.0)
			{
			var alt_agl = 	getprop("/position/altitude-agl-ft");	

			if (alt_agl > 2.75)
				{
				me.collective_step = 0.0005;
				}
			else 
				{
				if (me.collective > 0.6) {me.collective_step = 0.02;}
				else {me.collective_step = 0.005;} 

				}

			if (alt_agl < 5.0 + me.hover_alt_bias)
		
				{
				me.collective = me.collective - me.collective_step;
				me.collective_damping_bias = 0.0;
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

			setprop("/controls/engines/engine[0]/throttle", me.collective + me.collective_damping_bias - 0.005 * me.hover_alt_bias);

			}
		
		settimer (func {me.hover_loop ();}, 0.2);
	},
	

};



amelia.init();
