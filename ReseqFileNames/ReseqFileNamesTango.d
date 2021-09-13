/*
Resequence File Names
Dwayne Robinson
2006-12-12
*/

module ReseqFileNames;

// What the frack!?
// Why do I need to import SO many libraries
// to use Tango, whereas with Phobos, it was
// about 3!

//import std.c.windows.windows;
//import std.c.windows.windows;
private import tango.stdc.ctype;
private import tango.stdc.stdio;
private import tango.stdc.stdlib;
//private import tango.io.File;
private import Path = tango.io.Path;
private import tango.io.Console;
private import tango.io.Stdout;
private import tango.text.Util;
private import tango.text.Ascii;
private import tango.text.convert.Format;
private import tango.core.Array;

//-import std.file;
//-import std.stdio;
//import std.string;
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
        Cout(HelpInfo).flush;
        getche();
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
        //if (tango.text.Util.locate(fileName, '@') >= 0) {
        if (fileName.find('@') >= 0) {
            templateIdx = fi;
            break;
        }
    }
    fileNameTemplate = files[templateIdx];
    files[templateIdx] = files[files.length-1];
    files.length = files.length - 1;

    printf("Total files=%d\nTemplate: %s\n", files.length, fileNameTemplate);
    
    // trim filename template to first number that starts
    // sequence with 0 or 1
    char prevc = ' ';
    for (int ci=getFileNameOffset(fileNameTemplate); ci < fileNameTemplate.length; ++ci) {
        char c = fileNameTemplate[ci];
        printf("ci=%d c=%d\n", ci, c);
        if (c >= '0' && c <= '9' && (prevc == ' ' || prevc == '_' || prevc == '-')) {
            fileNameTemplate.length = ci;
            /*
            int value = atoi(fileNameTemplate[ci..length]);
            //printf("value=%d\n", value);
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

    printf("Trimmed:  %s\n\n", fileNameTemplate);

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
        char[] fileExt = toLower(fileName[fileExtOffset..length]);

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
                int value = atoi(&(fileName[ci-1..length])[0]);
                // skip remaining digits of number
                for (; ci < fileName.length; ++ci) {
                    char c2 = fileName[ci];
                    if (c2 < '0' || c2 > '9')
                        break;
                }
                if (numbersTotal > 0) {
					// Add dash separator between filename and number.
                    newFileName ~= Format.convert("-%03d", value);
                } else {
					// Just append number directly to filename.
                    newFileName ~= Format.convert("%03d", value);
                }
                numbersTotal++;
            }
        }

        newFiles[fi] = newFileName ~ fileExt;
        printf("old: %s\nnew: %s\n",
            files[fi][getFileNameOffset(files[fi])..length],
            newFiles[fi][getFileNameOffset(newFiles[fi])..length]
            );
    }

    printf("Press 'r' to rename...\n");
    if (getchar() != 'r') {
        printf("Rename canceled\n");
        return 0;
    }

    int errorCount = 0;
    printf("Renaming files:\n");
    //-if (quiet) printf(HtmlHeader);
    for (int fi = 0; fi < files.length; ++fi) {
        if (newFiles[fi].length > 0) {
            try {
                Path.rename(files[fi], newFiles[fi]);
            } catch(tango.core.Exception.IOException) {
                printf("Failed to rename: %s\n              to: %s\n",
                    files[fi][getFileNameOffset(files[fi])..length],
                    newFiles[fi][getFileNameOffset(newFiles[fi])..length]
                    );
                errorCount++;
            }
        }
     }
    if (errorCount > 0) {
        // pause long enough to read errors
        printf("%d error%s\n", errorCount, (errorCount != 1) ? "s" : "");
        getchar();
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
