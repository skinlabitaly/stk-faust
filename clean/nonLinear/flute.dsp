declare name "WaveGuide Flute";
declare author "Romain Michon (rmichon@ccrma.stanford.edu)";
declare copyright "Romain Michon";
declare version "1.0";
declare licence "STK-4.3"; // Synthesis Tool Kit 4.3 (MIT style license);
declare description "A simple flute based on Smith algorythm: https://ccrma.stanford.edu/~jos/pasp/Flutes_Recorders_Pipe_Organs.html"; 

import("math.lib");
import("music.lib");
import("instrument.lib");

//==================== GUI SPECIFICATION ================

freq = nentry("h:Basic Parameters/freq", 440, 20, 20000, 1);
gain = 5*nentry("h:Basic Parameters/gain", 1, 0, 1, 0.01); 
gate = button("h:Basic Parameters/gate");

noiseGain = hslider("v:Physical Parameters/noiseGain",0.2,0,1,0.01)/100;
pressure = hslider("v:Physical Parameters/presure",0.99,0,1,0.01) : smooth(0.999);

vibratoFreq = hslider("v:Vibrato Parameters/vibratoFreq",5,3,10,0.1);
vibratoGain = hslider("v:Vibrato Parameters/vibratoGain",0.5,0,1,0.01);
vibratoBegin = hslider("v:Vibrato Parameters/vibratoBegin",0.5,0,2,0.01);
vibratoAttack = hslider("v:Vibrato Parameters/vibratoAttack",0.5,0,2,0.01);
vibratoRelease = hslider("v:Vibrato Parameters/vibratoRelease",0.01,0,2,0.01);

envelopeAttack = hslider("v:Envelope Parameters/envelopeAttack",0.06,0,2,0.01);
envelopeDecay = hslider("v:Envelope Parameters/envelopeDecay",0.2,0,2,0.01);
envelopeRelease = hslider("v:Envelope Parameters/envelopeRelease",0.3,0,2,0.01);

//Nonlinear filter parameters
typeModulation = checkbox("v:Nonlinear Filter/typeMod");
signalModType = nentry("v:Nonlinear Filter/sigModType",0,0,2,1);
nonlinearity = hslider("v:Nonlinear Filter/Nonlinearity",0,0,1,0.01) : smooth(0.999);
frequencyMod = hslider("v:Nonlinear Filter/freqMod",220,20,1000,0.1) : smooth(0.999);
followFreq = checkbox("v:Nonlinear Filter/followFreq");
nonLinAttack = hslider("v:Nonlinear Filter/nonLinAttack",0.1,0,2,0.01);
nonLinDecay = hslider("v:Nonlinear Filter/nonLinDecay",0.05,0,2,0.01);
nonLinRelease = hslider("v:Nonlinear Filter/nonLinRelease",0.2,0,2,0.01);

//==================== SIGNAL PROCESSING ================

//Envelopes for pressure, vibrato and the global amplitude
pressureEnvelope = pressure*adsr(envelopeAttack,envelopeDecay,100,envelopeRelease,gate);
vibratoEnvelope = vibratoGain*envVibrato(vibratoBegin,vibratoAttack,100,vibratoRelease,gate);

//Loops feedbacks gains
feedback1 = 0.4;
feedback2 = 0.4;

//Delay lines length in number of samples
fqc1 = (SR/freq - 3)/2;
fqc2 = SR/freq - 3;

//Polinomial
cubic(x) = (_-_*_*_);

vibrato = osc(vibratoFreq)*vibratoEnvelope*0.1;

envelopeMod = adsr(nonLinAttack,nonLinDecay,100,nonLinRelease,gate); 
nonLinMod =  nonLinearModulator(envelopeMod,followFreq,freq,signalModType,typeModulation,frequencyMod,6);

//Noise + vibrato + pressure
blow = pressureEnvelope <: (noiseGain*noise*_) + vibrato + (pressure*1.1*_);

process = blow : ((+ : delay(4096, fqc1)) ~ (_<:cubic : (+ : lowpass(1,2000) : delay(4096, fqc2)) ~ 
	(* (feedback2) : (nonLinMod)))*(feedback1)) : _*gain/4 <: _,_;