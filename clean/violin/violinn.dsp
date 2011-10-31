// violinn = "Violin New" containing Esteban's latest bow-table formula

import("math.lib");
import("music.lib");
import("instrument.lib");

//==================== GUI SPECIFICATION ================

freqIn = nentry("h:Basic Parameters/freq", 1, 20, 20000, 1);
stringNumber = nentry("stringNumber",0,0,4,1) : int;

bowPositionIn = hslider("v:Physical Parameters/bowPosition",0.01,0.01,1,0.01);
//bowPositionIn = 0.2;
forceIn = hslider("v:Physical Parameters/force",0,0,7,0.01)/7;
bowVelIn = hslider("bowVel",0,0,130,0.01)/127;

//********************************************************************************

stringFilter(3) = stringFilterOP : seq(i,5,tf2(fCString(i,0),fCString(i,1),fCString(i,2),fCString(i,3),fCString(i,4)))*0.857261640575012
	     with{
		fCString = ffunction(float violinFDBFiltS4(int,int), <instrument.h>,"");
		filterPole = 0.6;
		filterGain = 0.95;
		pole = filterPole - (0.1*22050/SR);
		b0 = 1-pole;
		a1 = -pole;
		stringFilterOP = _*filterGain : -onePole(b0,a1);
		};

stringFilter(2) = stringFilterOP : seq(i,5,tf2(fCString(i,0),fCString(i,1),fCString(i,2),fCString(i,3),fCString(i,4)))*0.896576688334173
	     with{
		fCString = ffunction(float violinFDBFiltS3(int,int), <instrument.h>,"");
		filterPole = 0.7;
		filterGain = 1;
		pole = filterPole - (0.1*22050/SR);
		b0 = 1-pole;
		a1 = -pole;
		stringFilterOP = _*filterGain : -onePole(b0,a1);
		};

stringFilter(1) = stringFilterOP : seq(i,5,tf2(fCString(i,0),fCString(i,1),fCString(i,2),fCString(i,3),fCString(i,4)))*0.857261640575012
	     with{
		fCString = ffunction(float violinFDBFiltS4(int,int), <instrument.h>,"");
		filterPole = 0.6;
		filterGain = 0.95;
		pole = filterPole - (0.1*22050/SR);
		b0 = 1-pole;
		a1 = -pole;
		stringFilterOP = _*filterGain : -onePole(b0,a1);
		};

stringFilter(0) = stringFilterOP : seq(i,5,tf2(fCString(i,0),fCString(i,1),fCString(i,2),fCString(i,3),fCString(i,4)))*0.857261640575012
	     with{
		fCString = ffunction(float violinFDBFiltS4(int,int), <instrument.h>,"");
		filterPole = 0.6;
		filterGain = 0.95;
		pole = filterPole - (0.1*22050/SR);
		b0 = 1-pole;
		a1 = -pole;
		stringFilterOP = _*filterGain : -onePole(b0,a1);
		};

instrumentBody(force,bowVel,bowPosition,freq,trig,feedBckBridge) = (_*-1 <: _ + feedBckBridge,_ : 
		(bowVelocity-_ <: bowTable*_ : _*(trig : smooth(0.993)) <: _,_),_ : _,_+_ : _ + feedBckBridge,_) ~ 
		neckDelay : !,fdelbridge,_
	with{
		tableOffset =  0;
		tableSlope = 5 - (4.0*force);
		bowTable = bow_new(tableOffset,tableSlope,force);
		bow_new(offset,slope,normal_force) 
		 = abs(sample) + 0.3 * (1.0-log10(normal_force))
	         : ^(-4.0) 
		 : saturationPos 
		 : *(min(1.0,(normal_force^0.04)))
		with{ sample(y) = (y + offset)*slope; };
		maxVelocity = 0.03 + 0.2;
		bowVelocity = maxVelocity*bowVel;
		betaRatio = bowPosition;
		fdelneck = (SR/freq-4) * (1 - betaRatio);
		neckDelay = fdelay(4096,fdelneck);
		fdelbridge = (SR/freq-4) * betaRatio;
		bridgeDelay = delay(4096,fdelbridge);
	};

bodyFilter = seq(i,6,tf2(fC(i,0),fC(i,1),fC(i,2),fC(i,3),fC(i,4))) : *(0.0637)
	   with{
		fC = ffunction(float violinImpRes2(int,int), <instrument.h>,"");
	   };

//********************************************************************************

SH(trig,x) = (*(1 - trig) + x * trig) ~	_;

cnt = (_+1)~_ : _-1;

conditionHold(n) = ((stringNumber == (n + 1)) | (cnt<1));
freqHold(n) = SH(conditionHold(n),freqIn);
bowPositionHold(n) = SH(conditionHold(n),bowPositionIn);

process = par(i,4,
	(stringFilter(i) : instrumentBody(forceIn*(stringNumber == (i+1)),bowVelIn,bowPositionHold(i),freqHold(i),(stringNumber == (i+1))))~fdelay(4096) : !,_*2) :> 
	 + : *(2) : bodyFilter <: _,_;
