//
//  Parser.m
//  ICC Test App
//
//  parses text strings of commands sent by ICC and received via timestamp process
//


#import "Parser.h"
#import "AppController.h"

#define TIMESTAMP @"timestamp"

@implementation Parser

- (id)init
{
	[super init];
	
	actionTable = (SEL*) malloc(sizeof(SEL) * 256);
	for (int i=0; i<256; ++i) 
		actionTable[i] = nil;
	
	stringList = [[StringList alloc] init];
	
	nbuf = 0;  // number of chars in the buffer, for building it up
	place = 0; // place we're up to in the buffer for gobbling it up
	
	just_got_escape = FALSE;
    
	parse_state = 0; 
	
	unmatchedCount = 0;
	
	return self;
}

- (void)dealloc {
	free(actionTable);
	[stringList release];
	[super dealloc];
}

-(void)setAction:(SEL)selector forDatagram:(DATAGRAM)dg 
{
	if ( dg < 256 ) actionTable[dg] = selector;
}

#pragma mark network_stuff

-(void) setParserDelegate:(id)delegateObject
{
	parserDelegate = delegateObject;
}

- (void)startConnectionWithUsername:(NSString *)u password:(NSString *)p server:(NSString *)s
{
	nbuf = 0;  // number of chars in the buffer, for building it up
	place = 0; // place we're up to in the buffer for gobbling it up
	
	just_got_escape = FALSE;
    
	parse_state = 0; 
	
	unmatchedCount = 0;
	

	
	
	[stringList reset];
	
	char *userString = (char *)malloc([u length]+1);
	char *passString = (char *)malloc([p length]+1);
	
	userString = (char *)[u cStringUsingEncoding:NSUTF8StringEncoding];
	passString = (char *)[p cStringUsingEncoding:NSUTF8StringEncoding];
	
	sprintf(login_string, "%s %s\n\n", userString, passString);
	
	
	NSBundle *bundle = [NSBundle mainBundle];
	NSString *timestampPath = [bundle pathForResource:TIMESTAMP ofType:nil];
	task = [[NSTask alloc] init];
	[task setLaunchPath:timestampPath];
	
	NSArray *args = [NSArray arrayWithObjects:[s copy], @"5000", nil];
	
	[task setArguments:args];
	

	outPipe = [[NSPipe alloc] init];
	inPipe = [[NSPipe alloc] init];
	
	[task setStandardOutput:outPipe];
	[task setStandardInput:inPipe];
	
	NSFileHandle *fh = [outPipe fileHandleForReading];
	NSNotificationCenter *nc;
	nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self];

	[nc addObserver:self selector:@selector(dataReady:) name:NSFileHandleDataAvailableNotification object:fh];
	
	[nc addObserver:self selector:@selector(taskTerminated:) name:NSTaskDidTerminateNotification object:task];
	
	[task launch];
	
	[self init_parser];
	
	[fh waitForDataInBackgroundAndNotify];
	
	
}

- (void)dataReady:(NSNotification *)n
{	
	NSData *d;
	NSFileHandle *fh = [outPipe fileHandleForReading];
	d = [fh availableData];
	
		
	if ([d length]) {
		NSString *s = [[NSString alloc] initWithData:d encoding:NSASCIIStringEncoding];
		[self parse:s];
	}
	
	if (task)
		[[outPipe fileHandleForReading] waitForDataInBackgroundAndNotify];
}

-(void)disconnect {
	[task terminate];
}

- (void)taskTerminated:(NSNotification *)note
{
	NSLog (@"taskTerminated");
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleDataAvailableNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSTaskDidTerminateNotification object:task];


	


	[task release];
	[inPipe release];
	[outPipe release];
	task = nil;	
	inPipe = nil;
	outPipe = nil;
	[parserDelegate disconnected];
}

- (void)sendCommand:(NSData *)d
{
	if (inPipe) {
		NSFileHandle *fh2 = [inPipe fileHandleForWriting];
		if (fh2 != nil) {
			[fh2 writeData:d];
			//[parserDelegate appendData:d attributes:nil];

		}
	}
}


#pragma mark -
#pragma mark parser_stuff


// this section of code is adapted from C code provided by ICC
// which I've translated into Objective-C

- (void)fatal_error:(char *)s 
{

	fprintf(stderr, "%s\n", s);
    exit(1);
}

- (void)put_out:(char *)str 
{
	int n;
	n = strlen(str);
	NSString *writeString = [[NSString alloc] initWithCString:str encoding:NSUTF8StringEncoding];
	NSData *data = [writeString dataUsingEncoding:NSUTF8StringEncoding];		
	
	[self sendCommand:data];
}

