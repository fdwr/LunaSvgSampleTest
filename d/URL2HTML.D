/*
URL2HTML
Dwayne Robinson
2005-08-15

Reads a list of links (IE favs) and outputs the HTML
links to all of their targets.
*/

module URL2HTML;

private import std.c.windows.windows;
private import std.file;
private import std.path;
private import std.string;
private import std.date;
//import std.instrinsic;


const static char[] HelpInfo =
`URL2HTML / 20050819 / Dwayne Robinson
This program will read the given directory for URL files and produce a
simple HTML list of the contained addresses. Does not recurse folders
to create heirarchical lists (yet).

Display current folder's listing to screen:
	url2html .
Use redirection to capture the display output to a file:
	url2html d:\fav\links > Links.html

-s	Summary information
-t	Set page title

`;

const static char[] HtmlHeader =
`<html>
<head>
<title>%.*s</title>
<style>
body {
  font: 1em sans-serif;
  color: black;
  background-color: white;
}
a {
  font-weight: bold;
}
</style>
</head>

<body>
<h1>%.*s</h1><p/>
`;

const static char[] HtmlItem =
`<a href="%.*s">%.*s</a><br/>
`;

const static char[] HtmlSummary =
`<br/>
Date: %.*s<br/>
Totals files: %d<br/>
`;

const static char[] HtmlFooter =
`</body>
</html>
`;

int main(char[][] args)
{
 	char[][] files;
	char[] path = "";
	char[] title = "Links";
	bool quit = false;
	bool verbose = false;
	bool summary = false;

	for (int ai = 1; ai < args.length && !quit; ai++) {
		switch(args[ai]) {
		case "-o":
			// fill in later
			quit = true;
			break;
		case "-r":
			printf("Recursion not supported yet\n");
			quit = true;
			break;
		case "-v":
			printf("Verbose output not supported yet\n");
			verbose = true;
			quit = true;
			break;
		case "-t":
			ai++;
			if (ai >= args.length) {
				printf("No title given after the option\n");
				quit = true;
			} else {
				title = args[ai];
			}
			break;
		case "-s":
			summary = true;
			break;
		default:
			if (args[ai][0] == '-' || args[ai][0] == '/') {
				printf("Option %.*s not recognized.\n", args[ai]);
				quit = true;
			} else {
				path = args[ai];
			}
		}
	}
	if (quit)
		return -1;
	if (path.length == 0) {
		printf(HelpInfo);
		return 0;
	}

	if (path.length > 0 && path[length-1..length] != std.path.sep)
		path ~= std.path.sep;
 	files = listdir(path);
	int filesCounted = 0;

    printf(HtmlHeader, title, title);
 	for (int fi = 0; fi < files.length; fi++) {
 	    // split filename (excluding extension) into words
 	    char[] fileName = files[fi];

 	    int fileNameLength = rfind(fileName, '.');
 	    // skip if not PNG file
 	    if (fileNameLength <= 0
 	    ||  tolower(fileName[fileNameLength+1..length]) != "url") continue;

		// read file into memory and extract URL
		char[] fileBytes;
		try {
			fileBytes = cast(char[])read(path ~ fileName);
		} catch (FileException) {
			fileNameLength = fileName.length;
			if (fileNameLength > 60) fileNameLength = 60;
			printf("Could not read file %.*s\n", fileName[0..fileNameLength]);
			continue; // skip this one and move on
		}
		// force all line feeds to carriage returns
		for (int ci = 0; ci < fileBytes.length; ci++) {
			if (fileBytes[ci] == '\n')
				fileBytes[ci] == '\r';
		}
		// find start and end of url
		int urlPosStart = find(fileBytes, "\nURL=");
		if (urlPosStart < 0) continue;
		urlPosStart += 5;
		int urlPosEnd = find(fileBytes[urlPosStart..length], '\r') + urlPosStart;
		if (urlPosEnd < 0) urlPosEnd = fileBytes.length;
		char[] url = fileBytes[urlPosStart..urlPosEnd];

		// get tag text from filename (between the <a> and </a>
 	    // replace any hyphen or underscore separators with spaces
		// and any invalid characters with valid ones
		char[] tagText = strip(tr(fileName[0..fileNameLength], "-_<>", "  []"));

 		printf(HtmlItem,      url, tagText);

		// wonder if explicit nullification would do any good?
 		//tagText.length = 0;
 		//fileName.length = 0;
		filesCounted++;
 	}
	if (summary) {
		printf(HtmlSummary, std.date.toString(getUTCtime()), filesCounted);
	}
    printf(HtmlFooter);

	return 0;
}
