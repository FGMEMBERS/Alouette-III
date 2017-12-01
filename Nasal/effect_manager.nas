
# ALS effect manager

# provides relative vectors from eye-point to aircraft lightspots on runway
# and rotor wash
# in east/north/up coordinates the renderer uses used for outside views

# in addition manages splash vector for rain

# Thorsten Renk, 2017
 
var landcover_map = {BuiltUpCover: 0.1, Town: 0.1, Freeway:0.1, BarrenCover:1.0, HerbTundraCover: 0.2, GrassCover: 0.2, CropGrassCover: 0.2, EvergreenBroadCover: 0.2, EvergreenNeedleCover: 0.2, Sand: 1.0, Grass: 0.2, Grassland: 0.2, Ocean: 2.0, Marsh: 1.5, Lake: 2.0, ShrubCover: 0.4, Shrub: 0.4, Landmass: 0.2, CropWoodCover: 0.1, MixedForestCover: 0.1, DryCropPastureCover: 0.4, MixedCropPastureCover: 0.2, MixedCrop: 0.2, ComplexCrop: 0.2, IrrCropPastureCover: 0.1, DeciduousBroadCover: 0.1, DeciduousNeedleCover: 0.1, Bog: 1.5, Littoral: 2.0, pa_taxiway : 0.1, pa_tiedown: 0.1, pc_taxiway: 0.1, pc_tiedown: 0.1, Glacier: 3.0, SnowCover: 3.0, DryLake: 1.0, IntermittentStream: 1.0, DryCrop: 0.6, Lava: 1.0, GolfCourse: 0.1, Rock: 0.3, Construction: 0.5, PackIce: 2.0, NaturalCrop: 0.2};
 
