% Invoke after faust2octave tapnn2.dsp
set (0, "defaultaxesfontname", "Helvetica")
set (0, "defaultaxesfontsize", 20)
set (0, "defaulttextfontname", "Helvetica")
set (0, "defaulttextfontsize", 24)
grid('on');
plot(faustout);
title('RMS Level vs. Time');
xlabel('Time (samples)');
grid('on');
[len,chans] = size(faustout);
axis([0 len-1 0 1.0]);
