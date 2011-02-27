import("filter.lib");
import("music.lib");
import("math.lib");

freq = hslider("freq", 440, 20, 20000, 1);
gain = hslider("gain", 1, 0, 1, 0.01); 
gate = button("gate");

vibratoGain = hslider("vibratoAmp",0.02,0,1,0.01) : smooth(0.999);
vibratoFreq = hslider("vibratoFreq",6,1,15,0.1);

envelopeAttack = hslider("envelopeAttack",0.1,0,2,0.01);
envelopeDecay = hslider("envelopeDecay",0.05,0,2,0.01);
envelopeRelease = hslider("envelopeRelease",0.2,0,2,0.01);

nonLinAttack = hslider("nonLinAttack",0.1,0,2,0.01);
nonLinDecay = hslider("nonLinDecay",0.05,0,2,0.01);
nonLinRelease = hslider("nonLinRelease",0.2,0,2,0.01);

freqMod = hslider("freqMod",220,1,10000,0.1) : smooth(0.999);
nonlinearity = hslider("Nonlinearity",0,0,1,0.01) : smooth(0.999);
squared = checkbox("squared");
tuned = checkbox("tuned");

vibrato = osc(vibratoFreq)*vibratoGain;
envelope = adsr(envelopeAttack,envelopeDecay,90,envelopeRelease,gate)*gain;
breath = envelope + envelope*vibrato;

nonLinEnvelope = adsr(nonLinAttack,nonLinDecay,100,nonLinRelease,gate);

N = 6; 

//theta is modulated by a sine wave
//t = nonlinearity * PI * osc(freqMod+freq*tuned); //teta is modified by a sine wave 
//nonLinearFilter = _ <: allpassnn(N,par(i,N,t));

//theta is modulated by the signal itself
t(x) = nonlinearity * nonLinEnvelope * PI * x * (x*squared + (squared < 1)); //teta is modified by a sine wave 
nonLinearFilter(x) = x <: allpassnn(N,par(i,N,t(x)));

//theta is modulated by random values
//freqChange = float(SR)/hslider("freqChange",10,1,10000,0.1) : int;
//SH(trig,x) = (*(1 - trig) + x * trig) ~	_;
//cnt = +(1) ~ _ : -(1) : int : %(freqChange) ;
//randomizer = (cnt == (freqChange-1)),noise : SH;
//t = nonlinearity * PI * randomizer : smooth(0.999); //teta is modified by a sine wave 
//nonLinearFilter = _ <: allpassnn(N,par(i,N,t));

process = osc(freq)*breath : nonLinearFilter <: _,_;