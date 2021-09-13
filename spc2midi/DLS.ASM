;Spc2Midi - DLS File Related (traversing tree/loading samples)
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

; As you can see, it doesn't do much now ;-)



; attempt to load all instrument samples into 1mb memory
;   don't worry about regions, just pick the recorded sample
;    closest to A440
;   store sample info in table
;   load sample data, promoting to 16bit if necessary
; loop
LoadDlsFile:
