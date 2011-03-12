declare name "WaveGuide Saxophone from STK";
declare author "Romain Michon";
declare copyright "Romain Michon (rmichon@ccrma.stanford.edu)";
declare version "1.0";
declare licence "STK-4.3"; // Synthesis Tool Kit 4.3 (MIT style license);
declare description "This class implements a hybrid digital waveguide instrument that can generate a variety of wind-like sounds.  It has also been referred to as the blowed string model. The waveguide section is essentially that of a string, with one rigid and one lossy termination.  The non-linear function is a reed table. The string can be blown at any point between the terminations, though just as with strings, it is impossible to excite the system at either end. If the excitation is placed at the string mid-point, the sound is that of a clarinet.  At points closer to the bridge, the sound is closer to that of a saxophone.  See Scavone (2002) for more details.";
declare reference "https://ccrma.stanford.edu/~jos/pasp/Woodwinds.html";  

import("math.lib");
import("music.lib");
import("instrument.lib");

//==================== GUI SPECIFICATION ================

freq = nentry("h:Basic Parameters/freq", 440, 20, 20000, 1);
gain = nentry("h:Basic Parameters/gain", 0.8, 0, 1, 0.01); 
gate = button("h:Basic Parameters/gate");

pressure = hslider("v:Physical Parameters/pressure",1,0,1,0.01);
reedStiffness = hslider("v:Physical Parameters/reedStiffness",0.3,0,1,0.01);
blowPosition = hslider("v:Physical Parameters/blowPosition",0.5,0,1,0.01);
noiseGain = hslider("v:Physical Parameters/noiseGain",0.05,0,1,0.01);

vibratoGain = hslider("v:Vibrato Parameters/vibratoGain",0.1,0,1,0.01);
vibratoFreq = hslider("v:Vibrato Parameters/vibratoFreq",6,1,15,0.01);
vibratoBegin = hslider("v:Vibrato Parameters/vibratoBegin",0.05,0,2,0.01);
vibratoAttack = hslider("v:Vibrato Parameters/vibratoAttack",0.3,0,2,0.01);
vibratoRelease = hslider("v:Vibrato Parameters/vibratoRelease",0.1,0,2,0.01);

envelopeAttack = hslider("v:Envelope Parameters/envelopeAttack",0.05,0,2,0.01);
envelopeRelease = hslider("v:Envelope Parameters/envelopeRelease",0.01,0,2,0.01);

//Nonlinear filter parameters
typeModulation = nentry("v:Nonlinear Filter/typeMod",0,0,4,1);
nonLinearity = hslider("v:Nonlinear Filter/Nonlinearity",0,0,1,0.01) : smooth(0.999);
frequencyMod = hslider("v:Nonlinear Filter/freqMod",220,20,1000,0.1) : smooth(0.999);
nonLinAttack = hslider("v:Nonlinear Filter/nonLinAttack",0.1,0,2,0.01);

//==================== SIGNAL PROCESSING ================

//Parameters for the reed table lookup 
reedTableOffset = 0.7;
reedTableSlope = 0.1 + (0.4*reedStiffness);
reedTable = reed(reedTableOffset,reedTableSlope);

//Delay lines length in number of samples
fdel1 = (1-blowPosition) * (SR/freq - 3);
fdel2 = (SR/freq - 3)*blowPosition +1 ;

//Delay lines
delay1 = delay(4096,fdel1);
delay2 = delay(4096,fdel2);

//Breath pressure is controlled by an attack / sustain / release envelope
envelope = (0.55+pressure*0.3)*asr(pressure*envelopeAttack,100,pressure*envelopeRelease,gate);
breath = envelope + envelope*noiseGain*noise;
vibrato = vibratoGain*envVibrato(vibratoBegin,vibratoAttack,100,vibratoRelease,gate)*osc(vibratoFreq);
breathPressure = breath + breath*vibratoGain*osc(vibratoFreq);

nlfOrder = 6; 
envelopeMod = asr(nonLinAttack,100,envelopeRelease,gate);
nonLinMod =  nonLinearModulator(nonLinearity,envelopeMod,freq,typeModulation,frequencyMod,nlfOrder);
NLFM = _ <: (nonLinMod*nonLinearity,_*(1-nonLinearity) :> +)*(typeModulation < 3),nonLinMod*(typeModulation >= 3) :> _;

//Body filter is a one zero filter
bodyFilter = _*gain : oneZero1(b0,b1)
	with{
		gain = -0.95;
		b0 = 0.5;
		b1 = 0.5;	
	};

instrumentBody(delay1FeedBack,breathP) = delay1FeedBack <: _ - delay2 <: 
	((breathP - _ <: breathP - _*reedTable) - delay1FeedBack),_;

stereo = stereoizer(SR/freq);

process =
	(bodyFilter,breathPressure : instrumentBody) ~ 
	(delay1 : NLFM) : !,
	//Scaling Output and stereo
	_*0.3*gain : stereo;