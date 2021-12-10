; Spc2Midi - GUI responses
;
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

dd $+4
MenuOwner:

section data
StartUIJtbl .ActivateJtbl, .IgnoreMsg
AddUIJtbl   mnuMain.Quit, Main.Quit
AddUIJtbl   mnuControl.Play, MainCommand.Play
AddUIJtbl   mnuControl.Pause, MainCommand.Pause
AddUIJtbl   mnuControl.Stop, MainCommand.Stop
AddUIJtbl   mnuControl.Reverse, MainCommand.Reverse
AddUIJtbl   mnuControl.Restart, MainCommand.Restart
AddUIJtbl   mnuControl.Still, MainCommand.Still
AddUIJtbl   mnuControl.As, MainCommand.ToggleAs
AddUIJtbl   mnuControl.Sine, MainCommand.ToggleSine
AddUIJtbl   mnuControl.Dls, MainCommand.ToggleDls
AddUIJtbl   mnuControl.Fm, MainCommand.ToggleFm
AddUIJtbl   mnuControl.Gm, MainCommand.ToggleGm
AddUIJtbl   mnuControl.Mpu, MainCommand.ToggleMpu
AddUIJtbl   mnuControl.Tune, MainCommand.ToggleTune
AddUIJtbl   mnuSeek.Start, SongDisplayCode.SeekHome
AddUIJtbl   mnuSeek.Finish, SongDisplayCode.SeekEnd
AddUIJtbl   mnuDisplay.HorzSheet, SongView.InitNoteSheetHorz
AddUIJtbl   mnuDisplay.VolBars, SongView.InitVolumeBars
AddUIJtbl   mnuDisplay.SampleInfo, SongView.InitVoiceInfo
AddUIJtbl   mnuDisplay.WaveClear, SongView.InitDaWaveClear
AddUIJtbl   mnuDisplay.WaveFaded, SongView.InitDaWaveFaded
AddUIJtbl   mnuDisplay.WaveOcean, SongView.InitDaWaveOcean
AddUIJtbl   mnuDisplay.SignalCorrelationMap, SongView.InitSignalCorrelationMap
AddUIJtbl   mnuDisplay.SignalCorrelationBars, SongView.InitSignalCorrelationBars
AddUIJtbl   mnuDisplay.SignalCorrelationHistogram, SongView.InitSignalCorrelationHistogram
AddUIJtbl   mnuDisplay.None, SongView.InitNone
section code

    cmp al,MenuMsg.Activate
    jne .IgnoreMsg
    shr eax,16
    debugwrite "menu id=%d",eax
    cmp eax,JtblHigh
    jb .Activate
.IgnoreMsg:
    stc                         ;ignore all other messages
    ret
.Activate:
    jmp dword [.ActivateJtbl+eax*4]

%if 0
    cmp eax,MenuMsg.Activate|(mnuMain.Quit<<16)
    je near Main.Quit
    cmp eax,MenuMsg.Activate|(mnuControl.Play<<16)
    je .Play
    cmp eax,MenuMsg.Activate|(mnuControl.Pause<<16)
    je .Pause
    cmp eax,MenuMsg.Activate|(mnuControl.Stop<<16)
    je .Stop
    cmp eax,MenuMsg.Activate|(mnuControl.Reverse<<16)
    je .Reverse
    cmp eax,MenuMsg.Activate|(mnuControl.Still<<16)
    je .Still
.Nada:
    ret
%endif


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
MainCommand:
.Restart:
    mov dword [PlaySpeed],TicksPerFrame
    mov dword [PlayTime],0      ;reset end start
    mov dword [PlayTimeStart],0 ;reset start time
    ; (fall through)
.Play:
    mov eax,[PlaySpeed]
    and dword [PlayOptions],~(PlayOptions.Pause|PlayOptions.Stop)
    mov [PlayAdvance],eax
    or dword [PlayOptions],PlayOptions.Emulate
.Nada:
    ret
.Pause:
    or dword [PlayOptions],PlayOptions.Pause|PlayOptions.Emulate
    and dword [PlayOptions],~PlayOptions.Sample
    jmp SilenceSounds
    ;ret
