import("math.lib");
import("music.lib");
import("instrument.lib");

//==================== GUI SPECIFICATION ================

freq = nentry("h:Basic Parameters/freq", 1, 20, 20000, 1);
stringNumber = nentry("stringNumber",0,0,4,1) : int;

bowPosition = hslider("v:Physical Parameters/bowPosition",0.01,0.01,1,0.01)*1.2;
force = hslider("v:Physical Parameters/force",0,0,7,0.01)/7*0.5;
bowVel = hslider("bowVel",0,0,130,0.01)/127;

vibratoGain = hslider("v:Vibrato Parameters/vibratoGain",0,0,1,0.01);
vibratoFreq = hslider("v:Vibrato Parameters/vibratoFreq",6,1,15,0.1);

oneString(frq,fltP,fltG,bowPos,frc,bowV,vibG,vibF,playG) = component("violinString.dsp")[
							 frequency = frq; 
							 filterPole = fltP; 
							 filterGain = fltG; 
							 bowPosition = bowPos; 
							 force = frc; 
							 bowVel = bowV; 
							 vibGain = vibratoG; 
							 vibratoFreq = vibF; 
							 gate = playG;];

SH(trig,x) = (*(1 - trig) + x * trig) ~	_;

cnt = (_+1)~_ : _-1;

conditionHold(n) = ((stringNumber == (n + 1)) | (cnt<1));
freqHold(n) = SH(conditionHold(n),freq);
bowPositionHold(n) = SH(conditionHold(n),bowPosition);

filterPole(3) = 0.7;
filterGain(3) = 1;

filterPole(4) = 0.6;
filterGain(4) = 0.95;

filterPole(n) = 0.6;
filterGain(n) = 0.95;

process = par(i,4,(oneString(freqHold(i),
	filterPole(i+1),
	filterGain(i+1),
	bowPositionHold(i),
	force,
	bowVel,
	vibratoGain,
	vibratoFreq,
	(stringNumber == (i+1))))) :> + : _*2 <: _,_;
