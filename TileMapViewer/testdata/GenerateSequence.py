import sys
import array

if sys.byteorder == "big":
    sys.exit("Expecting a logical endian machine.")
#endif

totalCount = 64 * 64
totalRange = range(totalCount)

def WriteSequenceToFile(outputArray: array, typeMask: int, step: int, fileName: str):
    with open(fileName, "wb") as f:
        for i in totalRange:
            outputArray.append((i * step) & typeMask)
        #endfor
        outputArray.tofile(f)
    #endwith
#enddef

WriteSequenceToFile(array.array("B"), 255, 1, "SequenceUint8.bin")
WriteSequenceToFile(array.array("H"), 65535, 1, "SequenceUint16.bin")
WriteSequenceToFile(array.array("I"), 0xFFFFFFFF, 1, "SequenceUint32.bin")

WriteSequenceToFile(array.array("B"), 255, 8, "SequenceUint8Step8.bin")
WriteSequenceToFile(array.array("H"), 65535, 8, "SequenceUint16Step8.bin")
WriteSequenceToFile(array.array("I"), 0xFFFFFFFF, 8, "SequenceUint32Step8.bin")

#WriteSequenceToFile(array.array("B"), "SequenceUint8.bin")
#WriteSequenceToFile(array.array("H"), "SequenceUint8.bin")
#WriteSequenceToFile(array.array("I"), "SequenceUint8.bin")
#with open(, "wb") as f:
#    for i in totalRange:
#        outputArray.append(i & 255)
#    #endfor
#    outputArray.tofile(f)
##endwith
#
#outputArray = array.array("H")
#with open("SequenceUint16.bin", "wb") as f:
#    for i in totalRange:
#        outputArray.append(i & 65535)
#    #endfor
#    outputArray.tofile(f)
##endwith
#
#outputArray = array.array("I")
#with open("SequenceUint32.bin", "wb") as f:
#    for i in totalRange:
#        outputArray.append(i)
#    #endfor
#    outputArray.tofile(f)
##endwith

# Litter code:
#f.write(i.to_bytes(1, byteorder="little"))
#outputArray.byteswap()
