Assembly has not been implemented yet. It is just a test to see if the correct number of lines is output. The formula (bytes * 8 / 6) can be used to determine how many text characters it takes to represent the binary data.

==BeginEmbed==
Name: tiletran.com encoded on 06-09-1998
File: tiletran.com
Encoding:shifted,6bit,base64
Data: 514
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
==EndEmbed==

First test with encoding assembly added.

==BeginEmbed==
Name: trace.com encoded on 06-09-1998
File: trace.com
Encoding: shifted,6bit,base64
Data: 147
q@lcXGJI@xrhJFPèf@`KcrXÀz_lAd@PKAphCf@pñFP@@iE@cNX@@{k{äAt|IPqOy
`qcJteAO]TgJF\UÔxB@hNB\ÌgK@}aKbHNjiKA@F\UTxB@nNB\LgKôG`KlpLj
Y}uAXyrnhX@^@uÕxB@nNb]Ì{RhHFPbExrF`XÀ_auGOC@À@@@@xB@@@@pC@À
O@
==EndEmbed==

Everything looks okay below. :-)

==BeginEmbed==
Name: trace.com encoded on 06-09-1998
File: trace.com
Encoding: shifted,6bit,base64
Data: 147
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@
==EndEmbed==

Wait a minute...what's this?

==BeginEmbed==
Name: trace.com encoded on 06-09-1998
File: trace.com
Encoding: shifted,6bit,base64
Data: 147
ÿÿÿÿÿÿÿÿ
ÿÿÿÿÿÿÿÿ
ÿÿÿÿÿÿÿÿ

==EndEmbed==

Something is wrong here! It is printing extended characters when the valid range is only supposed to be 64-127.

==BeginEmbed==
Name: trace.com encoded on 06-09-1998
File: trace.com
Encoding: shifted,6bit,base64
Data: 147
q@lcXGJI@xrhJFPèf@`KcrXÀz_lAd@PKAphCf@pñFP@@iE@cNX@@{k{äAt|IPqOy
`qcJteAO]TgJF\UÔxB@hNB\ÌgK@}aKbHNjiKA@F\UTxB@nNB\LgKôG`KlpLj
Y}uAXyrnhX@^@uÕxB@nNb]Ì{RhHFPbExrF`XÀ_auGOC@À@@@@xB@@@@pC@À
O@
==EndEmbed==

The old routine did not produce the right output as can be seen below. Every eighth byte it not and out the remaining upper bits which would leave them on. That makes them extended characters, and many mail programs do not like extended characters for some reason. For example, Juno states that a file contains binary data if you try insert one with even a single extended character into your message.

==BeginEmbed==
Name: trace.com encoded on 06-09-1998
File: trace.com
Encoding: shifted,6bit,base64
Data: 147
ÿÿÿÿÿÿÿÿ
ÿÿÿÿÿÿÿÿ
ÿÿÿÿÿÿÿÿ

==EndEmbed==

Here the problem has been fixed and you can see a steady stream of chars.
!! :-) !!

==BeginEmbed==
Name: trace.com encoded on 06-09-1998
File: trace.com
Encoding: shifted,6bit,base64
Data: 147




==EndEmbed==
==BeginEmbed==
Name: trace.com encoded on 06-09-1998
File: trace.com
Encoding: shifted,6bit,base64
Data: 147
q@lcXGJI@xrhJFPhf@`KcrX@z_lAd@PKAphCf@pqFP@@iE@cNX@@{k{dAt|IPqOy
`qcJteAO]TgJF\UTxB@hNB\LgK@}aKbHNjiKA@F\UTxB@nNB\LgKtG`KlpLj
Y}uAXyrnhX@^@uUxB@nNb]L{RhHFPbExrF`X@_auGOC@@@@@@xB@@@@pC@@
O@
==EndEmbed==
==BeginEmbed==
Name: trace.com encoded on 06-10-1998,00:17:53
File: trace.com
Encoding: shifted,6bit,base64
Data: 147
q@lcXGJI@xrhJFPhf@`KcrX@z_lAd@PKAphCf@pqFP@@iE@cNX@@{k{dAt|IPqOy
`qcJteAO]TgJF\UTxB@hNB\LgK@}aKbHNjiKA@F\UTxB@nNB\LgKtG`KlpLj
Y}uAXyrnhX@^@uUxB@nNb]L{RhHFPbExrF`X@_auGOC@@@@@@xB@@@@pC@@
O@
==EndEmbed==

Add stripping of filename from path

==BeginEmbed==
Name: c:\dw\bas\trace.com encoded on 06-10-1998,00:20:03
File: Trace.COM
Encoding: shifted,6bit,base64
Data: 147
q@lcXGJI@xrhJFPhf@`KcrX@z_lAd@PKAphCf@pqFP@@iE@cNX@@{k{dAt|IPqOy
`qcJteAO]TgJF\UTxB@hNB\LgK@}aKbHNjiKA@F\UTxB@nNB\LgKtG`KlpLj
Y}uAXyrnhX@^@uUxB@nNb]L{RhHFPbExrF`X@_auGOC@@@@@@xB@@@@pC@@
O@
==EndEmbed==

Change the Embed beginning and ending to "==Embed???==" for easier and signifigantly faster searching. Encoding in 7bits also works now.

==EmbedBegin==
Name: tiletran.com, 06-10-1998
File: tiletran.com
Encoding: shifted,7bit,base128
Data: 514
ŒÔÊØ¼±»Šˆûó€—€Ğ¯ô¤¢âåÑÇ»Ùø“¸€‹İÑ¨‹¢äæ‚‡‡±°³±€›‹£ÚË·‚–€À¢–
ĞÛÏ»à¬ å€€€ˆ€ºû¹‡Ì…ÔŒ€À€€ ·Ÿ÷ÀÙÀÊ„€€€ôöó˜‹¨¹€€€€Àî¾Î³€€€€ôö
óŒ˜ë€€À€€ ·ŸçÀÙ†€‚€€€ºû¹†Ìµˆ€€€€æ¢£¶–Ú²ÿÉëå´–¸ºˆæ¦ƒ¶â¬â‚æ¦‹¶â¬âª
„‚¼÷ßùÃÂğş÷ºğÃ²†€¼˜¨•±ùâö”öçá¢·’‚¶Ç€ ¬„æÊš«šĞ±„€‚¼÷Ÿ¹ùİüĞ¬€€
òÈ‡ €‰„…À¼€òˆŒ€€À€€‚€ˆ€ €€€„€€À€€‚€ˆ€ €€€„€€À€€€€ˆ€àƒ€
òÿ‡€àÀùÿƒ€è€€ıÿ€°€Ğşÿ€€–€°ÿ¿€€Š€ÜÿŸ€À„€ğÿ€€‚€€€„€ğÀ€€âÿ€àƒ€
€ÄÿŸ€À‡€‚€ˆÿ¿€€€„€şÿ€€€ˆ€ üÿ€¼€€Àøÿƒ€ø€ €€ñÿ‡€ğÀ€€€€ˆ€àƒ€
€¼€€À‡€‚€ˆı¿€€€„€ğÀ€€€ˆ€ ôÿ€¼€€À‡€‚€ø€ €€Ñÿ‡€ğÀ€€€ˆ€àƒ€
€ÄşŸ€À‡€‚€ø€ €€€„€úÿ€€€ˆ€àƒ€€¼€€Àèÿƒ€ø€ €€€„€ğÀ€€¢ÿ€àƒ€
€¼€€À‡€‚€€
==EmbedEnd==
