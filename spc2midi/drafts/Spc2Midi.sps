; Experimental format for defining samples.

SpcFileSettings
{
  0="c:\emu\spc\smw.sp3",4B157A83
  {
    Markers
    {


    }
  }


}
SettingFilePaths
{
  0="SUPER MARIOWORLD     ",c:\emu\spc\smw.sps,,13571
  1="THE LEGEND OF ZELDA  ",c:\emu\spc\tloz.sps,,3948
  2="SUPER MARIO ALL_STARS",c:\emu\spc\allstars.sps,,5498
}




;SPC2MIDI Settings
Game=Zelda: A Link To The Past

;- Name to describe the sample. By default, any new samples found in an SPC
;  savestate are numbered sequentially, from "samp0000" to "samp9999". Also,
;  whenever copying sounds, a number will be attached to the end of it.
;  Copying "flute" and "trumpet3" would create "flute2" and "trumpet4".
;  Since many instrument sounds in games sound similar but with subtle
;  differences, they can be numbered sequentially; but for recognizability,
;  try to name them by attributes. For example, rather than "flute" and
;  "flute2", try "Flute-Bright" and "Flute-Dull". Put the description after
;  the instrument name so that sorting and searching will list starting with
;  the type.
;- Length is the sample length of the sound.
;- LoopLen is the sample length of the loop portion.
;- CheckSum is the total of all the raw dwords in both the sample and
;  its loop portion. Odd bytes at the top of a dword are zeroed. The
;  checksum is used to automatically associate samples in the SPC or ZST
;  to their proper attributes.
;- Pitch is the perceived pitch when the sample is played at 32khz, with note
;  number 69 being 440hz (or A5 above middle C).
;- Volume is the equivalent MIDI volume level (1-127) when the sample is
;  played at full volume.
;- Instrument is a general MIDI instrument that most closely matches the
;  sample's sound.
;- Bank is optional for sequencers or synthesizers that support more than the
;  standard MIDI 128 instruments.
;- Flags are miscellaneous bits for determining sample attributes.
SampleSettings=Name,Length,LoopLen,CheckSum,Pitch,Volume,Instrument,Bank,Flags
Samples
{
  0="Flute",840,48,1747A638,69,127,64,30572,M
  1="Drum",2080,96,837BD092,77,64
  2="Ocarina",496,128,123EF8A9,98,127
  3="Piano",248,64,976F3CE1,73,127,1
  6="Trumpet-Royal",1020,64,8BE5A526,82,34
  7="Rain",132,132,3616BE0C,108,128
}
;- Patch is the instrument number (0-127) within the current bank.
;- Bank is a block of instruments. Banks can be used by synthesizers to
;  access more instruments than the standard 128.
;- GmPatch is closest general MIDI instrument (bank 0) to that of the
;  synthesizer's for devices that only support the standard 128.
;- Type describes how the sound is generated, whether by wind, reed, string,
;  percussion, and the like. It is optional and simply used for grouping.
InstrumentSettings=Name,Patch,Bank,GmPatch,Type
Instruments
{
  ;Note that numbering starts at 256 rather than 0 because 0-255 are already
  ;defined, 0-127 as general MIDI instruments as 128+ as percussion.
  256="Chime Harp",23,0,126
  257="Chirp Whistle",24,0,87
  258="Glass Blow",25,1,1
  259="Glock Vibraphone",26,2,0
  260="Sitar",27,3,5
  261="Carnival",28,0,28
  262="Wood Glock",29,7
  263="Marimba",30,0,13
}
FileDefaults
{
  zelda.zst
  {
    Name="Opening Tune"
    ;If a particular channel has samples which are undefined yet, the entire
    ;channel can simply be muted to rid the exported MIDI of the offending
    ;sounds.
    MutedChannels=8
    ;Muting an entire channel has the drawback that it mutes all instruments
    ;played on that channel, even if they do sound okay, So similarly, if there
    ;is a particular sample that does not sound good in the conversion, it
    ;alone can be muted.
    MutedSamples
    {
      23
    }
    ;The SPC700 has a 64khz timer for very precise timing, although usually
    ;the less accurate (but more than adequate) 8khz timers are used. Markers
    ;are simply stored as the number of 64khz timer increments at the desired
    ;point in the song.
    Markers
    {
      187892
      402938
      1047352
      6725321
      8927345
    }
  }
  zelda.sp3
  {
    ;Although SPC's may include names within them, savestates do not, so this
    ;field is available.
    Name="Boss Music"
    Markers
    {
      34729819
    }
  }
  ;There are no markers for this file, so none were saved.
  zelda.zs7
  {
    Name="Fairy Music"
  }
}
