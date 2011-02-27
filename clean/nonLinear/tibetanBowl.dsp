declare name "Banded Waveguide Modeld Tibetan Bowl";
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
//preset = 1;
integrationConstant = hslider("v:Physical Parameters/integrationConstant",0,0,1,0.01);
baseGain = hslider("v:Physical Parameters/baseGain",1,0,1,0.01);
bowPressure = hslider("v:Physical Parameters/bowPressure",0.2,0,1,0.01);
bowPosition = hslider("v:Physical Parameters/bowPosition",0,0,1,0.01);

squared = checkbox("squared");
freqMod = hslider("freqMod",220,1,10000,0.1) : smooth(0.999);
nonlinearity = hslider("Nonlinearity",0,0,1,0.01) : smooth(0.999);

//==================== MODAL PARAMETERS ================

preset = 0;

nMode(0) = 12;

modes(0,0) = 0.996108344;
basegains(0,0) = 0.999925960128219;
excitation(0,0) = 11.900357 / 10;
    
modes(0,1) = 1.0038916562;
basegains(0,1) = 0.999925960128219;
excitation(0,1) = 11.900357 / 10;

modes(0,2) = 2.979178;
basegains(0,2) = 0.999982774366897;
excitation(0,2) = 10.914886 / 10;

modes(0,3) = 2.99329767;
basegains(0,3) = 0.999982774366897;
excitation(0,3) = 10.914886 / 10;
    
modes(0,4) = 5.704452;
basegains(0,4) = 1.0;
excitation(0,4) = 42.995041 / 10;
    
modes(0,5) = 5.704452;
basegains(0,5) = 1.0;
excitation(0,5) = 42.995041 / 10;
    
modes(0,6) = 8.9982;
basegains(0,6) = 1.0;
excitation(0,6) = 40.063034 / 10;
    
modes(0,7) = 9.01549726;
basegains(0,7) = 1.0;
excitation(0,7) = 40.063034 / 10;
    
modes(0,8) = 12.83303;
basegains(0,8) = 0.999965497558225;
excitation(0,8) = 7.063034 / 10;
   
modes(0,9) = 12.807382;
basegains(0,9) = 0.999965497558225;
excitation(0,9) = 7.063034 / 10;
    
modes(0,10) = 17.2808219;
basegains(0,10) = 0.9999999999999999999965497558225;
excitation(0,10) = 57.063034 / 10;
    
modes(0,11) = 21.97602739726;
basegains(0,11) = 0.999999999999999965497558225;
excitation(0,11) = 57.063034 / 10;

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

//Nonlinear filter

//filter order
N = 6; 

//theta is modulated by a sine wave
//t = nonlinearity * PI * osc(freqMod); //teta is modified by a sine wave 
//nonLinearFilter = _ <: allpassnn(N,par(i,N,t));

//theta is modulated by the signal itself
t(x) = nonlinearity * PI * x * (x*squared + (squared < 1)); //teta is modified by a sine wave  
nonLinearFilter(x) = x <: allpassnn(N,par(i,N,t(x)));

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
		_*2 : nonLinearFilter <: _,_;