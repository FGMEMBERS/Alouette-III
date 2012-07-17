# $Id: al3.nas







# engines/rotor =====================================================
var rotor = props.globals.getNode("controls/engines/engine/rotorgear");
var collective0= props.globals.getNode("controls/engines/engine/throttle");
var collective1= props.globals.getNode("controls/engines/engine[1]/throttle");
var state = props.globals.getNode("sim/model/al3/state");
var turbine = props.globals.getNode("sim/model/s51/turbine-rpm-pct", 1);
var brake = props.globals.getNode("controls/rotor/brake");
var folded = props.globals.getNode("controls/rotor/folded");
var master_bat = props.globals.getNode("controls/engines/engine/master-bat");
var magnetos = props.globals.getNode("controls/engines/engine/magnetos");
var master_switch = props.globals.getNode("controls/electric/master-switch");
var battery_switch = props.globals.getNode("controls/electric/battery-switch");
var blade0 = props.globals.getNode("rotors/main/blade[0]/position-deg");
var blade1 = props.globals.getNode("rotors/main/blade[1]/position-deg");
var blade2 = props.globals.getNode("rotors/main/blade[2]/position-deg");
var blad_fold = props.globals.getNode("/surface-positions/blade-fold-pos-norm");
var rpm = props.globals.getNode("rotors/main/rpm");

#rpm.setValue(0);
#blade0.setValue(0);
#blade1.setValue(120);
#blade2.setValue(240);

print("engines off");
var engines = func {
	var s = state.getValue();
	if (arg[0] == 1)  {
		if (s == 0  and master_switch.getValue() == 1 and blad_fold.getValue() == 0) {
			state.setValue(1);
			print("engines started");
                        brake.setValue(0);
                        collective0.setValue(1);
                        collective1.setValue(1);
                        magnetos.setValue(1);
			settimer(func { rotor.setValue(1) }, 3);
			interpolate(turbine, 100, 10.5);
			settimer(func { state.setValue(2) ; print("engines running") }, 10.5);
	}
	} else {
		if (s == 2) {
			print("engines stopped");
			rotor.setValue(0);
			state.setValue(3);
			interpolate(turbine, 0, 18);
			settimer(func { state.setValue(0) ; print("engines off") }, 18);
                        }
                        magnetos.setValue(0);
                        master_bat.setValue(0);
                        master_switch.setValue(0);
                        battery_switch.setValue(0);
                    }
                            
}

var electric = func {
                    magnetos.setValue(3);
                    master_bat.setValue(1);
                    master_switch.setValue(1);
                    battery_switch.setValue(1);
}

var blades_fold = func {
        var s = state.getValue();
        if (s == 0 and rpm.getValue() < 0.1 and brake.getValue() == 1){
                                        blade0.setValue(0);
            #var diff10 = blade0.getValue() ;
            #print ("Fold position: ", diff10);
            #setprop ("/controls/rotor/blade0-fold-pos", diff10);
            
            var diff11 = 480 - blade1.getValue() ;
            #print ("Fold position: ", diff1);
            setprop ("/controls/rotor/blade1-fold-pos", diff11);
            
            var diff12 = 600 - blade2.getValue() ;
            #print ("Fold position: ", diff2);
            setprop ("/controls/rotor/blade2-fold-pos", diff12);
            
            setprop ("/controls/rotor/folded",1);
            setprop ("/controls/flight/wing-fold",1);
        }
}

var blades_unfold = func {
        
        if (folded.getValue() ==1){
            var diff0 =  blade0.getValue();
            #print ("Fold position: ", diff0);
            setprop ("/controls/rotor/blade0-fold-pos", diff0);
            
            var diff1 = 120;
            #print ("Fold position: ", diff1);
            setprop ("/controls/rotor/blade1-fold-pos", diff1);
            
            var diff2 = 240;
            #print ("Fold position: ", diff2);
            setprop ("/controls/rotor/blade2-fold-pos", diff2);
            
             #setprop ("/controls/rotor/folded",0);
            setprop ("/controls/flight/wing-fold",0);
        }
}


#blades_fold();