import sys
import array

if sys.byteorder == "big":
    sys.exit("Expecting a logical endian machine.")
#endif

totalCount = 64 * 64

def WriteSequenceToFile(outputArray: array, totalCount: int, typeMask: int, orMask: int, step: int, fileName: str):
    with open(fileName, "wb") as f:
        for i in range(totalCount):
            outputArray.append(((i * step) | orMask) & typeMask)
        #endfor
        outputArray.tofile(f)
    #endwith
#enddef

def Write2DSequenceToFile(outputArray: array, xCount: int, yCount: int, typeMask: int, orMask: int, step: int, fileName: str):
    with open(fileName, "wb") as f:
        for y in range(yCount):
            for x in range(xCount):
                outputArray.append(((x * step) | ((y << 8) * step) | orMask) & typeMask)
            #endfor
        #endfor
        outputArray.tofile(f)
    #endwith
#enddef

WriteSequenceToFile(array.array("B"), totalCount, 255, 0, 1, "SequenceUint8.bin")
WriteSequenceToFile(array.array("H"), totalCount, 65535, 0, 1, "SequenceUint16.bin")
WriteSequenceToFile(array.array("I"), totalCount, 0xFFFFFFFF, 0xFF000000, 1, "SequenceUint32.bin")

WriteSequenceToFile(array.array("B"), totalCount, 255, 0, 4, "SequenceUint8Step4.bin")
WriteSequenceToFile(array.array("H"), totalCount, 65535, 0, 4, "SequenceUint16Step4.bin")
WriteSequenceToFile(array.array("I"), totalCount, 0xFFFFFFFF, 0xFF000000, 4, "SequenceUint32Step4.bin")

Write2DSequenceToFile(array.array("I"), 16, 16, 0xFFFFFFFF, 0xFF000000, 17, "Sequence2DUint32Step16.bin")

# Litter code:
#f.write(i.to_bytes(1, byteorder="little"))
#outputArray.byteswap()
