; Opcode Dissassembly Table
;
; 1999-09-30/2002-09-11
;
; Compiles into OPCINFO.DAT
;
Opc:
.Mov    equ 0
.Adc    equ 1
.Sbc    equ 2
.Cmp    equ 3
.And    equ 4
.Or     equ 5
.Eor    equ 6
.Inc    equ 7
.Dec    equ 8
.Asl    equ 9
.Lsr    equ 10
.Rol    equ 11
.Ror    equ 12
.Xcn    equ 13
.Movw   equ 14
.Incw   equ 15
.Decw   equ 16
.Addw   equ 17
.Subw   equ 18
.Cmpw   equ 19
.Mul    equ 20
.Div    equ 21
.Daa    equ 22
.Das    equ 23
.Bra    equ 24
.Beq    equ 25
.Bne    equ 26
.Bcs    equ 27
.Bcc    equ 28
.Bvs    equ 29
.Bvc    equ 30
.Bmi    equ 31
.Bpl    equ 32
.Bbs    equ 33
.Bbc    equ 34
.Cbne   equ 35
.Dbnz   equ 36
.Jmp    equ 37
.Call   equ 38
.Pcall  equ 39
.Tcall  equ 40
.Brk    equ 41
.Ret    equ 42
.Reti   equ 43
.Push   equ 44
.Pop    equ 45
.Set1   equ 46
.Clr1   equ 47
.Tset1  equ 48
.Tclr1  equ 49
.And1   equ 50
.Or1    equ 51
.Eor1   equ 52
.Not1   equ 53
.Mov1   equ 54
.Clrc   equ 55
.Setc   equ 56
.Notc   equ 57
.Clrv   equ 58
.Clrp   equ 59
.Setp   equ 60
.Ei     equ 61
.Di     equ 62
.Nop    equ 63
.Sleep  equ 64
.Stop   equ 65

Opr:
.None           equ 0
.A              equ 1
.X              equ 2
.Y              equ 3
.YA             equ 4
.Sp             equ 5   ;stack pointer
.Psw            equ 6   ;status word
.Im             equ 7   ;immediate
.DpX            equ 8
.DpXInc         equ 9
.DpY            equ 10
.DpO            equ 11
.DpOX           equ 12
.DpOY           equ 13
.AbsO           equ 14
.AbsOX          equ 15
.AbsOY          equ 16
.InDpOX         equ 17
.YInDpO         equ 18
.JumpRel        equ 19
.JumpAbs        equ 20
.MemBit         equ 21
.MemBitN        equ 22
.DpOBit         equ 23
.InAbsOX        equ 24
.OpcH           equ 25  ;operand is part of opcode itself, high nybble
.UsrPage        equ 26  ;FF00-FFFF
.Carry          equ 27  ;carry flag
.DpO2           equ 28

