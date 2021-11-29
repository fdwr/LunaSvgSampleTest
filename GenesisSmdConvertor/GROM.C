/*****************************************************************************
* GROM Version 0.75                                                          *
* Bart Trzynadlowski, 2000, public domain.                                   *
*****************************************************************************/

/*
 * grom.c:
 *
 * Simple utility for toying with Genesis ROMs. Supports converting of SMD to
 * BIN ROM formats. Also displays information from the Sega cartridge header.
 *
 * Much thanks to Kuwanger (http://members.tripod.com/~Kuwanger), XnaK, and
 * Later Dude.
 */

 /* for DOS: make sure to do a #define DOS here */

#include <stdio.h> 
#include <string.h> 
#include <stdbool.h> 
#include <stdint.h> 

#define VERSION "0.75" 
#define error(str1, str2)					\
	{							\
		printf(str1, str2);				\
		return 1;					\
	}
#define lower(str, i, j)					\
	{							\
		for (i = 0; str[i] != '\0'; i++)		\
			for (j = 0; j < 6; j++)			\
				if (str[i] == ltab[j])		\
				{				\
					str[i] = ltab[j + 6];	\
					break;			\
				}				\
	}

typedef unsigned char char8_t;

typedef enum INTERLEAVING_MODE
{
    INTERLEAVING_MODE_NONE,
    INTERLEAVING_MODE_EVEN_ODD,
    INTERLEAVING_MODE_ODD_EVEN,
    INTERLEAVING_MODE_UNKNOWN,
} INTERLEAVING_MODE;

typedef struct ROM_INFO
{
    uint32_t data_offset; // 0 or 512 (if SMD header).
    uint32_t data_size; // File size minus any SMD header.
    INTERLEAVING_MODE interleaving_mode;
    char8_t header[512];
} ROM_INFO;

// functions
int convert_smd_bin(char* file_name);
int show_info(char*);
void deinterleave_block(unsigned char* bin_block, const unsigned char* smd_block, INTERLEAVING_MODE interleaving_mode);
int get_rom_info(FILE* fp, char* file_name, /*out*/ ROM_INFO* rom_info);

// letter conversion table
char ltab[] = { 'B', 'I', 'N', 'S', 'M', 'D', 'b', 'i', 'n', 's', 'm', 'd' };
char* mode_strings[4] = {"none", "even/odd", "odd/even", "unknown"};


/*****************************************************************************
 int main(int, char **):
                Stop reading this source code if you don't know what main()
                is. Your head might pop.
 Input:         Obvious.
 Returns:       Obvious.
*****************************************************************************/
int main(int argc, char** argv)
{
    int i, j, f = 0;
    bool should_convert_to_bin = 0;
    bool should_show_info = 0;
    #ifdef DOS 
    int k;
    #endif 

    /* show help */
    if (argc <= 1)
    {
        printf("GROM Version %s by Bart Trzynadlowski, 2000\n",
            VERSION);
        printf("A Free Multi-function Sega Genesis ROM Utility\n");
        printf("\n");
        printf("Usage:    grom [files] [commands] [options]\n");
        #ifdef DOS 
        printf("File:     Genesis ROM file, BIN or SMD format\n");
        #endif 
        #ifndef DOS 
        printf("File:     Genesis ROM file, BIN or SMD format. " \
            "Must have lowercase extension\n");
        #endif 
        printf("Commands: -bin          Deinterleave file(s) to linear .gen format\n");
        printf("          -info         Show information about file(s)\n");
        return 0;
    }
    else if (argc <= 2)     /* user didn't specify an option */
    {
        printf("main: Not enough arguments\n");
        return 0;
    }

    /* find options, don't remove them from argv[] */
    for (i = 1; i < argc; i++)
    {
        if (strcmp(argv[i], "-bin") == 0)
            should_convert_to_bin = 1;
        else if (strcmp(argv[i], "-info") == 0)
            should_show_info = 1;
        else if (argv[i][0] == '-')
            error("Unknown argument %s", argv[i]);
    }

    #ifdef DOS 
    /* go through the command line, convert letters s, m, d, and b, i, n
       to lowercase to prevent problems with strstr() later on */
    for (i = 1; i < argc; i++)
    {
        lower(argv[i], j, k);
    }
    #endif 

    if (!should_show_info && !should_convert_to_bin)
        printf("main: No commands specified\n");

    /* enumerate each file */
    for (j = 1; j < argc; j++)
    {
        if (*argv[j] != '-')
        {
            if (should_show_info)
            {
                show_info(argv[j]);
            }
            if (should_convert_to_bin)
            {
                convert_smd_bin(argv[j]);
            }
            ++f;
        }
    }

    /* no options found */
    if (f == 0)
        printf("main: No filenames specified\n");

    return 0;
}

