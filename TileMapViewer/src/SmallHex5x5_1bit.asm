;Small monochrome font used by the output routine DisplayNumericValue.
;The 5x5 character set consists of only 0-9,A-F since it only needs to
;display binary, decimal, or hex numbers, not any character strings.
;
; tools\nasmw.exe src\SmallHex5x5_1bit.asm -o src\SmallHex5x5_1bit.fnt

;0
db 01110000b
db 11011000b
db 11011000b
db 11011000b
db 01110000b
;1
db 00110000b
db 01110000b
db 00110000b
db 00110000b
db 01111000b
;2
db 01110000b
db 11011000b
db 00110000b
db 01100000b
db 11111000b
;3
db 01110000b
db 11011000b
db 00110000b
db 11011000b
db 01110000b
;4
db 11011000b
db 11011000b
db 11111000b
db 00011000b
db 00011000b
;5
db 11111000b
db 11000000b
db 11110000b
db 00011000b
db 11110000b
;6
db 01111000b
db 11000000b
db 11110000b
db 11011000b
db 01110000b
;7
db 11111000b
db 00011000b
db 00110000b
db 01100000b
db 11000000b
;8
db 01110000b
db 11011000b
db 01110000b
db 11011000b
db 01110000b
;9
db 01110000b
db 11011000b
db 01111000b
db 00011000b
db 00011000b
;A
db 01110000b
db 11011000b
db 11111000b
db 11011000b
db 11011000b
;B
db 11110000b
db 11011000b
db 11110000b
db 11011000b
db 11110000b
;C
db 01110000b
db 11011000b
db 11000000b
db 11011000b
db 01110000b
;D
db 11110000b
db 11011000b
db 11011000b
db 11011000b
db 11110000b
;E
db 11111000b
db 11000000b
db 11111000b
db 11000000b
db 11111000b
;F
db 11111000b
db 11000000b
db 11111000b
db 11000000b
db 11000000b