.Stop:
    or dword [PlayOptions],PlayOptions.Stop
    and dword [PlayOptions],~PlayOptions.Emulate
    jmp StopSounds
    ;ret
; pauses song leaving sound output active
.Still:
    mov dword [PlayAdvance],0
    and dword [PlayOptions],~(PlayOptions.Pause|PlayOptions.Stop)
    or dword [PlayOptions],PlayOptions.Emulate
    ret
.Reverse:
    neg dword [PlaySpeed]
    neg dword [PlayAdvance]
    ret

.ToggleTune:
    xor byte [PlayOptions],PlayOptions.TuningWave
    test byte [PlayOptions],PlayOptions.TuningWave
    jz .TuneOff
    call GenerateSineWave.Start
    test byte [SoundFlags],SoundFlags.Da
    jz .EnableAudio
.TuneOff:
    ret

.ToggleAs:
    xor byte [PlayOptions],PlayOptions.AsVoices
    test byte [SoundFlags],SoundFlags.Da
    jz .EnableAudio
    ret
.ToggleDls:
    xor byte [PlayOptions],PlayOptions.DlsVoices
    test byte [SoundFlags],SoundFlags.Da
    jz .EnableAudio
    ret
.ToggleSine:
    xor byte [PlayOptions],PlayOptions.SineVoices
    test byte [SoundFlags],SoundFlags.Da
    jz .EnableAudio
    ret
.EnableAudio:
  %ifdef WinVer
    jmp InitDaSound
  %elifdef DosVer
    call InitDaSound
    jmp InitDmaTransfer
  %endif

.ToggleFm:
    test byte [SoundFlags],SoundFlags.Fm
    jz .EnableFm
    mov ebx,PlayOptions.FmVoices
    mov esi,FmEmu.Given
    mov edi,FmSongPos
    jmp short .ToggleMidiSound
.EnableFm:
    or byte [PlayOptions],PlayOptions.FmVoices
    jmp InitFmSound

%ifdef WinVer
.ToggleGm:
    test byte [SoundFlags],SoundFlags.Gm
    jz .EnableGm
    mov ebx,PlayOptions.GmVoices
    mov esi,GmEmu.Given
    mov edi,GmSongPos
    jmp short .ToggleMidiSound
.EnableGm:
    or byte [PlayOptions],PlayOptions.GmVoices
    jmp InitGm
%endif

.EnableMpu:
    or byte [PlayOptions],PlayOptions.MpuVoices
    jmp InitMpu
.ToggleMpu:
%ifdef DosVer
.ToggleGm:
%endif
    test byte [SoundFlags],SoundFlags.Mpu
    jz .EnableMpu
    mov ebx,PlayOptions.MpuVoices
    mov esi,MpuEmu.Given
    mov edi,MpuSongPos
    ;jmp short .ToggleMidiSound

.ToggleMidiSound:
    xor dword [PlayOptions],ebx
    test dword [PlayOptions],ebx
    jnz .ToggledOn
   %ifdef WinVer
   %if PlayThreaded
    ; simply synchronize if necessary
    api EnterCriticalSection, DspCriticalSection
    api LeaveCriticalSection, DspCriticalSection
   %endif
   %endif
    mov al,[edi+SongPos.Heard]
    shl eax,24
    xchg [edi+SongPos.Active],ah ;swap zero for active voices
    mov [edi+SongPos.Changed],eax
    jmp esi
.ToggledOn:
    ret


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; (dword item ptr, ebx=item ptr)
SongDisplayCode:
;vwSongDisplay

section data
    StartMsgJtbl
    AddMsgJtbl Msg.Redraw,.Draw
    AddMsgJtbl Msg.Focus,CommonItemCode.GrabKeyFocus
    AddMsgJtbl Msg.KeyPress,.KeyPress
    AddMsgJtbl Msg.MousePrsRls,.MousePrsRls
    AddMsgJtbl Msg.MouseIn,.MouseIn
    ;AddMsgJtbl Msg.MouseOut,.MouseOut
