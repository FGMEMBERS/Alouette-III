#################### long line ####################

var rope_angle_v_array = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
var rope_angle_vr_array = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
var rope_angle_r_array = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
var onground_flag = 0;

var rope_animation = func (reset=0) {

  #This is only needed if your flying over "hot" or colidable objects and want a true AGL
  var lonNode = getprop("/position/longitude-deg");
  var latNode = getprop("/position/latitude-deg");
  var aircraft_alt_ft = getprop("/position/altitude-ft") -13.8;#this was set for the aircrane, I didn't redo it.
  var true_grnd_elev_ft = geo.elevation(latNode, lonNode) * 3.28;           
  var true_agl_ft =  aircraft_alt_ft - true_grnd_elev_ft;
  setprop("position/true-agl-ft", true_agl_ft);

	#var overland = getprop("gear/gear/ground-is-solid");
  var overland = getprop("fdm/jsbsim/environment/terrain-solid");
  var altitude = getprop("position/true-agl-ft");
  var alt_agl = altitude * 0.3048 + getprop("/sim/winch/rope/offset");
  var n_segments = 90;
  var segment_length = getprop("/sim/winch/rope/factor") * 0.7;
  var hitch_offset = getprop("/sim/winch/hitchoffset");

  var n_segments_reeled = getprop("/sim/winch/segments-reeled-in");
  
  if (reset)
    {
      var ax = 0;
			var ay = 0;
			var az = 0;
      for (var i = 0; i < n_segments; i+=1)
        {
          setprop("/sim/winch/rope/pitch"~i, 0);
          setprop("/sim/winch/rope/roll"~i, 0);
        }
      reset = 0;
    }

  if (overland)
    {
      if ((alt_agl + hitch_offset) - ((n_segments - n_segments_reeled) * segment_length) < 0.0)
			  onground_flag = 1;
		  else
			  onground_flag = 0;
    }
  else
	  {
      #TODO: decide how to handel this event, slowly allow to sink?
	    onground_flag = 0;
	  }

	var flex_force = getprop("/sim/winch/rope/flex-force");
	var damping = getprop("/sim/winch/rope/damping");
	var stiffness = getprop("/sim/winch/rope/stiffness");
	var sum_angle = 0.0;
	var dt = getprop("/sim/time/delta-sec");
  	var bend_force = getprop("/sim/winch/rope/bendforce");
	var angle_correction = getprop("/sim/winch/rope/correction");
	var load = getprop("/sim/winch/load");

	var aircraft_pitch = getprop("/orientation/pitch-deg");

	if (onground_flag == 0)
		{
			var ax = getprop("/accelerations/pilot/x-accel-fps_sec");
			var ay = getprop("/accelerations/pilot/y-accel-fps_sec");
			var az = getprop("/accelerations/pilot/z-accel-fps_sec");
		}
	else
		{
			var ax = 0;
			var ay = 0;
			var az = 0;
		}

	var a = math.sqrt(ax* ax + ay*ay + az*az);

	if (a==0.0) {a=1.0;}

	var ref_ang1 = math.asin(ax/a) * 180.0/math.pi;
	var ref_ang2 = math.asin(ay/a) * 180.0/math.pi;

	var damping_factor = math.pow(damping, dt);

	if (onground_flag == 0)
	  {
      var current_angle = getprop("/sim/winch/rope/pitch1");

      var ang_error = ref_ang1 - current_angle;

      rope_angle_v_array[0] += ang_error * stiffness * dt;
      rope_angle_v_array[0] *= damping_factor;

      var ang_speed = rope_angle_v_array[0];

      setprop("/sim/winch/rope/pitch1", current_angle + dt * ang_speed);

      var current_roll = getprop("/sim/winch/rope/roll1");
      ang_error = ref_ang2 - current_roll;

      rope_angle_vr_array[0] +=  ang_error * stiffness * dt;
      rope_angle_vr_array[0] *= damping_factor;

      ang_speed = rope_angle_vr_array[0];

      var next_roll =  current_roll + dt * ang_speed;
      setprop("/sim/winch/rope/roll"~(1+n_segments_reeled), next_roll);

      # kink excitation
      var kink =  -(next_roll - rope_angle_r_array[0]);
      setprop("/sim/winch/rope/roll"~(2+n_segments_reeled),  kink) ;
      rope_angle_r_array[1] = kink;
    } 
  else
    {
      #lets cargo align with parallel rope if not conditioned as above
      setprop("/sim/winch/rope/pitch"~(1+n_segments_reeled), ref_ang1);
      setprop("/sim/winch/rope/roll"~(1+n_segments_reeled), ref_ang2);
    }

  # pull_force was hard coded into the force value below
  # I separated it out because I changed its value for other condition
  # that no longer apply to your implementation.
  pull_force = 0.05;

	var roll_target = 0.0;


	for (var i = 0; i< n_segments_reeled; i=i+1)
		{
          	setprop("/sim/winch/rope/pitch"~(i+1),0.0);
		setprop("/sim/winch/rope/roll"~(i+1), 0.0);
		rope_angle_r_array[i] = 0.0;
		}

	for (var i = n_segments_reeled; i< n_segments; i=i+1)
    {
	    var gravity = n_segments - i + load;

		  var velocity = getprop("/velocities/equivalent-kt");

		  if (velocity == nil) {velocity = 0;}
		  if (velocity > 500.0) {velocity = 500.0;}

		  var dist_above_ground = alt_agl - (i+1 - n_segments_reeled) * segment_length + 0.25;
 
      var force = flex_force * math.cos(sum_angle * math.pi/180.0) * pull_force * velocity;

      if (overland)
        {
          if (dist_above_ground < 0.0)
            {
              force = force + bend_force * math.cos(sum_angle * math.pi/180.0);
            }
        }

		  if (force > 1.0 * gravity) {force = 1.0 * gravity;}

		  var angle = - 180.0 /math.pi * math.atan2(force, gravity);#(force/gravity);

		  # outside transition zone, make sure segments lie really flat
		  if (dist_above_ground < -1.0 ) {angle = 270.0- sum_angle - aircraft_pitch;}

		#if (i==0) {print ("mark")};
		#print (angle);
		  sum_angle += angle;

      if (onground_flag == 0)
		    {
		      current_angle = getprop("/sim/winch/rope/pitch"~(i+1));

		      ang_error = angle - current_angle;

		      rope_angle_v_array[i] += ang_error * stiffness * dt;
		      rope_angle_v_array[i] *= damping_factor;

		      ang_speed = rope_angle_v_array[i];

          setprop("/sim/winch/rope/pitch"~(i+1), current_angle + dt * ang_speed);

		      # the transverse dynamics is largely waves excited by the helicopter

		      if (i==1) # this is set by the kink excitation
            {
              continue;
            }   
          else
            {
              roll_target =  rope_angle_r_array[i-1];
            }

		      ang_error = roll_target - rope_angle_r_array[i];

		      rope_angle_vr_array[i] += ang_error * stiffness * dt;
		      rope_angle_vr_array[i] *= damping_factor;

		      ang_speed = rope_angle_vr_array[i];

          setprop("/sim/winch/rope/roll"~(i+1), roll_target);
		    }
      else
        {
          #rope sections to angle parallel to ground
          setprop("/sim/winch/rope/pitch"~(i+1), angle + angle_correction);
          setprop("/sim/winch/rope/roll"~(i+1), 0.0);
        }
  }

  # copy the current values into the last step array

  for (var i = 0; i< n_segments; i=i+1)
    {
      rope_angle_r_array[i] = getprop("/sim/winch/rope/roll"~(i+1));
    }

  settimer(rope_animation, 0);

}
