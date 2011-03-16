declare name "Nonlinear WaveGuide Bowed Instrument";
declare author "Romain Michon";
declare copyright "Romain Michon (rmichon@ccrma.stanford.edu)";
declare version "1.0";
declare licence "STK-4.3"; // Synthesis Tool Kit 4.3 (MIT style license);
declare description "A bowed string model, a la Smith (1986), after McIntyre, Schumacher, Woodhouse (1983).";
declare reference "https://ccrma.stanford.edu/~jos/pasp/Bowed_Strings.html";

import("music.lib");
import("instrument.lib");

//==================== GUI SPECIFICATION ================

freq = nentry("h:Basic Parameters/freq", 440, 20, 20000, 1);
gain = nentry("h:Basic Parameters/gain", 0.9, 0, 1, 0.01); 
gate = button("h:Basic Parameters/gate");

bowPosition = hslider("h:Physical and Nonlinearity/v:Physical Parameters/Bow Position",0.7,0.01,1,0.01);
bowPressure = hslider("h:Physical and Nonlinearity/v:Physical Parameters/Bow Pressure",0.75,0,1,0.01);

typeModulation = nentry("h:Physical and Nonlinearity/v:Nonlinear Filter/Modulation Type",0,0,4,1);
nonLinearity = hslider("h:Physical and Nonlinearity/v:Nonlinear Filter/Nonlinearity",0,0,1,0.01);
frequencyMod = hslider("h:Physical and Nonlinearity/v:Nonlinear Filter/Modulation Frequency",220,20,1000,0.1);
nonLinAttack = hslider("h:Physical and Nonlinearity/v:Nonlinear Filter/Nonlinearity Attack",0.1,0,2,0.01);

vibratoGain = hslider("h:Envelopes and Vibrato/v:Vibrato Parameters/Vibrato Gain",0.01,0,1,0.01);
vibratoFreq = hslider("h:Envelopes and Vibrato/v:Vibrato Parameters/Vibrato Freq",6,1,15,0.1);
vibratoBegin = hslider("h:Envelopes and Vibrato/v:Vibrato Parameters/Vibrato Begin",0.05,0,2,0.01);
vibratoAttack = hslider("h:Envelopes and Vibrato/v:Vibrato Parameters/Vibrato Attack",0.5,0,2,0.01);
vibratoRelease = hslider("h:Envelopes and Vibrato/v:Vibrato Parameters/Vibrato Release",0.1,0,2,0.01);

envelopeAttack = hslider("h:Envelopes and Vibrato/v:Envelope Parameters/Envelope Attack",0.01,0,2,0.01);
envelopeDecay = hslider("h:Envelopes and Vibrato/v:Envelope Parameters/Envelope Decay",0.05,0,2,0.01);
envelopeRelease = hslider("h:Envelopes and Vibrato/v:Envelope Parameters/Envelope Release",0.1,0,2,0.01);

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

//Parameters for the bow table
tableOffset =  0;
tableSlope = 5 - (4*bowPressure);

//the bow table is declared in instrument.lib
bowTable = bow(tableOffset,tableSlope);

//a attack - decay - sustain - release envelope is used 
envelope = adsr(gain*envelopeAttack,envelopeDecay,90, (1-gain)*envelopeRelease,gate);
maxVelocity = 0.03 + (0.2 * gain);

//Delay lines declaration and vibrato, the length of the two delay lines are evolving propotionally
betaRatio = 0.027236 + (0.2*bowPosition);
fdelneck = (SR/freq-4)*(1 - betaRatio);
vibratoEnvelope = envVibrato(vibratoBegin,vibratoAttack,100,vibratoRelease,gate);
vibrato = fdelneck + ((SR/freq - 4)*vibratoGain*vibratoEnvelope*osc(vibratoFreq));
neckDelay = fdelay(4096,vibrato);
fdelbridge = (SR/freq - 4)*betaRatio;
bridgeDelay = delay(4096,fdelbridge);

//Body Filter: a biquad filter with a normalized pick gain (declared in instrument.lib)
bodyFilter = bandPass(500,0.85);

//String Filter: a lowpass filter (declared in instrument.lib)
stringFilter = *(0.95) : -onePole(b0,a1)
	with{
		pole = 0.6 - (0.1*22050/SR);
		gain = 0.95;
		b0 = 1-pole;
		a1 = -pole;	
	};

//stereoizer is declared in instrument.lib and implement a stereo spacialisation in function of 
//the frequency period in number of samples 
stereo = stereoizer(SR/freq);

//----------------------- Algorithm implementation ----------------------------

bowVelocity = envelope*maxVelocity;
instrumentBody(feedBckBridge) = (*(-1) <: +(feedBckBridge),_ : (bowVelocity-_ <: *(bowTable) <: _,_),_ : 
	_, + : +(feedBckBridge),_) ~ (neckDelay) : !,_;

process = (stringFilter : instrumentBody) ~ (bridgeDelay : NLFM) : bodyFilter(*(0.2)) : 
	_*gain*8 : stereo;