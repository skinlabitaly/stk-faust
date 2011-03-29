import("effect.lib"); // for mesh_square()
nlmesh(N,NA,x)=mesh_square(N)~(apbank(4*N,x)) 
with {
  coeffs(x)=par(i,NA,x); // e.g.
  apbranch(i,x) = allpassnn(NA,coeffs(x),x);
  apbank(M,x) = bus(M)
    : par(i,M-1,apbranch(i)), 
                apbranch(M-1) + x; 
};
N=2;  // mesh order (nonnegative power of 2)
NA=1; // allpass order (any positive integer)
process = nlmesh(N,NA);
