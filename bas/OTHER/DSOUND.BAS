DECLARE SUB SetVoice (OnOff%)
DIM BaseIO, IRQ, DMA
DIM WritePort
DIM value AS STRING * 1

BaseIO = &H220
IRQ = 5
DMA = 3

WritePort = BaseIO + 12

SetVoice 1

OPEN "c:\rogge.wav" FOR BINARY AS #1


  DO UNTIL EOF(1)
   
    GET #1, , value
 
    WAIT WritePort, &H80, &HFF             'wait for data-ready
    OUT WritePort, &H10
    WAIT WritePort, &H80, &HFF
    OUT WritePort, ASC(value)
  LOOP

CLOSE

SetVoice 0

' Turns Speaker on and off
SUB SetVoice (OnOff%)
  IF OnOff% = 1 THEN
    WAIT WritePort%, &H80, &HFF             'wait for data-ready on SB
    OUT WritePort%, &HD1 'ON
  ELSE
    WAIT WritePort%, &H80, &HFF
    OUT WritePort%, &HD3 'OFF
  END IF
END SUB