- (void)init_parser 
{
    if (strlen(LOGIN_PROMPT) != LOGIN_LEN) {
		NSLog(@"LOGIN_LEN and LOGIN_PROMPT are inconsistent");
		[self fatal_error:"LOGIN_LEN and LOGIN_PROMPT are inconsistent"];
    }
}

- (int)my_getchar 
{
    /* returns the next char in the buffer */
    if (place >= nbuf) {
		NSLog(@"Tried to parse off the end of the datagram");

		[self fatal_error:"Tried to parse off the end of the datagram"];
    }
	place++;
    
	return buf[place-1];
}

/* The following function gets the next character from the input stream.
 It puts it in the global variable "token".  It regards the MARK
 followed by one of the 6 acceptable options as a single character.
 In this case it sets special to TRUE, and char after the mark is put
 in "token".  If the character after the MARK is not one of the
 special ones, it just acts like the MARK was not there. */

- (void)get_token 
{
    token = [self my_getchar];
    
	if (token == EOF) {
		fprintf(stderr, "Input terminated unexpectedly.\n");
		exit(1);
    }
	
    if (token != ESCAPE) {
		special = FALSE;
		return;
    }
    
	token = [self my_getchar];
    special = (token == OPEN1 || token == CLOSE1 ||
			   token == OPEN2 || token == CLOSE2 ||
			   token == OPENQ || token == CLOSEQ);
}

/* This function expects to find the remainder of a quoted string.  By
 the time it gets here, we've already read a begin quote mark.  It
 puts the result into the return_word variable.  It returns with us
 sitting on the quote mark.  "spec" tells us if we're requiring a
 special mark at the end, or just a CLOSEQ. */

- (void)get_quoted_string:(int)spec
{
    int i;
    for (i=0; i<MAX_WORD; i++) {
		[self get_token];
		if (special == spec && token == CLOSEQ) break;
		return_word[i] = token;
    }
    return_word[i] = '\0';
    [self get_token];  /* skip the close quote */
}

/* This function gets one datagram type string.  The first character of
 this string has already been read.  It skips preceeding blanks, and a
 blank (or CLOSE2 or any special mark) indicates the end of the
 string.  It returns the result in return_word[].  If there is no word
 before the CLOSE2, it returns FALSE (leaving us sitting on the
 CLOSE2), otherwise returns TRUE.  It leaves us sitting on the
 character AFTER the last character read. */

- (int)get_word
{
    int i;
    while ((!special) && isspace(token)) 
		[self get_token];
	
    if (special && token == CLOSE2) {
		return_word[0] = '\0';
		return FALSE;
    }
    if (token == OPENQ) {
		[self get_quoted_string:special];
		return TRUE;
    }
    return_word[0] = token;
    for (i=1; i<MAX_WORD; i++) {
		[self get_token];
		if (special || isspace(token)) break;
		return_word[i] = token;
    }
    return_word[i] = '\0';    
    return TRUE;
}

/* This function is called to read a level2 datagram.  We've
 already read an OPEN2 token to get here.  This reads the rest of the
 datagram.  It puts the result of it into a linked list of strings and
 returns a pointer to it.  This list should eventually be freed with
 free_strings().  This function leaves us sitting on the final
 CLOSE2.*/
- (void)datagram
{	
	place = 0;
	
	[self get_token];
	
	while([self get_word]) {
		[stringList addToList:[NSString stringWithCString:return_word encoding:NSUTF8StringEncoding]];
	}

}