.KeysJtbl:
    dd .SeekDecLarge
    dd .SeekIncLarge
    dd .SeekDecSmall
    dd .SeekIncSmall
    dd .SeekDecNormal
    dd .SeekIncNormal
    dd .DecSpeed
    dd .IncSpeed
    dd .DecSpeed
    dd .IncSpeed
    dd .SeekEnd
    dd .HalveSpeed
    dd .DoubleSpeed
    dd .HalveSpeed
    dd .DoubleSpeed
    dd .FastForward
    dd .SeekHome
    dd MainCommand.Reverse
    dd MainCommand.ToggleAs
    dd MainCommand.ToggleSine
    dd MainCommand.ToggleDls
    dd MainCommand.ToggleFm
    dd MainCommand.ToggleGm
    dd MainCommand.ToggleMpu
    dd MainCommand.ToggleTune
    dd .TogglePitchSlide
    dd .AllVoicesOff
    dd .ToggleVoice
    dd .ToggleVoice
    dd .ToggleVoice
    dd .ToggleVoice
    dd .ToggleVoice
    dd .ToggleVoice
    dd .ToggleVoice
    dd .ToggleVoice
    dd .AllVoicesOn
    dd .TogglePause
    dd .LoopStartIn
    dd .LoopFinishIn
    dd .LoopStart
    dd .LoopFinish
    dd .KeyShowMenu
.Keys:
    db 2,VK_LEFT,   0,VK_CONTROL
    db 2,VK_RIGHT,  0,VK_CONTROL
    db 2,VK_LEFT,   0,VK_SHIFT
    db 2,VK_RIGHT,  0,VK_SHIFT
    db 0,VK_LEFT
    db 0,VK_RIGHT
    db 2,VK_MINUS,  1,VK_SHIFT
    db 2,VK_PLUS,   1,VK_SHIFT
    db 0,VK_SUBTRACT
    db 0,VK_ADD
    db 0,VK_END
    db 4,VK_MINUS
    db 4,VK_PLUS
    db 4,VK_DIVIDE
    db 4,VK_MULTIPLY
    db 4,VK_TILDE
    db 4,VK_HOME
    db 4,VK_BACK
    db 4,VK_A
    db 4,VK_S
    db 4,VK_D
    db 4,VK_F
    db 4,VK_G
    db 4,VK_H
    db 4,VK_T
    db 4,VK_P
    db 4,VK_0
    db 4,VK_1
    db 4,VK_2
    db 4,VK_3
    db 4,VK_4
    db 4,VK_5
    db 4,VK_6
    db 4,VK_7
    db 4,VK_8
    db 4,VK_9
    db 4,VK_SPACE
    db 6,VK_INSERT, 0,VK_CONTROL
    db 6,VK_DELETE, 0,VK_CONTROL
    db 4,VK_INSERT
    db 4,VK_DELETE
    db 4,VK_APPS
    db -1

section code

    UseMsgJtbl

;컴컴컴컴컴컴컴컴컴컴
.Draw:
    ;push dword 6
    ;push dword SongView.Height|(SongView.Width<<16)
    ;push dword 0                ;top/left
    ;call DrawRect
    ;add esp,byte 12

    push dword SongView.Buffer
    push dword SongView.Height|(SongView.Width<<16)
    push dword 0                ;top/left
    call DrawImageOpaque
    add esp,byte 12

    ;clc
    ret

;컴컴컴컴컴컴컴컴컴컴
.KeyPress:
    mov esi,.Keys
    call ScanForKey
    jc .KeyNoMatch
    call [.KeysJtbl+ecx*4];jump to the right key response
    clc
.KeyNoMatch:
    ret

.SeekDecLarge:
    mov eax,TicksPerSecond*-10
    jmp short .AdjustPos
.SeekIncLarge:
    mov eax,TicksPerSecond*10
    jmp short .AdjustPos
.SeekDecSmall:
    mov eax,-TicksPerFrame
    jmp short .AdjustPos
.SeekIncSmall:
    mov eax,TicksPerFrame
    jmp short .AdjustPos
.SeekDecNormal:
    mov eax,-TicksPerSecond
    jmp short .AdjustPos
.SeekIncNormal:
    mov eax,TicksPerSecond
.AdjustPos:
    add eax,[PlayTime]
    jns .PosOk
    xor eax,eax
