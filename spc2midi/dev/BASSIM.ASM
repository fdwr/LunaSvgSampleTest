;ebx=basilar membrane velocity
;ecx=count
;esi=ptr to wave height
;edi=basilar membrane level

    mov ecx,[.SamplesLeft]
    mov ebx,[.Vel]
    mov edi,[.Lvl]
.NextSample:
    mov eax,[esi]               ;get wave height from sample buffer
    mov edx,[.PreWaveLvl]       ;get wave height of previous sample
    mov [.PreWaveLvl],eax       ;set previous sample for next loop
    sub edx,eax                 ;WaveVel = WaveLvl - PreWaveLvl

    add edi,ebx                 ;BsmLvl += BsmVel
    sub edx,ebx
    imul dword [.Resist]        ;BsmVel +=
    shrd eax,edx,16             ;  ((WaveVel - BsmVel) * BsmResist) >> 16
    add ebx,edx
    mov eax,edi
    imul [.Tension]             ;  ((WaveVel - BsmVel) * BsmResist) >> 16
    shrd eax,edx,16
    sub ebx,eax

    dec ecx
    jnz .Next
