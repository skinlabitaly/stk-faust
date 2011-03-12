declare name "Blowed Botle instrument";
declare author "Romain Michon (rmichon@ccrma.stanford.edu)";
declare copyright "Romain Michon";
declare version "1.0";
declare licence "STK-4.3"; // Synthesis Tool Kit 4.3 (MIT style license);
declare description "This object implements a helmholtz resonator (biquad filter) with a polynomial jet excitation (a la Cook).";

import("math.lib");
import("music.lib");
import("instrument.lib");

//==================== GUI SPECIFICATION ================

freq = nentry("h:Basic Parameters/freq", 440, 20, 20000, 1);
gain = nentry("h:Basic Parameters/gain", 0.9, 0, 1, 0.01); 
gate = button("h:Basic Parameters/gate");

noiseGain = hslider("v:Physical Parameters/noiseGain",0.5,0,1,0.01)*2;
pressure = hslider("v:Physical Parameters/pressure",1,0,1,0.01);

vibratoGain = hslider("v:Vibrato Parameters/vibratoGain",0.1,0,1,0.01);
vibratoFreq = hslider("v:Vibrato Parameters/vibratoFreq",6,1,15,0.1);
vibratoBegin = hslider("v:Vibrato Parameters/vibratoBegin",0.05,0,2,0.01);
vibratoAttack = hslider("v:Vibrato Parameters/vibratoAttack",0.5,0,2,0.01);
vibratoRelease = hslider("v:Vibrato Parameters/vibratoRelease",0.1,0,2,0.01);

envelopeAttack = hslider("v:Envelope Parameters/envelopeAttack",0.01,0,2,0.01);
envelopeDecay = hslider("v:Envelope Parameters/envelopeDecay",0.01,0,2,0.01);
envelopeRelease = hslider("v:Envelope Parameters/envelopeRelease",0.5,0,2,0.01);

//Nonlinear filter parameters
typeModulation = nentry("v:Nonlinear Filter/typeMod",0,0,4,1);
nonLinearity = hslider("v:Nonlinear Filter/Nonlinearity",0,0,1,0.01) : smooth(0.999);
frequencyMod = hslider("v:Nonlinear Filter/freqMod",220,20,1000,0.1) : smooth(0.999);
nonLinAttack = hslider("v:Nonlinear Filter/nonLinAttack",0.1,0,2,0.01);

//==================== SIGNAL PROCESSING ================

botleRadius = 0.999;

//global envelope
envelopeG =  gain*adsr(gain*envelopeAttack,envelopeDecay,80,envelopeRelease,gate);

//pressure envelope (ADSR)
envelope = pressure*adsr(gain*0.02,0.01,80,gain*0.2,gate);

//vibrato
vibrato = osc(vibratoFreq)*vibratoGain*envVibrato(vibratoBegin,vibratoAttack,100,vibratoRelease,gate)*osc(vibratoFreq);

nlfOrder = 6; 
envelopeMod = asr(nonLinAttack,100,envelopeRelease,gate);
nonLinMod =  nonLinearModulator(nonLinearity,envelopeMod,freq,typeModulation,frequencyMod,nlfOrder);
NLFM = _ <: (nonLinMod*nonLinearity,_*(1-nonLinearity) :> +)*(typeModulation < 3),nonLinMod*(typeModulation >= 3) :> _;

breathPressure = envelope+vibrato;

//breath noise
randPressure = noiseGain*noise*breathPressure ;

stereo = stereoizer(SR/freq);

process = 
	//differential pressure
	(breathPressure - _ <: 
	((1 + _)*randPressure : breathPressure + _) - jetTable*_,_ : bandPass(freq,botleRadius),_)~NLFM : !,_ : 
	//signal scaling
	dcblocker*envelopeG*0.5 : stereo;