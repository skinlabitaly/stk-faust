Angle numbers are radians. Average bowing angles 'alpha' from the
string detection function (from motion capture) in Esteban's thesis
(page 38). Angle 'alpha' is the bow angle with respect to the normal
vector coming out of a plane 'parallel' to the top plate. Yes, it does
depend on the string, because they are computed from the string in the
score. So, if the score says string 1, I go fetch the 'average angle'
alpha for such string, string, convert it to radians, and make beta =
(pi/2)-alpha. (This has nothing to do with beta \in (0,1) for bow
position along the string.)  Therefore, as it is now, Vx and Vy must
respectively be V*cos(beta) and V*sin(beta). The sign of bow velocity
just makes it bow-up or bow-down. The convention for the angle 'beta'
is 'looking at the string from the tailpiece'.