.PosOk:
    mov [PlayTime],eax
    ret

.SeekHome:
    mov [PlayTime],dword 0      ;reset time
    mov [PlayTimeStart],dword 0 ;reset time
    ;mov dword [PlayAdvance],TicksPerFrame  (leave alone)
    ;mov dword [PlaySpeed],TicksPerFrame
    ret

.SeekEnd:
    mov eax,[DspBufferTime]
    mov [PlayTime],eax
    ret

.ToggleVoice:
    movzx eax,ah
    sub eax,byte '1'
    btc [EnabledVoices],eax
    ret
.AllVoicesOff:
    mov byte [EnabledVoices],0
    ret
.AllVoicesOn:
    mov byte [EnabledVoices],255
    ret

.TogglePitchSlide:
    xor dword [DspFlags],DspFlags.PitchSlide
    ret

.TogglePause:
    xor dword [PlayOptions],PlayOptions.Pause
    test dword [PlayOptions],PlayOptions.Pause
    jz .Unpause
    jmp SilenceSounds
.Unpause:
    and dword [PlayOptions],~PlayOptions.Stop ;|PlayOptions.Suspended
    ret

.LoopFinish:
    mov eax,-1
    cmp dword [PlayLoopFinish],eax
    jb .LoopFinishSet
.LoopFinishIn:
    mov eax,[PlayTime]
.LoopFinishSet:
    cmp [PlayLoopStart],eax
    je .LoopFinishRet
    mov dword [PlayLoopFinish],eax
    jb .LoopFinishRet
    mov dword [PlayLoopStart],0
.LoopFinishRet:
    ret

.LoopStart:
    mov dword [PlayLoopFinish],-1
.LoopStartIn:
    mov eax,[PlayTime]
    mov [PlayLoopStart],eax
    ret

.LoopClear:
    mov dword [PlayLoopStart],0
    mov dword [PlayLoopFinish],-1
    ret

.DoubleSpeed:
    mov eax,[PlaySpeed]
    sal eax,1
    jmp short .ChangeSpeed
.HalveSpeed:
    mov eax,[PlaySpeed]
    sar eax,1
    jmp short .ChangeSpeed
.IncSpeed:
    mov eax,[PlaySpeed]
    add eax,TicksPerSecond/(30*27)
    jz .ChangeSpeed
    jnc .ChangeSpeed
    jmp short .ZeroSpeed
.DecSpeed:
    mov eax,[PlaySpeed]
    sub eax,TicksPerSecond/(30*27)
    jnc .ChangeSpeed
.ZeroSpeed:
    xor eax,eax
.ChangeSpeed:
    mov [PlaySpeed],eax
.FastForwardOff:
    mov [PlayAdvance],eax
    ret

.FastForward:
    mov eax,[PlaySpeed]
    cmp dword [PlayAdvance],TicksPerFrame*16
    je .FastForwardOff
    mov dword [PlayAdvance],TicksPerFrame*16
    ret

.KeyShowMenu:
    call GetItemAbsPosition
    push dword [ebx+GuiObj.Size] ;height/width
    push cx                     ;left
    push dx                     ;top
    push dword FloatMenuObj.AlignCol|FloatMenuObj.AlignBtm
    push dword MenuOwner
    push dword mnuDisplay
    push dword mnuDisplay
    call FloatMenuCode.Show
    add esp,byte 24
    ret

;컴컴컴컴컴컴컴컴컴컴
.Focus:
    test dword [ebx+GuiObj.Flags],GuiObj.NotFullFocus
    jnz .NotFullFocus
    mov eax,Msg.SetKeyFocus|KeyMsgFlags.SetContainer
    jmp SendContainerMsg
.NotFullFocus:
    ret

;컴컴컴컴컴컴컴컴컴컴
.MousePrsRls:
    ; do the action appropriate for the current visualization
    ; forex: clicking on a note in the rolling note sheet should select that
    ; sample
    test dword [Mouse.Buttons],Mouse.RightPress
    stc
    jz .MouseIgnore
    push dword 0                ;no height/width
    push word [Cursor.Col]      ;left
    push word [Cursor.Row]      ;top
    push dword FloatMenuObj.AlignCol|FloatMenuObj.AlignRow
    push dword MenuOwner        ;owner
    push dword mnuDisplay       ;selected menu list
    push dword mnuDisplay       ;menu list ptr
    call FloatMenuCode.Show
    add esp,byte 24
    ;clc
