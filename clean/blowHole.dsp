declare name "WaveGuide Clarinet with one register hole and one tonehole from STK";
declare author "Romain Michon";
declare copyright "Romain Michon (rmichon@ccrma.stanford.edu)";
declare version "1.0";
declare licence "STK-4.3"; // Synthesis Tool Kit 4.3 (MIT style license);
declare description "A clarinet model, with the addition of a two-port register hole and a three-port dynamic tonehole implementation, as discussed by Scavone and Cook (1998). In this implementation, the distances between the reed/register hole and tonehole/bell are fixed.  As a result, both the tonehole and register hole will have variable influence on the playing frequency, which is dependent on the length of the air column.  In addition, the highest playing freqeuency is limited by these fixed lengths.";
declare reference "https://ccrma.stanford.edu/~jos/pasp/Woodwinds.html";

import("math.lib");
import("music.lib");
import("filter.lib");
import("instrument.lib");

//==================== GUI SPECIFICATION ================

freq = nentry("h:Basic Parameters/freq", 440, 100, 2000, 1);
gain = nentry("h:Basic Parameters/gain", 1, 0, 1, 0.01); 
gate = button("h:Basic Parameters/gate");

pressure = hslider("v:Physical Parameters/pressure",0.1,0,1,0.01);
toneHoleOpenness = hslider("v:Physical Parameters/toneHoleOpenness",0,0,1,0.01);
ventOpenness = hslider("v:Physical Parameters/ventOpenness",0,0,1,0.01);
reedStiffness = hslider("v:Physical Parameters/reedStiffness",0.35,0,1,0.01);
noiseGain = hslider("v:Physical Parameters/noiseGain",0.05,0,1,0.01);

vibratoGain = hslider("v:Vibrato Parameters/vibratoGain",0.03,0,1,0.01);
vibratoFreq = hslider("v:Vibrato Parameters/vibratoFreq",6,1,15,0.1);
vibratoAttack = hslider("v:Vibrato Parameters/vibratoAttack",0.5,0,1,0.01);
vibratoRelease = hslider("v:Vibrato Parameters/vibratoRelease",0.01,0,2,0.01);

envelopeAttack = hslider("v:Envelope Parameters/envelopeAttack",0.01,0,2,0.01);
envelopeRelease = hslider("v:Envelope Parameters/envelopeRelease",0.1,0,2,0.01);

//==================== SIGNAL PROCESSING ================

//parameters for the reed table look-up
reedTableOffset = 0.7;
reedTableSlope = -0.44 + (0.26*reedStiffness);
reedTable = reed(reedTableOffset,reedTableSlope);

// Calculate the initial tonehole three-port scattering coefficient
rb = 0.0075;    // main bore radius
rth = 0.003;    // tonehole radius
scattering = pow(rth,2)*-1 / ( pow(rth,2) + 2*pow(rb,2) );

// Calculate register hole filter coefficients
r_rh = 0.0015; 	// register vent radius
teVent = 1.4*r_rh;	 // effective length of the open hole
xi = 0 ; 	// series resistance term
zeta = 347.23 + 2*PI*pow(rb,2)*xi/1.1769;
psi = 2*PI*pow(rb,2)*teVent / (PI*pow(r_rh,2));
rhCoeff = (zeta - 2 * SR * psi) / (zeta + 2 * SR * psi);
rhGain = -347.23 / (zeta + 2 * SR * psi);
ventFilterGain = rhGain*ventOpenness;

// Vent filter
ventFilter = _*ventFilterGain : poleZero(1,1,rhCoeff);

teHole = 1.4*rth; // effective length of the open hole
coeff = (teHole*2*SR-347.23)/(teHole*2*SR+347.23);
scaledCoeff = (toneHoleOpenness*(coeff - 0.9995)) + 0.9995;

//register hole filter
toneHoleFilter = _*1 : poleZero(b0,-1,a1)
	with{
		b0 = scaledCoeff;
		a1 = -scaledCoeff;
	};

//delay lengths in number of samples
delay0Length = 5*SR/22050;
delay2Length = 4*SR/22050;
delay1Length = (SR/freq*0.5-3.5) - (delay0Length + delay2Length);

//fractional delay lines
delay0 = fdelay(4096,delay0Length);
delay1 = fdelay(4096,delay1Length);
delay2 = fdelay(4096,delay2Length);

//envelope(ADSR) + vibrato + noise
envelope = (0.55+pressure*0.3)*asr(pressure*envelopeAttack,100,pressure*envelopeRelease,gate);
vibratoEnvelope = envVibrato(0.1*2*vibratoAttack,0.9*2*vibratoAttack,100,vibratoRelease,gate);
vibrato = vibratoGain*osc(vibratoFreq)*vibratoEnvelope;
breath = envelope + envelope*noiseGain*noise;
breathPressure = breath + (breath*vibrato);

//two-port junction scattering for register vent
twoPortJunction(portB) = (pressureDiff : ((_ <: breathPressure + _*reedTable) <: (_+portB : ventFilter <: _ + portB,_),_))~
		delay0 : inverter : _+_,_
	with{
		pressureDiff = _-breathPressure; 
		portA(x) = _ <: x + _*reedTable;
		inverter(a,b,c) = b,c,a;
	};

//three-port junction scattering (under tonehole)
threePortJunction(x) =  (_ <: junctionScattering(x),_ : _+x,_+_ : oneZero0(0.5,0.5)*-0.95,_)~delay2 : !,_
	with{
		toneHole(temp,portA2,portB2) = (portA2+portB2-_+temp : toneHoleFilter)~_;
		junctionScattering(portA2,portB2) = (((portA2+portB2-2*_)*scattering) <: toneHole(_,portA2,portB2),_,_)~_ : !,_,_;
	};

process = (twoPortJunction : threePortJunction,_) ~ delay1 : !,_*gain <: _,_;