
# animations for a reelable rope hanging from an aircraft, possibly carrying a cargo
# Thorsten Renk and Wayne Bragg, 2017


var ground_contact = {


	new: func () {

	 	var c = { parents: [ground_contact] };
	
		c.active = 0;
		c.bearing = 0.0;
		c.dragging_flag = 0;

		return c;
	},
	
	mark: func {

		me.active = 1;
		me.position = geo.aircraft_position();
		#print ("Ground contact.");
	},


	delete: func {
		
		me.active = 0;
		me.dragging_flag = 0;
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

	unset_dragging: func {

		me.dragging_flag = 0;

	},

	do_dragging: func (pos, dt, length_onground) {

		if (me.dragging_flag == 0)
			{
			me.bearing =  pos.course_to(me.position);
			me.dragging_flag = 1;
			}

		var v_north = getprop("/velocities/speed-north-fps");
		var v_east = getprop("/velocities/speed-east-fps");

		var v_ground = math.sqrt(v_north * v_north + v_east * v_east);

		var course = (math.atan2(v_east, v_north) - math.pi) * 180.0/math.pi;
		course = course;
		if (course < 0.0) {course = course + 360.0;}
		else if (course > 360.0) {course = course- 360.0;}

		#print ("Drag bearing is now: ", course);


		#print ("Contact bearing is now: ", me.bearing);

		var dist = pos.distance_to(me.position);

		var ang_error = course - me.bearing;
		if (ang_error < -180.0) 
			{ang_error = ang_error + 360.0;}
		else if (ang_error > 180.0) 
			{ang_error = ang_error - 360.0;}

		var sign = 1;
		
		if (ang_error < 0.0)
			{sign = -1}	

		#print ("Error is now: ", ang_error);	

		var correction = math.abs(ang_error) / 10.0;
		correction = correction * v_ground * dt;
		
		if (correction > math.abs(ang_error))
			{
			me.bearing = course;
			}
		else
			{
			correction = correction * sign;
			me.bearing = me.bearing + correction;
			}
		me.position = pos.apply_course_distance(me.bearing,  1.1 * length_onground);

		return me.bearing;

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
	segment_length: 0.2,
	flex_force: 0.0,
	damping: 0.0,
	stiffness: 0.0,
	load: 0.0,
	bend_force: 0.0,
	load_damping: 1.0,
	ground_friction: 0.0,
	
	coil_flag: 0,
	coil_factor: 0.0,
	coil_angle: 0.0,
	i_segment_firstground: -1,
	n_segments_piled: 0, 
	n_segments_straight: 0,

	# simulation internal properties

	ground_contact: {},
	rope_animation_run: 0,
	reset_flag: 0,
	aircraft_roll_last: 0.0,
	aircraft_pitch_last: 0.0,
	damping_factor: 0.0,
	onground_flag: 0,
	offset: 0,

	ax: 0.0,
	ay: 0.0,
	az: 0.0,

	sum_angle: 0.0,

	dt: 0.0,

	# property node references

	nd_ref_pitch_array: [],
	nd_ref_roll_array: [],

	nd_ref_flex_force: props.globals.getNode("/sim/winch/rope/flex-force"),
	nd_ref_damping: props.globals.getNode("/sim/winch/rope/damping"),
	nd_ref_load: props.globals.getNode("/sim/winch/load"),
	nd_ref_n_segments_reeled: props.globals.getNode("/sim/winch/segments-reeled-in"),
	nd_ref_segment_length: props.globals.getNode("/sim/winch/rope/factor"),
	nd_ref_coil_flag: props.globals.getNode("/sim/winch/rope/coil-flag"),
	nd_ref_coil_factor: props.globals.getNode("/sim/winch/rope/coil-factor"),
	nd_ref_coil_angle: props.globals.getNode("/sim/winch/rope/coil-angle"),
	nd_ref_load_damping: props.globals.getNode("/sim/winch/load-damping"),
	nd_ref_offset: props.globals.getNode("/sim/winch/rope/offset"),
	nd_ref_stiffness: props.globals.getNode("/sim/winch/rope/stiffness"),
	nd_ref_bendforce: props.globals.getNode("/sim/winch/rope/bendforce"),

	nd_ref_acc_x: props.globals.getNode("/accelerations/pilot/x-accel-fps_sec"),
	nd_ref_acc_y: props.globals.getNode("/accelerations/pilot/y-accel-fps_sec"),
	nd_ref_acc_z: props.globals.getNode("/accelerations/pilot/z-accel-fps_sec"),

	nd_ref_delta_t: props.globals.getNode("/sim/time/delta-sec"),
	nd_ref_velocity: props.globals.getNode("/velocities/equivalent-kt",1),

	nd_ref_aircraft_pitch: props.globals.getNode("/orientation/pitch-deg"),
	nd_ref_aircraft_roll: props.globals.getNode("/orientation/roll-deg"),

	nd_ref_lat:  props.globals.getNode("/position/latitude-deg"),
	nd_ref_lon:  props.globals.getNode("/position/longitude-deg"),
	nd_ref_alt:  props.globals.getNode("/position/altitude-ft"),


	init: func {

		me.ground_contact = ground_contact.new();
		me.read_parameters();
		me.init_arrays();

	},

	excitation_test: func {

		setprop("/sim/winch/excitation-test", 10.0);
		settimer ( func {setprop("/sim/winch/excitation-test", 0.0); }, 1.0);

	},

	read_parameters: func {

		me.flex_force = me.nd_ref_flex_force.getValue();
		me.damping = me.nd_ref_damping.getValue();
		me.load = me.nd_ref_load.getValue();
		me.segment_length = me.nd_ref_segment_length.getValue(); 
		me.coil_flag = me.nd_ref_coil_flag.getValue(); 
		me.coil_factor = me.nd_ref_coil_factor.getValue(); 
		me.coil_angle = me.nd_ref_coil_angle.getValue(); 
		me.offset = me.nd_ref_offset.getValue();
		me.stiffness = me.nd_ref_stiffness.getValue();
		me.bend_force = me.nd_ref_bendforce.getValue();

		# the rope for the Alouette is scaled by 0.7 via a global scale animation
		me.segment_length = me.segment_length * 0.7;
		me.load_damping = me.nd_ref_load_damping.getValue();
	},

	init_arrays: func {


		for (var i=0; i< me.n_segments; i=i+1)
			{
			append(me.rope_angle_v_array, 0);
			append(me.rope_angle_vr_array, 0);
			append(me.rope_angle_r_array, 0);

			var nd_string = "/sim/winch/rope/pitch"~(i+1);
			append(me.nd_ref_pitch_array, props.globals.getNode(nd_string));

			nd_string = "/sim/winch/rope/roll"~(i+1);
			append(me.nd_ref_roll_array, props.globals.getNode(nd_string));
			}

	},


	_set_pitch: func (i, value) {

		me.nd_ref_pitch_array[i].setValue(value);

	},

	_get_pitch: func (i) {

		return me.nd_ref_pitch_array[i].getValue();

	},

	_set_roll: func (i, value) {

		me.nd_ref_roll_array[i].setValue(value);

	},

	_get_roll: func (i) {

		return me.nd_ref_roll_array[i].getValue();

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

	_coil_func : func (i) {
		
		var coil = (math.mod(i,5) - 2.0);

		if (coil < -1) {coil = -1;}
		else if (coil > 1) { coil = 1;}

		var ground_factor = (1.0 - me.ground_friction);
		if (ground_factor < 0.0) {ground_factor = 0.0;}

		return me.coil_factor * coil * ground_factor;  ;

	},


	rope_animation_loop : func {


		if (me.rope_animation_run == 0) 
			{

			return;
			}

		  #This is only needed if your flying over "hot" or colidable objects and want a true AGL
		  var lonNode = me.nd_ref_lon.getValue(); 
		  var latNode = me.nd_ref_lat.getValue(); 
		  var aircraft_alt_ft = me.nd_ref_alt.getValue() -13.8; # this was set for the aircrane
		  var true_grnd_elev_ft = geo.elevation(latNode, lonNode) * 3.28;           
		  var true_agl_ft =  aircraft_alt_ft - true_grnd_elev_ft;
		  setprop("position/true-agl-ft", true_agl_ft);


		  var overland = getprop("fdm/jsbsim/environment/terrain-solid");
		  #var altitude = getprop("position/true-agl-ft");
		  var altitude = true_agl_ft;
		  var alt_agl = altitude * 0.3048 + me.offset;

		  me.n_segments_reeled = me.nd_ref_n_segments_reeled.getValue();
		  me.i_segment_firstground = -1;

		  
		  if (me.reset_flag == 1)
			{
			me.reset();
			}


		  if (overland)
		    {

		      if ((alt_agl + 0.25) - ((me.n_segments - me.n_segments_reeled) * me.segment_length) < 0.0)
					{
					me.onground_flag = 1;
					}
				  else
					{
					me.onground_flag = 0;
					}
		    }
		  else
			  {
		      #TODO: decide how to handel this event, slowly allow to sink?
			    me.onground_flag = 0;
			  }


			me.sum_angle = 0.0;
			me.dt = me.nd_ref_delta_t.getValue();


			me.aircraft_pitch = me.nd_ref_aircraft_pitch.getValue();
			me.aircraft_roll = me.nd_ref_aircraft_roll.getValue();

			if (me.onground_flag == 0)
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

			var ref_ang1 = -math.asin(me.ax/a) * 180.0/math.pi;
			var ref_ang2 = math.asin(me.ay/a) * 180.0/math.pi;


			# undo instantaneous pitching effect, accelerations drive this

			#ref_ang1 = ref_ang1 - me.aircraft_pitch + me.aircraft_pitch_last;
			#me.aircraft_pitch_last = me.aircraft_pitch;

			me.damping_factor = math.pow(me.damping, me.dt);

			if (me.onground_flag == 0)
			  {
		          #var current_angle = getprop("/sim/winch/rope/pitch"~(1+me.n_segments_reeled));
			  var current_angle = me._get_pitch(me.n_segments_reeled);

		      	  var ang_error = ref_ang1 - current_angle;

			  me.rope_angle_v_array[me.n_segments_reeled] += ang_error * me.stiffness * me.dt;
			  me.rope_angle_v_array[me.n_segments_reeled] *= me.damping_factor;

			  var ang_speed = me.rope_angle_v_array[me.n_segments_reeled];

			  #setprop("/sim/winch/rope/pitch"~(1+me.n_segments_reeled), current_angle + me.dt * ang_speed);
			  me._set_pitch(me.n_segments_reeled, current_angle + me.dt * ang_speed);

			  var current_roll = getprop("/sim/winch/rope/roll"~(1+me.n_segments_reeled));
			  ang_error = ref_ang2 - current_roll;

			  me.rope_angle_vr_array[me.n_segments_reeled] +=  ang_error * me.stiffness * me.dt;
			  me.rope_angle_vr_array[me.n_segments_reeled] *= me.damping_factor;

			  ang_speed = me.rope_angle_vr_array[me.n_segments_reeled];

			  var next_roll =  current_roll + me.dt * ang_speed;

			  # test code block for kink excitations

			  var excitation_test = getprop("/sim/winch/excitation-test");
			  next_roll = next_roll + excitation_test;

			  #setprop("/sim/winch/rope/roll"~(1+me.n_segments_reeled), next_roll);
			  me._set_roll(me.n_segments_reeled, next_roll);

			  # kink excitation
			  var kink =  -(next_roll - me.rope_angle_r_array[me.n_segments_reeled]);

			  kink = kink + me.aircraft_roll - me.aircraft_roll_last;
			  me.aircraft_roll_last = me.aircraft_roll;

			  #setprop("/sim/winch/rope/roll"~(2+me.n_segments_reeled),  kink) ;
			  me._set_roll(1+ me.n_segments_reeled, kink);

			  me.rope_angle_r_array[me.n_segments_reeled + 1] = kink;
		    } 
		  else
		    {
		      #lets cargo align with parallel rope if not conditioned as above

		      	   #setprop("/sim/winch/rope/pitch"~(1+me.n_segments_reeled), ref_ang1);
		      	   #setprop("/sim/winch/rope/roll"~(1+me.n_segments_reeled), ref_ang2);
	
			   me._set_pitch(me.n_segments_reeled, ref_ang1);
			   me._set_roll(me.n_segments_reeled, ref_ang2);


		    }


		  	var pull_force = 0.05;

			var roll_target = 0.0;


			for (var i = 0; i< me.n_segments_reeled; i=i+1)
				{
			  	#setprop("/sim/winch/rope/pitch"~(i+1),0.0);
				#setprop("/sim/winch/rope/roll"~(i+1), 0.0);

			   	me._set_pitch(i, 0.0);
			   	me._set_roll(i, 0.0);
		
				me.rope_angle_r_array[i] = 0.0;
				}

			for (var i = me.n_segments_reeled; i< me.n_segments; i=i+1)
		    		{
			    	var gravity = me.n_segments - i + me.load;

				  var velocity = me.nd_ref_velocity.getValue();

				  if (velocity == nil) {velocity = 0;}
				  if (velocity > 500.0) {velocity = 500.0;}

				  var dist_above_ground = alt_agl - (i+1 - me.n_segments_reeled) * me.segment_length + 0.25;
		 
		      var force = me.flex_force * math.cos(me.sum_angle * math.pi/180.0) * pull_force * velocity;

		      if (overland)
			{
			  if (dist_above_ground < 0.0)
			    {
			      force = force + me.bend_force * math.cos(me.sum_angle * math.pi/180.0);
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
						#print ("On ground!");
						#print ("setting: ", me.i_segment_firstground);
						if (me.ground_contact.get_state() == 0)
							{
							me.ground_contact.mark();
							

							}

						var aircraft_heading = getprop("/orientation/heading-deg");
					
						var aircraft_pos = geo.aircraft_position();


						var dist = me.ground_contact.get_distance(aircraft_pos);

						me.n_segments_straight = int( dist/me.segment_length);		
						me.n_segments_piled = me.n_segments - i - me.n_segments_straight;

						var bearing = 0;
			
						if (me.n_segments_piled > 0)
							{
						 	bearing = me.ground_contact.get_bearing(aircraft_pos);
							me.ground_contact.unset_dragging();
							}
						else
							{
							bearing = me.ground_contact.do_dragging(aircraft_pos, me.dt, me.segment_length * me.n_segments_straight);
							}


						var rel_bearing =  (aircraft_heading - 180.0) - bearing;



						

						if (dist > 4.0) {dist = 4.0;}

						me.ground_friction = 0.003 * dist * (me.n_segments_straight + me.n_segments_piled);

						if (dist < 0.5) {rel_bearing = 0.0;}

						setprop("/sim/winch/rope/yaw1", rel_bearing);

						}
					# decide whether to pile or straighed ground segments
				
					if ((i == me.n_segments - me.n_segments_piled + 1) or (me.coil_flag == 0))
						{
						angle = 270.0- me.sum_angle - me.aircraft_pitch;
						}

					else if (i> me.n_segments - me.n_segments_piled)
						{
						angle = 0.0;
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
						setprop("/sim/winch/rope/yaw1", 0.0);
						me.ground_friction = 0.0;
						}
					}

				  me.sum_angle += angle;

		      if (me.onground_flag == 0)
				    {

				      if (i > me.n_segments_reeled)
					      {
					      #current_angle = getprop("/sim/winch/rope/pitch"~(i+1));
			   		      current_angle = me._get_pitch(i);

					      ang_error = angle - current_angle;

					      me.rope_angle_v_array[i] += ang_error * me.stiffness * me.dt;
					      me.rope_angle_v_array[i] *= me.damping_factor;

					      ang_speed = me.rope_angle_v_array[i];

				  	      #setprop("/sim/winch/rope/pitch"~(i+1), current_angle + me.dt * ang_speed);			
					      me._set_pitch(i, current_angle + me.dt * ang_speed);
					}

				      # the transverse dynamics is largely waves excited by the helicopter

			if ((i== (me.n_segments_reeled + 1)) or (i == me.n_segments_reeled)) # this is set by the kink excitation
			    {
			      continue;
			    }   
			  else
			    {
			      roll_target =  me.rope_angle_r_array[i-1];
			      roll_target = roll_target * me.load_damping;
			
			    }

				      ang_error = roll_target - me.rope_angle_r_array[i];

				      me.rope_angle_vr_array[i] += ang_error * me.stiffness * me.dt;
				      me.rope_angle_vr_array[i] *= me.damping_factor;

				      ang_speed = me.rope_angle_vr_array[i];

			  #setprop("/sim/winch/rope/roll"~(i+1), roll_target);
			  me._set_roll(i, roll_target);
				    }
		      else
			{
			  #rope sections to angle parallel to ground
			  #setprop("/sim/winch/rope/pitch"~(i+1), angle);
			  me._set_pitch(i, angle);

			  if ((i == me.i_segment_firstground + me.n_segments_straight)  and (me.i_segment_firstground > -1))
				{
				#print ("i is now", i);
				#print ("Firstground is: ", me.i_segment_firstground, " straight: ", me.n_segments_straight);
				var coil = 90.0;

				if (me.coil_flag == 0)
					{
					
					# we want the rope to align with a non-wiggly rope
					# so we have to connect with the right part of the pattern
	
					var coil_cur = me._coil_func(i);
					var coil_next = me._coil_func(i+1);

					#print ("Cur: ", coil_cur, " next: ", coil_next);

					if (coil_cur == 0.0) 
						{
						coil = -1.0 * coil_next;
						}
					else if ((coil_cur > 0.0) and (coil_next > 0.0))
						{
						coil = 0.0;
						}
					else if ((coil_cur < 0.0) and (coil_next < 0.0))
						{
						coil = 0.0;
						}
					else if ((coil_cur > 0.0) and (coil_next < 0.0))
						{
						coil = -1.0 * coil_next;
						}
					else if ((coil_cur < 0.0) and (coil_next == 0.0))
						{
						coil = 1.0 * coil_cur;
						}

					coil = coil + 0.25 * me.coil_factor;
						
					}


			  	#setprop("/sim/winch/rope/roll"~(i+1), coil);
				me._set_roll(i, coil);				
				}

			  else if ((i > (me.i_segment_firstground + me.n_segments_straight)) and (me.i_segment_firstground > -1))
				{

				var coil = (math.mod(i,5) - 2.0) * me.coil_factor + me.coil_angle;
				
				if (me.coil_flag == 0)
					{
					coil = me._coil_func(i);		
					}

			  	#setprop("/sim/winch/rope/roll"~(i+1), coil);
				me._set_roll(i, coil);				
				}
			  else if ((i > me.i_segment_firstground) and (me.i_segment_firstground > -1))
				{
				#setprop("/sim/winch/rope/roll"~(i+1), me._coil_func(i));
				me._set_roll(i, me._coil_func(i));				
				}
			  else
				{
				#setprop("/sim/winch/rope/roll"~(i+1), 0.0);
				me._set_roll(i, 0.0);		
				}		


			}
		  }

		  # copy the current values into the last step array

		  for (var i = 0; i< me.n_segments; i=i+1)
		    {
		      #me.rope_angle_r_array[i] = getprop("/sim/winch/rope/roll"~(i+1));
		      me.rope_angle_r_array[i] = me._get_roll(i);
		    }

		  settimer( func {me.rope_animation_loop();}, 0.0);



	},

};

rope_manager.init();


# listeners to update parameters when changed

setlistener("/sim/winch/rope/flex-force", func {rope_manager.read_parameters();},0,0);
setlistener("/sim/winch/rope/damping", func {rope_manager.read_parameters();},0,0);
setlistener("/sim/winch/load", func {rope_manager.read_parameters();},0,0);
setlistener("/sim/winch/load-damping", func {rope_manager.read_parameters();},0,0);
setlistener("/sim/winch/rope/factor", func {rope_manager.read_parameters();},0,0);
setlistener("/sim/winch/rope/coil-flag", func {rope_manager.read_parameters();},0,0);
setlistener("/sim/winch/rope/coil-factor", func {rope_manager.read_parameters();},0,0);
setlistener("/sim/winch/rope/coil-angle", func {rope_manager.read_parameters();},0,0);
setlistener("/sim/winch/rope/offset", func {rope_manager.read_parameters();},0,0);
setlistener("/sim/winch/rope/stiffness", func {rope_manager.read_parameters();},0,0);
setlistener("/sim/winch/rope/bendforce", func {rope_manager.read_parameters();},0,0);



setlistener("/sim/winch/excitation-test-start", func {rope_manager.excitation_test();},0,0);

