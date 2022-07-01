# Splits an SVG with <symbol> elements into separate files.

import sys
import re
import os

fileNumber = 0

if len(sys.argv) <= 1:
    print("Supply filename to split to separate files by id. split-symbol.py input.svg");
    quit()

with open(sys.argv[1]) as inputFile:
    lines = inputFile.readlines()
    for line in lines:
        #print(line)
        if "<symbol" in line:
            outputFileName = f"{fileNumber}.svg"
            #idMatch = re.search(r"id=\"([A-Za-z\-\_]*)", line)
            idMatch = re.search(r"id=\"([^\"]*)\"", line)
            if idMatch is not None:
                outputFileName = f"{idMatch.group(1)}.svg"

            line = line.replace("<symbol", "<svg")
            line = line.replace("</symbol", "</svg")
            print(outputFileName)
            with open(outputFileName, "w") as outputFile:
                outputFile.write(line)
        fileNumber += 1
