#Rescue Op  Gérard Robin  Copyright 
#Au sol 0.07 => Agl ft 3.7
# Alt 1 => Agl ft 31.9  (rope on ground/sea)
# Man rescued heigh => 6.56 ft

var AGL_REF = 33.51;
var agl_low = 0;
var rescue_lift = 1;
var VIEW = "Rescued_View";
var yViewNode = props.globals.getNode("sim/current-view/y-offset-m", 1);
var rescue_liftNode = props.globals.getNode("sim/model/rescue-lift", 1);

#print (AGL_REF);
setprop ("/sim/model/rescue-lift",0);
setprop ("/position/altitude-agl-ft",0.01);


var rope_size = func {
	var rescue = getprop("/sim/model/rescue");

	if ( rescue == 1) {
            var agl = getprop("/position/altitude-agl-ft");
            var rope = getprop("/sim/model/rescue-lift");
            var terrain = getprop("fdm/jsbsim/environment/terrain-solid");
            if (terrain == 1) {
#on ground
                    agl_low = agl - 1;
            }else{
#in water
                    agl_low = agl + 3;
            }

            if ( rope * AGL_REF  > agl_low )  {
            rescue_lift = agl_low / AGL_REF;
                    if (rescue_lift < 0) {
                    rescue_lift = 0;
                    }
setprop ("/sim/model/rescue-lift", 0 );
            setprop ("/sim/model/rescue-lift", rescue_lift );
            }
            if (getprop("/sim/current-view/name") == VIEW) {
            yView = 1.5 - rescue_liftNode.getValue() * 10;
            yViewNode.setValue(yView);
            }
        }
	settimer(rope_size, 0.05);
	}



rope_size();