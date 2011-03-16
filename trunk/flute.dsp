declare name "Nonlinear WaveGuide Flute";
declare author "Romain Michon (rmichon@ccrma.stanford.edu)";
declare copyright "Romain Michon";
declare version "1.0";
declare licence "STK-4.3"; // Synthesis Tool Kit 4.3 (MIT style license);
declare description "A simple flute based on Smith algorythm: https://ccrma.stanford.edu/~jos/pasp/Flutes_Recorders_Pipe_Organs.html"; 

import("music.lib");
import("instrument.lib");

//==================== GUI SPECIFICATION ================

freq = nentry("h:Basic Parameters/freq", 440, 20, 20000, 1);
gain = 5*nentry("h:Basic Parameters/gain", 1, 0, 1, 0.01); 
gate = button("h:Basic Parameters/gate");

noiseGain = hslider("h:Physical and Nonlinearity/v:Physical Parameters/Noise Gain",0.2,0,1,0.01)/100;
pressure = hslider("h:Physical and Nonlinearity/v:Physical Parameters/Noise Presure",0.99,0,1,0.01) : smooth(0.999);

typeModulation = nentry("h:Physical and Nonlinearity/v:Nonlinear Filter Parameters/Modulation Type",0,0,4,1);
nonLinearity = hslider("h:Physical and Nonlinearity/v:Nonlinear Filter Parameters/Nonlinearity",0,0,1,0.01);
frequencyMod = hslider("h:Physical and Nonlinearity/v:Nonlinear Filter Parameters/Modulation Frequency",220,20,1000,0.1);
nonLinAttack = hslider("h:Physical and Nonlinearity/v:Nonlinear Filter Parameters/Nonlinearity Attack",0.1,0,2,0.01);

vibratoFreq = hslider("h:Envelopes and Vibrato/v:Vibrato Parameters/Vibrato Freq",5,3,10,0.1);
vibratoGain = hslider("h:Envelopes and Vibrato/v:Vibrato Parameters/Vibrato Gain",0.5,0,1,0.01);
vibratoBegin = hslider("h:Envelopes and Vibrato/v:Vibrato Parameters/Vibrato Begin",0.5,0,2,0.01);
vibratoAttack = hslider("h:Envelopes and Vibrato/v:Vibrato Parameters/Vibrato Attack",0.5,0,2,0.01);
vibratoRelease = hslider("h:Envelopes and Vibrato/v:Vibrato Parameters/Vibrato Release",0.01,0,2,0.01);

envelopeAttack = hslider("h:Envelopes and Vibrato/v:Envelope Parameters/Envelope Attack",0.06,0,2,0.01);
envelopeDecay = hslider("h:Envelopes and Vibrato/v:Envelope Parameters/Envelope Decay",0.2,0,2,0.01);
envelopeRelease = hslider("h:Envelopes and Vibrato/v:Envelope Parameters/Envelope Release",0.3,0,2,0.01);

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

//Loops feedbacks gains
feedback1 = 0.4;
feedback2 = 0.4;

//Delay lines
fqc1 = (SR/freq - 3)/2;
fqc2 = SR/freq - 3;
delay1 = fdelay(4096, fqc1);
delay2 = fdelay(4096, fqc2);

//Polinomial
cubic = _ <: (_ - _*_*_);

//jet filter is a lowwpass filter (declared in filter.lib)
jetFilter = lowpass(1,2000);

//stereoizer is declared in instrument.lib and implement a stereo spacialisation in function of 
//the frequency period in number of samples 
stereo = stereoizer(SR/freq);

//----------------------- Algorithm implementation ----------------------------

//Envelopes for pressure, vibrato and the global amplitude, adsr and envVibrato are declared in instrument.lib
pressureEnvelope = pressure*adsr(envelopeAttack,envelopeDecay,100,envelopeRelease,gate);
vibratoEnvelope = vibratoGain*envVibrato(vibratoBegin,vibratoAttack,100,vibratoRelease,gate);

vibrato = osc(vibratoFreq)*vibratoEnvelope*0.1;

//Noise + vibrato + pressure
blow = pressureEnvelope <: (noiseGain*noise*_) + vibrato + (pressure*1.1*_);

process = blow : ((+ : delay1) ~ (cubic : (+ : jetFilter : delay2 : NLFM) ~ 
	(* (feedback2) : /(2)))*(feedback1)) : *(gain)/4 : stereo;