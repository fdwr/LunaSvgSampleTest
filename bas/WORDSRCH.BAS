ON ERROR GOTO FileErrorHandler

LINE INPUT "Text file to search in:", File$
IF LEN(File$) = 0 THEN END

ErrorNum = 0
OPEN File$ FOR INPUT AS 1: CLOSE 1
IF ErrorNum THEN
  PRINT "Error opening file"
  END
END IF

OPEN File$ FOR BINARY AS 1
StrLen = LOF(1)
IF StrLen > 1000 THEN StrLen = 1000
SearchText$ = INPUT$(StrLen, 1)
CLOSE 1

GetWord:
LINE INPUT "Text to search for:", MatchText$
IF LEN(MatchText$) = 0 THEN END

SearchTextBase = 1
DO
  GOSUB SearchFor
  IF INKEY$ = CHR$(27) THEN EXIT DO
  IF FoundPos THEN
    PRINT "Match found at"; FoundPos; ":";
    Text$ = MID$(SearchText$, FoundPos, 40)
    GOSUB PrintAllChars
    PRINT
    FoundPos = 0
  END IF
LOOP UNTIL SearchDone
SearchDone = 0

PRINT
GOTO GetWord

SearchFor:
  MatchTextPos = 1
  SearchTextPos = SearchTextBase
  DO
    MatchChar$ = UCASE$(MID$(MatchText$, MatchTextPos, 1))
    SearchChar$ = UCASE$(MID$(SearchText$, SearchTextPos, 1))
    IF SearchChar$ < "A" OR SearchChar$ > "Z" THEN
      SearchTextPos = SearchTextPos + 1
      IF SearchTextPos > LEN(SearchText$) THEN SearchDone = 1: EXIT DO
    ELSEIF MatchChar$ = SearchChar$ THEN
      MatchTextPos = MatchTextPos + 1
      SearchTextPos = SearchTextPos + 1
      IF MatchTextPos > LEN(MatchText$) THEN FoundPos = SearchTextBase: SearchTextBase = SearchTextBase + 1: RETURN
    ELSE
      MatchTextPos = 1
      SearchTextBase = SearchTextBase + 1
      SearchTextPos = SearchTextBase
      IF SearchTextBase >= LEN(SearchText$) THEN SearchDone = 1: EXIT DO
    END IF
  LOOP
  FoundPos = 0
RETURN

PrintAllChars:
  FOR CurChar = 1 TO LEN(Text$)
    Char$ = MID$(Text$, CurChar, 1)
    IF ASC(Char$) > 31 THEN PRINT Char$;  ELSE PRINT "ù";
  NEXT CurChar
RETURN

FileErrorHandler:
  ErrorNum = ERR
RESUME NEXT

