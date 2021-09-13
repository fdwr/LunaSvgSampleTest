void VramTileFill()
{
    for (row = 0; row < rows; row++)
    {
        for (col = 0; col < cols; col++)
        {
            long paldword
        
            if (UseTable & (UseTablePalette | UseTableGfx))
            {
                char byte = VramFormat[VramSource >> 4]
                if (UseTable & UseTablePalette)
                    paldword = (byte | (byte<<8) | (byte<<16) | (byte<<24)) & 0FCFCFCFCh);
                if (UseTable & UseTableGfx)
                {
                    SourceInc = VramFormatTileSize[byte &= 7]
                    *VramFormatTileRoutines[byte](VramSource, SourceInc >> 3)
                }
            }
            else
            {
                *CurrentTileRoutine(VramSource, Bitdepth)
            }
        
            Source = VramBuffer + 65536 - 64
            PixDest = Dest
            for (pixrow = 0; pixrow < 8; pixrow++)
                for (pixcol = 0; pixcol < 8; pixcol++)
                    *PixDest++ = *Source++ + PalBase;
        
            VramSource += SourceInc
            Dest += 8
        }
        Dest += 128
    }
}
