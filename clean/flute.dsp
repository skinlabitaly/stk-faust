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

noiseGain = hslider("v:Physical Parameters/noiseGain",0.4,0,1,0.01)/100;
pressure = hslider("v:Physical Parameters/presure",0.9,0,1,0.01);

vibratoFreq = hslider("v:Vibrato Parameters/vibratoFreq",5,3,10,0.1);
vibratoGain = hslider("v:Vibrato Parameters/vibratoGain",0.5,0,1,0.01);
vibratoBegin = hslider("v:Vibrato Parameters/vibratoBegin",0.5,0,2,0.01);
vibratoAttack = hslider("v:Vibrato Parameters/vibratoAttack",0.5,0,2,0.01);
vibratoRelease = hslider("v:Vibrato Parameters/vibratoRelease",0.01,0,2,0.01);

envelopeAttack = hslider("v:Envelope Parameters/envelopeAttack",0.06,0,2,0.01);
envelopeDecay = hslider("v:Envelope Parameters/envelopeDecay",0.2,0,2,0.01);
envelopeRelease = hslider("v:Envelope Parameters/envelopeRelease",0.1,0,2,0.01);

//==================== SIGNAL PROCESSING ================

//Envelopes for pressure, vibrato and the global amplitude
pressureEnvelope = adsr(envelopeAttack,envelopeDecay,100*pressure,envelopeRelease,gate);
vibratoEnvelope = vibratoGain*envVibrato(vibratoBegin,vibratoAttack,100,vibratoRelease,gate);

//Loops feedbacks gains
feedback1 = 0.4;
feedback2 = 0.4;

//Delay lines length in number of samples
fqc1 = (SR/freq - 10)/2;
fqc2 = SR/freq - 10;

//Polinomial
cubic(x) = (_-_*_*_);

vibrato = osc(vibratoFreq)*vibratoEnvelope*0.1;

//Noise + vibrato + pressure
blow = pressureEnvelope <: (noiseGain*noise*_) + vibrato + (pressure*1.1*_);

process = blow : ((+ : delay(4096, fqc1)) ~ (_<:cubic : (+ : lowpass(1,2000) : delay(4096, fqc2)) ~ 
	(* (feedback2)))*(feedback1)) : _*gain <: _,_;