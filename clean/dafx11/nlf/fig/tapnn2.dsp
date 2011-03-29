// Test stability of normalized nested allpass filter 

import("filter.lib"); // for allpassnn

N = 3;
theta = par(i,N,PI*noise@(i+1));
rms = ^(2) : smooth(0.999) : sqrt;
uvwnoise = sqrt(3)*noise; // unit variance white noise (from uniform on [-1,1])
process =  uvwnoise <: _, allpassnn(N,theta) : rms, rms;
