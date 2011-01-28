declare name "WaveGuide Saxophone from STK";
declare author "Romain Michon";
declare version "1.0"; 

import("math.lib");
import("music.lib");
import("filter.lib");
import("envelope.lib");
import("table.lib");

//==================== GUI SPECIFICATION ================

freq = nentry("freq", 440, 20, 20000, 1);
gain = nentry("gain", 0.8, 0, 1, 0.01); 
gate = button("gate");

reedStiffness = hslider("reedStiffness",0.36,0,1,0.01);
blowPosition = hslider("blowPosition",0.2,0,1,0.01);
noiseGain = hslider("noiseGain",0.05,0,1,0.01);
vibratoGain = hslider("vibratoGain",0.1,0,1,0.01);
vibratoFreq = hslider("vibratoFreq",6,1,15,0.01);

//==================== SIGNAL PROCESSING ================

//Parameters for the reed table lookup 
reedTableOffset = 0.7;
reedTableSlope = 0.1 + (0.4*reedStiffness);

//Delay lines length in number of samples
fdel1 = (1-blowPosition) * (SR/freq - 3);
fdel2 = (SR/freq - 3)*blowPosition +1 ;

oneZero(x) = (x'*0.5 + x*0.5);

//oneZero(x) = (_*0.5 + x*0.5)~_;

//Breath pressure is controlled by an attack / sustain / release envelope
envelope = (0.55+gain*0.3)*asr(gain*0.005,100,gain*0.01,gate);
breath = envelope + envelope*noiseGain*noise;
breathPressure = breath + breath*vibratoGain*osc(vibratoFreq);

//Delay lines
delay1 = delay(4096,fdel1);
delay2 = delay(4096,fdel2);

//Body filter is a one zero filter
bodyFilter = oneZero*-0.95;

instrumentBody(x) = x <: _- delay2 <: 
	((hgroup("Differential Pressure",breathPressure - _) <: 
	hgroup("Reed Table Lookup",breathPressure-_*reed(reedTableOffset,reedTableSlope)))-x),_;

process =
	((bodyFilter) <: instrumentBody) ~ 
	delay1 : !,
	//Scaling Output and stereo
	_*0.3 <: _,_;