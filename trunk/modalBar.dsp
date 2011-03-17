declare name "Nonlinear Modal percussive instruments";
declare author "Romain Michon (rmichon@ccrma.stanford.edu)";
declare copyright "Romain Michon";
declare version "1.0";
declare licence "STK-4.3"; // Synthesis Tool Kit 4.3 (MIT style license);
declare description "A number of different struck bar instruments. Presets numbers: 0->Marimba, 1->Vibraphone, 2->Agogo, 3->Wood1, 4->Reso, 5->Wood2, 6->Beats, 7->2Fix; 8->Clump"; 

import("music.lib");
import("instrument.lib");

//==================== GUI SPECIFICATION ================

freq = nentry("h:Basic Parameters/freq", 440, 20, 20000, 1);
gain = nentry("h:Basic Parameters/gain", 1, 0, 1, 0.01);
gate = button("h:Basic Parameters/gate") > 0; 

stickHardness = hslider("h:Physical and Nonlinearity/v:Physical Parameters/Stick Hardness",0.25,0,1,0.01);
reson = nentry("h:Physical and Nonlinearity/v:Physical Parameters/Resonance",1,0,1,1);
presetNumber = nentry("h:Physical and Nonlinearity/v:Physical Parameters/Preset",1,0,8,1);

typeModulation = nentry("h:Physical and Nonlinearity/v:Nonlinear Filter Parameters/Modulation Type",0,0,4,1);
nonLinearity = hslider("h:Physical and Nonlinearity/v:Nonlinear Filter Parameters/Nonlinearity",0,0,1,0.01);
frequencyMod = hslider("h:Physical and Nonlinearity/v:Nonlinear Filter Parameters/Modulation Frequency",220,20,1000,0.1);

vibratoFreq = hslider("v:Envelope Parameters/Vibrato Frequency",6,1,15,0.1);
vibratoGain = hslider("v:Envelope Parameters/Vibrato Gain",0.1,0,1,0.01);

//==================== SIGNAL PROCESSING ================

//----------------------- Nonlinear filter ----------------------------
//nonlinearities are created by the nonlinear passive allpass ladder filter declared in filter.lib

//nonlinear filter order
nlfOrder = 6; 

//nonLinearModultor is declared in instrument.lib, it adapts allpassnn from filter.lib 
//for using it with waveguide instruments
NLFM =  nonLinearModulator((nonLinearity : smooth(0.999)),1,freq,
     typeModulation,(frequencyMod : smooth(0.999)),nlfOrder);

//----------------------- Synthesis parameters computing and functions declaration ----------------------------

//stereoizer is declared in instrument.lib and implement a stereo spacialisation in function of 
//the frequency period in number of samples 
stereo = stereoizer(SR/freq);

//check if the vibraphone is used
vibratoOn = presetNumber == 1;

//vibrato
vibrato = 1 + osc(vibratoFreq)*vibratoGain*vibratoOn; 

//filter bank output gain
directGain = loadPreset(presetNumber,3,2);

//modal values for the filter bank 
loadPreset = ffunction(float loadPreset (int,int,int), <modalBar.h>,"");
 
//filter bank using biquad filters
biquadBank = _ <: sum(i, 4, oneFilter(i))
	with{
		condition(x) = x<0 <: *(-x),((-(1))*-1)*x*freq :> +;
		dampCondition = (gate < 1) & (reson != 1);
		
		//the filter coefficients are interpolated when changing of preset
		oneFilter(j,y) = (loadPreset(presetNumber,0,j : smooth(0.999)) : condition), 
						loadPreset(presetNumber,1,j : smooth(0.999))*(1-(gain*0.03*dampCondition)), 
						y*(loadPreset(presetNumber,2,j) : smooth(0.999)) : bandPassH;
	};

//one pole filter with pole set at 0.9 for pre-filtering, onePole is declared in instrument.lib 
sourceFilter = onePole(b0,a1)
	with{
		b0 = 1 - 0.9;
		a1 = -0.9;
	};

//excitation signal
excitation = counterSamples < (marmstk1TableSize*rate) : *(marmstk1Wave*gate)
	   with{
		//readMarmstk1 and marmstk1TableSize are both declared in instrument.lib
		marmstk1 = time%marmstk1TableSize : int : readMarmstk1;
		
		dataRate(readRate) = readRate : (+ : decimal) ~ _ : *(float(marmstk1TableSize));
		
		//the reading rate of the stick table is defined in function of the stickHardness
		rate = 0.25*pow(4,stickHardness);
		
		counterSamples = (*(gate)+1)~_ : -(1);
		marmstk1Wave = rdtable(marmstk1TableSize,marmstk1,int(dataRate(rate)*gate));
	   };

process = excitation : sourceFilter : *(gain) <: 
	//resonance
	(biquadBank <: -(*(directGain))) + (directGain*_) :
	//vibrato for the vibraphone
	*(vibrato) : NLFM*0.6 : stereo;