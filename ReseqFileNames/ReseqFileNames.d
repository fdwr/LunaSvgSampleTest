/*
Resequence File Names
Dwayne Robinson
2006-12-12
*/

module ReseqFileNames;

import std.file;
import std.stdio;
import std.string;
//import std.c.windows.windows;
//import std.instrinsic;

const static char[] HelpInfo =
`Rename File To Pattern
(c) 2006 Dwayne Robinson
Simpleton renamer changes a list of filenames, given a
template filename, keeping the same numeric values.
-All files MUST be in the same path.
-Numbers can only be appended to the end
-For more powerful renamers, try Siren Renamer or ReNamer by Den4b
-Does not work with Unicode :-/

renamefilepattern.exe "Liv Tyler 1.jpg" img1.jpg img2.jpg img3.jpg
renamefilepattern.exe "Test 2006 1.jpg" dsfc101.jpg dsfc102.jpg dsfc103.jpg
`;

/*
const static char[] HtmlHeader = `<html>`;

const static char[] HtmlItem =
`<img src="%.*s" /><span class="float"><span class="label"></span><span class="text">%.*s</span></span>`;

const static char[] HtmlFooter =
`</body>
</html>
`;
*/

int main(char[][] args)
{
    if (args.length <= 1) {
        writefln(HelpInfo);
        getch();
        return 0;
    }

     char[][] files, newFiles;
    for (int ai=1; ai < args.length; ++ai) {
        if (args[ai][0] == '-') {
            // determine switch
            ;
        } else {
            int numFiles = files.length;
            files.length = numFiles + 1;
            files[numFiles] = args[ai];
        }
    }
    //listdir("");

    // find the filename template by
    // -looking for @ symbol
    // -using first filename
    char[] fileNameTemplate;
    int templateIdx = 0;
    for (int fi = 0; fi < files.length; ++fi) {
        char[] fileName = files[fi];
        if (fileName.find('@') >= 0) {
            templateIdx = fi;
            break;
        }
    }
    fileNameTemplate = files[templateIdx];
    files[templateIdx] = files[files.length-1];
    files.length = files.length - 1;

    writef("Total files=%d\nTemplate: %s\n", files.length, fileNameTemplate);
    
    // trim filename template to first number that starts
    // sequence with 0 or 1
    char prevc = ' ';
    for (int ci=getFileNameOffset(fileNameTemplate); ci < fileNameTemplate.length; ++ci) {
        char c = fileNameTemplate[ci];
        writef("ci=%d c=%d\n", ci, c);
        if (c >= '0' && c <= '9' && (prevc == ' ' || prevc == '_' || prevc == '-')) {
            fileNameTemplate.length = ci;
            /*
            int value = atoi(fileNameTemplate[ci..length]);
            //writef("value=%d\n", value);
            if (value == 0 || value == 1) {
                fileNameTemplate.length = ci;
            }
            for (; ci < fileNameTemplate.length; ++ci) {
                char c2 = fileNameTemplate[ci];
                if (c2 < '0' || c2 > '9')
                    break;
            }
            */
        }
        prevc = c;
    }
    int templateExtOffset = getFileExtOffset(fileNameTemplate);
    if (templateExtOffset > 0) fileNameTemplate.length = templateExtOffset-1;

    writef("Trimmed:  %s\n\n", fileNameTemplate);

    // set new files initially empty
    newFiles.length = files.length;
    files.sort;

    for (int fi = 0; fi < files.length; ++fi) {

        char[] fileName = files[fi],  newFileName = fileNameTemplate ~ "";

        // get filename and extension
        int fileNameOffset = getFileNameOffset(fileName);
        int fileExtOffset = getFileExtOffset(fileName);
        if (fileExtOffset <= fileNameOffset) {
            //newFiles[fi].length = 0;
            continue;
        }
        fileExtOffset--; // move back to dot
        char[] fileExt = tolower(fileName[fileExtOffset..length]);

         // find all numbers in filename
        int valuesTotal = 0;
        int ci = getFileNameOffset(fileName);

        bool insideParens = false;
        int numbersTotal = 0;
        while (ci < fileName.length) {

            char c = fileName[ci++];
            if (c=='(' || c=='[') {
                insideParens = true;
            }
            else if (c==')' || c==']') {
                insideParens = false;
            }
            else if (!insideParens && c >= '0' && c <= '9') {
                int value = atoi(fileName[ci-1..length]);
                // skip remaining digits of number
                for (; ci < fileName.length; ++ci) {
                    char c2 = fileName[ci];
                    if (c2 < '0' || c2 > '9')
                        break;
                }
                if (numbersTotal > 0) {
                    newFileName ~= format("-%03d", value);
                } else {
                    newFileName ~= format("%03d", value);
                }
                numbersTotal++;
            }
        }

        newFiles[fi] = newFileName ~ fileExt;
        writefln("old: %s\nnew: %s\n",
            files[fi][getFileNameOffset(files[fi])..length],
            newFiles[fi][getFileNameOffset(newFiles[fi])..length]
            );
    }

    writefln("Press 'r' to rename...");
    if (getch() != 'r') {
        writefln("Rename canceled");
        return 0;
    }

    int errorCount = 0;
    writefln("Renaming files:\n");
    //-if (quiet) writefln(HtmlHeader);
    for (int fi = 0; fi < files.length; ++fi) {
        if (newFiles[fi].length > 0) {
            try {
                std.file.rename(files[fi], newFiles[fi]);
            } catch(FileException) {
                writefln("Failed to rename: %s\n              to: %s",
                    files[fi][getFileNameOffset(files[fi])..length],
                    newFiles[fi][getFileNameOffset(newFiles[fi])..length]
                    );
                errorCount++;
            }
        }
     }
    if (errorCount > 0) {
        // pause long enough to read errors
        writefln("%d error%s", errorCount, (errorCount != 1) ? "s" : "");
        getch();
    }

    return 0;
}


int getFileNameOffset(char[] fileName)
{
    for (int ci=fileName.length-1; ci >= 0; --ci) {
        char c = fileName[ci];
        switch (c) {
        case '/':
        case '\\':
        //case ':':
            return ci+1;
        default:
        }
    }
    return 0;
    //int ci = fileName.rfind('\\'); // skip the path
    //if (ci < 0) ci = fileName.rfind('/');
    //if (ci < 0) ci = 0;
}


int getFileExtOffset(char[] fileName)
{
    for (int ci=fileName.length-1; ci >= 0; --ci) {
        char c = fileName[ci];
        switch (c) {
        case '/':
        case '\\':
        //case ':':
            return -1; // path separator found before dot
        case '.':
            return ci+1;    // found it
        default:
        }
    }
    return -1;
}
