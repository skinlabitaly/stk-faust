import("instrument.lib");
import("music.lib");

freq = nentry("h:Basic Parameters/freq", 440, 20, 20000, 1);
gain = nentry("h:Basic Parameters/gain", 1, 0, 1, 0.01); 
gate = button("h:Basic Parameters/gate") > 0;

touchLength = hslider("v:Physical Parameters/Touch Length",0.15,0,1,0.01)*2;

//Nonlinear filter parameters
typeModulation = nentry("v:Nonlinear Filter/typeMod",0,0,4,1);
nonLinearity = hslider("Nonlinearity",0,0,1,0.01) : smooth(0.999);
frequencyMod = hslider("freqMod",220,20,1000,0.1) : smooth(0.999);

delayLength = float(SR)/freq;

excitationFilter = onePole(0.035,-0.965);
excitation = asympT60(-0.5,-0.985,0.02,gate),noise*asympT60(gain,0,touchLength,gate) : 
	   onePoleSwep : excitationFilter : excitationFilter;

bodyFilter = bandPass(108,0.997);

loopFilter = poleZero(b0,b1,a1)
	   with{
		loopFilterb0 = ffunction(float getValueBassLoopFilterb0(float), <instrument.h>,"");
		loopFilterb1 = ffunction(float getValueBassLoopFilterb1(float), <instrument.h>,"");
		loopFiltera1 = ffunction(float getValueBassLoopFiltera1(float), <instrument.h>,"");
		freqToNoteNumber = (log - log(440))/log(2)*12 + 69 + 0.5 : int;
		freqn = freq : freqToNoteNumber;
		b0 = loopFilterb0(freqn);
		b1 = loopFilterb1(freqn);
		a1 = loopFiltera1(freqn);
	   };

delayLine = asympT60(0,delayLength,0.01,gate),_ : fdelay(4096);

resonanceGain = gate + (gate < 1 <: *(asympT60(1,0.9,0.05)));

nlfOrder = 6;
nonLinMod =  nonLinearModulator(nonLinearity,1,freq,typeModulation,frequencyMod,nlfOrder);
NLFM = _ <: (nonLinMod*nonLinearity,_*(1-nonLinearity) :> +)*(typeModulation < 3),nonLinMod*(typeModulation >= 3) :> _;

stereo = stereoizer(delayLength);

process = excitation : 
	(+)~(delayLine : NLFM : loopFilter*resonanceGain) <: 
	bodyFilter*1.5 + *(0.5) : *(4) : stereo;