import("instrument.lib");

gate = button("gate") > 0;
stickHardness = hslider("stickHardness",0.25,0,1,0.01);
resonance = hslider("resonance",0,0,0.99,0.01)*0.001;
nonlinearity = hslider("nonlinearity",0,0,1,0.01);

// four-port scattering junction:
mesh(1,x) = bus(4) <: par(i,4,*(-1)), (bus(4) :> (*(.5)+x) <: bus(4)) :> bus(4);

block(N) = par(i,N,!);

s8(i,N) = par(j, 8*N, Sv(i, j))
       with { Sv(i,i) = bus(N); Sv(i,j) = block(N); };

// prune mesh outputs down to the signals which make it out:
prune_outputs(N) 
  = bus(16*N) : 
    block(N), bus(N),   block(N), bus(N), 
    block(N), bus(N),   bus(N),   block(N), 
    bus(N),   block(N), block(N), bus(N), 
    bus(N),   block(N), bus(N),   block(N)
    : bus(8*N);

// collect mesh outputs into standard order (N,W,E,S):
route_outputs(N) 
  = bus(8*N) 
    <: s8(4,N),s8(5,N), s8(0,N),s8(2,N), s8(3,N),s8(7,N), s8(1,N),s8(6,N)
    : bus(8*N);

// collect signals used as feedback:
prune_feedback(N) = bus(16*N) : 
    bus(N),   block(N), bus(N),   block(N),
    bus(N),   block(N), block(N), bus(N),
    block(N), bus(N),   bus(N),   block(N),
    block(N), bus(N),   block(N), bus(N) : 
    bus(8*N);

s16(i,N) = par(j, 16*N, Sv(i, j))
       with { Sv(i,i) = bus(N); Sv(i,j) = block(N); };

// route mesh inputs (feedback, external inputs):
route_inputs(N) = bus(8*N), bus(8*N)
<:s16(8,N),s16(4,N), s16(12,N),s16(3,N), s16(9,N),s16(6,N), s16(1,N),s16(14,N),
  s16(0,N),s16(10,N), s16(13,N),s16(7,N), s16(2,N),s16(11,N), s16(5,N),s16(15,N)
  : bus(16*N);

//passive nonlinear ladder filter
nonLin = nonLinearModulator(1,0,1,0,0,1,2);

//uncomment to use the NLF in the mesh
//mesh(N,x) = par(i,4*N,*(0.999+resonance) : nonLin) : bus(4*N) : (route_inputs(N/2) : par(i,4,mesh(N/2,x))) 
mesh(N,x) = par(i,4*N,*(0.999+resonance)) : bus(4*N) : (route_inputs(N/2) : par(i,4,mesh(N/2,x))) 
	  ~(prune_feedback(N/2))
	  : prune_outputs(N/2) : route_outputs(N/2) : bus(4*N);

ibus(N) = bus(N) : par(i,N,*(-1)); // inverting bus

busi(N,x) = bus(N) : par(i,N,*(-1)) : par(i,N-1,_), +(x) ; 

//mesh_velocity_free(N,x) = mesh(N,x)~(bus(4*N)); // each side gets noninverting reflection
mesh_velocity_free(N,x) = mesh(N,0)~(busi(4*N,x)); // each side gets noninverting reflection
mesh_velocity_clamped(N,x) = mesh(N,x)~(ibus(4*N)); // each side gets inverting reflection

//mesh_torus(N) = mesh(N)~(...); // each side connected to opposite side

s2(i,N) = par(j, N, Sv(i, j)) // NOTE N IS NOT 2*N INSIDE PAR
       with { Sv(i,i) = bus(N); Sv(i,j) = block(N); };
cross(N) = bus(N),bus(N) <: s2(1,N),s2(0,N) : bus(N),bus(N);
// 4->3, 2->1, 1->2, 3->4:
mesh_rotated(N) = mesh(N)~(cross(N),cross(N));

N=8; // N=1,2,4,8,...

//***************************************************************
//Excitation read from table
//***************************************************************

counterWave = ((_*gate)+1)~_ : _-1;

//the reading rate of the stick table is defined in function of the stickHardness
rate = 0.25*pow(4,stickHardness);

//read the stick table
marmstk1Wave = rdtable(marmstk1TableSize,marmstk1,int(dataRate(rate)*gate))
	with{
		marmstk1 = time%marmstk1TableSize : int : readMarmstk1;
		dataRate(readRate) = readRate : (+ : decimal) ~ _ : *(float(marmstk1TableSize));
	};
	
//excitation signal
excitation = counterWave < (marmstk1TableSize*rate) : _*(marmstk1Wave*gate);

process = excitation : mesh_velocity_free(N) :> _;
//process = exci : mesh_velocity_free(N) : par(i,4*N,^(2)) :> _; // compute sum of squared outputs
//ok: process = 1-1' : mesh(1);
//process = 1-1' : mesh_velocity_free(N) :> _;
//process = exci : mesh_velocity_clamped(N) :> _;
//process = mesh_rotated(N);
//process = mesh(N);
//process = cross(N);