/*****************************************************************************
 int convert_smd_bin(char *):
                Converts an SMD ROM file (<filename>.smd) to a BIN ROM file
                (<filename>.bin).
 Input:         File path.
 Returns:       Nothing.
*****************************************************************************/
int convert_smd_bin(char* file_name)
{
    int meter = 0;
    FILE* in_fp;
    FILE* out_fp;
    unsigned char output_filename[256];
    unsigned char smd_block[16384];
    unsigned char bin_block[16384];
    ROM_INFO rom_info = {0};

    /* open SMD file, open BIN file, get number of blocks, read header */
    if ((in_fp = fopen(file_name, "rb")) == NULL)
    {
        error("convert_smd_bin: SMD file could not be opened: %s\n", file_name);
    }

    if (get_rom_info(in_fp, file_name, /*out*/ &rom_info))
    {
        return 1;
    }

    if (rom_info.interleaving_mode == INTERLEAVING_MODE_UNKNOWN)
    {
        error("convert_smd_bin: file has an unknown interleaving mode: %s\n", file_name);
    }
    if (rom_info.interleaving_mode == INTERLEAVING_MODE_NONE && rom_info.data_offset == 0)
    {
        error("convert_smd_bin: file is already deinterleaved and has no 512-byte header: %s\n", file_name);
    }

    strcpy_s(output_filename, sizeof(output_filename), file_name);
    strtok(output_filename, ".");
    strcat_s(output_filename, sizeof(output_filename), ".gen");

    if ((out_fp = fopen(output_filename, "wb")) == NULL)
    {
        error("convert_smd_bin: BIN file could not be opened: %s\n", file_name);
    }

    uint32_t num_blocks = rom_info.data_size / 16384;
    fseek(in_fp, rom_info.data_offset, SEEK_SET);

    /* turn off line buffering on stdout so we can see progress meter */
    setvbuf(stdout, NULL, _IONBF, 0);

    printf("convert_smd_bin: Converting (%s) to deinterleaved format (%s)", file_name, output_filename);

    /* convert smd to bin */
    for (uint32_t i = 0; i < num_blocks; ++i)
    {
        fread(smd_block, 1, sizeof(smd_block), in_fp);
        deinterleave_block(/*out*/ bin_block, smd_block, rom_info.interleaving_mode);
        fwrite(bin_block, 1, sizeof(bin_block), out_fp);

        /* increase meter every 1/10th total blocks */
        meter++;
        if (meter % 10 == 0)
        {
            printf(".");
            meter = 0;
        }
    }

    printf(" done\n");

    setvbuf(stdout, NULL, _IOLBF, BUFSIZ);    /* line buffering back on */

    /* close files and exit */
    fclose(in_fp);
    fclose(out_fp);

    return 0;
}