.MouseIgnore:
    ret

;컴컴컴컴컴컴컴컴컴컴
.MouseIn:
    mov eax,Msg.SetItemFocus|FocusMsgFlags.Specified|FocusMsgFlags.SetItem|FocusMsgFlags.SetGroup|FocusMsgFlags.ByMouse
    call SendContainerMsg
    mov esi,GuiCursor.SmallPointer
    jmp SetCursorImage
    ;clc
    ;ret


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
dd $+4
atrlSampleOwner:

section data
align 4,db 0
.GetValueJtbl:
dd .GetSample
dd .GetBrrNum
dd .GetFreq
dd .GetVolume
dd .GetPatch
dd .GetDrum
dd .GetBank
dd .GetTrack
dd .GetEnvelope
dd .GetInterpolate
dd .GetValid
dd .GetLength
dd .GetLoopLen
dd .GetOffset
dd .GetLoopOffset
dd .GetChecksum
.SetValueJtbl:
dd .SetSample
dd .SetBrrNum
dd .SetFreq
dd .SetVolume
dd .SetPatch
dd .SetDrum
dd .SetBank
dd .SetTrack
dd .SetEnvelope
dd .SetInterpolate
dd .SetValid
dd .SetLength
dd .SetLoopLen
dd .SetOffset
dd .SetLoopOffset
dd .SetChecksum
section code

    movzx edx,ah
    cmp al,AtrListMsg.Change
    je .SetValue
    cmp al,AtrListMsg.GetValue
    je near .GetValue
    stc
    ret

;컴컴컴컴컴컴컴컴컴컴
.SetValue:
    mov esi,edx
    imul esi,AtrListObj.Items_size
    mov ebx,[GlobalSample.Selected]
    mov eax,[atrlSample+esi+AtrListObj.Value]
    mov ecx,GlobalSample.Max-1
    test ebx,ebx
    call dword [.SetValueJtbl+edx*4]
.SetBank:
.SetTrack:
.SetEnvelope:
.SetInterpolate:    ;<- all dummies
.SetLength:
.SetLoopLen:
.SetOffset:
.SetLoopOffset:
.SetChecksum:
    clc
    ret

.SetBrrNum:
    ; force redraw of sample attribute

    mov esi,[LocalSample.GlobalIdx+eax*4]
    mov [GlobalSample.Selected],esi
    mov [atrlSample.SamplePtr+AtrListObj.Value],esi
    mov ebx,[LocalSample.Length+eax*4]
    mov ecx,[LocalSample.LoopLen+eax*4]
    mov edx,[LocalSample.Checksum+eax*4]
    mov edi,[LocalSample.Offset+eax*4]
    mov [GlobalSample.Length],ebx
    mov [GlobalSample.LoopLen],ecx
    mov [GlobalSample.Checksum],edx
    mov [GlobalSample.Offset],edi
    mov eax,esi
    jmp short .SetSampleAlready

.SetSample: ;(eax=selected sample)
    mov esi,[GlobalSample.LocalIdx+eax*4]
    mov [GlobalSample.Selected],eax
    mov [atrlSample.BrrNumPtr+AtrListObj.Value],esi

.SetSampleAlready:

    ; change displayed sample if necessary

%if 0
    mov ebx,[LocalSample.Length+esi*4]
    mov ecx,[LocalSample.LoopLen+esi*4]
    mov edx,[LocalSample.Checksum+esi*4]
    mov [atrlSample.LengthPtr+AtrListObj.Value],ebx
    mov [atrlSample.LoopLenPtr+AtrListObj.Value],ecx
    mov [atrlSample.ChecksumPtr+AtrListObj.Value],edx
    xor ebx,ebx
    bt [LocalSample.Valid],esi
    adc ebx,ebx                 ;set false / true if valid bit (carry set)
    mov [atrlSample.ValidPtr+AtrListObj.Value],ebx
