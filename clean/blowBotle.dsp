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

//==================== SIGNAL PROCESSING ================

botleRadius = 0.999;

//global envelope
envelopeG =  gain*adsr(gain*envelopeAttack,envelopeDecay,80,envelopeRelease,gate);

//pressure envelope (ADSR)
envelope = pressure*adsr(gain*0.02,0.01,80,gain*0.02,gate);

//vibrato
vibrato = osc(vibratoFreq)*vibratoGain*envVibrato(vibratoBegin,vibratoAttack,100,vibratoRelease,gate)*osc(vibratoFreq);

breathPressure = envelope+vibrato;

//breath noise
randPressure = noiseGain*noise*breathPressure ;

process = 
	//differential pressure
	(breathPressure - _ <: 
	((1 + _)*randPressure : breathPressure + _) - (jetTable*_),_ : bandPass(freq,botleRadius),_)~_ : !,_ : 
	//signal scaling
	dcblocker*envelopeG*0.5 <: _,_;