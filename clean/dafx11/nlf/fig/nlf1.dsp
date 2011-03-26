// Figure

import("filter.lib"); // for allpassnn
N = 1;
theta = par(i,N,PI*i/N);
process =  allpassnn(N,theta);
//process =  allpassnkl(N,theta);
