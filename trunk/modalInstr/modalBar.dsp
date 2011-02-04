declare name "Modal percussive instruments";
declare author "Romain Michon";
declare version "1.0"; 

import("math.lib");
import("music.lib");
import("filter.lib");
import("envelope.lib");
import("table.lib");

/*
PRESETS NUMBERS:

0: Marimba
1: Vibraphone
2: Agogo
3: Wood1
4: Reso
5: Wood2
6: Beats
7: 2Fix
8: Clump

*/

//==================== GUI SPECIFICATION ================

freq = nentry("freq", 440, 20, 20000, 1);
gain = nentry("gain", 1, 0, 1, 0.01);
gate = button("gate"); 

vibratoFreq = hslider("vibratoFreq",6,1,15,0.1);
vibratoGain = hslider("vibratoGain",0.1,0,1,0.01);
stickHardness = hslider("stickHardness",0.25,0,1,0.01);
reson = nentry("reson",1,0,1,1);
presetNumber = nentry("preset",1,0,8,1);

//==================== SIGNAL PROCESSING ================

//Size of marmstk1 in sample
marmstk1TableSize = 246;

//When note-off, counter is set to 0. When note-on, counter starts
counterWave = ((_*gateSignal)+1)~_ : _-1;

//convert gate from boolean to float
gateSignal = gate>0;

//check if the vibraphone is used
vibratoVibra = presetNumber == 1;

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
onePole(x) = (b0*x - a1*_)~_
	with{
		b0 = 1 - 0.9;
		a1 = -0.9;
	};


process = 
	//the table look-up in processed only once for each note 
	counterWave < marmstk1TableSize : _*(marmstk1Wave(stickHardness)*gateSignal) : 
	//pre-filtering
	onePole : _*gain <: 
	//resonance
	(biquadBank <: _-(_*directGain)) + (directGain*_) : 
	//vibrato for the vibraphone
	_ * (1 + osc(vibratoFreq)*vibratoGain*vibratoVibra) <:
	//stereo signal
	_,_;