%endif

    mov ebx,[GlobalSample.Freq+eax*4]
    mov ecx,[GlobalSample.Volume+eax*4]
    mov edx,[GlobalSample.Instrument+eax*4]
    mov [atrlSample.FreqPtr+AtrListObj.Value],ebx
    mov [atrlSample.VolumePtr+AtrListObj.Value],ecx
    mov [atrlSample.PatchPtr+AtrListObj.Value],dl
    mov [atrlSample.DrumPtr+AtrListObj.Value],dh
    shr edx,16
    mov [atrlSample.BankPtr+AtrListObj.Value],edx

    ;mov ebx,[GlobalSample.Track+eax*4]
    ;mov ecx,[GlobalSample.Envelope+eax*4]
    ;mov edx,[GlobalSample.Interpolate+eax*4]
    ;mov [atrlSample.TrackPtr+AtrListObj.Value],ebx
    ;mov [atrlSample.EnvelopePtr+AtrListObj.Value],ecx
    ;mov [atrlSample.InterpolatePtr+AtrListObj.Value],edx

    mov esi,[GlobalSample.Offset+eax*4]
    mov ebx,[GlobalSample.Length+eax*4]
    mov ecx,[GlobalSample.LoopLen+eax*4]
    mov edx,[GlobalSample.Checksum+eax*4]
    mov [atrlSample.OffsetPtr+AtrListObj.Value],si
    mov [atrlSample.LengthPtr+AtrListObj.Value],ebx
    mov [atrlSample.LoopLenPtr+AtrListObj.Value],ecx
    shr esi,16
    mov [atrlSample.ChecksumPtr+AtrListObj.Value],edx
    mov [atrlSample.LoopOffsetPtr+AtrListObj.Value],esi

    mov edi,atrlSample.SamplePtr+AtrListObj.Flags
.SsNextFlag:
    or dword [edi],AtrListObj.Redraw|AtrListObj.GetValue
    add edi,AtrListObj.Items_size
    cmp edi,atrlSample.ChecksumPtr+AtrListObj.Flags
    jbe .SsNextFlag
    ;call SendContainerRedraw.Partial

    ret

; (eax=value, ebx=selected sample, ecx=max samples, zf=first sample)
.SetFreq:
    jz .SfDefault
    bts [GlobalSample.Independant],ebx
    mov [GlobalSample.Freq+ebx*4],eax
    ret
.SfDefault:
    bt [GlobalSample.Independant],ebx
    jc .SfSkip
    mov [GlobalSample.Freq+ecx*4],eax
.SfSkip:
    dec ecx
    jge .SfDefault
    ret

; (eax=value, ebx=selected sample, ecx=max samples, zf=first sample)
.SetVolume:
    jz .SvDefault
    bts [GlobalSample.Independant],ebx
    mov [GlobalSample.Volume+ebx*4],eax
    ret
.SvDefault:
    bt [GlobalSample.Independant],ebx
    jc .SvSkip
    mov [GlobalSample.Volume+ecx*4],eax
.SvSkip:
    dec ecx
    jge .SvDefault
    ret

; (eax=value, ebx=selected sample, ecx=max samples, zf=first sample)
.SetPatch:
    jz .SpDefault
    bts [GlobalSample.Independant],ebx
    mov [GlobalSample.Instrument+ebx*4],al
    ret
.SpDefault:
    bt [GlobalSample.Independant],ebx
    jc .SpSkip
    mov [GlobalSample.Instrument+ecx*4],al
.SpSkip:
    dec ecx
    jge .SpDefault
    ret

; (eax=value, ebx=selected sample, ecx=max samples, zf=first sample)
.SetDrum:
    jz .SdDefault
    bts [GlobalSample.Independant],ebx
    mov [GlobalSample.Instrument+ebx*4+1],al
    ret
.SdDefault:
    bt [GlobalSample.Independant],ebx
    jc .SdSkip
    mov [GlobalSample.Instrument+ecx*4+1],al
.SdSkip:
    dec ecx
    jge .SdDefault
    ret

; (eax=value, ebx=selected sample, ecx=max samples, zf=first sample)
.SetValid:
    mov ecx,[GlobalSample.LocalIdx+ebx*4]
    cmp ecx,256
    jae .SvdSkip
    test eax,eax
    jz .SvdYes
    btr [LocalSample.Valid],ecx
