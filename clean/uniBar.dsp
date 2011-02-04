declare name "Banded Waveguide Modeled Uniform Bar";
declare author "Romain Michon";
declare copyright "Romain Michon (rmichon@ccrma.stanford.edu)";
declare version "1.0";
declare licence "STK-4.3"; // Synthesis Tool Kit 4.3 (MIT style license);
declare description "This instrument uses banded waveguide. For more information, see Essl, G. and Cook, P. Banded Waveguides: Towards Physical Modelling of Bar Percussion Instruments, Proceedings of the 1999 International Computer Music Conference.";

import("math.lib");
import("music.lib");
import("instrument.lib");

//==================== GUI SPECIFICATION ================

freq = nentry("h:Basic Parameters/freq", 440, 20, 20000, 1);
gain = nentry("h:Basic Parameters/gain", 0.8, 0, 1, 0.01); 
gate = button("h:Basic Parameters/gate") > 0;

select = nentry("v:Physical Parameters/selector",0,0,1,1);
integrationConstant = hslider("v:Physical Parameters/integrationConstant",0,0,1,0.01);
baseGain = hslider("v:Physical Parameters/baseGain",1,0,1,0.01);
bowPressure = hslider("v:Physical Parameters/bowPressure",0.2,0,1,0.01);
bowPosition = hslider("v:Physical Parameters/bowPosition",0,0,1,0.01);

//==================== MODAL PARAMETERS ================
nModes = 4;

modes0 = 1;
modes1 = 2.756;
modes2 = 5.404;
modes3 = 8.933;

basegains0 = pow(0.9,1);
basegains1 = pow(0.9,2);
basegains2 = pow(0.9,3);
basegains3 = pow(0.9,4);

excitation = 1*gain/nModes;

//==================== SIGNAL PROCESSING ================

tableOffset = 0;
tableSlope = 10 - (9*bowPressure);

base = SR/freq;

//delay lengths in number of samples
delay0Length = base/modes0;
delay1Length = base/modes1;
delay2Length = base/modes2;
delay3Length = base/modes3;

//delay lines
delay0 = delay(4096,delay0Length);
delay1 = delay(4096,delay1Length);
delay2 = delay(4096,delay2Length);
delay3 = delay(4096,delay3Length);

//Filter bank: biquad filters
radius = 1 - PI*32/SR;
bandPass0 = bandPass(freq*modes0,radius);
bandPass1 = bandPass(freq*modes1,radius);
bandPass2 = bandPass(freq*modes2,radius);
bandPass3 = bandPass(freq*modes3,radius);

//Delay lines feedback for bow table lookup control
baseGainApp = 0.8999999999999999 + (0.1 * baseGain);
velocityInputApp = integrationConstant;
velocityInput(fdbk0,fdbk1,fdbk2,fdbk3) = velocityInputApp + (baseGainApp*fdbk0) : 
	_ + (baseGainApp*fdbk1) :
	_ + (baseGainApp*fdbk2) :
	_ + (baseGainApp*fdbk3);

//Bow velocity is controled by an ADSR envelope
maxVelocity = 0.03 + (0.1*gain);
bowVelocity = maxVelocity*adsr(0.02,0.005,90,0.01,gate);

//Bow table lookup
bowing = (bowVelocity - velocityInput) <: _*bow(tableOffset,tableSlope) : _/nModes;

//Resonance system
resonance0 = (_ + _ + (excitation*select) : delay0 : _*basegains0 : bandPass0);
resonance1 = (_ + _ + (excitation*select) : delay1 : _*basegains1 : bandPass1);
resonance2 = (_ + _ + (excitation*select) : delay2 : _*basegains2 : bandPass2);
resonance3 = (_ + _ + (excitation*select) : delay3 : _*basegains3 : bandPass3);

process =
		//Bowed Excitation
		(bowing*((select-1)*-1) <: 
		resonance0(_)~_,resonance1(_)~_,resonance2(_)~_,resonance3(_)~_) ~(_,_,_,_) :> + : 
		//Signal Scaling and stereo
		_*4 <: _,_;