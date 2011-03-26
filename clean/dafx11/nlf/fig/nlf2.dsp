// Figure

import("filter.lib"); // for allpassnn
N = 2;
theta = par(i,N,PI*i/N);
process =  allpassnn(N,theta);
//process =  allpassnkl(N,theta);
