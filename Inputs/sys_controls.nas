

var window_lhb = screen.window.new(nil, -180, 2, 2000);

var fg = getprop("/sim/version/flightgear");    print ("FGVER ",fg);
var model_min = getprop("/sim/model/fg-ver_min");    print ("MODELmin ",model_min);
var model_max = getprop("/sim/model/fg-ver_max");    print ("MODELmax ",model_max);
var fgn1 = substr(fg,0,1);
var fgn3 = substr(fg,3,1);

#print ("FGN1     ",fgn1);
#print ("FGN3     ",fgn3);

if (fgn3  == ".") {
#print ("POINT");
var fgn2 = substr(fg,2,1);
var nfg = (fgn2/100)+fgn1;
#print ("FGVER ",nfg);
}
elsif (fgn3  != ".") {
#print ("NOTPOINT");
var fgn2 = substr(fg,2,2);
var nfg = (fgn2/100)+fgn1;
#print ("FGVER ",nfg);
}


#var diff_min = cmp(fg,model_min);    print ("DIFFSTRINGn ",diff_min);
#var diff_max = cmp(fg,model_max);    print ("DIFFSTRINGx ",diff_max);
#if (diff_min == -1 or diff_max == 1){


if (nfg < model_min  or  nfg > model_max){
setprop("fdm/simulation/wrg-ver",1);
window_lhb.write("WRONG FLIGHTGEAR VERSION");
window_lhb.write("YOU WANT AT LEAST FG VERSION IN THE RANGE : " "MIN "~ model_min ~" MAX "~model_max);
}else{
setprop("fdm/simulation/wrg-ver",9);
}
print("SYSVER  ",getprop("fdm/simulation/wrg-ver"));

