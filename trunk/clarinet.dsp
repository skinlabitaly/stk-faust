declare name "Nonlinear WaveGuide Clarinet";
declare author "Romain Michon";
declare copyright "Romain Michon (rmichon@ccrma.stanford.edu)";
declare version "1.0";
declare licence "STK-4.3"; // Synthesis Tool Kit 4.3 (MIT style license);
declare description "A simple clarinet physical model, as discussed by Smith (1986), McIntyre, Schumacher, Woodhouse (1983), and others.";
declare reference "https://ccrma.stanford.edu/~jos/pasp/Woodwinds.html";

import("math.lib");
import("music.lib");
import("instrument.lib");

//==================== GUI SPECIFICATION ================

freq = nentry("h:Basic Parameters/freq",440,20,20000,1);
gain = nentry("h:Basic Parameters/gain",1,0,1,0.01); 
gate = button("h:Basic Parameters/gate");

reedStiffness = hslider("h:Physical and Nonlinearity/v:Physical Parameters/Reed Stiffness",0.5,0,1,0.01);
noiseGain = hslider("h:Physical and Nonlinearity/v:Physical Parameters/Noise Gain",0,0,1,0.01);
pressure = hslider("h:Physical and Nonlinearity/v:Physical Parameters/Pressure",1,0,1,0.01);

typeModulation = nentry("h:Physical and Nonlinearity/v:Nonlinear Filter Parameters/Modulation Type",0,0,4,1);
nonLinearity = hslider("h:Physical and Nonlinearity/v:Nonlinear Filter Parameters/Nonlinearity",0,0,1,0.01);
frequencyMod = hslider("h:Physical and Nonlinearity/v:Nonlinear Filter Parameters/Modulation Frequency",220,20,1000,0.1);
nonLinAttack = hslider("h:Physical and Nonlinearity/v:Nonlinear Filter Parameters/Nonlinearity Attack",0.1,0,2,0.01);

vibratoFreq = hslider("h:Envelopes and Vibrato/v:Vibrato Parameters/Vibrato Freq",5,1,15,0.1);
vibratoGain = hslider("h:Envelopes and Vibrato/v:Vibrato Parameters/Vibrato Gain",0.1,0,1,0.01);
vibratoAttack = hslider("h:Envelopes and Vibrato/v:Vibrato Parameters/Vibrato Attack",0.5,0,2,0.01);
vibratoRelease = hslider("h:Envelopes and Vibrato/v:Vibrato Parameters/Vibrato Release",0.01,0,2,0.01);

envelopeAttack = hslider("h:Envelopes and Vibrato/v:Envelope Parameters/Envelope Attack",0.01,0,2,0.01);
envelopeDecay = hslider("h:Envelopes and Vibrato/v:Envelope Parameters/Envelope Decay",0.05,0,2,0.01);
envelopeRelease = hslider("h:Envelopes and Vibrato/v:Envelope Parameters/Envelope Release",0.1,0,2,0.01);

//==================== SIGNAL PROCESSING ======================

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

//reed table parameters
reedTableOffset = 0.7;
reedTableSlope = -0.44 + (0.26*reedStiffness);

//the reed function is declared in instrument.lib
reedTable = reed(reedTableOffset,reedTableSlope);

//delay line with a length adapted in function of the order of nonlinear filter
delayLength = SR/freq*0.5 - 1.5 - (nlfOrder*nonLinearity)*(typeModulation < 2);
delayLine = fdelay(4096,delayLength);

//one zero filter used as a allpass: pole is set to -1
filter = oneZero0(0.5,0.5);

//stereoizer is declared in instrument.lib and implement a stereo spacialisation in function of 
//the frequency period in number of samples 
stereo = stereoizer(SR/freq);

//----------------------- Algorithm implementation ----------------------------

//Breath pressure + vibrato + breath noise + envelope (Attack / Decay / Sustain / Release)
envelope = adsr(envelopeAttack,envelopeDecay,100,envelopeRelease,gate)*pressure*0.9;

vibrato = osc(vibratoFreq)*vibratoGain*
	envVibrato(0.1*2*vibratoAttack,0.9*2*vibratoAttack,100,vibratoRelease,gate);
breath = envelope + envelope*noise*noiseGain;
breathPressure = breath + breath*vibrato;

process =
	//Commuted Loss Filtering
	(filter*-0.95 - breathPressure <: 
	
	//Non-Linear Scattering
	reedTable*_ + breathPressure) ~ 
	
	//Delay with Feedback
	(delayLine : NLFM) : 
	
	//scaling and stereo
	*(gain) : stereo ; 