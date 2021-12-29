        DefWindow NullGuiItem,0,0
        DefContainedItem mainbg
        DefContainedItem ttlMainMenu
        DefContainedItem emnuMain
        DefContainedItem label3
        DefContainedItem ttlSongDisplay
        DefContainedItem vwSongDisplay
        DefContainedItem buttonXP
        DefContainedItem pbrSongPos
        DefContainedItem tlbrSongControls
        DefContainedItem lblSongPos
        DefContainedItem ttlSongAtrs
        DefContainedItem border16
        DefContainedItem atrlSong
        DefContainedItem scroll30
        DefContainedItem titlebar31
        DefContainedItem border32
        DefContainedItem ttlSampleAtrs
        DefContainedItem border34
        DefContainedItem atrlSample
        DefContainedItem scroll49
        DefContainedItem border50
        DefContainedItem label51
        DefContainedItem label52
        DefWindowEnd
DefItem mainbg,MainBgCode,0,MainBgObj.DefFlags, 0,0,Screen.Height,Screen.Width
        DefTitleBar Program.Title,Program.Title_size,TitleBarObj.HelpButton|TitleBarObj.CloseButton|TitleBarObj.MinButton|TitleBarObj.MaxButton

DefItem ttlMainMenu,TitleBarCode,NullGuiItem,TitleBarObj.DefFlags|GuiObj.GroupStart, 24,6,18,108
        DefTitleBar ttlMainMenu.Text,9,TitleBarObj.GroupIndicate|TitleBarObj.HelpButton
DefItem emnuMain,BorderCode,0,BorderObj.DefFlags^GuiObj.NoKeyFocus, 44,6,400,108
DefItem label3,LabelCode,0,LabelObj.DefFlags, 48,10,16,80
        DefLabel label3.Text,9,LabelObj.AlignLeft
DefItem ttlSongDisplay,TitleBarCode,NullGuiItem,TitleBarObj.DefFlags|GuiObj.GroupStart, 24,118,18,260
        DefTitleBar ttlSongDisplay.Text,12,TitleBarObj.GroupIndicate|TitleBarObj.HelpButton|TitleBarObj.MaxButton
DefItem vwSongDisplay,BorderCode,0,BorderObj.DefFlags^GuiObj.NoKeyFocus, 44,118,132,260
DefItem pbrSongPos,BorderCode,0,BorderObj.DefFlags, 178,118,20,516
DefItem tlbrSongControls,LabelCode,0,LabelObj.DefFlags, 202,118,16,384
        DefLabel tlbrSongControls.Text,55,LabelObj.AlignLeft
DefItem lblSongPos,LabelCode,0,LabelObj.DefFlags, 202,506,16,128
        DefLabel lblSongPos.Text,21,LabelObj.AlignLeft
DefItem ttlSongAtrs,TitleBarCode,NullGuiItem,TitleBarObj.DefFlags|GuiObj.GroupStart, 24,382,18,252
        DefTitleBar ttlSongAtrs.Text,15,TitleBarObj.GroupIndicate|TitleBarObj.HelpButton
DefItem border16,BorderCode,0,BorderObj.DefFlags, 44,382,132,238
DefItem atrlSong,AtrListCode,NullGuiItem,AtrListObj.DefFlags, 46,384,128,234
        DefAtrList scroll30
        DefAtrListItem .18,atrlistitem18.Name,7,atrlistitem18.Text,8, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem .19,atrlistitem19.Name,5,atrlistitem19.Text,11, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem .20,atrlistitem20.Name,6,atrlistitem20.Text,4, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem .21,atrlistitem21.Name,7,atrlistitem21.Text,7, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem .22,atrlistitem22.Name,5,atrlistitem22.Text,5, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem .23,atrlistitem23.Name,5,atrlistitem23.Text,9, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem .24,atrlistitem24.Name,6,atrlistitem24.Text,10, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem .25,atrlistitem25.Name,7,atrlistitem25.Text,10, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem .26,atrlistitem26.Name,5,atrlistitem26.Text,10, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem .27,atrlistitem27.Name,10,atrlistitem27.Text,8, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem .28,atrlistitem28.Name,7,atrlistitem28.Text,9, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem .29,atrlistitem29.Name,9,atrlistitem29.Text,6, 0, 0,-1000,1000, 1,10,100
        DefAtrListEnd
DefItem scroll30,ScrollHandleCode,atrlSong,ScrollHandleObj.DefFlags, 44,622,132,12
        DefScrollHandle 100,0,0,1,10
DefItem titlebar31,TitleBarCode,NullGuiItem,TitleBarObj.DefFlags|GuiObj.GroupStart, 224,118,18,260
        DefTitleBar titlebar31.Text,14,TitleBarObj.GroupIndicate|TitleBarObj.HelpButton|TitleBarObj.MaxButton
DefItem border32,BorderCode,0,BorderObj.DefFlags^GuiObj.NoKeyFocus, 244,118,132,260
DefItem ttlSampleAtrs,TitleBarCode,NullGuiItem,TitleBarObj.DefFlags|GuiObj.GroupStart, 224,382,18,252
        DefTitleBar ttlSampleAtrs.Text,17,TitleBarObj.GroupIndicate|TitleBarObj.HelpButton
