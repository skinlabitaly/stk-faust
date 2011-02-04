declare name "WaveGuide Bowed Instrument from STK";
declare author "Romain Michon";
declare copyright "Romain Michon (rmichon@ccrma.stanford.edu)";
declare version "1.0";
declare licence "STK-4.3"; // Synthesis Tool Kit 4.3 (MIT style license);
declare description "A bowed string model, a la Smith (1986), after McIntyre, Schumacher, Woodhouse (1983).";
declare reference "https://ccrma.stanford.edu/~jos/pasp/Bowed_Strings.html";

import("math.lib");
import("music.lib");
import("instrument.lib");

//==================== GUI SPECIFICATION ================

freq = nentry("h:Basic Parameters/freq", 440, 20, 20000, 1);
gain = nentry("h:Basic Parameters/gain", 0.9, 0, 1, 0.01); 
gate = button("h:Basic Parameters/gate");

bowPosition = hslider("v:Physical Parameters/bowPosition",0.7,0.01,1,0.01);
bowPressure = hslider("v:Physical Parameters/bowPressure",0.75,0,1,0.01);

vibratoGain = hslider("v:Vibrato Parameters/vibratoGain",0.02,0,1,0.01);
vibratoFreq = hslider("v:Vibrato Parameters/vibratoFreq",6,1,15,0.1);
vibratoBegin = hslider("v:Vibrato Parameters/vibratoBegin",0.05,0,2,0.01);
vibratoAttack = hslider("v:Vibrato Parameters/vibratoAttack",0.5,0,2,0.01);
vibratoRelease = hslider("v:Vibrato Parameters/vibratoRelease",0.1,0,2,0.01);

envelopeAttack = hslider("v:Envelope Parameters/envelopeAttack",0.01,0,2,0.01);
envelopeDecay = hslider("v:Envelope Parameters/envelopeDecay",0.05,0,2,0.01);
envelopeRelease = hslider("v:Envelope Parameters/envelopeRelease",0.1,0,2,0.01);

//==================== SIGNAL PROCESSING ================

//Parameters for bow table look-up
tableOffset =  0;
tableSlope = 5 - (4*bowPressure);
bowTable = bow(tableOffset,tableSlope);

//The shape of the envelope (ADSR) is calculated in function of the global amplitude
envelope = adsr(gain*envelopeAttack,envelopeDecay,90, (1-gain)*envelopeRelease,gate);
maxVelocity = 0.03 + (0.2 * gain);

//Delay lines declaration
betaRatio = 0.027236 + (0.2*bowPosition);
fdelneck = (SR/freq-4) * (1 - betaRatio);
vibratoEnvelope = envVibrato(vibratoBegin,vibratoAttack,100,vibratoRelease,gate);
vibrato = fdelneck + ((SR/freq-4)*vibratoGain*vibratoEnvelope*osc(vibratoFreq));
neckDelay = fdelay(4096,vibrato);
fdelbridge = (SR/freq-4) * betaRatio;
bridgeDelay = delay(4096,fdelbridge);

//Body Filter: a biquad filter with a normalized pick gain
bodyFilter = bandPass(500,0.85);

//String Filter: a lowpass filter
stringFilter = _*0.95 : -onePole(b0,a1)
	with{
		pole = 0.6 - (0.1*22050/SR);
		gain = 0.95;
		b0 = 1-pole;
		a1 = -pole;	
	};

bowVelocity = envelope*maxVelocity;
instrumentBody(x) = (_*-1 <: _ + x,_ : (bowVelocity-_ <: bowTable*_ <: _,_),_ : _,_+_ : _ + x,_) ~ neckDelay : !,_;

process = (stringFilter : instrumentBody) ~ bridgeDelay : bodyFilter(_*0.2) : 
	_*gain <: _,_;