struc PointCharge
.q  resd 1                      ; charge strength
.m  resd 1                      ; mass
.x  resd 1                      ; particle position
.y  resd 1
.vx resd 1                      ; velocity
.vy resd 1
endstruc

%macro DefPointCharge 6
dd %1                           ; charge strength
dd %2                           ; mass
dd %3                           ; particle position
dd %4
dd %5                           ; velocity
dd %6
%endmacro