/*****************************************************************************
 int show_info(char *file):
                Shows information about a given file. If it is a binary file
                information will be obtained from the Sega header, otherwise
                we will show whatever information we can obtain.
 Input:         File path.
 Returns:       Nothing.
*****************************************************************************/
int show_info(char* file_name)
{
    FILE* fp;
    char string[49];
    ROM_INFO rom_info = {0};

    /* open file and read the header */
    if ((fp = fopen(file_name, "rb")) == NULL)
    {
        error("show_info: File could not be opened: %s\n", file_name);
    }

    get_rom_info(fp, file_name, /*out*/ &rom_info);

    printf("Showing information from cartridge data...\n");

    /* print info from Sega header */
    printf("                    File: %s\n", file_name);
    string[16] = '\0';
    strncpy_s(string, sizeof(string), &rom_info.header[0x100], 16);
    printf("                  System: %s\n", string);
    strncpy_s(string, sizeof(string), &rom_info.header[0x110], 16);
    printf("               Copyright: %s\n", string);
    string[48] = '\0';
    strncpy_s(string, sizeof(string), &rom_info.header[0x120], 48);
    printf("    Game name (domestic): %s\n", string);
    strncpy_s(string, sizeof(string), &rom_info.header[0x150], 48);
    printf("    Game name (overseas): %s\n", string);
    printf("           Software type: ");
    if (rom_info.header[0x180] == 'G' && rom_info.header[0x181] == 'M')
        printf("game\n");
    else if (rom_info.header[0x180] == 'A' && rom_info.header[0x181] == 'l')
        printf("educational\n");
    else
        printf("%c%c", rom_info.header[0x180], rom_info.header[0x181]);
    /* from personal observation, it seems the product code
        field starts at 0x183, and is 11 bytes long. 0x182 may be
        a continuation of the software type field, but I am most
        likely wrong */
    string[11] = '\0';
    strncpy_s(string, sizeof(string), &rom_info.header[0x183], 11);
    printf("Product code and version: %s\n", string);
    printf("                Checksum: %02X%02X\n", rom_info.header[0x18e], rom_info.header[0x18f]);
    string[16] = '\0';
    strncpy_s(string, sizeof(string), &rom_info.header[0x190], 16);
    printf("             I/O support: %s\n", string);
    /* the meaning of these fields may have been misinterpreted */
    printf(
        "       ROM start address: %02X%02X%02X%02X\n",
        rom_info.header[0x1a0],
        rom_info.header[0x1a1],
        rom_info.header[0x1a2],
        rom_info.header[0x1a3]
    );
    printf(
        "         ROM end address: %02X%02X%02X%02X\n",
        rom_info.header[0x1a4],
        rom_info.header[0x1a5],
        rom_info.header[0x1a6],
        rom_info.header[0x1a7]
    );
    /* is the modem data field really 20 bytes? XnaK's document
        seems to indicate it is only 10... */
    string[20] = '\0';
    strncpy_s(string, sizeof(string), &rom_info.header[0x1bc], 20);
    printf("              Modem data: %s\n", string);
    string[40] = '\0';
    strncpy_s(string, sizeof(string), &rom_info.header[0x1c8], 40);
    printf("                    Memo: %s\n", string);
    string[3] = '\0';
    strncpy_s(string, sizeof(string), &rom_info.header[0x1f0], 3);
    printf("               Countries: %s\n", string);

    printf("       Interleaving mode: %s\n", mode_strings[rom_info.interleaving_mode]);

    fclose(fp);

    return 0;
}

/*****************************************************************************
 void deinterleave_block(unsigned char *, unsigned char *, char type):
                Converts a 16KB SMD block to BIN.
 Input:         Destination buffer address, source buffer address.
 Returns:       Nothing.
*****************************************************************************/
void deinterleave_block(
    /*output 16384 bytes*/ unsigned char* bin_block,
    /*input 16384 bytes */ const unsigned char* smd_block,
    INTERLEAVING_MODE interleaving_mode
    )
{
    if (interleaving_mode == INTERLEAVING_MODE_NONE
    ||  interleaving_mode == INTERLEAVING_MODE_UNKNOWN)
    {
        memcpy(bin_block, smd_block, 16384);
        return;
    }

    int even_block_offset = (interleaving_mode == INTERLEAVING_MODE_EVEN_ODD) ? 0 : 8192;
    int odd_block_offset  = (interleaving_mode == INTERLEAVING_MODE_EVEN_ODD) ? 8192 : 0;

    // Convert 16KB of SMD to BIN.
    for (int i = 0; i < 8192; i++)
    {
        bin_block[i * 2 + 0] = smd_block[i + even_block_offset];
        bin_block[i * 2 + 1] = smd_block[i + odd_block_offset];
    }
}

