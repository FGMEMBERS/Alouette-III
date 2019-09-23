var helper  = screen.display.new(10, 20);

var display_helper = func {
helper.setcolor(0.4,1.0,0.0);

helper.add("fdm/jsbsim/fcs/x-col");

helper.add("fdm/jsbsim/fcs/x-lon");
helper.add("fdm/jsbsim/propulsion/engine/longitudinal-ctrl-rad");

helper.add("fdm/jsbsim/fcs/x-lat");
helper.add("fdm/jsbsim/propulsion/engine/lateral-ctrl-rad");

helper.add("fdm/jsbsim/fcs/x-ped");
helper.add("fdm/jsbsim/propulsion/engine[1]/antitorque-ctrl-rad");

helper.add("fdm/jsbsim/propulsion/engine[0]/a1-rad");
helper.add("fdm/jsbsim/propulsion/engine[0]/b1-rad");
}

var init_Run =   func {

setprop("/fdm/jsbsim/animation/cockpit-left-door-pos-cmd", 0);
setprop("/fdm/jsbsim/animation/cockpit-right-door-pos-cmd", 0);

setprop("fdm/jsbsim/electrical/switch/battery", 1);
setprop("fdm/jsbsim/electrical/switch/alternator", 1);

setprop("fdm/jsbsim/animation/rotor_brake-switch-lock-cmd", 0);
setprop("fdm/jsbsim/animation/rotor_brake-switch-cmd", 0);

setprop("fdm/jsbsim/fcs/nominal-flow-cmd", 1);

setprop("fdm/jsbsim/animation/rotor_clutch-switch-cmd", 0);

setprop("fdm/jsbsim/propulsion/engine[0]/cutoff", 0);
interpolate("fdm/jsbsim/propulsion/engine[0]/cutoff",0, 2.0);

setprop("fdm/jsbsim/animation/master-switch-cmd", 1);
interpolate("fdm/jsbsim/animation/master-switch-cmd", 1,4.0);

print("Startup sequence complete");
var window_lhbon = screen.window.new(nil, -210, 1, 15);
window_lhbon.write("Rotor ready, engine started, wait for rotor to spin up. ",0.5,1,0.9);
            }

#display_helper();



close_helper = func { helper.close(); }


# flex rope animation


#setlistener("/sim/signals/fdm-initialized",     func {rescue.rope_animation(0); }    );



#basic rotor animation 
#JSBsim is unable to process a sequential function loop , so it is done there with nasal
#the main part of animation is done within "systems/animation-dev.xml" file

var time_rotate = func{
    var v_deg_s = getprop("fdm/jsbsim/systems/rotor/velocity-deg-s");
    var delta_sec = getprop("fdm/jsbsim/animation/delta-sec");
    var raw_pos  = getprop("fdm/jsbsim/systems/rotor/raw-pos-deg");
   raw_pos += delta_sec*v_deg_s;
setprop("fdm/jsbsim/systems/rotor/raw-pos-deg", raw_pos);
settimer(time_rotate,0);
}

setlistener("/sim/signals/fdm-initialized", time_rotate);
