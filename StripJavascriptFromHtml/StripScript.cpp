// Strips <SCRIPT>...</SCRIPT> from HTML, useful for killing
// irritating Javascript in saved webpages.

#include "basictypes.h"
#include <tchar.h>
#include <ctype.h>
#include <stdarg.h>
#include "std.h"

////////////////////////////////////////////////////////////////
int StripTags(FILE* infp, FILE* outfp);
extern "C" void FatalError(TCHAR* msg, ...);
int strmatchn(const TCHAR* string, const TCHAR* matches);

////////////////////////////////////////////////////////////////

int main(int argc, char* argv[])
{
    if (argc < 2)
        FatalError(T("No source filename supplied\n"));

    FILE* infp = fopen(argv[1], "rb");
    #ifdef _WINDOWS
    FILE* outfp = fopen("con:", "w");
    #else
    FILE* outfp = stdout;
    #endif
    if (infp == null)
        FatalError(T("Could not open source filename \"%s\"\n"), argv[1]);

    StripTags(infp, outfp);
    
    fclose(infp);
    fclose(outfp);

    return 0;
}


/** Strips a file of undesired tags.
*/
int StripTags(FILE* infp, FILE* outfp)
{
    uint8* inbuf;
    uint8  outbuf[4096];

    fseek( infp, 0, SEEK_END );
    int insize = ftell(infp);
    rewind(infp);

    // allocate memory to contain the whole file.
    // and copy the file into the buffer.
    inbuf = (uint8*) malloc(insize+1);
    if (inbuf == null) FatalError("Could not allocate enough memory for file buffer. File could be too large?");
    fread( inbuf,1, insize,infp);
    inbuf[insize] = '\0';

    int inpos = 0;
    int outsize = 0;

    while (inpos < insize) {
        switch( inbuf[inpos] ) {
        case '\r':
            inpos++;
            #ifdef _WINDOWS
            // output both carriage return AND line fed
            outbuf[outsize++] = '\r';
            outbuf[outsize++] = '\n';
            if (inbuf[inpos] == '\n') inpos++;
            #else
            outbuf[outsize++] = '\n';
            if (inbuf[inpos] == '\n') inpos++;
            #endif
            break;
        case '\n':
            inpos++;
            #ifdef _WINDOWS
            // output both carriage return AND line fed
            outbuf[outsize++] = '\r';
            outbuf[outsize++] = '\n';
            #else
            outbuf[outsize++] = '\n';
            #endif
            break;
        case '<':
            inpos++;
            switch (strmatchn((char*)&inbuf[inpos], "script\0" "noscript\0" "\0")) {
            case 0:
                {
                    TCHAR* next;
                    TCHAR* match = T("</SCRIPT>");
                    if (islower( inbuf[inpos] )) match = T("</script>");
                    next = strstr((char*)&inbuf[inpos], match) + 9;

                    if (next == null) {
                        next = strchr((char*)&inbuf[inpos], '>');
                        if (next == null) break;
                    }
                    inpos = (uint8*)next - inbuf;
                }
                break;
            case 1:
                inpos += 9;
                break;
            default:
                outbuf[outsize++] = '<';
                break;
            }
            break;
        default:
            outbuf[outsize++] = inbuf[inpos++];
            break;

        }
        if (outsize > elmsof(outbuf)-256) {
            fwrite(outbuf, outsize, 1, outfp);
            outsize = 0;
        }
    }
    fwrite(outbuf, outsize, 1, outfp);

    free(inbuf);

    return 0;
}

/** Matches a string prefix against a list and returns the match index.
    Unlike strmatch, this matches only the prefix, meaning 'dogwood' and
    'doghouse' would both match with 'dog'. So the order of the items in
    the matches string is important. Always put the longer words first
    (otherwise they may match a shorter word first).

\param[in]  string  ASCIIZ string to match
\param[in]  matches list of several null separated strings, with
                    the final string being double null terminated.

\return     zero based match index or -1 if no match found
*/
int strmatchn(const TCHAR* string, const TCHAR* matches)
{
    int match = 0, len;

    while(len = strlen(matches), *matches && strnicmp(string, matches, len)) {
        match++;
        matches += len + 1;
    }
    if (*matches == '\0') match = -1;
    return match;
}

////////////////////////////////////////////////////////////////////////////////

/** Global text message logger.

\param[in]  msg     Text message.
\param[in]  ...     Variable number of parameters (anything printf can handle)
*/
extern "C" void FatalError(TCHAR* msg, ...)
{
    TCHAR text[1024];
    va_list args;
    va_start(args, msg);
    _vsntprintf(text, elmsof(text), msg, args);
    text[1023] = '\0';

    // delete old lines if too long
    #ifdef _DEBUG
    //OutputDebugString(text);
    #endif
    puts("StripScript 1.0 - Dwayne Robinson\r\nStrips javascript from HTML.\r\n");
    puts(text);

    exit(-1);
}
