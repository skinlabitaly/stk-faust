declare name "WaveGuide Flute from STK";
declare author "Romain Michon";
declare version "1.0"; 

import("math.lib");
import("music.lib");
import("filter.lib");
import("envelope.lib");

//==================== GUI SPECIFICATION ================

freq = nentry("freq", 440, 20, 20000, 1);
gain = nentry("gain", 0.95, 0, 1, 0.01); 
gate = button("gate");

embouchureAjust = hslider("embouchureAjust",0.5,0,1,0.01);
noiseGain = hslider("noiseGain",0.01,0,1,0.01);
vibratoGain = hslider("vibratoGain",0.01,0,1,0.01);
vibratoFreq = hslider("vibratoFreq",6,1,15,0.1);

//==================== SIGNAL PROCESSING ================

jetReflexion = 0.5;
jetRatio = 0.08 + (0.48*embouchureAjust);
endReflexion = 0.5;

//Delay lines lengths in number of samples
jetDelayFreq = (SR/freq - 2)*jetRatio;
boreDelayFreq = SR/freq - 2;
filterPole = 0.7 - (0.1*22050/SR);

//One Pole Filter
onePole(x) = b0*x*gain - a1*x*gain'
	with{
		gain = -1;
		pole = 0.7 - (0.1*22050/SR);
		b0 = 1-pole;
		a1 = -pole;
};

//One Zero Filter
oneZero(x) = (_*0.5 + x*0.5)~_;

//Jet Table: flue jet non-linear function, computed by a polynomial calculation
jetTable(x) = x*(x*x-1) : saturation1 : saturation2
	with{
		saturation1(x) = x<: (_>1),(_<=1 : _*x) :> _+_;
		saturation2(x) = x<: (_<-1),(_>=-1 : _*x) :> _*-1+_;
	};

vibrato = vibratoGain*osc(vibratoFreq);

//Breath pressure is controlled by an Attack / Decay / Sustain / Release envelope
envelopeBreath = gain*adsr(gain*0.02,0.01,80,0.1,gate);
breathPressure = envelopeBreath + envelopeBreath*(noiseGain*noise + vibrato);

jetDelay = delay(4096,jetDelayFreq);
boreDelay = delay(4096,boreDelayFreq);

filters = onePole : oneZero;

process = hgroup("STK flute",
	(vgroup("[1]Filters",filters) <: 
	vgroup("[2]Differential Pressure",((breathPressure - _*jetReflexion)) : 
	jetDelay : jetTable)+(_*endReflexion) : 
	vgroup("[3]Bore Delay",boreDelay)) ~_ : 
	vgroup("[4]Output scaling",_*0.3)); 