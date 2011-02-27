declare name "EKS Electric Guitar Synth";
declare author "Julius Smith";
declare version "1.0";
declare license "STK-4.3";
declare copyright "Julius Smith";
declare reference "http://ccrma.stanford.edu/~jos/pasp/vegf.html";
// -> Virtual\_Electric\_Guitars\_Faust.html";

import("music.lib");    // Define SR, delay
import("instrument.lib");
import("effect.lib");   // stereopanner

//==================== GUI SPECIFICATION ================

// standard MIDI voice parameters:
// NOTE: The labels MUST be "freq", "gain", and "gate" for faust2pd
freq = nentry("freq", 440, 20, 7040, 1);  // Hz
gain = nentry("gain", 1, 0, 10, 0.01);    // 0 to 1
gate = button("gate");                    // 0 or 1

// Additional parameters (MIDI "controllers"):

// Pick angle in [0,0.9]:
pickangle = 0.9 * hslider("pick_angle",0,0,0.9,0.1);

// Normalized pick-position in [0,0.5]:
beta = hslider("pick_position [midi: ctrl 0x81]", 0.13, 0.02, 0.5, 0.01);
       // MIDI Control 0x81 often "highpass filter frequency"

// String decay time in seconds:
t60 = hslider("decaytime_T60", 4, 0, 10, 0.01);  // -60db decay time (sec)

// Normalized brightness in [0,1]:
B = hslider("brightness [midi:ctrl 0x74]", 0.5, 0, 1, 0.01);// 0-1
    // MIDI Controller 0x74 is often "brightness" 
    // (or VCF lowpass cutoff freq)

// Dynamic level specified as dB level desired at Nyquist limit:
L = hslider("dynamic_level", -10, -60, 0, 1) : db2linear;
// Note: A lively clavier is obtained by tying L to gain (MIDI velocity).

// Spatial "width" (not in original EKS, but only costs "one tap"):
W = hslider("center-panned spatial width", 0.5, 0, 1, 0.01);
A = hslider("pan angle", 0.5, 0, 1, 0.01);

spring1 = hslider("spring1",0.1,-1.0,1.0,0.01);
spring2 = hslider("spring2",-0.1,-1,1,0.01);

//==================== SIGNAL PROCESSING ================

//----------------------- noiseburst -------------------------
// White noise burst (adapted from Faust's karplus.dsp example)
// Requires music.lib (for noise)
noiseburst(gate,P) = noise : *(gate : trigger(P))
with {
  diffgtz(x) = (x-x') > 0;
  decay(n,x) = x - (x>0)/n;
  release(n) = + ~ decay(n);
  trigger(n) = diffgtz : release(n) : > (0.0);
};

P = SR/freq; // fundamental period in samples
Pmax = 4096; // maximum P (for delay-line allocation)

ppdel = beta*P; // pick position delay
pickposfilter = ffcombfilter(Pmax,ppdel,-1); // defined in filter.lib

excitation = noiseburst(gate,P) : *(gain); // defined in signal.lib

rho = pow(0.001,1.0/(freq*t60)); // multiplies loop-gain

// Original EKS damping filter:
b1 = 0.5*B; b0 = 1.0-b1; // S and 1-S
dampingfilter1(x) = rho * ((b0 * x) + (b1 * x'));

// Linear phase FIR3 damping filter:
h0 = (1.0 + B)/2; h1 = (1.0 - B)/4;
dampingfilter2(x) = rho * (h0 * x' + h1*(x+x''));

loopfilter = dampingfilter2; // or dampingfilter1

filtered_excitation = excitation : smooth(pickangle) 
		    : pickposfilter : levelfilter(L,freq); // see filter.lib


//NonLinear Filter

freqMod = hslider("freqMod",220,20,1000,0.1) : smooth(0.999);
nonlinearity = hslider("Nonlinearity",0,0,1,0.01) : smooth(0.999);

//allow the use of the same frequency for the pole modulation than for the instrument tone
followFreq = checkbox("followFreq");

//select the type of the pole modulation: sine wave or the signal itself
typeMod = checkbox("typeMod");

nonLinEnvelope = adsr(nonLinAttack,nonLinDecay,100,nonLinRelease,gate);
freqOscMod = followFreq*freq + (followFreq < 1)*freqMod;

tsig(x) = nonlinearity * PI * x; 
//t(x) = nonlinearity * PI * ((x + x')/2);
t = nonlinearity * PI * osc(freqOscMod); //teta is modified by a sine wave
N = 6; 

nonLinearFilterSig(x) = x <: allpassnn(N,(par(i,N,tsig(x)))); // use input signal for each theta coefficient
nonLinearFilter = _ <: allpassnn(N,(par(i,N,t)));


stringloop = (+ : fdelay4(Pmax, P-2)) ~ (loopfilter <: (nonLinearFilter*typeMod,nonLinearFilterSig*(typeMod < 1) :> +));

// Second output decorrelated somewhat for spatial diversity over imaging:
widthdelay = delay(Pmax,W*P/2);

// Assumes an optionally spatialized mono signal, centrally panned:
stereopanner(A) = _,_ : *(1.0-A), *(A);

process = filtered_excitation : stringloop : widthdelay <: _,_;// : stereopanner(A);