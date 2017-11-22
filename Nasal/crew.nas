
# animations for walker-based models
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

		me.headshake = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[2]/z-deg", 30.0);
		me.nod = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[2]/y-deg", 30.0);

		me.hip_bend = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[1]/y-deg", 30.0);
		me.hip_side = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[1]/z-deg", 30.0);

		me.elbow_right_bend = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[4]/z-deg", 20.0);
		me.elbow_left_bend = movement.new("/sim/model/crew/pilot[1]/pose/position/limb[7]/z-deg", 20.0);

		me.nd_ref_acc_x = props.globals.getNode("/accelerations/pilot/x-accel-fps_sec");
		me.nd_ref_acc_y = props.globals.getNode("/accelerations/pilot/y-accel-fps_sec");




	},

	stop: func {

		print("Stopping Amelia");
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

	# Amelia changes seat

	rn = rand();

	if (rn > 0.9)
		{
		var ang = rand() * 10.0;
		me.hip_side.execute(ang);
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
		

	settimer (func {me.run_fast ();}, 0.0);
	},


	

};



amelia.init();