/* initialize session and login */
- (void)send_login_strings
{
    char level2[MAX_DG+1];
    int i;
    for (i=0; i<MAX_DG; i++) level2[i] = '0';
    level2[MAX_DG] = '\0';
    level2[DG_WHO_AM_I] = '1';
	level2[DG_MY_GAME_STARTED] = '1';
	level2[DG_ISOLATED_BOARD] = '1';
	level2[DG_STARTED_OBSERVING] = '1';
	level2[DG_MY_RELATION_TO_GAME] = '1';
	level2[DG_POSITION_BEGIN] = '1';
	level2[DG_MOVE_ALGEBRAIC] = '1';
	level2[DG_MOVE_SMITH] = '1';
	level2[DG_MOVE_TIME] = '1';
	level2[DG_MOVE_CLOCK] = '1';
	level2[DG_SEND_MOVES] = '1';
	level2[DG_GAME_RESULT] = '1';
	level2[DG_MY_GAME_RESULT] = '1';
	level2[DG_KIBITZ] = '1';
	level2[DG_PERSONAL_TELL] = '1';
	level2[DG_FLIP] = '1';
	level2[DG_ILLEGAL_MOVE] = '1';
	level2[DG_SET_CLOCK] = '1';
	level2[DG_TAKEBACK] = '1';
	level2[DG_BACKWARD] = '1';
	level2[DG_CIRCLE] = '1';
	level2[DG_UNCIRCLE] = '1';
	level2[DG_ARROW] = '1';
	level2[DG_UNARROW] = '1';
	level2[DG_GAME_MESSAGE] = '1';
	level2[DG_GAMELIST_BEGIN] = '1';
	level2[DG_GAMELIST_ITEM] = '1';
	level2[DG_LOGIN_FAILED] = '1';
	level2[DG_LOG_PGN] = '1';
	level2[DG_PEOPLE_IN_MY_CHANNEL] = '1';
	level2[DG_CHANNELS_SHARED] = '1';
	level2[DG_CHANNEL_TELL] = '1';
	level2[DG_SHOUT] = '1';
	level2[DG_MY_GAME_CHANGE] = '1';
	
    for (i=MAX_DG; (i>=0) && (level2[i] != '1'); i--) level2[i] = '\0';
    sprintf(stemp, "level2settings=%s\n", level2);
    [self put_out:stemp];
    

	[self put_out:login_string];
	
	
}

void safe_strcpy(char *u, char * v, int usize) {
	// Copies as much of v into u as it can assuming u is of size usize
	// guaranteed to terminate u with a '\0'.
    strncpy(u, v, usize-1);
    u[usize-1] = '\0';
}

- (void)process_finished_datagram
{
	NSArray *datagramArray = [stringList getDatagramArray];

	
	[self datagram];
	

	
	
   /* string_list_t *sl, *slx, *sl_free_later;*/
    int dg = [[datagramArray objectAtIndex:0] intValue];
		
	
	if (dg != 46 && dg != 27) {
		NSLog(@"[");
		for (NSString *dgStr in datagramArray)
			NSLog(@"%@ ", dgStr);
		NSLog(@"]\n");
	}
	
	if (dg > -1) {
		[parserDelegate performSelector:actionTable[dg] withObject:datagramArray];
	}
	
}

- (void)process_1_char_from_ICC:(int)c
{
	// 0 means looking for "login: "
	// 1 means looking for start of datagram
	// 2 means looking for end of datagram
    
    int i;
	

	
    // the following line prints the contents of everything not in level 2
    // echo non-level2
    if ((parse_state != 2) && (!just_got_escape) && (c != ESCAPE)) {
		printf("%c", c);
		
		unmatchedBuffer[unmatchedCount] = c;
		unmatchedCount++;
		
		
		
		if (c == '\n' || unmatchedCount == MAX_WORD-1) {
			unmatchedBuffer[unmatchedCount] = '\0';
			[parserDelegate performSelector:actionTable[DG_UNMATCHED_INPUT] withObject:[NSString stringWithFormat:@"%s",unmatchedBuffer]];
			unmatchedCount = 0;
		}
	}
	
    if (parse_state == 0) 
	{
		for (i=1; i<LOGIN_LEN; i++) 
			last_few[i-1] = last_few[i];
		
		last_few[i-1] = c;
		
		if (strncmp(LOGIN_PROMPT, last_few, LOGIN_LEN) == 0) 
		{
			[self send_login_strings];
			parse_state = 1;
		}
    } 
	else if (parse_state == 1) 
	{
		if (just_got_escape && c == OPEN2) 
		{
			parse_state = 2;
			nbuf = 0;
		}
		
		just_got_escape = (c == ESCAPE);
    } 
	else // parse state is 2
	{
		if (nbuf == MAX_DATAGRAM_SIZE) 
			[self fatal_error:"Datagram exceeded the maximum allowed size"];
		
		buf[nbuf] = c;
		nbuf++;
		
		if (just_got_escape && c == CLOSE2) 
		{
			[self process_finished_datagram];  /* the datagram, ending with the CLOSE2 mark */
			parse_state = 1;
		}
		
		just_got_escape = (c == ESCAPE);	
    }
}

- (void)parse:(NSString*)text  
{
	const char* buffer = [text cStringUsingEncoding:NSUTF8StringEncoding];
	if (buffer != nil) {
		for (int i = 0; buffer[i] != 0; ++i)
			[self process_1_char_from_ICC:buffer[i]];
	}
}

@end