var effect_manager = {
 
	run: 0,
 
	lat_to_m: 110952.0,
	lon_to_m: 0.0,
 
	light1_xpos: 0.0,
	light1_ypos: 0.0,
	light1_zpos: 0.0,
	light1_r: 0.0,
	light1_g: 0.0,
	light1_b: 0.0,
	light1_size: 0.0,
	light1_stretch: 0.0,
	light1_is_on: 0,
 
	light2_xpos: 0.0,
	light2_ypos: 0.0,
	light2_zpos: 0.0,
	light2_r: 0.0,
	light2_g: 0.0,
	light2_b: 0.0,
	light2_size: 0.0,	
	light2_is_on: 0,
 
	light3_xpos: 0.0,
	light3_ypos: 0.0,
	light3_zpos: 0.0,
	light3_r: 0.0,
	light3_g: 0.0,
	light3_b: 0.0,
	light3_size: 0.0,
	light3_is_on : 0,
 
	light4_xpos: 0.0,
	light4_ypos: 0.0,
	light4_zpos: 0.0,
	light4_r: 0.0,
	light4_g: 0.0,
	light4_b: 0.0,
	light4_size: 0.0,
	light4_is_on: 0,

	splash_x: 0.01,
	splash_y: 0.0,
	splash_z: -1.0,
	frost: 0.0,

	dust: 0.0,
	is_water: 0,
	is_snow: 0,
	dust_color: [1.0, 1.0,1.0],
	dust_color_last: [0.0, 0.0, 0.0],

	# node reference pointers for faster property I/O

	nd_ref_light1_x:  props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-x-m", 1),
	nd_ref_light1_y:  props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-y-m", 1),
	nd_ref_light1_z: props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-z-m", 1),
	nd_ref_light1_dir: props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/dir", 1),

	nd_ref_light2_x: props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-x-m[1]", 1),
	nd_ref_light2_y: props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-y-m[1]", 1),
	nd_ref_light2_z: props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-z-m[1]", 1),

	nd_ref_light3_x: props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-x-m[2]", 1),
	nd_ref_light3_y: props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-y-m[2]", 1),
	nd_ref_light3_z: props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-z-m[2]", 1),

	nd_ref_light4_x: props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-x-m[3]", 1),
	nd_ref_light4_y: props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-y-m[3]", 1),
	nd_ref_light4_z: props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-z-m[3]", 1),

	nd_ref_wash_x: props.globals.getNode("/environment/aircraft-effects/wash-x", 1),
	nd_ref_wash_y: props.globals.getNode("/environment/aircraft-effects/wash-y", 1),
	nd_ref_wash_strength: props.globals.getNode("/environment/aircraft-effects/wash-strength", 1),

	nd_ref_splash_x: props.globals.getNode("/environment/aircraft-effects/splash-vector-x", 1),
	nd_ref_splash_y: props.globals.getNode("/environment/aircraft-effects/splash-vector-y", 1),
	nd_ref_splash_z: props.globals.getNode("/environment/aircraft-effects/splash-vector-z", 1),

	nd_ref_frost_level: props.globals.getNode("/environment/aircraft-effects/frost-level", 1),

	nd_ref_dust_r: props.globals.getNode("/fdm/jsbsim/effects/dust-r", 1),
	nd_ref_dust_g: props.globals.getNode("/fdm/jsbsim/effects/dust-g", 1),
	nd_ref_dust_b: props.globals.getNode("/fdm/jsbsim/effects/dust-b", 1),

	nd_ref_heatblur: props.globals.getNode("/fdm/jsbsim/effects/heatblur", 1),

	init: func {
		# define your lights here
 
		# light 1 ########
		# offsets to aircraft center
 
		me.light1_xpos = 15.0;
		me.light1_ypos = 0.0;
		me.light1_zpos = 0.0;
 
		# color values
 
		me.light1_r = 0.3;
		me.light1_g = 0.3;
		me.light1_b = 0.3;
 
		# spot size
 
		me.light1_size = 6.0;
		me.light1_stretch = 1.5;
 
		# light 2 ########
		# offsets to aircraft center
 
		me.light2_xpos = 2.0;
		me.light2_ypos = -1.5;
		me.light2_zpos = 2.0;
 
		# color values
	
		me.light2_r = 0.0;
		me.light2_g = 0.2;
		me.light2_b = 0.0;
 
		# spot size
		
		me.light2_size = 2.0;
 
		# light 3 ########
		# offsets to aircraft center
 
		me.light3_xpos = 2.0;
		me.light3_ypos = 1.0;
		me.light3_zpos = 2.0;
 
		# color values
	
		me.light3_r = 0.2;
		me.light3_g = 0.0;
		me.light3_b = 0.0;
 
		# spot size
		
		me.light3_size = 2.0;

		# light 4 ########
		# offsets to aircraft center
 
		me.light4_xpos = -2.0;
		me.light4_ypos = 0.0;
		me.light4_zpos = 2.5;
 
		# color values
	
		me.light4_r = 0.1;
		me.light4_g = 0.0;
		me.light4_b = 0.0;
 
		# spot size
		
		me.light4_size = 3.0;
	
		me.start();
		},
 
	start: func {
 
		setprop("/sim/rendering/als-secondary-lights/num-lightspots", 4);
 
		setprop("/sim/rendering/als-secondary-lights/lightspot/size", me.light1_size);
		setprop("/sim/rendering/als-secondary-lights/lightspot/size[1]", me.light2_size);
		setprop("/sim/rendering/als-secondary-lights/lightspot/size[2]", me.light3_size);
		setprop("/sim/rendering/als-secondary-lights/lightspot/size[3]", me.light4_size);
 
		setprop("/sim/rendering/als-secondary-lights/lightspot/stretch", me.light1_stretch);
 
		me.run = 1;		
		me.update();
 
 
		},
 
	stop: func {
		me.run = 0;
 
		},
 
	update: func {
 
		if (me.run == 0) {return;}
 
		var alt_agl = getprop("/position/altitude-agl-ft");
		var rotor_rpm = getprop("/fdm/jsbsim/propulsion/engine/rotor-rpm");
		var als_on = getprop("/sim/rendering/shaders/skydome");

		setprop("/position/gear-agl-m", alt_agl * 0.3048 - 0.72);

		# lights and wash we only need to do close to the ground when ALS is on

		if ((als_on == 1) and (alt_agl < 100.0))
			{
			var apos = geo.aircraft_position();
			var vpos = geo.viewer_position();
	 
			me.lon_to_m = math.cos(apos.lat()*math.pi/180.0) * me.lat_to_m;
	 
			var heading = getprop("/orientation/heading-deg") * math.pi/180.0;
	 
			var lat = apos.lat();
			var lon = apos.lon();
			var alt = apos.alt();
	 
			var sh = math.sin(heading);
			var ch = math.cos(heading);

			var strobelights = getprop("/fdm/jsbsim/electrical/strobe-lights");
			var strobe1 = getprop("/fdm/jsbsim/systems/effets/lights/blinker-kinemat-in");
			
			if (strobelights == 1) 
	 			{
				if (strobe1 == 1)
					{
					me.light2_on();
					me.light3_off();
					}
				else
					{
					me.light2_off();
					me.light3_on();
					}
				
				}
			else
				{
				me.light2_off();
				me.light3_off();
				}			

			var beacon = getprop("/fdm/jsbsim/electrical/beacon");
			var strobe2 = getprop("/fdm/jsbsim/systems/effets/lights/beacon2-on");


			if (beacon == 1)
				{
				if (strobe2 == 0)
					{
					me.light4_on();
					}
				else
					{
					me.light4_off();
					}
				}
			else
				{
				me.light4_off();
				}
					
			var view = getprop("/sim/current-view/view-number");

			if ((getprop("/fdm/jsbsim/electrical/landing-light") == 1) and (view != 0) and (view != 9) and (view != 10))
				{
				me.light1_on();
				}
			else
				{
				me.light1_off();
				}

			# rotor particle dust

			me.terrain_probe(apos.lat(), apos.lon(), apos.alt());
			me.set_dust();


			# rotor wash

			var delta_x = (apos.lat() - vpos.lat()) * me.lat_to_m;
			var delta_y = -(apos.lon() - vpos.lon()) * me.lon_to_m;
			 
			me.nd_ref_wash_x.setValue(delta_x);
			me.nd_ref_wash_y.setValue(delta_x);
			 
			var rpm_factor = rotor_rpm /350.0;
			 
			var strength = 20.0/alt_agl;
			if (strength > 1.0) {strength = 1.0;}
			strength = strength * rpm_factor;
			 
			me.nd_ref_wash_strength.setValue(strength);

			# light 1 position
	 
			#var alt_agl = getprop("/position/altitude-agl-ft");
	 
			var proj_x = alt_agl;
			var proj_z = alt_agl/10.0;
	 
			apos.set_lat(lat + ((me.light1_xpos + proj_x) * ch + me.light1_ypos * sh) / me.lat_to_m);
			apos.set_lon(lon + ((me.light1_xpos + proj_x)* sh - me.light1_ypos * ch) / me.lon_to_m);
	 
			delta_x = (apos.lat() - vpos.lat()) * me.lat_to_m;
			delta_y = -(apos.lon() - vpos.lon()) * me.lon_to_m;
			var delta_z = apos.alt()- proj_z - vpos.alt();
	 
			me.nd_ref_light1_x.setValue(delta_x);
			me.nd_ref_light1_y.setValue(delta_y);
			me.nd_ref_light1_z.setValue(delta_z);
			me.nd_ref_light1_dir.setValue(heading);			


	 
			# light 2 position
	 
			apos.set_lat(lat + (me.light2_xpos * ch + me.light2_ypos * sh) / me.lat_to_m);
			apos.set_lon(lon + (me.light2_xpos * sh - me.light2_ypos * ch) / me.lon_to_m);
	 
			delta_x = (apos.lat() - vpos.lat()) * me.lat_to_m;
			delta_y = -(apos.lon() - vpos.lon()) * me.lon_to_m;
			delta_z = apos.alt() - vpos.alt();
	 
			me.nd_ref_light2_x.setValue(delta_x);
			me.nd_ref_light2_y.setValue(delta_y);
			me.nd_ref_light2_z.setValue(delta_z);

	 
			# light 3 position
	 
			apos.set_lat(lat + (me.light3_xpos * ch + me.light3_ypos * sh) / me.lat_to_m);
			apos.set_lon(lon + (me.light3_xpos * sh - me.light3_ypos * ch) / me.lon_to_m);
	 
			delta_x = (apos.lat() - vpos.lat()) * me.lat_to_m;
			delta_y = -(apos.lon() - vpos.lon()) * me.lon_to_m;
			delta_z = apos.alt() - vpos.alt();
	 
			me.nd_ref_light3_x.setValue(delta_x);
			me.nd_ref_light3_y.setValue(delta_y);
			me.nd_ref_light3_z.setValue(delta_z);

		

			# light 4 position
	 
			apos.set_lat(lat + (me.light4_xpos * ch + me.light4_ypos * sh) / me.lat_to_m);
			apos.set_lon(lon + (me.light4_xpos * sh - me.light4_ypos * ch) / me.lon_to_m);
	 
			delta_x = (apos.lat() - vpos.lat()) * me.lat_to_m;
			delta_y = -(apos.lon() - vpos.lon()) * me.lon_to_m;
			delta_z = apos.alt() - vpos.alt();
	 
			me.nd_ref_light4_x.setValue(delta_x);
			me.nd_ref_light4_y.setValue(delta_y);
			me.nd_ref_light4_z.setValue(delta_z);


			

			}
		
		# rain also needs to be done above 100 ft
		
		if (als_on == 1)
			{

			me.splash_z = -1.0 - rotor_rpm/100.0;
			if (me.splash_z < -2.0) {me.splash_z = -2.0;}
			
			var beta = getprop("/fdm/jsbsim/aero/beta-deg") * math.pi/180.0;
			var airspeed = getprop("/velocities/airspeed-kt");

			var splash_h = airspeed/80.0;
			if (splash_h > 1.0) {splash_h = 1.0;}

			me.splash_x = splash_h * math.cos(beta) -0.001;
			me.splash_y = splash_h * math.sin(beta);

			me.nd_ref_splash_x.setValue(me.splash_x);
			me.nd_ref_splash_y.setValue(me.splash_y);
			me.nd_ref_splash_z.setValue(me.splash_z);
	
			var temperature = getprop("/environment/temperature-degc");

			me.frost = - (temperature + 5.0);
			if (me.frost < 0.0) {me.frost = 0.0;}
			else if (me.frost > 0.5) {me.frost = 0.5;}

			me.nd_ref_frost_level.setValue(me.frost);

			var turbine_rpm = getprop("/fdm/jsbsim/propulsion/engine/engine-rpm");

			turbine_rpm = turbine_rpm / 5000.0;
			if (turbine_rpm > 1.0) {turbine_rpm = 1.0;}

			me.nd_ref_heatblur.setValue(turbine_rpm * 0.4);
			}

 
		settimer ( func me.update(), 0.0);
		},
 
 
	light1_on : func {
 		if (me.light1_is_on == 1) {return;}
		setprop("/sim/rendering/als-secondary-lights/lightspot/lightspot-r", me.light1_r);
		setprop("/sim/rendering/als-secondary-lights/lightspot/lightspot-g", me.light1_g);
		setprop("/sim/rendering/als-secondary-lights/lightspot/lightspot-b", me.light1_b);
 		me.light1_is_on = 1;
		},
 
	light1_off : func {
  		if (me.light1_is_on == 0) {return;}
		setprop("/sim/rendering/als-secondary-lights/lightspot/lightspot-r", 0.0);
		setprop("/sim/rendering/als-secondary-lights/lightspot/lightspot-g", 0.0);
		setprop("/sim/rendering/als-secondary-lights/lightspot/lightspot-b", 0.0);
  		me.light1_is_on = 0;
		},
 
	light2_on : func {
  		if (me.light2_is_on == 1) {return;}
		#setprop("/sim/rendering/als-secondary-lights/lightspot/lightspot-r[1]", me.light2_r);
		setprop("/sim/rendering/als-secondary-lights/lightspot/lightspot-g[1]", me.light2_g);
		#setprop("/sim/rendering/als-secondary-lights/lightspot/lightspot-b[1]", me.light2_b);
  		me.light2_is_on = 1;
		},
 
	light2_off : func {
  		if (me.light2_is_on == 0) {return;}
		#setprop("/sim/rendering/als-secondary-lights/lightspot/lightspot-r[1]", 0.0);
		setprop("/sim/rendering/als-secondary-lights/lightspot/lightspot-g[1]", 0.0);
		#setprop("/sim/rendering/als-secondary-lights/lightspot/lightspot-b[1]", 0.0);
  		me.light2_is_on = 0;
		},
 
	light3_on : func {
  		if (me.light3_is_on == 1) {return;}
		setprop("/sim/rendering/als-secondary-lights/lightspot/lightspot-r[2]", me.light3_r);
		#setprop("/sim/rendering/als-secondary-lights/lightspot/lightspot-g[2]", me.light3_g);
		#setprop("/sim/rendering/als-secondary-lights/lightspot/lightspot-b[2]", me.light3_b);
  		me.light3_is_on = 1;
		},
 
	light3_off : func {
  		if (me.light3_is_on == 0) {return;}
		setprop("/sim/rendering/als-secondary-lights/lightspot/lightspot-r[2]", 0.0);
		#setprop("/sim/rendering/als-secondary-lights/lightspot/lightspot-g[2]", 0.0);
		#setprop("/sim/rendering/als-secondary-lights/lightspot/lightspot-b[2]", 0.0);
  		me.light3_is_on = 0;
		},

	light4_on : func {
  		if (me.light4_is_on == 1) {return;}
		setprop("/sim/rendering/als-secondary-lights/lightspot/lightspot-r[3]", me.light3_r);
		#setprop("/sim/rendering/als-secondary-lights/lightspot/lightspot-g[3]", me.light3_g);
		#setprop("/sim/rendering/als-secondary-lights/lightspot/lightspot-b[3]", me.light3_b);
  		me.light4_is_on = 1;
		},
 
	light4_off : func {
  		if (me.light4_is_on == 0) {return;}
		setprop("/sim/rendering/als-secondary-lights/lightspot/lightspot-r[3]", 0.0);
		#setprop("/sim/rendering/als-secondary-lights/lightspot/lightspot-g[3]", 0.0);
		#setprop("/sim/rendering/als-secondary-lights/lightspot/lightspot-b[3]", 0.0);
  		me.light4_is_on = 0;
		},


	terrain_probe: func (lat, lon, alt) {
		
		var info = geodinfo(lat, lon);
		if ((info != nil) and (info[1] != nil))
			{
	 		if (contains(landcover_map,info[1].names[0])) 
				{me.dust = landcover_map[info[1].names[0]];}
			else 
				{me.dust = 0.2;}
		
			}
		else
			{
			me.dust = 0.2;	
			}

			if (me.dust > 2.99)
				{
				me.is_snow = 1;
				me.is_water = 0;
				me.dust = 2.0 * (me.dust - 2.0);
				}
			else if (me.dust > 1.99)
				{
				me.is_water = 1;
				me.is_snow = 0;
				me.dust = 3.0 * (me.dust - 1.0);
				}
			else
				{
				me.dust = 2.0 * me.dust;
				me.is_snow = 0;
				me.is_water = 0;
				}
				
         		var snowlevel = getprop("/environment/snow-level-m");
			var dustcover = getprop("/environment/surface/dust-cover-factor");
			var wetness = getprop("/environment/surface/wetness");

			if ((alt  > snowlevel) and (me.is_water == 0))
				{
				me.is_snow = 1;
				}
			else if ((wetness > 0.3) and (me.is_snow == 0))
				{
				me.is_water = 1;
				}

			if (me.is_snow == 1)
				{
				me.dust = 2.0 * (me.dust + 1.0);
				}
			else if (me.is_water == 1)
				{
				me.dust = 3.5 * me.dust + 1.0 * wetness ;
				}
			else
				{
				me.dust = me.dust + 3.5 * dustcover;
				}
		},


		set_dust: func {


			var torque = getprop("/fdm/jsbsim/propulsion/engine/torque-lbsft");

			var size = 0.04 * math.sqrt(math.abs(torque)) + 0.8  + 0.00000004 * math.pow(torque, 2.0);
			size *= me.dust;
			setprop("/fdm/jsbsim/effects/dust", me.dust);
			setprop("/fdm/jsbsim/effects/particle-size", size);
			
			if ((me.is_snow) or (me.is_water))
				{
				me.dust_color = [1.0, 1.0, 1.0];
				}
			else 
				{
				me.dust_color = [0.75, 0.75, 0.6];
				}
			var scenelight = 1.2 * getprop("/rendering/scene/diffuse/red");
			if (me.light1_is_on == 1)
				{
				scenelight+= 0.5;
				}

			if (scenelight > 1.0) {scenelight = 1.0;}

			me.dust_color[0] *= scenelight;
			me.dust_color[1] *= scenelight;
			me.dust_color[2] *= scenelight;

			if (me.dust_color[0] != me.dust_color_last[0])
				{
				me.nd_ref_dust_r.setValue(me.dust_color[0]);
				me.dust_color_last[0] = me.dust_color[0];
				}
			if (me.dust_color[1] != me.dust_color_last[1])
				{
				me.nd_ref_dust_g.setValue(me.dust_color[1]);
				me.dust_color_last[1] = me.dust_color[1];
				}
			if (me.dust_color[2] != me.dust_color_last[2])
				{
				me.nd_ref_dust_b.setValue(me.dust_color[2]);
				me.dust_color_last[2] = me.dust_color[2];
				}

		},

 
};


effect_manager.init();



