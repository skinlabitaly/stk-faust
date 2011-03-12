declare name "WaveGuide Brass instrument from STK";
declare author "Romain Michon (rmichon@ccrma.stanford.edu)";
declare copyright "Romain Michon";
declare version "1.0";
declare licence "STK-4.3"; // Synthesis Tool Kit 4.3 (MIT style license);
declare description "A simple brass instrument waveguide model, a la Cook (TBone, HosePlayer).";
declare reference "https://ccrma.stanford.edu/~jos/pasp/Brasses.html"; 

import("math.lib");
import("music.lib");
import("instrument.lib");

//==================== GUI SPECIFICATION ================

freq = nentry("h:Basic Parameters/freq", 440, 100, 2000, 1);
gain = nentry("h:Basic Parameters/gain", 1, 0, 1, 0.01); 
gate = button("h:Basic Parameters/gate");

pressure = hslider("v:Physical Parameters/pressure",1,0.01,1,0.01);
lipTension = hslider("v:Physical Parameters/lipTension",0.5,0.01,1,0.01);
slideLength = hslider("v:Physical Parameters/slideLength",0.5,0.01,1,0.01);

vibratoFreq = hslider("v:Vibrato Parameters/vibratoFreq",6,1,15,0.1);
vibratoGain = hslider("v:Vibrato Parameters/vibratoGain",0.05,0,1,0.01);
vibratoBegin = hslider("v:Vibrato Parameters/vibratoBegin",0.05,0,2,0.01);
vibratoAttack = hslider("v:Vibrato Parameters/vibratoAttack",0.5,0,2,0.01);
vibratoRelease = hslider("v:Vibrato Parameters/vibratoRelease",0.1,0,2,0.01);

envelopeAttack = hslider("v:Envelope Parameters/envelopeAttack",0.005,0,2,0.01);
envelopeDecay = hslider("v:Envelope Parameters/envelopeDecay",0.001,0,2,0.01);
envelopeRelease = hslider("v:Envelope Parameters/envelopeRelease",0.07,0,2,0.01);

//Nonlinear filter parameters
typeModulation = nentry("v:Nonlinear Filter/typeMod",0,0,4,1);
nonLinearity = hslider("v:Nonlinear Filter/Nonlinearity",0,0,1,0.01) : smooth(0.999);
frequencyMod = hslider("v:Nonlinear Filter/freqMod",220,20,1000,0.1) : smooth(0.999);
nonLinAttack = hslider("v:Nonlinear Filter/nonLinAttack",0.1,0,2,0.01);

//==================== SIGNAL PROCESSING ================

//lips are simulated by a biquad filter whose output is squared and hard-clipped
lipFilterFrequency = freq*pow(4,(2*lipTension)-1);
lipFilter = bandPassH(lipFilterFrequency,0.997) <: _*_ : saturationPos;

//vibrato
vibrato = vibratoGain*osc(vibratoFreq)*envVibrato(vibratoBegin,vibratoAttack,100,vibratoRelease,gate);

nlfOrder = 6;
envelopeMod = asr(nonLinAttack,100,envelopeRelease,gate);
nonLinMod =  nonLinearModulator(nonLinearity,envelopeMod,freq,typeModulation,frequencyMod,nlfOrder);
NLFM = _ <: (nonLinMod*nonLinearity,_*(1-nonLinearity) :> +)*(typeModulation < 3),nonLinMod*(typeModulation >= 3) :> _;

//delay times in number of samples
slideTarget = ((SR/freq)*2 + 3)*(0.5 + slideLength);
boreDelay = delay(4096,slideTarget);

//envelope (Attack / Decay / Sustain / Release), breath pressure and vibrato
breathPressure = pressure*adsr(envelopeAttack,envelopeDecay,100,envelopeRelease,gate) + vibrato;
mouthPressure = 0.3*breathPressure;

//scale the delay feedback
borePressure = _*0.85;

//differencial presure
deltaPressure = mouthPressure - _;

bore(boreDelayFeedBck) = deltaPressure(boreDelayFeedBck) : _*0.03 : 
	lipFilter <: _*mouthPressure,(1-_)*boreDelayFeedBck :> + ;

stereo = stereoizer(SR/freq);

process = (borePressure <: bore :
		  //Body Filter
		  dcblocker) ~ (boreDelay : NLFM) :
		  //scaling and stereo
		  _*gain : stereo;