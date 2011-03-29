// This one has no input and is superceded by mesch.dsp

import("effect.lib");

NA=1; // allpass order (not visible in figure)
napcoeffs(x)= par(i,NA,x); // example nonlinear coeffs
apbranch(N,NA,i,x) = allpassnn(NA,napcoeffs(x),x);
allpassbank(N,NA) = par(i,4*N,apbranch(N,NA,i));
mesh_square_nl(N) = mesh_square(N)~(allpassbank(N,NA));

N=2;
process = mesh_square_nl(N);
