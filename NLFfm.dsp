declare name "FM synthesizer implemented with a nonlinear passive allpass filter";
declare author "Romain Michon";
declare copyright "Romain Michon (rmichon@ccrma.stanford.edu)";
declare version "1.0";

import("instrument.lib");
import("music.lib");

//==================== GUI SPECIFICATION ================

freq = hslider("h:Basic Parameters/freq", 440, 20, 20000, 1);
gain = hslider("h:Basic Parameters/gain", 1, 0, 1, 0.01); 
gate = button("h:Basic Parameters/gate");

typeModulation = nentry("h:Physical and Nonlinearity/v:Nonlinear Filter Parameters/Modulation Type",0,0,4,1);
nonLinearity = hslider("h:Physical and Nonlinearity/v:Nonlinear Filter Parameters/Nonlinearity",0,0,1,0.01);
frequencyMod = hslider("h:Physical and Nonlinearity/v:Nonlinear Filter Parameters/Modulation Frequency",220,20,1000,0.1);
nonLinAttack = hslider("h:Physical and Nonlinearity/v:Nonlinear Filter Parameters/Nonlinearity Attack",0.1,0,2,0.01);

vibratoFreq = hslider("h:Envelopes and Vibrato/v:Vibrato Parameters/Vibrato Freq",5,1,15,0.1);
vibratoGain = hslider("h:Envelopes and Vibrato/v:Vibrato Parameters/Vibrato Gain",0.1,0,1,0.01);
vibratoAttack = hslider("h:Envelopes and Vibrato/v:Vibrato Parameters/Vibrato Attack",0.5,0,2,0.01);
vibratoRelease = hslider("h:Envelopes and Vibrato/v:Vibrato Parameters/Vibrato Release",0.01,0,2,0.01);

envelopeAttack = hslider("h:Envelopes and Vibrato/v:Envelope Parameters/Envelope Attack",0.05,0,2,0.01);
envelopeDecay = hslider("h:Envelopes and Vibrato/v:Envelope Parameters/Envelope Decay",0.05,0,2,0.01);
envelopeRelease = hslider("h:Envelopes and Vibrato/v:Envelope Parameters/Envelope Release",0.05,0,2,0.01);

//----------------------- Nonlinear filter ----------------------------
//nonlinearities are created by the nonlinear passive allpass ladder filter declared in filter.lib

//nonlinear filter order
nlfOrder = 3; 

//attack - sustain - release envelope for nonlinearity (declared in instrument.lib)
envelopeMod = asr(nonLinAttack,100,envelopeRelease,gate);

//nonLinearModultor is declared in instrument.lib, it adapts allpassnn from filter.lib 
//for using it with waveguide instruments
NLFM =  nonLinearModulator((nonLinearity : smooth(0.999)),envelopeMod,freq,
     typeModulation,(frequencyMod : smooth(0.999)),nlfOrder);

//----------------------- Algorithm implementation ----------------------------

//stereoizer is declared in instrument.lib and implement a stereo spacialisation in function of 
//the frequency period in number of samples 
stereo = stereoizer(SR/freq);

//vibrato gain is controled by envVibrato (declared in instrument.LIB)
vibrato = osc(vibratoFreq)*vibratoGain*envVibrato(0.1*2*vibratoAttack,0.9*2*vibratoAttack,100,vibratoRelease,gate);

//output gain is controled by an adsr envelope
envelope = adsr(envelopeAttack,envelopeDecay,90,envelopeRelease,gate)*gain;
breath = envelope + envelope*vibrato;

process = osc(freq)*breath : NLFM : stereo;