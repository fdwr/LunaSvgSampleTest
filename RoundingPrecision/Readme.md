## BiNums - binary number viewer that displays numbers in various formats  
2019-02-14..2021-02-24  
Dwayne Robinson  
https://github.com/fdwr/BiNums  

![](BiNums.png)

## Usage examples

    binums 12.75                                   // floating point value in various formats
    binums 0b1101                                  // read binary integer
    binums float32 raw 0x40490FDB                  // read raw floating point bits
    binums float16 raw 0x5140                      // read raw floating point bits
    binums fields hex 7 12.75 -13 bin 7 12.75 -13  // see fields of numbers
    binums int8 fields 13 -13                      // see fields of numbers
    binums uint32 add 1.5 3.25                     // perform operation
    binums float32 add float16 2 3                 // read float16, compute in float32
    binums uint32 mul 3 2 add 3 2 subtract 3 2 dot 1 2 3 4
    binums 0x1.5p5                                 // floating point hexadecimal
    binums fixed12_12 sub 3.5 2                    // fixed point arithmetic

## Options

    showbinary showhex - display raw bits as binary or hex (default)
    showhexfloat showdecfloat - display float as hex or decimal (default)
    raw num - treat input as raw bit data or as number (default)
    add subtract multiply divide dot - apply operation to following numbers
    float16 bfloat16 float32 float64 - set floating point data type
    uint8 uint16 uint32 uint64 int8 int16 int32 int64 - set integer data type
    fixed12_12 fixed16_16 fixed8_24 - set fixed precision data type

## Sample output

### Display integer:

    BiNums.exe 123
    Representations:
              type int32
           decimal 123
          floathex 123
               hex 0x0000007B
               oct 0o00000000173
               bin 0b00000000000000000000000001111011
        fields bin int:0b0000000000000000000000001111011 sign:0b0

    To binary:
             uint8 0x7B
            uint16 0x007B
            uint32 0x0000007B
            uint64 0x000000000000007B
              int8 0x7B
             int16 0x007B
     ->      int32 0x0000007B
             int64 0x000000000000007B
           float16 0x57B0
          bfloat16 0x42F6
           float32 0x42F60000
           float64 0x405EC00000000000
        fixed12_12 0x07B000
        fixed16_16 0x007B0000
         fixed8_24 0x7B000000

    From binary:
             uint8 123
            uint16 123
            uint32 123
            uint64 123
              int8 123
             int16 123
     ->      int32 123
             int64 123
           float16 7.331371307373046875e-06
          bfloat16 1.12957660274329190218871e-38
           float32 1.72359711111952499723619e-43
           float64 6.0770074438473324933718e-322
        fixed12_12 0.030029296875
        fixed16_16 0.0018768310546875
         fixed8_24 7.331371307373046875e-06

### Display floating point value:

    BiNums.exe 12.75
    Representations:
              type float64
           decimal 12.75
          floathex 0x1.9800000000000p+3
               hex 0x4029800000000000
               oct 0o0400514000000000000000
               bin 0b0100000000101001100000000000000000000000000000000000000000000000
        fields bin frac:0b1001100000000000000000000000000000000000000000000000 exp:0b10000000010 sign:0b0

    To binary:
             uint8 0x0C
            uint16 0x000C
            uint32 0x0000000C
            uint64 0x000000000000000C
              int8 0x0C
             int16 0x000C
             int32 0x0000000C
             int64 0x000000000000000C
           float16 0x4A60
          bfloat16 0x414C
           float32 0x414C0000
     ->    float64 0x4029800000000000
        fixed12_12 0x00CC00
        fixed16_16 0x000CC000
         fixed8_24 0x0CC00000

    From binary:
             uint8 0
            uint16 0
            uint32 0
            uint64 4623367229960880128
              int8 0
             int16 0
             int32 0
             int64 4623367229960880128
           float16 0
          bfloat16 0
           float32 0
     ->    float64 12.75
        fixed12_12 0
        fixed16_16 0
         fixed8_24 0

### Display multiple values in a specific format:

    BiNums.exe float64 1 3.14159 1234
          float64 1 (0x3FF0000000000000)
          float64 3.14159 (0x400921F9F01B866E)
          float64 1234 (0x4093480000000000)

### Show as binary rather than hex:

    BiNums.exe float64 bin 1 3.14159 1234
          float64 1 (0b0011111111110000000000000000000000000000000000000000000000000000)
          float64 3.14159 (0b0100000000001001001000011111100111110000000110111000011001101110)
          float64 1234 (0b0100000010010011010010000000000000000000000000000000000000000000)

### Add values:

    BiNums.exe float64 add 1 3.14159 1234
    Operands:
          float64 1 (0x3FF0000000000000)
          float64 3.14159 (0x400921F9F01B866E)
          float64 1234 (0x4093480000000000)
    Result of add:
          float64 1238.14 (0x40935890FCF80DC3)
