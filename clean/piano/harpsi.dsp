declare name "WaveGuide Commuted Harpsichord";
declare author "Romain Michon (rmichon@ccrma.stanford.edu)";
declare copyright "Romain Michon";
declare version "1.0";
declare licence "STK-4.3"; // Synthesis Tool Kit 4.3 (MIT style license);
declare description "A commuted WaveGuide Harpsichord."; 

import("math.lib");
import("music.lib");
import("instrument.lib");

//==================== GUI SPECIFICATION ================

freq = nentry("h:Basic Parameters/freq", 440, 20, 20000, 1);
gain = nentry("h:Basic Parameters/gain", 1, 0, 1, 0.01); 
gate = button("h:Basic Parameters/gate") > 0;

brightnessFactor = hslider("v:Physical Parameters/brightnessFactor",0,0,1,0.01);
detuningFactor = hslider("v:Physical Parameters/detuningFactor",0.1,0,1,0.01)*10;
stiffnessFactor = hslider("v:Physical Parameters/stiffnessFactor",0.28,0,1,0.01)*3.7;
hammerHardness = hslider("v:Physical Parameters/hammerHardness",0.1,0,1,0.01)*0.1;

//==================== PROCESSING ================

//The parameters from the SynthBuilder patch are stored in a C++ file

dryTapAmpT60 = ffunction(float getValueDryTapAmpT60(float), <piano.h>,"");
sustainPedalLevel = ffunction(float getValueSustainPedalLevel(float), <piano.h>,"");
releaseLoopGain = ffunction(float getValueReleaseLoopGain(float), <piano.h>,"");
loopFilterb0 = ffunction(float getValueLoopFilterb0(float), <piano.h>,"");
loopFilterb1 = ffunction(float getValueLoopFilterb1(float), <piano.h>,"");
loopFilterb2 = ffunction(float getValueLoopFilterb2(float), <piano.h>,"");
loopFiltera1 = ffunction(float getValueLoopFiltera1(float), <piano.h>,"");
loopFiltera2 = ffunction(float getValueLoopFiltera2(float), <piano.h>,"");

//convert a frequency in a midi note number
freqToNoteNumber = (log(_)-log(440))/log(2)*12+69+0.5 : int;
freqn = freq : freqToNoteNumber;

//==================== PIANO SOUND BOARD ================

//exponential envelope with 2 phases for the dry excitation
asympT60dry(value,T60) = (_*factor + constant)~_
	with{
		cntSample = _*gate+1~_ : _-1;
		attDur = hammerHardness*float(SR);
		target = value*((cntSample < attDur) & (gate > 0));
		factorAtt = exp(-7/attDur);
		factorT60 = exp(-7/(T60*float(SR)));
		factor = factorAtt*((cntSample < attDur) & (gate > 0)) + ((cntSample >= attDur) | (gate < 1))*factorT60;
		constant = (1 - factor)*target;	
	};

//piano sound board
soundBoard = dryTapAmp*noise
	with{
		noteCutOffTime = freqn : dryTapAmpT60*gain;
		noteEnvValue = 0.15;
		dryTapAmp = asympT60dry(noteEnvValue,noteCutOffTime);
	};	

//loopfilter is a biquad filter
loopFilter = TF2(b0,b1,b2,a1,a2)
	   with{
		b0 = loopFilterb0(freqn);
		b1 = loopFilterb1(freqn);
		b2 = loopFilterb2(freqn);
		a1 = loopFiltera1(freqn);
		a2 = loopFiltera2(freqn);
	   };

//delay length as a number of samples
delayLength = SR/freq;

stringLoopGainT = gate*0.9996 + (gate<1)*releaseLoopGain(freqn)*0.9 : smooth(0.999);
string(delayL) = (_*stringLoopGainT+_ : delay(4096,delayL) : loopFilter)~_;

process = soundBoard : string(delayLength) <: _,_;
