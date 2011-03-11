import("instrument.lib");
import("music.lib");

freq = hslider("h:Basic Parameters/freq", 440, 20, 20000, 1);
gain = hslider("h:Basic Parameters/gain", 1, 0, 1, 0.01); 
gate = button("h:Basic Parameters/gate");

vibratoFreq = hslider("v:Vibrato Parameters/vibratoFreq",5,1,15,0.1);
vibratoGain = hslider("v:Vibrato Parameters/vibratoGain",0.1,0,1,0.01);
vibratoAttack = hslider("v:Vibrato Parameters/vibratoAttack",0.5,0,2,0.01);
vibratoRelease = hslider("v:Vibrato Parameters/vibratoRelease",0.01,0,2,0.01);

envelopeAttack = hslider("v:Envelope Parameters/envelopeAttack",0.1,0,2,0.01);
envelopeDecay = hslider("v:Envelope Parameters/envelopeDecay",0.05,0,2,0.01);
envelopeRelease = hslider("v:Envelope Parameters/envelopeRelease",0.2,0,2,0.01);

//Nonlinear filter parameters
typeModulation = nentry("v:Nonlinear Filter/typeMod",0,0,4,1);
nonLinearity = hslider("v:Nonlinear Filter/Nonlinearity",0,0,1,0.01) : smooth(0.999);
frequencyMod = hslider("v:Nonlinear Filter/freqMod",220,20,1000,0.1) : smooth(0.999);
nonLinAttack = hslider("v:Nonlinear Filter/nonLinAttack",0.1,0,2,0.01);
nonLinDecay = hslider("v:Nonlinear Filter/nonLinDecay",0.05,0,2,0.01);
nonLinRelease = hslider("v:Nonlinear Filter/nonLinRelease",0.2,0,2,0.01); 

vibrato = osc(vibratoFreq)*vibratoGain*envVibrato(0.1*2*vibratoAttack,0.9*2*vibratoAttack,100,vibratoRelease,gate);
envelope = adsr(envelopeAttack,envelopeDecay,90,envelopeRelease,gate)*gain;
breath = envelope + envelope*vibrato;

nlfOrder = 3;
//envelopeMod = adsr(nonLinAttack,nonLinDecay,100,nonLinRelease,gate); 
envelopeMod = invSineEnv(nonLinAttack,gate);
NLFM =  nonLinearModulator(nonLinearity,envelopeMod,freq,typeModulation,frequencyMod,nlfOrder);

stereo = stereoizer(SR/freq);

process = osc(freq)*breath : NLFM : stereo;