/*****************************************************************************
 Get ROM info, ignoring filename extension.

 Input:         File pointer, file name, a string describing the format: "bin"
                or "smd".
 Returns:       0 if okay, 1 if not.
 Note:          Assumes file is at SEEK_SET. Will return with file at SEEK_SET
                if check is successful, otherwise the pointer will be at 512.
                Type can be 'b' (bin) or 's' (smd) or 'u' (unknown).
*****************************************************************************/
int get_rom_info(FILE* fp, char* file_name, /*out*/ ROM_INFO* rom_info)
{
    fseek(fp, 0, SEEK_END);
    uint32_t file_length = ftell(fp);
    const uint32_t data_offset = (file_length & 1023);
    rom_info->data_offset = data_offset;
    rom_info->data_size = file_length - data_offset;
    fseek(fp, data_offset, SEEK_SET);

    unsigned char raw_data[16384];
    unsigned char linear_data[16384];
    //_Static_assert(sizeof(raw_data) >= sizeof(rom_info->header));
    //_Static_assert(sizeof(linear_data) >= sizeof(rom_info->header));

    // Read 16384 bytes of file (.bin/.gen/.smd).
    fseek(fp, data_offset, SEEK_SET);
    fread(raw_data, 1, sizeof(raw_data), fp);

    // Check for "SEGA GENESIS" text.
    // Depending on the interleaving, it may be split in the first bank or second bank with even/odd bytes.
    // It might also be shifted one space over " SEGA GENESIS".
    INTERLEAVING_MODE interleaving_mode = INTERLEAVING_MODE_UNKNOWN;
    if (strncmp(raw_data + 256, "SEGA", 4) == 0)
    {
        interleaving_mode = INTERLEAVING_MODE_NONE;
    }
    else if (strncmp(raw_data + (256/2), "EA", 2) == 0 && strncmp(raw_data + 0x2080, "SG", 2) == 0)
    {
        interleaving_mode = INTERLEAVING_MODE_ODD_EVEN;
    }
    else if (strncmp(raw_data + (256/2), "SG", 2) == 0 && strncmp(raw_data + 0x2080, " E", 2) == 0)
    {
        // Leading space shifts " SEGA GENESIS" over.
        interleaving_mode = INTERLEAVING_MODE_ODD_EVEN;
    }
    else if (strncmp(raw_data + (256/2), "SG", 2) == 0 && strncmp(raw_data + 0x2080, "EA", 2) == 0)
    {
        interleaving_mode = INTERLEAVING_MODE_EVEN_ODD;
    }
    else
    {
        interleaving_mode = INTERLEAVING_MODE_UNKNOWN;
    }
    rom_info->interleaving_mode = interleaving_mode;

    if (interleaving_mode == INTERLEAVING_MODE_NONE || interleaving_mode == INTERLEAVING_MODE_UNKNOWN)
    {
        // Just copy the raw data over.
        memcpy(&rom_info->header, raw_data, sizeof(rom_info->header));
    }
    else
    {
        // Deinterleave the data.
        deinterleave_block(/*out*/ linear_data, raw_data, interleaving_mode);
        memcpy(&rom_info->header, linear_data, sizeof(rom_info->header));
    }

    return 0;
}

#if 0
/*****************************************************************************
 int check_format(FILE *, char *, char *):
                Checks the given file to make sure it is of a given ROM type.
 Input:         File pointer, file name, a string describing the format: "bin"
                or "smd".
 Returns:       0 if okay, 1 if not.
 Note:          Assumes file is at SEEK_SET. Will return with file at SEEK_SET
                if check is successful, otherwise the pointer will be at 512.
*****************************************************************************/
int check_format(FILE* fp, char* file_name, char* type)
{
    char actual_type = 'u';

    if (chkheader == 0 && chkext == 0) /* don't perform checks if user doesn't want to */
        return 0;

    bool is_bin = (strstr(file_name, ".bin") != NULL) || (strstr(file_name, ".gen") != NULL);
    bool is_smd = (strstr(file_name, ".smd") != NULL);

    if (strcmp(type, "bin") == 0)           /* BIN */
    {
        if (chkext && !is_bin)       /* check extension */
            error(
                "check_format: File %s may not be deinterleaved format, as it lacks .bin extension. " \
                "Operation cancelled.\n",
                file_name
            );

        if (chkheader)
        {
            get_actual_format(fp, file_name, &actual_type);
            if (actual_type != 'b')
                error(
                    "check_format: File %s may not be deinterleaved format, as it lacks 'SEGA' text in header. " \
                    "Operation cancelled.\n",
                    file_name
                );
        }
    }
    else if (strcmp(type, "smd") == 0)      /* SMD */
    {
        if (chkext && !is_smd)
            error(
                "check_format: File %s may not be in SMD " \
                "format, as it lacks .smd extension. Operation cancelled.\n",
                file_name
            );

        if (chkheader)
        {
            get_actual_format(fp, file_name, &actual_type);
            if (actual_type != 's')
                error(
                    "check_format: File %s may not be deinterleaved format looking in the header. " \
                    "Operation cancelled.\n",
                    file
                );
        }
    }

    return 0;
}
#endif