.SvdSkip:
    ret
.SvdYes:
    bts [LocalSample.Valid],ecx
    ret

;컴컴컴컴컴컴컴컴컴컴
; (eax=msg, ecx=value)
.GetValue:
    mov eax,ecx
    call dword [.GetValueJtbl+edx*4]
    mov ecx,-1                  ;force caller to determine ASCIIZ length
    clc
    ret

.GetEnvelope: ;(eax=value)
.GetInterpolate: ;(eax=value)
    mov esi,Text.Null
    stc
    ret

.GetSample: ;(eax=value)
    shl eax,GlobalSample.NameShl
    lea esi,[GlobalSample.Name+eax+1]
.GetBrrNumRet:
    ret

.GetBrrNum: ;(eax=value)
    ;mov eax,[atrlSample.BrrNumPtr+AtrListObj.Value]
    mov esi,atrlSample.None
    cmp eax,255
    ja .GetBrrNumRet
    mov edi,atrlSample.BrrNumV
    mov ecx,3
    jmp NumToString.UseDLen

.GetFreq: ;(eax=value)
    ;mov eax,[atrlSample.FreqPtr+AtrListObj.Value]
    mov edi,atrlSample.FreqV
    mov ecx,5
    jmp NumToString.UseDLen

.GetVolume: ;(eax=value)
    mov edi,atrlSample.VolumeV
    mov ecx,4
    jmp NumToString.UseDLen

.GetPatch: ;(eax=value)
    mov edi,atrlSample.PatchV
    mov ecx,3
    push eax
    call NumToString.UseDLen
    pop eax
    push esi
    call GetMidiPatchName
    cld
    mov edi,atrlSample.PatchV+4
    rep movsb
    mov byte [edi],0
    pop esi
    ret

.GetDrum: ;(eax=value)
    mov edi,atrlSample.DrumV
    mov ecx,3
    jmp NumToString.UseDLen

.GetBank: ;(eax=value)
    mov edi,atrlSample.BankV
    mov ecx,5
    jmp NumToString.UseDLen

.GetTrack: ;(eax=value)
    mov edi,atrlSample.TrackV
    mov ecx,2
    jmp NumToString.UseDLen

.GetLength: ;(eax=value)
    mov edi,atrlSample.LengthV
    mov ecx,6
    jmp NumToString.UseDLen

.GetLoopLen: ;(eax=value)
    mov edi,atrlSample.LoopLenV
    mov ecx,6
    jmp NumToString.UseDLen

.GetOffset: ;(eax=value)
    mov edi,atrlSample.OffsetV
    mov ecx,5
    jmp NumToString.UseDLen

.GetLoopOffset: ;(eax=value)
    mov edi,atrlSample.LoopOffsetV
    mov ecx,5
    jmp NumToString.UseDLen

.GetChecksum: ;(eax=value)
    push dword [NumToString.FillChar]
    mov byte [NumToString.FillChar],'0'
    mov edi,atrlSample.ChecksumV
    mov ecx,8
    mov ebx,16
    push edi
    call NumToString.UseDLRadix
    pop esi
    pop dword [NumToString.FillChar]
    ret

.GetValid:
    test eax,eax
    mov esi,Text.Yes
    jnz .GetValidYes
    mov esi,Text.No
.GetValidYes:
    ret

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
dd $+4
atrlSongOwner:
    cmp al,AtrListMsg.Change
    je .Change
    cmp al,AtrListMsg.GetValue
    je .GetValue
    stc
    ret

.Change:
    stc
    ret

.GetValue:
    mov edx,[GlobalSample.Selected]
    cmp ah,atrlSong.Voices
    je .GetVoices
    cmp ah,atrlSong.Mute
    je .GetMute
    cmp ah,atrlSong.Speed
    je .GetSpeed
    stc
    ret


.GetVoices:
.GetMute:
.GetSpeed:
.GetGame:
.GetFile:
.GetTitle:
.GetAuthor:
.GetDate:
.GetCopyright:
.GetDumper:
.GetComments:
    stc
    ret