;  Opcode    Operand 1   Operand 2  Bytes
db Opc.Nop,  Opr.None,   Opr.None,   1; 00
db Opc.Tcall,Opr.OpcH,   Opr.None,   1; 01
db Opc.Set1, Opr.DpOBit, Opr.None,   2; 02
db Opc.Bbs,  Opr.DpOBit, Opr.JumpRel,3; 03
db Opc.Or,   Opr.A,      Opr.DpO,    2; 04
db Opc.Or,   Opr.A,      Opr.AbsO,   3; 05
db Opc.Or,   Opr.A,      Opr.DpX,    1; 06
db Opc.Or,   Opr.A,      Opr.InDpOX, 2; 07
db Opc.Or,   Opr.A,      Opr.Im,     2; 08
db Opc.Or,   Opr.DpO2,   Opr.DpO,    3; 09
db Opc.Or1,  Opr.Carry,  Opr.MemBit, 3; 0A
db Opc.Asl,  Opr.DpO,    Opr.None,   2; 0B
db Opc.Asl,  Opr.AbsO,   Opr.None,   3; 0C
db Opc.Push, Opr.Psw,    Opr.None,   1; 0D
db Opc.Tset1,Opr.AbsO,   Opr.A,      3; 0E
db Opc.Brk,  Opr.None,   Opr.None,   1; 0F
db Opc.Bpl,  Opr.JumpRel,Opr.None,   2; 10
db Opc.Tcall,Opr.OpcH,   Opr.None,   1; 11
db Opc.Clr1, Opr.DpOBit, Opr.None,   2; 12
db Opc.Bbc,  Opr.DpOBit, Opr.JumpRel,3; 13
db Opc.Or,   Opr.A,      Opr.DpOX,   2; 14
db Opc.Or,   Opr.A,      Opr.AbsOX,  3; 15
db Opc.Or,   Opr.A,      Opr.AbsOY,  3; 16
db Opc.Or,   Opr.A,      Opr.YInDpO, 2; 17
db Opc.Or,   Opr.DpO2,   Opr.Im,     3; 18
db Opc.Or,   Opr.DpX,    Opr.DpY,    1; 19
db Opc.Decw, Opr.DpO,    Opr.None,   2; 1A
db Opc.Asl,  Opr.DpOX,   Opr.None,   2; 1B
db Opc.Asl,  Opr.A,      Opr.None,   1; 1C
db Opc.Dec,  Opr.X,      Opr.None,   1; 1D
db Opc.Cmp,  Opr.X,      Opr.AbsO,   3; 1E
db Opc.Jmp,  Opr.InAbsOX,Opr.None,   3; 1F
db Opc.Clrp, Opr.None,   Opr.None,   1; 20
db Opc.Tcall,Opr.OpcH,   Opr.None,   1; 21
db Opc.Set1, Opr.DpOBit, Opr.None,   2; 22
db Opc.Bbs,  Opr.DpOBit, Opr.JumpRel,3; 23
db Opc.And,  Opr.A,      Opr.DpO,    2; 24
db Opc.And,  Opr.A,      Opr.AbsO,   3; 25
db Opc.And,  Opr.A,      Opr.DpX,    1; 26
db Opc.And,  Opr.A,      Opr.InDpOX, 2; 27
db Opc.And,  Opr.A,      Opr.Im,     2; 28
db Opc.And,  Opr.DpO2,   Opr.DpO,    3; 29
db Opc.Or1,  Opr.Carry,  Opr.MemBitN,3; 2A
db Opc.Rol,  Opr.DpO,    Opr.None,   2; 2B
db Opc.Rol,  Opr.AbsO,   Opr.None,   3; 2C
db Opc.Push, Opr.A,      Opr.None,   1; 2D
db Opc.Cbne, Opr.DpO,    Opr.JumpRel,3; 2E
db Opc.Bra,  Opr.JumpRel,Opr.None,   2; 2F
db Opc.Bmi,  Opr.JumpRel,Opr.None,   2; 30
db Opc.Tcall,Opr.OpcH,   Opr.None,   1; 31
db Opc.Clr1, Opr.DpOBit, Opr.None,   2; 32
db Opc.Bbc,  Opr.DpOBit, Opr.JumpRel,3; 33
db Opc.And,  Opr.A,      Opr.DpOX,   2; 34
db Opc.And,  Opr.A,      Opr.AbsOX,  3; 35
db Opc.And,  Opr.A,      Opr.AbsOY,  3; 36
db Opc.And,  Opr.A,      Opr.YInDpO, 2; 37
db Opc.And,  Opr.DpO2,   Opr.Im,     3; 38
db Opc.And,  Opr.DpX,    Opr.DpY,    1; 39
db Opc.Incw, Opr.DpO,    Opr.None,   2; 3A
db Opc.Rol,  Opr.DpOX,   Opr.None,   2; 3B
db Opc.Rol,  Opr.A,      Opr.None,   1; 3C
db Opc.Inc,  Opr.X,      Opr.None,   1; 3D
db Opc.Cmp,  Opr.X,      Opr.DpO,    2; 3E
db Opc.Call, Opr.JumpAbs,Opr.None,   3; 3F
db Opc.Setp, Opr.None,   Opr.None,   1; 40
db Opc.Tcall,Opr.OpcH,   Opr.None,   1; 41
db Opc.Set1, Opr.DpOBit, Opr.None,   2; 42
db Opc.Bbs,  Opr.DpOBit, Opr.JumpRel,3; 43
db Opc.Eor,  Opr.A,      Opr.DpO,    2; 44
db Opc.Eor,  Opr.A,      Opr.AbsO,   3; 45
db Opc.Eor,  Opr.A,      Opr.DpX,    1; 46
db Opc.Eor,  Opr.A,      Opr.InDpOX, 2; 47
db Opc.Eor,  Opr.A,      Opr.Im,     2; 48
db Opc.Eor,  Opr.DpO2,   Opr.DpO,    3; 49
db Opc.And1, Opr.Carry,  Opr.MemBit, 3; 4A
db Opc.Lsr,  Opr.DpO,    Opr.None,   2; 4B
db Opc.Lsr,  Opr.AbsO,   Opr.None,   3; 4C
db Opc.Push, Opr.X,      Opr.None,   1; 4D
db Opc.Tclr1,Opr.AbsO,   Opr.A,      3; 4E
db Opc.Pcall,Opr.UsrPage,Opr.None,   2; 4F
db Opc.Bvc,  Opr.JumpRel,Opr.None,   2; 50
db Opc.Tcall,Opr.OpcH,   Opr.None,   1; 51
db Opc.Clr1, Opr.DpOBit, Opr.None,   2; 52
db Opc.Bbc,  Opr.DpOBit, Opr.JumpRel,3; 53
db Opc.Eor,  Opr.A,      Opr.DpOX,   2; 54
db Opc.Eor,  Opr.A,      Opr.AbsOX,  3; 55
db Opc.Eor,  Opr.A,      Opr.AbsOY,  3; 56
db Opc.Eor,  Opr.A,      Opr.YInDpO, 2; 57
db Opc.Eor,  Opr.DpO2,   Opr.Im,     3; 58
db Opc.Eor,  Opr.DpX,    Opr.DpY,    1; 59
db Opc.Cmpw, Opr.YA,     Opr.DpO,    2; 5A
db Opc.Lsr,  Opr.DpOX,   Opr.None,   2; 5B
db Opc.Lsr,  Opr.A,      Opr.None,   1; 5C
db Opc.Mov,  Opr.X,      Opr.A,      1; 5D
db Opc.Cmp,  Opr.Y,      Opr.AbsO,   3; 5E
db Opc.Jmp,  Opr.JumpAbs,Opr.None,   3; 5F
db Opc.Clrc, Opr.None,   Opr.None,   1; 60
db Opc.Tcall,Opr.OpcH,   Opr.None,   1; 61
db Opc.Set1, Opr.DpOBit, Opr.None,   2; 62
db Opc.Bbs,  Opr.DpOBit, Opr.JumpRel,3; 63
db Opc.Cmp,  Opr.A,      Opr.DpO,    2; 64
db Opc.Cmp,  Opr.A,      Opr.AbsO,   3; 65
db Opc.Cmp,  Opr.A,      Opr.DpX,    1; 66
db Opc.Cmp,  Opr.A,      Opr.InDpOX, 2; 67
db Opc.Cmp,  Opr.A,      Opr.Im,     2; 68
db Opc.Cmp,  Opr.DpO2,   Opr.DpO,    3; 69
db Opc.And1, Opr.Carry,  Opr.MemBitN,3; 6A
db Opc.Ror,  Opr.DpO,    Opr.None,   2; 6B
db Opc.Ror,  Opr.AbsO,   Opr.None,   3; 6C
db Opc.Push, Opr.Y,      Opr.None,   1; 6D
db Opc.Dbnz, Opr.DpO,    Opr.JumpRel,3; 6E
db Opc.Ret,  Opr.None,   Opr.None,   1; 6F
db Opc.Bvs,  Opr.JumpRel,Opr.None,   2; 70
db Opc.Tcall,Opr.OpcH,   Opr.None,   1; 71
db Opc.Clr1, Opr.DpOBit, Opr.None,   2; 72
db Opc.Bbc,  Opr.DpOBit, Opr.JumpRel,3; 73
db Opc.Cmp,  Opr.A,      Opr.DpOX,   2; 74
db Opc.Cmp,  Opr.A,      Opr.AbsOX,  3; 75
db Opc.Cmp,  Opr.A,      Opr.AbsOY,  3; 76
db Opc.Cmp,  Opr.A,      Opr.YInDpO, 2; 77
db Opc.Cmp,  Opr.DpO2,   Opr.Im,     3; 78
db Opc.Cmp,  Opr.DpX,    Opr.DpY,    1; 79
db Opc.Addw, Opr.YA,     Opr.DpO,    2; 7A
db Opc.Ror,  Opr.DpOX,   Opr.None,   2; 7B
db Opc.Ror,  Opr.A,      Opr.None,   1; 7C
db Opc.Mov,  Opr.A,      Opr.X,      1; 7D
db Opc.Cmp,  Opr.Y,      Opr.DpO,    2; 7E
db Opc.Reti, Opr.None,   Opr.None,   1; 7F
db Opc.Setc, Opr.None,   Opr.None,   1; 80
db Opc.Tcall,Opr.OpcH,   Opr.None,   1; 81
db Opc.Set1, Opr.DpOBit, Opr.None,   2; 82
db Opc.Bbs,  Opr.DpOBit, Opr.JumpRel,3; 83
db Opc.Adc,  Opr.A,      Opr.DpO,    2; 84
db Opc.Adc,  Opr.A,      Opr.AbsO,   3; 85
db Opc.Adc,  Opr.A,      Opr.DpX,    1; 86
db Opc.Adc,  Opr.A,      Opr.InDpOX, 2; 87
db Opc.Adc,  Opr.A,      Opr.Im,     2; 88
db Opc.Adc,  Opr.DpO2,   Opr.DpO,    3; 89
db Opc.Eor1, Opr.Carry,  Opr.MemBit, 3; 8A
db Opc.Dec,  Opr.DpO,    Opr.None,   2; 8B
db Opc.Dec,  Opr.AbsO,   Opr.None,   3; 8C
db Opc.Mov,  Opr.Y,      Opr.Im,     2; 8D
db Opc.Pop,  Opr.Psw,    Opr.None,   1; 8E
db Opc.Mov,  Opr.DpO2,   Opr.Im,     3; 8F
db Opc.Bcc,  Opr.JumpRel,Opr.None,   2; 90
db Opc.Tcall,Opr.OpcH,   Opr.None,   1; 91
db Opc.Clr1, Opr.DpOBit, Opr.None,   2; 92
db Opc.Bbc,  Opr.DpOBit, Opr.JumpRel,3; 93
db Opc.Adc,  Opr.A,      Opr.DpOX,   2; 94
db Opc.Adc,  Opr.A,      Opr.AbsOX,  3; 95
db Opc.Adc,  Opr.A,      Opr.AbsOY,  3; 96
db Opc.Adc,  Opr.A,      Opr.YInDpO, 2; 97
db Opc.Adc,  Opr.DpO2,   Opr.Im,     3; 98
db Opc.Adc,  Opr.DpX,    Opr.DpY,    1; 99
db Opc.Subw, Opr.YA,     Opr.DpO,    2; 9A
db Opc.Dec,  Opr.DpOX,   Opr.None,   2; 9B
db Opc.Dec,  Opr.A,      Opr.None,   1; 9C
db Opc.Mov,  Opr.X,      Opr.Sp,     1; 9D
db Opc.Div,  Opr.YA,     Opr.X,      1; 9E
db Opc.Xcn,  Opr.A,      Opr.None,   1; 9F
db Opc.Ei,   Opr.None,   Opr.None,   1; A0
db Opc.Tcall,Opr.OpcH,   Opr.None,   1; A1
db Opc.Set1, Opr.DpOBit, Opr.None,   2; A2
db Opc.Bbs,  Opr.DpOBit, Opr.JumpRel,3; A3
db Opc.Sbc,  Opr.A,      Opr.DpO,    2; A4
db Opc.Sbc,  Opr.A,      Opr.AbsO,   3; A5
db Opc.Sbc,  Opr.A,      Opr.DpX,    1; A6
db Opc.Sbc,  Opr.A,      Opr.InDpOX, 2; A7
db Opc.Sbc,  Opr.A,      Opr.Im,     2; A8
db Opc.Sbc,  Opr.DpO2,   Opr.DpO,    3; A9
db Opc.Mov1, Opr.Carry,  Opr.MemBit, 3; AA
db Opc.Inc,  Opr.DpO,    Opr.None,   2; AB
db Opc.Inc,  Opr.AbsO,   Opr.None,   3; AC
db Opc.Cmp,  Opr.Y,      Opr.Im,     2; AD
db Opc.Pop,  Opr.A,      Opr.None,   1; AE
db Opc.Mov,  Opr.DpXInc, Opr.A,      1; AF
db Opc.Bcs,  Opr.JumpRel,Opr.None,   2; B0
db Opc.Tcall,Opr.OpcH,   Opr.None,   1; B1
db Opc.Clr1, Opr.DpOBit, Opr.None,   2; B2
db Opc.Bbc,  Opr.DpOBit, Opr.JumpRel,3; B3
db Opc.Sbc,  Opr.A,      Opr.DpOX,   2; B4
db Opc.Sbc,  Opr.A,      Opr.AbsOX,  3; B5
db Opc.Sbc,  Opr.A,      Opr.AbsOY,  3; B6
db Opc.Sbc,  Opr.A,      Opr.YInDpO, 2; B7
db Opc.Sbc,  Opr.DpO2,   Opr.Im,     3; B8
db Opc.Sbc,  Opr.DpX,    Opr.DpY,    1; B9
db Opc.Movw, Opr.YA,     Opr.DpO,    2; BA
db Opc.Inc,  Opr.DpOX,   Opr.None,   2; BB
db Opc.Inc,  Opr.A,      Opr.None,   1; BC
db Opc.Mov,  Opr.Sp,     Opr.X,      1; BD
db Opc.Das,  Opr.A,      Opr.None,   1; BE
db Opc.Mov,  Opr.A,      Opr.DpXInc, 1; BF
db Opc.Di,   Opr.None,   Opr.None,   1; C0
db Opc.Tcall,Opr.OpcH,   Opr.None,   1; C1
db Opc.Set1, Opr.DpOBit, Opr.None,   2; C2
db Opc.Bbs,  Opr.DpOBit, Opr.JumpRel,3; C3
db Opc.Mov,  Opr.DpO,    Opr.A,      2; C4
db Opc.Mov,  Opr.AbsO,   Opr.A,      3; C5
db Opc.Mov,  Opr.DpX,    Opr.A,      1; C6
db Opc.Mov,  Opr.InDpOX, Opr.A,      2; C7
db Opc.Cmp,  Opr.X,      Opr.Im,     2; C8
db Opc.Mov,  Opr.AbsO,   Opr.X,      3; C9
db Opc.Mov1, Opr.MemBit, Opr.Carry,  3; CA
db Opc.Mov,  Opr.DpO,    Opr.Y,      2; CB
db Opc.Mov,  Opr.AbsO,   Opr.Y,      3; CC
db Opc.Mov,  Opr.X,      Opr.Im,     2; CD
db Opc.Pop,  Opr.X,      Opr.None,   1; CE
db Opc.Mul,  Opr.YA,     Opr.None,   1; CF
db Opc.Bne,  Opr.JumpRel,Opr.None,   2; D0
db Opc.Tcall,Opr.OpcH,   Opr.None,   1; D1
db Opc.Clr1, Opr.DpOBit, Opr.None,   2; D2
db Opc.Bbc,  Opr.DpOBit, Opr.JumpRel,3; D3
db Opc.Mov,  Opr.DpOX,   Opr.A,      2; D4
db Opc.Mov,  Opr.AbsOX,  Opr.A,      3; D5
db Opc.Mov,  Opr.AbsOY,  Opr.A,      3; D6
db Opc.Mov,  Opr.YInDpO, Opr.A,      2; D7
db Opc.Mov,  Opr.DpO,    Opr.X,      2; D8
db Opc.Mov,  Opr.DpOY,   Opr.X,      2; D9
db Opc.Movw, Opr.DpO,    Opr.YA,     2; DA
db Opc.Mov,  Opr.DpOX,   Opr.Y,      2; DB
db Opc.Dec,  Opr.Y,      Opr.None,   1; DC
db Opc.Mov,  Opr.A,      Opr.Y,      1; DD
db Opc.Cbne, Opr.DpOX,   Opr.JumpRel,3; DE
db Opc.Daa,  Opr.A,      Opr.None,   1; DF
db Opc.Clrv, Opr.None,   Opr.None,   1; E0
db Opc.Tcall,Opr.OpcH,   Opr.None,   1; E1
db Opc.Set1, Opr.DpOBit, Opr.None,   2; E2
db Opc.Bbs,  Opr.DpOBit, Opr.JumpRel,3; E3
db Opc.Mov,  Opr.A,      Opr.DpO,    2; E4
db Opc.Mov,  Opr.A,      Opr.AbsO,   3; E5
db Opc.Mov,  Opr.A,      Opr.DpX,    1; E6
db Opc.Mov,  Opr.A,      Opr.InDpOX, 2; E7
db Opc.Mov,  Opr.A,      Opr.Im,     2; E8
db Opc.Mov,  Opr.X,      Opr.AbsO,   3; E9
db Opc.Not1, Opr.MemBit, Opr.None,   3; EA
db Opc.Mov,  Opr.Y,      Opr.DpO,    2; EB
db Opc.Mov,  Opr.Y,      Opr.AbsO,   3; EC
db Opc.Notc, Opr.None,   Opr.None,   1; ED
db Opc.Pop,  Opr.Y,      Opr.None,   1; EE
db Opc.Sleep,Opr.None,   Opr.None,   1; EF
db Opc.Beq,  Opr.JumpRel,Opr.None,   2; F0
db Opc.Tcall,Opr.OpcH,   Opr.None,   1; F1
db Opc.Clr1, Opr.DpOBit, Opr.None,   2; F2
db Opc.Bbc,  Opr.DpOBit, Opr.JumpRel,3; F3
db Opc.Mov,  Opr.A,      Opr.DpOX,   2; F4
db Opc.Mov,  Opr.A,      Opr.AbsOX,  3; F5
db Opc.Mov,  Opr.A,      Opr.AbsOY,  3; F6
db Opc.Mov,  Opr.A,      Opr.YInDpO, 2; F7
db Opc.Mov,  Opr.X,      Opr.DpO,    2; F8
db Opc.Mov,  Opr.X,      Opr.DpOY,   2; F9
db Opc.Mov,  Opr.DpO2,   Opr.DpO,    3; FA
db Opc.Mov,  Opr.Y,      Opr.DpOX,   2; FB
db Opc.Inc,  Opr.Y,      Opr.None,   1; FC
db Opc.Mov,  Opr.Y,      Opr.A,      1; FD
db Opc.Dbnz, Opr.Y,      Opr.JumpRel,2; FE
db Opc.Stop, Opr.None,   Opr.None,   1; FF
