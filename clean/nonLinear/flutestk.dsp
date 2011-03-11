declare name "WaveGuide Flute from STK";
declare author "Romain Michon";
declare copyright "Romain Michon (rmichon@ccrma.stanford.edu)";
declare version "1.0";
declare licence "STK-4.3"; // Synthesis Tool Kit 4.3 (MIT style license);
declare description "A simple flute physical model, as discussed by Karjalainen, Smith, Waryznyk, etc.  The jet model uses a polynomial, a la Cook.";
declare reference "https://ccrma.stanford.edu/~jos/pasp/Flutes_Recorders_Pipe_Organs.html"; 

import("math.lib");
import("music.lib");
import("instrument.lib");

//==================== GUI SPECIFICATION ================

freq = nentry("h:Basic Parameters/freq", 440, 20, 20000, 1);
gain = nentry("h:Basic Parameters/gain", 0.95, 0, 1, 0.01); 
gate = button("h:Basic Parameters/gate");

embouchureAjust = hslider("v:Physical Parameters/embouchureAjust",0.5,0,1,0.01);
noiseGain = hslider("v:Physical Parameters/noiseGain",0.03,0,1,0.01);
pressure = hslider("v:Physical Parameters/pressure",1,0,1,0.01);

vibratoGain = hslider("v:Vibrato Parameters/vibratoGain",0.05,0,1,0.01);
vibratoFreq = hslider("v:Vibrato Parameters/vibratoFreq",6,1,15,0.1);
vibratoBegin = hslider("v:Vibrato Parameters/vibratoBegin",0.05,0,2,0.01);
vibratoAttack = hslider("v:Vibrato Parameters/vibratoAttack",0.5,0,2,0.01);
vibratoRelease = hslider("v:Vibrato Parameters/vibratoRelease",0.1,0,2,0.01);

envelopeAttack = hslider("v:Envelope Parameters/envelopeAttack",0.03,0,2,0.01);
envelopeDecay = hslider("v:Envelope Parameters/envelopeDecay",0.01,0,2,0.01);
envelopeRelease = hslider("v:Envelope Parameters/envelopeRelease",0.3,0,2,0.01);

//Nonlinear filter parameters
typeModulation = nentry("v:Nonlinear Filter/typeMod",0,0,4,1);
nonLinearity = hslider("v:Nonlinear Filter/Nonlinearity",0,0,1,0.01) : smooth(0.999);
frequencyMod = hslider("v:Nonlinear Filter/freqMod",220,20,1000,0.1) : smooth(0.999);
nonLinAttack = hslider("v:Nonlinear Filter/nonLinAttack",0.1,0,2,0.01);

//==================== SIGNAL PROCESSING ================

jetReflexion = 0.5;
jetRatio = 0.08 + (0.48*embouchureAjust);
endReflexion = 0.5;

nlfOrder = 6; 
envelopeMod = invSineEnv(nonLinAttack,gate);
nonLinMod =  nonLinearModulator(nonLinearity,envelopeMod,freq,typeModulation,frequencyMod,nlfOrder);
NLFM = _ <: (nonLinMod*nonLinearity,_*(1-nonLinearity) :> +)*(typeModulation < 3),nonLinMod*(typeModulation >= 3) :> _;

//Delay lines lengths in number of samples
jetDelayLength = (SR/freq)*jetRatio;
boreDelayLength = SR/freq;
filterPole = 0.7 - (0.1*22050/SR);

//One Pole Filter
onePoleFilter = _*gain : onePole(b0,a1)
	with{
		gain = -1;
		pole = 0.7 - (0.1*22050/SR);
		b0 = 1-pole;
		a1 = -pole;
	};

vibrato = vibratoGain*envVibrato(vibratoBegin,vibratoAttack,100,vibratoRelease,gate)*osc(vibratoFreq);

//Breath pressure is controlled by an Attack / Decay / Sustain / Release envelope
envelopeBreath = pressure*adsr(pressure*envelopeAttack,envelopeDecay,80,envelopeRelease,gate);
breathPressure = envelopeBreath + envelopeBreath*(noiseGain*noise + vibrato);

jetDelay = delay(4096,jetDelayLength);
boreDelay = delay(4096,boreDelayLength);

filters = onePoleFilter : dcblocker;

stereo = stereoizer(boreDelayLength);

process =
	(filters <: 
	//Differential Pressure
	((breathPressure - _*jetReflexion) : 
	jetDelay : jetTable) + (_*endReflexion)) ~ (boreDelay : NLFM) : 
	//output scaling and stereo signal
	_*0.3*gain : stereo; 