declare name "WaveGuide Brass from STK";
declare author "Romain Michon (rmichon@ccrma.stanford.edu)";
declare copyright "Romain Michon";
declare version "1.0";
declare licence "STK-4.3"; // Synthesis Tool Kit 4.3 (MIT style license);
declare description "This instrument implements a sitar plucked string physical model based on the Karplus-Strong algorithm.";

import("math.lib");
import("music.lib");
import("instrument.lib");

//==================== GUI SPECIFICATION ================

freq = nentry("h:Basic Parameters/freq", 440, 100, 2000, 1);
gain = nentry("h:Basic Parameters/gain", 1, 0, 1, 0.01); 
gate = button("h:Basic Parameters/gate");

resonance = hslider("v:Physical Parameters/resonance",0.7,0,1,0.01)*0.1;

//==================== SIGNAL PROCESSING ================

//excitation envelope
envelope = adsr(0.001,0.04,0,0.5,gate);

//the delay length is randomly modulated
targetDelay = SR/freq;
delayLength = targetDelay*((1+(0.5*noise)) : smooth(0.9992));

loopGain = 0.895 + resonance + (freq*0.0000005);
amGain = 0.1*gain;

delayLine = delay(4096,delayLength);

//feedback filter is a one zero
filter = oneZero1(b0,b1)
	with{
		zero = 0.01;
		b0 = 1/(1+zero);
		b1 = -zero*b0;
	};

process = (_*loopGain : filter + (envelope*noise*amGain))~delayLine <: _,_;