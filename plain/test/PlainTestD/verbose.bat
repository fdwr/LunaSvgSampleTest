::Include the Pgfx object files.
::Exclude the definitions, otherwise the linker complains about multiply defined symbols.
::Set version to Unicode (maybe should use MSLU)
dbuild plaintest.d @build.brf -debug -debug=verbose %1 %2 %3 %4 %5 %6 %7 %8 %9