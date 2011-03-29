import("effect.lib");

import("effect.lib");
NA=1; // allpass order
napcoeffs(x)=par(i,NA,x); // nonlinear coeffs
apbranch(NA,i,x) = allpassnn(NA,napcoeffs(x),x);
allpassbank(M,NA,x)=bus(M)
    : par(i,M-1,apbranch(NA,i)), apbranch(NA,M-1)+x;
nlmesh(N,NA,x)=mesh_square(N)~(allpassbank(4*N,NA,x));
N=2; 
process = nlmesh(N,NA);
