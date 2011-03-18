declare name "Nonlinear WaveGuide Saxophone";
declare author "Romain Michon";
declare copyright "Romain Michon (rmichon@ccrma.stanford.edu)";
declare version "1.0";
declare licence "STK-4.3"; // Synthesis Tool Kit 4.3 (MIT style license);
declare description "This class implements a hybrid digital waveguide instrument that can generate a variety of wind-like sounds.  It has also been referred to as the blowed string model. The waveguide section is essentially that of a string, with one rigid and one lossy termination.  The non-linear function is a reed table. The string can be blown at any point between the terminations, though just as with strings, it is impossible to excite the system at either end. If the excitation is placed at the string mid-point, the sound is that of a clarinet.  At points closer to the bridge, the sound is closer to that of a saxophone.  See Scavone (2002) for more details.";
declare reference "https://ccrma.stanford.edu/~jos/pasp/Woodwinds.html";  

import("music.lib");
import("instrument.lib");

//==================== GUI SPECIFICATION ================

freq = nentry("h:Basic Parameters/freq", 440, 20, 20000, 1);
gain = nentry("h:Basic Parameters/gain", 0.8, 0, 1, 0.01); 
gate = button("h:Basic Parameters/gate");

pressure = hslider("h:Physical and Nonlinearity/v:Physical Parameters/Pressure",1,0,1,0.01);
reedStiffness = hslider("h:Physical and Nonlinearity/v:Physical Parameters/Reed Stiffness",0.3,0,1,0.01);
blowPosition = hslider("h:Physical and Nonlinearity/v:Physical Parameters/Blow Position",0.5,0,1,0.01);
noiseGain = hslider("h:Physical and Nonlinearity/v:Physical Parameters/Noise Gain",0.05,0,1,0.01);

typeModulation = nentry("h:Physical and Nonlinearity/v:Nonlinear Filter Parameters/Modulation Type",0,0,4,1);
nonLinearity = hslider("h:Physical and Nonlinearity/v:Nonlinear Filter Parameters/Nonlinearity",0,0,1,0.01);
frequencyMod = hslider("h:Physical and Nonlinearity/v:Nonlinear Filter Parameters/Modulation Frequency",220,20,1000,0.1);
nonLinAttack = hslider("h:Physical and Nonlinearity/v:Nonlinear Filter Parameters/Nonlinearity Attack",0.1,0,2,0.01);

vibratoGain = hslider("h:Envelopes and Vibrato/v:Vibrato Parameters/Vibrato Gain",0.1,0,1,0.01);
vibratoFreq = hslider("h:Envelopes and Vibrato/v:Vibrato Parameters/Vibrato Freq",6,1,15,0.01);
vibratoBegin = hslider("h:Envelopes and Vibrato/v:Vibrato Parameters/Vibrato Begin",0.05,0,2,0.01);
vibratoAttack = hslider("h:Envelopes and Vibrato/v:Vibrato Parameters/Vibrato Attack",0.3,0,2,0.01);
vibratoRelease = hslider("h:Envelopes and Vibrato/v:Vibrato Parameters/Vibrato Release",0.1,0,2,0.01);

envelopeAttack = hslider("h:Envelopes and Vibrato/v:Envelope Parameters/Envelope Attack",0.05,0,2,0.01);
envelopeRelease = hslider("h:Envelopes and Vibrato/v:Envelope Parameters/Envelope Release",0.01,0,2,0.01);

//==================== SIGNAL PROCESSING ================

//----------------------- Nonlinear filter ----------------------------
//nonlinearities are created by the nonlinear passive allpass ladder filter declared in filter.lib

//nonlinear filter order
nlfOrder = 6; 

//attack - sustain - release envelope for nonlinearity (declared in instrument.lib)
envelopeMod = asr(nonLinAttack,100,envelopeRelease,gate);

//nonLinearModultor is declared in instrument.lib, it adapts allpassnn from filter.lib 
//for using it with waveguide instruments
NLFM =  nonLinearModulator((nonLinearity : smooth(0.999)),envelopeMod,freq,
     typeModulation,(frequencyMod : smooth(0.999)),nlfOrder);

//----------------------- Synthesis parameters computing and functions declaration ----------------------------

//stereoizer is declared in instrument.lib and implement a stereo spacialisation in function of 
//the frequency period in number of samples 
stereo = stereoizer(SR/freq);

//reed table parameters
reedTableOffset = 0.7;
reedTableSlope = 0.1 + (0.4*reedStiffness);

//the reed function is declared in instrument.lib
reedTable = reed(reedTableOffset,reedTableSlope);

//Delay lines length in number of samples
fdel1 = (1-blowPosition) * (SR/freq - 3);
fdel2 = (SR/freq - 3)*blowPosition +1 ;

//Delay lines
delay1 = fdelay(4096,fdel1);
delay2 = fdelay(4096,fdel2);

//Breath pressure is controlled by an attack / sustain / release envelope (asr is declared in instrument.lib)
envelope = (0.55+pressure*0.3)*asr(pressure*envelopeAttack,100,pressure*envelopeRelease,gate);
breath = envelope + envelope*noiseGain*noise;

//envVibrato is decalred in instrument.lib
vibrato = vibratoGain*envVibrato(vibratoBegin,vibratoAttack,100,vibratoRelease,gate)*osc(vibratoFreq);
breathPressure = breath + breath*vibratoGain*osc(vibratoFreq);

//Body filter is a one zero filter (declared in instrument.lib)
bodyFilter = *(gain) : oneZero1(b0,b1)
	with{
		gain = -0.95;
		b0 = 0.5;
		b1 = 0.5;	
	};

instrumentBody(delay1FeedBack,breathP) = delay1FeedBack <: -(delay2) <: 
	((breathP - _ <: breathP - _*reedTable) - delay1FeedBack),_;

process =
	(bodyFilter,breathPressure : instrumentBody) ~ 
	(delay1 : NLFM) : !,
	//Scaling Output and stereo
	*(0.3)*gain : stereo;