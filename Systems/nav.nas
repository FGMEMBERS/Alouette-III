survey_autopilot=func{
	if(getprop("fdm/jsbsim/instruments/autopilot-hold")) {

			if (getprop("fdm/jsbsim/instruments/autopilot-lock-true-heading")==1){
			setprop("/autopilot/locks/heading","true-heading-hold");
                        }
                        if (getprop("fdm/jsbsim/instruments/autopilot-lock-heading-bug")==1){
			setprop("/autopilot/locks/heading","dg-heading-hold");
			}
                        if (getprop("fdm/jsbsim/instruments/autopilot-lock-altitude")==1){
			setprop("/autopilot/locks/altitude","altitude-hold");
			}
	}else{
	setprop("/autopilot/locks/heading", "");
        setprop("/autopilot/locks/altitude", "");
	}
}
setlistener("fdm/jsbsim/instruments/autopilot-hold",survey_autopilot);
