#################### long line ####################


var ground_contact = {

	new: func () {

	 	var c = { parents: [ground_contact] };
	
		c.active = 0;

		return c;
	},
	
	mark: func {

		me.active = 1;
		me.position = geo.aircraft_position();
		#print ("Ground contact.");
	},


	delete: func {
		
		me.active = 0;
		#print ("Ground contact removed.");
	},

	get_distance: func (pos) {

		var distance = me.position.distance_to (pos);
		#print (distance);
		return distance;
	},

	get_bearing: func (pos) {

		var bearing = pos.course_to(me.position);
		#print (bearing);

		return bearing;

	},


	get_state: func {

		return me.active;

	},

};


var rope_manager = {

	# rope arrays

	rope_angle_v_array: [],
	rope_angle_vr_array: [],
	rope_angle_r_array: [],

	# aircraft properties

	aircraft_pitch: 0.0,
	aircraft_roll: 0.0,

	# rope properties

	n_segments: 90,
	n_segments_reeled: 88,
	flex_force: 0.0,
	damping: 0.0,
	ground_friction: 0.0,
	
	i_segment_firstground: -1,
	n_segments_piled: 0, 
	n_segments_straight: 0,

	# simulation internal properties

	ground_contact: {},
	rope_animation_run: 0,
	reset_flag: 0,
	aircraft_roll_last: 0.0,
	damping_factor: 0.0,

	ax: 0.0,
	ay: 0.0,
	az: 0.0,

	sum_angle: 0.0,

	dt: 0.0,

	# property node references

	nd_ref_flex_force: props.globals.getNode("/sim/winch/rope/flex-force"),
	nd_ref_damping: props.globals.getNode("/sim/winch/rope/damping"),
	nd_ref_n_segments_reeled: props.globals.getNode("/sim/winch/segments-reeled-in"),

	nd_ref_acc_x: props.globals.getNode("/accelerations/pilot/x-accel-fps_sec"),
	nd_ref_acc_y: props.globals.getNode("/accelerations/pilot/y-accel-fps_sec"),
	nd_ref_acc_z: props.globals.getNode("/accelerations/pilot/z-accel-fps_sec"),

	nd_ref_delta_t: props.globals.getNode("/sim/time/delta-sec"),
	nd_ref_velocity: props.globals.getNode("/velocities/equivalent-kt",1),

	nd_ref_aircraft_pitch: props.globals.getNode("/orientation/pitch-deg"),
	nd_ref_aircraft_roll: props.globals.getNode("/orientation/roll-deg"),

	nd_ref_lat:  props.globals.getNode("/position/latitude-deg"),
	nd_ref_lon:  props.globals.getNode("/position/longitude-deg"),

	init: func {

		me.ground_contact = ground_contact.new();
		me.read_parameters();
		me.init_arrays();

	},

	read_parameters: func {

		me.flex_force = me.nd_ref_flex_force.getValue();
		me.damping = me.nd_ref_damping.getValue();
	},

	init_arrays: func {

		for (var i=0; i< me.n_segments; i=i+1)
			{
			append(me.rope_angle_v_array, 0);
			append(me.rope_angle_vr_array, 0);
			append(me.rope_angle_r_array, 0);
			}

	},

	stop: func {
			
		print ("Ending rope animation.");
		me.rope_animation_run = 0;


	},

	start: func {

		if (me.rope_animation_run == 1) {return;}
		print ("Starting rope animation.");
		me.rope_animation_run = 1;
		me.rope_animation_loop();
	},

	reset: func {


		me.ax = 0;
		me.ay = 0;
		me.az = 0;
		for (var i = 0; i < me.n_segments; i+=1)
			{
			setprop("/sim/winch/rope/pitch"~i, 0);
			setprop("/sim/winch/rope/roll"~i, 0);
			}

	},


	rope_animation_loop : func {


		if (me.rope_animation_run == 0) 
			{

			return;
			}

		  #This is only needed if your flying over "hot" or colidable objects and want a true AGL
		  var lonNode = me.nd_ref_lon.getValue(); #getprop("/position/longitude-deg");
		  var latNode = me.nd_ref_lat.getValue(); #getprop("/position/latitude-deg");
		  var aircraft_alt_ft = getprop("/position/altitude-ft") -13.8;#this was set for the aircrane, I didn't redo it.
		  var true_grnd_elev_ft = geo.elevation(latNode, lonNode) * 3.28;           
		  var true_agl_ft =  aircraft_alt_ft - true_grnd_elev_ft;
		  setprop("position/true-agl-ft", true_agl_ft);

			#var overland = getprop("gear/gear/ground-is-solid");
		  var overland = getprop("fdm/jsbsim/environment/terrain-solid");
		  var altitude = getprop("position/true-agl-ft");
		  var alt_agl = altitude * 0.3048 + getprop("/sim/winch/rope/offset");
		  var segment_length = getprop("/sim/winch/rope/factor") * 0.7;
		  var hitch_offset = getprop("/sim/winch/hitchoffset");

		  me.n_segments_reeled = me.nd_ref_n_segments_reeled.getValue();
		  me.i_segment_firstground = -1;

		  
		  if (me.reset_flag == 1)
			{
			me.reset();
			}


		  if (overland)
		    {

		      if ((alt_agl + 0.25) - ((me.n_segments - me.n_segments_reeled) * segment_length) < 0.0)
					  onground_flag = 1;
				  else
					  onground_flag = 0;
		    }
		  else
			  {
		      #TODO: decide how to handel this event, slowly allow to sink?
			    onground_flag = 0;
			  }


			var stiffness = getprop("/sim/winch/rope/stiffness");
			me.sum_angle = 0.0;
			me.dt = me.nd_ref_delta_t.getValue();
		  	var bend_force = getprop("/sim/winch/rope/bendforce");
			var load = getprop("/sim/winch/load");

			me.aircraft_pitch = me.nd_ref_aircraft_pitch.getValue();
			me.aircraft_roll = me.nd_ref_aircraft_roll.getValue();

			if (onground_flag == 0)
				{
					me.ax = me.nd_ref_acc_x.getValue();
					me.ay = me.nd_ref_acc_y.getValue();
					me.az = me.nd_ref_acc_z.getValue();
				}
			else
				{
					me.ax = 0;
					me.ay = 0;
					me.az = 0;
				}

			var a = math.sqrt(me.ax* me.ax + me.ay*me.ay + me.az*me.az);

			if (a==0.0) {a=1.0;}

			var ref_ang1 = math.asin(me.ax/a) * 180.0/math.pi;
			var ref_ang2 = math.asin(me.ay/a) * 180.0/math.pi;


			me.damping_factor = math.pow(me.damping, me.dt);

			if (onground_flag == 0)
			  {
		      var current_angle = getprop("/sim/winch/rope/pitch"~(1+me.n_segments_reeled));

		      var ang_error = ref_ang1 - current_angle;

		      me.rope_angle_v_array[me.n_segments_reeled] += ang_error * stiffness * me.dt;
		      me.rope_angle_v_array[me.n_segments_reeled] *= me.damping_factor;

		      var ang_speed = me.rope_angle_v_array[me.n_segments_reeled];

		      setprop("/sim/winch/rope/pitch"~(1+me.n_segments_reeled), current_angle + me.dt * ang_speed);

		      var current_roll = getprop("/sim/winch/rope/roll"~(1+me.n_segments_reeled));
		      ang_error = ref_ang2 - current_roll;

		      me.rope_angle_vr_array[me.n_segments_reeled] +=  ang_error * stiffness * me.dt;
		      me.rope_angle_vr_array[me.n_segments_reeled] *= me.damping_factor;

		      ang_speed = me.rope_angle_vr_array[me.n_segments_reeled];

		      var next_roll =  current_roll + me.dt * ang_speed;
		      setprop("/sim/winch/rope/roll"~(1+me.n_segments_reeled), next_roll);

		      # kink excitation
		      var kink =  -(next_roll - me.rope_angle_r_array[me.n_segments_reeled]);

		      kink = kink + me.aircraft_roll - me.aircraft_roll_last;
		      me.aircraft_roll_last = me.aircraft_roll;

		      setprop("/sim/winch/rope/roll"~(2+me.n_segments_reeled),  kink) ;
		      me.rope_angle_r_array[me.n_segments_reeled + 1] = kink;
		    } 
		  else
		    {
		      #lets cargo align with parallel rope if not conditioned as above
		      setprop("/sim/winch/rope/pitch"~(1+me.n_segments_reeled), ref_ang1);
		      setprop("/sim/winch/rope/roll"~(1+me.n_segments_reeled), ref_ang2);
		    }

		  # pull_force was hard coded into the force value below
		  # I separated it out because I changed its value for other condition
		  # that no longer apply to your implementation.
		  var pull_force = 0.05;

			var roll_target = 0.0;


			for (var i = 0; i< me.n_segments_reeled; i=i+1)
				{
			  	setprop("/sim/winch/rope/pitch"~(i+1),0.0);
				setprop("/sim/winch/rope/roll"~(i+1), 0.0);
		
				me.rope_angle_r_array[i] = 0.0;
				}

			for (var i = me.n_segments_reeled; i< me.n_segments; i=i+1)
		    		{
			    	var gravity = me.n_segments - i + load;

				  var velocity = me.nd_ref_velocity.getValue();

				  if (velocity == nil) {velocity = 0;}
				  if (velocity > 500.0) {velocity = 500.0;}

				  var dist_above_ground = alt_agl - (i+1 - me.n_segments_reeled) * segment_length + 0.25;
		 
		      var force = me.flex_force * math.cos(me.sum_angle * math.pi/180.0) * pull_force * velocity;

		      if (overland)
			{
			  if (dist_above_ground < 0.0)
			    {
			      force = force + bend_force * math.cos(me.sum_angle * math.pi/180.0);
			    }
			  else
			    {
			    force = force + me.ground_friction;
			    }
			
			}

				  if (force > 1.0 * gravity) {force = 1.0 * gravity;}

				  var angle = - 180.0 /math.pi * math.atan2(force, gravity);

				  # outside transition zone, make sure segments lie really flat or coil into a pile
				  if (dist_above_ground < -0.5 ) 
					{
					if (me.i_segment_firstground == -1)
						{
						me.i_segment_firstground = i;
				
						if (me.ground_contact.get_state() == 0)
							{
							me.ground_contact.mark();
							

							}

						var aircraft_heading = getprop("/orientation/heading-deg");
					
						var aircraft_pos = geo.aircraft_position();

						var bearing = me.ground_contact.get_bearing(aircraft_pos);
						var dist = me.ground_contact.get_distance(aircraft_pos);
						var rel_bearing =  (aircraft_heading - 180.0) - bearing;


						me.n_segments_straight = int( dist/segment_length);		
						me.n_segments_piled = me.n_segments - i - me.n_segments_straight;
						
						if (dist > 4.0) {dist = 4.0;}

						me.ground_friction = 0.003 * dist * (me.n_segments_straight + me.n_segments_piled);

						if (dist < 1.0) {rel_bearing = 0.0;}

						setprop("/sim/winch/rope/yaw1", rel_bearing);

						}
					# decide whether to pile or straighed ground segments
					if (i> me.n_segments - me.n_segments_piled)
						{
						angle =  3.0 * i  + 127.0 * i - me.sum_angle - me.aircraft_pitch;
						
						#angle = 270.0;
						#if ((math.mod(i,4) == 2) or (math.mod(i,4) == 3)) {angle = 90.0;}
					
						#angle = angle  - me.sum_angle - me.aircraft_pitch;
						#if (math.mod(i, 3) == 1){angle = angle + 127.0 * i;}

						}
					else	
						{

						angle = 270.0- me.sum_angle - me.aircraft_pitch;
						}

					}
				  else
					{
					if ((me.i_segment_firstground == -1) and (i == me.n_segments -1) and (me.ground_contact.get_state() == 1))
						{
						me.ground_contact.delete();
						me.ground_friction = 0.0;
						}
					}

				  me.sum_angle += angle;

		      if (onground_flag == 0)
				    {
				      current_angle = getprop("/sim/winch/rope/pitch"~(i+1));

				      ang_error = angle - current_angle;

				      me.rope_angle_v_array[i] += ang_error * stiffness * me.dt;
				      me.rope_angle_v_array[i] *= me.damping_factor;

				      ang_speed = me.rope_angle_v_array[i];

			  setprop("/sim/winch/rope/pitch"~(i+1), current_angle + me.dt * ang_speed);

				      # the transverse dynamics is largely waves excited by the helicopter

			if ((i== (me.n_segments_reeled + 1)) or (i == me.n_segments_reeled)) # this is set by the kink excitation
			    {
			      continue;
			    }   
			  else
			    {
			      roll_target =  me.rope_angle_r_array[i-1];
			    }

				      ang_error = roll_target - me.rope_angle_r_array[i];

				      me.rope_angle_vr_array[i] += ang_error * stiffness * me.dt;
				      me.rope_angle_vr_array[i] *= me.damping_factor;

				      ang_speed = me.rope_angle_vr_array[i];

			  setprop("/sim/winch/rope/roll"~(i+1), roll_target);
				    }
		      else
			{
			  #rope sections to angle parallel to ground
			  setprop("/sim/winch/rope/pitch"~(i+1), angle);

			  if (i == me.i_segment_firstground + me.n_segments_straight)
				{
			  	setprop("/sim/winch/rope/roll"~(i+1), 0.0);
				}
			  else	
				{
			  	setprop("/sim/winch/rope/roll"~(i+1), 0.0);
				}
			}
		  }

		  # copy the current values into the last step array

		  for (var i = 0; i< me.n_segments; i=i+1)
		    {
		      me.rope_angle_r_array[i] = getprop("/sim/winch/rope/roll"~(i+1));
		    }

		  settimer( func {me.rope_animation_loop();}, 0.0);



	},

};

rope_manager.init();


# listeners to update parameters when changed

setlistener("/sim/winch/rope/flex-force", func {rope_manager.read_parameters();},0,0);
setlistener("/sim/winch/rope/damping", func {rope_manager.read_parameters();},0,0);