DefItem border34,BorderCode,0,BorderObj.DefFlags, 244,382,132,238
DefItem atrlSample,AtrListCode,NullGuiItem,AtrListObj.DefFlags, 246,384,128,234
        DefAtrList scroll49
        DefAtrListItem .36,atrlistitem36.Name,7,atrlistitem36.Text,2, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem .37,atrlistitem37.Name,5,atrlistitem37.Text,10, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem .38,atrlistitem38.Name,7,atrlistitem38.Text,3, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem .39,atrlistitem39.Name,9,atrlistitem39.Text,11, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem .40,atrlistitem40.Name,6,atrlistitem40.Text,10, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem .41,atrlistitem41.Name,6,atrlistitem41.Text,2, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem .42,atrlistitem42.Name,5,atrlistitem42.Text,1, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem .43,atrlistitem43.Name,6,atrlistitem43.Text,1, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem .44,atrlistitem44.Name,9,atrlistitem44.Text,4, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem .45,atrlistitem45.Name,12,atrlistitem45.Text,4, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem .46,atrlistitem46.Name,7,atrlistitem46.Text,4, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem .47,atrlistitem47.Name,8,atrlistitem47.Text,2, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem .48,atrlistitem48.Name,9,atrlistitem48.Text,8, 0, 0,-1000,1000, 1,10,100
        DefAtrListEnd
DefItem scroll49,ScrollHandleCode,atrlSample,ScrollHandleObj.DefFlags, 244,622,132,12
        DefScrollHandle 100,0,0,1,10
DefItem border50,BorderCode,0,BorderObj.DefFlags, 378,118,20,516
DefItem label51,LabelCode,0,LabelObj.DefFlags, 402,118,16,384
        DefLabel label51.Text,28,LabelObj.AlignLeft
DefItem label52,LabelCode,0,LabelObj.DefFlags, 402,506,16,128
        DefLabel label52.Text,21,LabelObj.AlignLeft
DefItem buttonXP,ButtonCode,NullGuiItem,ButtonObj.DefFlags, 56,130,23,75
        DefPushButton buttonXP.Text,6,0

        ttlMainMenu.Text: db "Main Menu"
        label3.Text: db "Tree Menu"
        ttlSongDisplay.Text: db "Song Display"
        tlbrSongControls.Text: db "    *                L  A  S  D  F  G  H  M  T"
        lblSongPos.Text: db "012:30.33 / 023:12.44"
        ttlSongAtrs.Text: db "Song Attributes"
        atrlistitem18.Name: db "Voices:"
        atrlistitem18.Text: db "12345678"
        atrlistitem19.Name: db "Mute:"
        atrlistitem19.Text: db "Solo Sample"
        atrlistitem20.Name: db "Speed:"
        atrlistitem20.Text: db "120%"
        atrlistitem21.Name: db "Sample:"
        atrlistitem21.Text: db "Flute 3"
        atrlistitem22.Name: db "Game:"
        atrlistitem22.Text: db "Zelda"
        atrlistitem23.Name: db "File:"
        atrlistitem23.Text: db "zelda.sp3"
        atrlistitem24.Name: db "Title:"
        atrlistitem24.Text: db "Boss Music"
        atrlistitem25.Name: db "Author:"
        atrlistitem25.Text: db "Koji Kondo"
        atrlistitem26.Name: db "Date:"
        atrlistitem26.Text: db "1991-08-03"
        atrlistitem27.Name: db "Copyright:"
        atrlistitem27.Text: db "Nintendo"
        atrlistitem28.Name: db "Dumper:"
        atrlistitem28.Text: db "(unknown)"
        atrlistitem29.Name: db "Comments:"
        atrlistitem29.Text: db "(none)"
        titlebar31.Text: db "Sample Display"
        ttlSampleAtrs.Text: db "Sample Attributes"
        atrlistitem36.Name: db "BrrNum:"
        atrlistitem36.Text: db "39"
        atrlistitem37.Name: db "Freq:"
        atrlistitem37.Text: db "440hz (A5)"
        atrlistitem38.Name: db "Volume:"
        atrlistitem38.Text: db "128"
        atrlistitem39.Name: db "Keyboard:"
        atrlistitem39.Text: db "(play keys)"
        atrlistitem40.Name: db "Instr:"
        atrlistitem40.Text: db "Soft Flute"
        atrlistitem41.Name: db "Patch:"
        atrlistitem41.Text: db "43"
        atrlistitem42.Name: db "Bank:"
        atrlistitem42.Text: db "0"
        atrlistitem43.Name: db "Track:"
        atrlistitem43.Text: db "0"
        atrlistitem44.Name: db "Envelope:"
        atrlistitem44.Text: db "ADSR"
        atrlistitem45.Name: db "Interpolate:"
        atrlistitem45.Text: db "None"
        atrlistitem46.Name: db "Length:"
        atrlistitem46.Text: db "1012"
        atrlistitem47.Name: db "LoopLen:"
        atrlistitem47.Text: db "64"
        atrlistitem48.Name: db "Checksum:"
        atrlistitem48.Text: db "1A358B9F"
        label51.Text: db "    *              "
        label52.Text: db "012:30.33 / 023:12.44"
        buttonXP.Text: db "Cancel"
