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

frequency = nentry("h:Basic Parameters/freq", 1, 20, 20000, 1);
gate = nentry("playGate",1,0,1,1);

bowPosition = hslider("v:Physical Parameters/bowPosition",0.01,0.01,1,0.01);
force = hslider("v:Physical Parameters/force",0,0,7,0.01)/7*0.3;
bowVel = hslider("bowVel",0,0,130,0.01)/127;
filterGain = hslider("filterGain",0.95,0,1,0.01);
filterPole = hslider("filterPole",0.6,0,1,0.01);

vibratoGain = hslider("v:Vibrato Parameters/vibratoGain",0,0,1,0.01);
vibratoFreq = hslider("v:Vibrato Parameters/vibratoFreq",6,1,15,0.1);

//==================== SIGNAL PROCESSING ================ 

//Parameters for bow table look-up
tableOffset =  0;
tableSlope = 5 - (4*force);
bowTable = bow(tableOffset,tableSlope);

maxVelocity = 0.03 + 0.2;
bowVelocity = maxVelocity*bowVel;

//Delay lines declaration
betaRatio = 0.027236 + (0.2*bowPosition) : _*1.6;
fdelneck = (SR/frequency-4) * (1 - betaRatio);
//vibratoEnvelope = envVibrato(vibratoBegin,vibratoAttack,100,vibratoRelease,gate);
vibrato = fdelneck + ((SR/frequency-4)*vibratoGain*osc(vibratoFreq));
neckDelay = fdelay(4096,vibrato);
fdelbridge = (SR/frequency-4) * betaRatio;
bridgeDelay = delay(4096,fdelbridge);

//Body Filter: a biquad filter with a normalized pick gain
bodyFilter = bandPass(500,0.85);

//String Filter: a lowpass filter
stringFilter = _*filterGain : -onePole(b0,a1)
	with{
		pole = filterPole - (0.1*22050/SR);
		b0 = 1-pole;
		a1 = -pole;	
	};

//bowVelocity = envelope*maxVelocity;
forceCondition = force > 0;
instrumentBody(feedBckBridge) = (_*-1 <: _ + feedBckBridge,_ : (bowVelocity-_ <: bowTable*_ : _*forceCondition*gate <: _,_),_ : 
	_,_+_ : _ + feedBckBridge,_) ~ neckDelay : !,_;

process = (stringFilter : instrumentBody) ~ bridgeDelay : bodyFilter(_*0.2);

//process = string : _*gain <: _,_;