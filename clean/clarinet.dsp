declare name "WaveGuide Clarinet from STK";
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

freq = nentry("h:Basic Parameters/freq", 440, 20, 20000, 1);
gain = nentry("h:Basic Parameters/gain", 1, 0, 1, 0.01); 
gate = button("h:Basic Parameters/gate");

reedStiffness = hslider("v:Physical Parameters/reedStiffness",0.5,0,1,0.01);
noiseGain = hslider("v:Physical Parameters/noiseGain",0,0,1,0.01);
pressure = hslider("v:Physical Parameters/pressure",1,0,1,0.01);

vibratoFreq = hslider("v:Vibrato Parameters/vibratoFreq",5,1,15,0.1);
vibratoGain = hslider("v:Vibrato Parameters/vibratoGain",0.1,0,1,0.01);
vibratoAttack = hslider("v:Vibrato Parameters/vibratoAttack",0.5,0,2,0.01);
vibratoRelease = hslider("v:Vibrato Parameters/vibratoRelease",0.01,0,2,0.01);

envelopeAttack = hslider("v:Envelope Parameters/envelopeAttack",0.01,0,2,0.01);
envelopeDecay = hslider("v:Envelope Parameters/envelopeDecay",0.05,0,2,0.01);
envelopeRelease = hslider("v:Envelope Parameters/envelopeRelease",0.1,0,2,0.01);

//==================== SIGNAL PROCESSING ================

//reed table parameters
reedTableOffset = 0.7;
reedTableSlope = -0.44 + (0.26*reedStiffness);
reedTable = reed(reedTableOffset,reedTableSlope);

//Delay line 
delayLength = SR/freq*0.5 - 1.5;
delayLine = delay(4096,delayLength);

//One zero filter with with pole at -1
filter = oneZero0(0.5,0.5);

//Breath pressure + vibrato + breath noise + envelope (Attack / Decay / Sustain / Release)
envelope = adsr(envelopeAttack,envelopeDecay,100,envelopeRelease,gate)*pressure*0.9;
vibrato = osc(vibratoFreq)*vibratoGain*envVibrato(0.1*2*vibratoAttack,0.9*2*vibratoAttack,100,vibratoRelease,gate);
breath = envelope + envelope*noise*noiseGain;
breathPressure = breath + breath*vibrato;

process =
	//Commuted Loss Filtering
	(filter*-0.95 - breathPressure <: 
	//Non-Linear Scattering
	reedTable*_ + breathPressure) ~ 
	//Delay with Feedback
	delayLine : 
	//scaling and stereo
	_*gain <: _,_; 