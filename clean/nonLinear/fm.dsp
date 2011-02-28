import("instrument.lib");
import("music.lib");

freq = hslider("h:Basic Parameters/freq", 440, 20, 20000, 1);
gain = hslider("h:Basic Parameters/gain", 1, 0, 1, 0.01); 
gate = button("h:Basic Parameters/gate");

vibratoGain = hslider("v:Vibrato Parameters/vibratoAmp",0.02,0,1,0.01) : smooth(0.999);
vibratoFreq = hslider("v:Vibrato Parameters/vibratoFreq",6,1,15,0.1);

envelopeAttack = hslider("v:Envelope Parameters/envelopeAttack",0.1,0,2,0.01);
envelopeDecay = hslider("v:Envelope Parameters/envelopeDecay",0.05,0,2,0.01);
envelopeRelease = hslider("v:Envelope Parameters/envelopeRelease",0.2,0,2,0.01);

//Nonlinear filter parameters
typeModulation = checkbox("v:Nonlinear Filter/typeMod");
signalModType = nentry("v:Nonlinear Filter/sigModType",0,0,2,1);
nonlinearity = hslider("v:Nonlinear Filter/Nonlinearity",0,0,1,0.01) : smooth(0.999);
frequencyMod = hslider("v:Nonlinear Filter/freqMod",220,20,1000,0.1) : smooth(0.999);
followFreq = checkbox("v:Nonlinear Filter/followFreq");
nonLinAttack = hslider("v:Nonlinear Filter/nonLinAttack",0.1,0,2,0.01);
nonLinDecay = hslider("v:Nonlinear Filter/nonLinDecay",0.05,0,2,0.01);
nonLinRelease = hslider("v:Nonlinear Filter/nonLinRelease",0.2,0,2,0.01);

vibrato = osc(vibratoFreq)*vibratoGain;
envelope = adsr(envelopeAttack,envelopeDecay,90,envelopeRelease,gate)*gain;
breath = envelope + envelope*vibrato;

envelopeMod = adsr(nonLinAttack,nonLinDecay,100,nonLinRelease,gate); 
nonLinMod =  nonLinearModulator(envelopeMod,followFreq,freq,signalModType,typeModulation,frequencyMod,2);

process = osc(freq)*breath : nonLinMod <: _,_;