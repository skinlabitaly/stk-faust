declare name "Modal percussive instruments";
declare author "Romain Michon (rmichon@ccrma.stanford.edu)";
declare copyright "Romain Michon";
declare version "1.0";
declare licence "STK-4.3"; // Synthesis Tool Kit 4.3 (MIT style license);
declare description "A number of different struck bar instruments. Presets numbers: 0->Marimba, 1->Vibraphone, 2->Agogo, 3->Wood1, 4->Reso, 5->Wood2, 6->Beats, 7->2Fix; 8->Clump"; 

import("math.lib");
import("music.lib");
import("instrument.lib");

//==================== GUI SPECIFICATION ================

freq = nentry("h:Basic Parameters/freq", 440, 20, 20000, 1);
gain = nentry("h:Basic Parameters/gain", 1, 0, 1, 0.01);
gate = button("h:Basic Parameters/gate") > 0; 

stickHardness = hslider("v:Physical Parameters/stickHardness",0.25,0,1,0.01);
reson = nentry("v:Physical Parameters/reson",1,0,1,1);
presetNumber = nentry("v:Physical Parameters/preset",1,0,8,1);

vibratoFreq = hslider("v:Envelope Parameters/vibratoFreq",6,1,15,0.1);
vibratoGain = hslider("v:Envelope Parameters/vibratoGain",0.1,0,1,0.01);

//==================== SIGNAL PROCESSING ================

//When note-off, counter is set to 0. When note-on, counter starts
counterWave = ((_*gate)+1)~_ : _-1;

//check if the vibraphone is used
vibratoOn = presetNumber == 1;

//vibrato
vibrato = 1 + osc(vibratoFreq)*vibratoGain*vibratoOn; 

//modal values for the filter bank 
loadPreset = ffunction(float loadPreset (int,int,int), <modalBar.h>,"");

//filter bank output gain
directGain = loadPreset(presetNumber,3,2);
 
//filter bank using biquad filters
biquadBank = _ <: sum(i, 4, oneFilter(i))
	with{
		condition(x) = x<0 <: _*-x,((_-1)*-1)*x*freq :> +;
		dampCondition = (gate<1) & (reson!=1);
		oneFilter(j,y) = (loadPreset(presetNumber,0,j) : condition), 
						loadPreset(presetNumber,1,j)*(1-(gain*0.03*dampCondition)), 
						y*loadPreset(presetNumber,2,j) : bandPassH;
	};

//one pole filter with pole set at 0.9 for pre-filtering 
sourceFilter = onePole(b0,a1)
	with{
		b0 = 1 - 0.9;
		a1 = -0.9;
	};
	
//the reading rate of the stick table is defined in function of the stickHardness
rate = 0.25*pow(4,stickHardness);

//read the stick table
marmstk1Wave = rdtable(marmstk1TableSize,marmstk1,int(dataRate(rate)*gate))
	with{
		marmstk1 = time%marmstk1TableSize : int : readMarmstk1;
		dataRate(readRate) = readRate : (+ : decimal) ~ _ : *(float(marmstk1TableSize));
	};
	
//excitation signal
excitation = counterWave < (marmstk1TableSize*rate) : _*(marmstk1Wave*gate);

process = excitation : sourceFilter : _*gain <: 
	//resonance
	(biquadBank <: _-(_*directGain)) + (directGain*_) : 
	//vibrato for the vibraphone
	_*vibrato <:
	//stereo signal
	_,_;