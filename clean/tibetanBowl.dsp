declare name "Banded Waveguide Modeled Tibetan Bowl";
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
nModes = 12;

modes0 = 0.996108344;
basegains0 = 0.999925960128219;
excitation0 = 11.900357*gate / 10;
    
modes1 = 1.0038916562;
basegains1 = 0.999925960128219;
excitation1 = 11.900357*gate / 10;
    
modes2 = 2.979178;
basegains2 = 0.999982774366897;
excitation2 = 10.914886*gate / 10;

modes3 = 2.99329767;
basegains3 = 0.999982774366897;
excitation3 = 10.914886*gate / 10;
    
modes4 = 5.704452;
basegains4 = 1.0;
excitation4 = 42.995041*gate / 10;
    
modes5 = 5.704452;
basegains5 = 1.0;
excitation5 = 42.995041*gate / 10;
    
modes6 = 8.9982;
basegains6 = 1.0;
excitation6 = 40.063034*gate / 10;
    
modes7 = 9.01549726;
basegains7 = 1.0;
excitation7 = 40.063034*gate / 10;
    
modes8 = 12.83303;
basegains8 = 0.999965497558225;
excitation8 = 7.063034*gate / 10;
   
modes9 = 12.807382;
basegains9 = 0.999965497558225;
excitation9 = 7.063034*gate / 10;
    
modes10 = 17.2808219;
basegains10 = 0.9999999999999999999965497558225;
excitation10 = 57.063034*gate / 10;
    
modes11 = 21.97602739726;
basegains11 = 0.999999999999999965497558225;
excitation11 = 57.063034*gate / 10;

//==================== SIGNAL PROCESSING ================

tableOffset = 0;
tableSlope = 10 - (9*bowPressure);

base = SR/freq;

//delay lengths in number of samples
delay0Length = base/modes0;
delay1Length = base/modes1;
delay2Length = base/modes2;
delay3Length = base/modes3;
delay4Length = base/modes4;
delay5Length = base/modes5;
delay6Length = base/modes6;
delay7Length = base/modes7;
delay8Length = base/modes8;
delay9Length = base/modes9;
delay10Length = base/modes10;
delay11Length = base/modes11;

//delay lines
delay0 = delay(4096,delay0Length);
delay1 = delay(4096,delay1Length);
delay2 = delay(4096,delay2Length);
delay3 = delay(4096,delay3Length);
delay4 = delay(4096,delay4Length);
delay5 = delay(4096,delay5Length);
delay6 = delay(4096,delay6Length);
delay7 = delay(4096,delay7Length);
delay8 = delay(4096,delay8Length);
delay9 = delay(4096,delay9Length);
delay10 = delay(4096,delay10Length);
delay11 = delay(4096,delay11Length);

//Filter bank: biquad filters
radius = 1 - PI*32/SR;
bandPass0 = bandPass(freq*modes0,radius);
bandPass1 = bandPass(freq*modes1,radius);
bandPass2 = bandPass(freq*modes2,radius);
bandPass3 = bandPass(freq*modes3,radius);
bandPass4 = bandPass(freq*modes4,radius);
bandPass5 = bandPass(freq*modes5,radius);
bandPass6 = bandPass(freq*modes6,radius);
bandPass7 = bandPass(freq*modes7,radius);
bandPass8 = bandPass(freq*modes8,radius);
bandPass9 = bandPass(freq*modes9,radius);
bandPass10 = bandPass(freq*modes10,radius);
bandPass11 = bandPass(freq*modes11,radius);

//Delay lines feedback for bow table lookup control
baseGainApp = 0.8999999999999999 + (0.1 * baseGain);
velocityInputApp = integrationConstant;
velocityInput(fdbk0,fdbk1,fdbk2,fdbk3,fdbk4,fdbk5,fdbk6,fdbk7,fdbk8,fdbk9,fdbk10,fdbk11) = 
	velocityInputApp + (baseGainApp*fdbk0) : 
	_ + (baseGainApp*fdbk1) :
	_ + (baseGainApp*fdbk2) :
	_ + (baseGainApp*fdbk3) :
	_ + (baseGainApp*fdbk4) :
	_ + (baseGainApp*fdbk5) :
	_ + (baseGainApp*fdbk6) :
	_ + (baseGainApp*fdbk7) :
	_ + (baseGainApp*fdbk8) :
	_ + (baseGainApp*fdbk9) :
	_ + (baseGainApp*fdbk10) :
	_ + (baseGainApp*fdbk11);

//Bow velocity is controled by an ADSR envelope
maxVelocity = 0.03 + (0.1 * gain);
bowVelocity = maxVelocity*adsr(0.02,0.005,90,0.01,gate);

//Bow table lookup
bowing = (bowVelocity - velocityInput) <: _*bow(tableOffset,tableSlope) : _/nModes;

//Resonance system
resonance0 = (_ + _ + (excitation0*select) : delay0 : _*basegains0 : bandPass0);
resonance1 = (_ + _ + (excitation1*select) : delay1 : _*basegains1 : bandPass1);
resonance2 = (_ + _ + (excitation2*select) : delay2 : _*basegains2 : bandPass2);
resonance3 = (_ + _ + (excitation3*select) : delay3 : _*basegains3 : bandPass3);
resonance4 = (_ + _ + (excitation4*select) : delay4 : _*basegains4 : bandPass4);
resonance5 = (_ + _ + (excitation5*select) : delay5 : _*basegains5 : bandPass5);
resonance6 = (_ + _ + (excitation6*select) : delay6 : _*basegains6 : bandPass6);
resonance7 = (_ + _ + (excitation7*select) : delay7 : _*basegains7 : bandPass7);
resonance8 = (_ + _ + (excitation8*select) : delay8 : _*basegains8 : bandPass8);
resonance9 = (_ + _ + (excitation9*select) : delay9 : _*basegains9 : bandPass9);
resonance10 = (_ + _ + (excitation10*select) : delay10 : _*basegains10 : bandPass10);
resonance11 = (_ + _ + (excitation11*select) : delay11 : _*basegains11 : bandPass11);
resonance12 = (_ + _ + (excitation12*select) : delay12 : _*basegains12 : bandPass12);

process =
		//Bowed Excitation
		(bowing*((select-1)*-1) <: 
		resonance0(_)~_,resonance1(_)~_,resonance2(_)~_,resonance3(_)~_,
		resonance4(_)~_,resonance5(_)~_,resonance6(_)~_,resonance7(_)~_,
		resonance8(_)~_,resonance9(_)~_,resonance10(_)~_,resonance11(_)~_)~ 
		(_,_,_,_,_,_,_,_,_,_,_,_) :> + : 
		//Signal Scaling and stereo
		_*4 <: _,_;