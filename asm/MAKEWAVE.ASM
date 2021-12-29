; Dwayne Robinson
; 2001-09-21
;
; Simple source to turn any file into a wave file so you can listen to any
; sounds contained in it. Much of it will be static, but if there are
; uncompressed samples contained within, you will hear them. My main reason
; for creating this was extract the sounds from a Click & Play game's library.
; Also wanted to hear the instruments in Microsoft's Synthesizer GM DLS.
;
; To compile use Netwide Assembler:
;   NASM.EXE -f bin makewav.asm -o test.wav

%if 1
    %define WaveFile "D:\src\spc2midi\captures\wave\SoundDump(raw int16).pcm"
    WaveFileStart   equ 0
    Channels        equ 1       ;1-mono 2-stereo
    Mode            equ 1       ;1-uncompressed PCM
    BytesPerSample  equ 2*Channels
    BitsPerSample   equ BytesPerSample*8
    SampleRate      equ 11025
%elif 0
    %define WaveFile "e:\music\godown.umx"
    WaveFileStart   equ 0
    Channels        equ 1       ;1-mono 2-stereo
    Mode            equ 1       ;1-uncompressed PCM
    BytesPerSample  equ 2*Channels
    BitsPerSample   equ BytesPerSample*8
    SampleRate      equ 11025
%elif 0
    %define WaveFile "e:\aud.mix"
    WaveFileStart   equ 0
    Channels        equ 1       ;1-mono 2-stereo
    Mode            equ 1       ;1-uncompressed PCM
    BytesPerSample  equ 1*Channels
    BitsPerSample   equ BytesPerSample*8
    SampleRate      equ 8000
%elif 0
    %define WaveFile "c:\temp\mortuum2\mort10.snd"
    WaveFileStart   equ 0
    BytesPerSample  equ 1
    BitsPerSample   equ BytesPerSample*8
    SampleRate      equ 11025
    Channels        equ 1       ;1-mono 2-stereo
    Mode            equ 1       ;1-uncompressed PCM
%elif 0
    %define WaveFile "c:\windows\system\gm16.dls"
    WaveFileStart   equ 280158
    BytesPerSample  equ 2
    BitsPerSample   equ BytesPerSample*8
    SampleRate      equ 11025
    Channels        equ 1       ;1-mono 2-stereo
    Mode            equ 1       ;1-uncompressed PCM
%elif 0
    %define WaveFile "c:\windows\system\dxdiag.exe"
    WaveFileStart   equ 0
    BytesPerSample  equ 2
    BitsPerSample   equ BytesPerSample*8
    SampleRate      equ 11025
    Channels        equ 1       ;1-mono 2-stereo
    Mode            equ 1       ;1-uncompressed PCM
%endif

WaveHeader:         db "RIFF"
                    dd 4+24+8+WaveDataSize
                    db "WAVE","fmt "
                    dd 16               ;format info header size
                    dw Mode,Channels    ;PCM/Channels
                    dd SampleRate,SampleRate*BytesPerSample*Channels
                    dw 1,BitsPerSample  ;block alignment/16bit audio
                    db "data"
                    dd WaveDataSize
WaveData:           incbin WaveFile,WaveFileStart
WaveDataSize        equ $-WaveData
