declare name "Banded Waveguide Models";
declare author "Romain Michon";
declare copyright "Romain Michon (rmichon@ccrma.stanford.edu)";
declare version "1.0";
declare licence "STK-4.3"; // Synthesis Tool Kit 4.3 (MIT style license);
declare description "This instrument uses banded waveguide. For more information, see Essl, G. and Cook, P. Banded Waveguides: Towards Physical Modelling of Bar Percussion Instruments, Proceedings of the 1999 International Computer Music Conference. Presets numbers: 0->Tibetan Bowl, 1->Uni Bar, 2->TunedBar, 4->Glass Harmonica";

import("math.lib");
import("music.lib");
import("instrument.lib");

//==================== GUI SPECIFICATION ================

freq = nentry("h:Basic Parameters/freq", 440, 20, 20000, 1);
gain = nentry("h:Basic Parameters/gain", 0.8, 0, 1, 0.01); 
gate = button("h:Basic Parameters/gate") > 0;

select = nentry("v:Physical Parameters/selector",0,0,1,1);
//preset = 1;
integrationConstant = hslider("v:Physical Parameters/integrationConstant",0,0,1,0.01);
baseGain = hslider("v:Physical Parameters/baseGain",1,0,1,0.01);
bowPressure = hslider("v:Physical Parameters/bowPressure",0.2,0,1,0.01);
bowPosition = hslider("v:Physical Parameters/bowPosition",0,0,1,0.01);

//==================== MODAL PARAMETERS ================

preset = 2;

nMode(2) = 4;

modes(2,0) = 1;
basegains(2,0) = pow(0.999,1);
excitation(2,0) = 1*gain*gate/nMode(2);

modes(2,1) = 4.0198391420;
basegains(2,1) = pow(0.999,2);
excitation(2,1) = 1*gain*gate/nMode(2);

modes(2,2) = 10.7184986595;
basegains(2,2) = pow(0.999,3);
excitation(2,2) = 1*gain*gate/nMode(2);

modes(2,3) = 18.0697050938;
basegains(2,3) = pow(0.999,4);
excitation(2,3) = 1*gain*gate/nMode(2);

//==================== SIGNAL PROCESSING ================

nModes = nMode(preset);

tableOffset = 0;
tableSlope = 10 - (9*bowPressure);

base = SR/freq;

//delay lengths in number of samples
delayLength(x) = base/modes(preset,x);

//delay lines
delayLine(x) = delay(4096,delayLength(x));

//Filter bank: biquad filters
radius = 1 - PI*32/SR;
bandPassFilter(x) = bandPass(freq*modes(preset,x),radius);

//Delay lines feedback for bow table lookup control
baseGainApp = 0.8999999999999999 + (0.1*baseGain);
velocityInputApp = integrationConstant;
velocityInput = velocityInputApp + _*baseGainApp,par(i,(nModes-1),(_*baseGainApp)) :> +;

//Bow velocity is controled by an ADSR envelope
maxVelocity = 0.03 + 0.1*gain;
bowVelocity = maxVelocity*adsr(0.02,0.005,90,0.01,gate);

//Bow table lookup
bowing = bowVelocity - velocityInput <: _*bow(tableOffset,tableSlope) : _/nModes;

//One resonance
resonance(x) = + : + (excitation(preset,x)*select) : delayLine(x) : _*basegains(preset,x) : bandPassFilter(x);

process =
		//Bowed Excitation
		(bowing*((select-1)*-1) <:
		//nModes resonances with nModes feedbacks for bow table look-up 
		par(i,nModes,(resonance(i)~_)))~par(i,nModes,_) :> + : 
		//Signal Scaling and stereo
		_*4 <: _,_;