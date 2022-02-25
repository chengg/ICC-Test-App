//
//  AppController.m
//  ICC Test App
//
//

// AppController takes the datagrams received from ICC server via timestamp and performs some action depending on the datagram

#import "AppController.h"
#import "MainWindowController.h"

NSString * const GCUsernameKey = @"Username";
NSString * const GCPasswordKey = @"Password";
NSString * const GCRememberLoginKey = @"RememberLogin";
NSString * const GCAutomaticLoginKey = @"AutomaticLogin";

@implementation AppController

+ (void)initialize
{
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	[defaultValues setObject:@"" forKey:GCUsernameKey];
	[defaultValues setObject:@"" forKey:GCPasswordKey];
	[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:GCRememberLoginKey];
	[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:GCAutomaticLoginKey];

	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}

- (id)init
{
	[super init];
	
	connected = NO;
	
	boardDict = [[NSMutableDictionary alloc] initWithCapacity:5];
	gameListArray = [[NSMutableArray alloc] init];
	
	attributes = [[NSMutableDictionary alloc] init];
	[attributes setObject:[NSFont fontWithName:@"Lucida Grande Bold"  size:12.0] forKey:NSFontAttributeName];
	[attributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
	
	regularAttributes = [[NSMutableDictionary alloc] init];
	[regularAttributes setObject:[NSFont fontWithName:@"Lucida Grande"  size:12.0] forKey:NSFontAttributeName];
	[regularAttributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
	
	tellAttributes = [[NSMutableDictionary alloc] init];
	[tellAttributes setObject:[NSFont fontWithName:@"Bitstream Vera Sans Mono"  size:12.0] forKey:NSFontAttributeName];
	[tellAttributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
	[tellAttributes setObject:[NSColor selectedTextBackgroundColor]  forKey:NSBackgroundColorAttributeName];
	
	tellBoardAttributes = [[NSMutableDictionary alloc] init];
	[tellBoardAttributes setObject:[NSFont fontWithName:@"Lucida Grande"  size:12.0] forKey:NSFontAttributeName];
	[tellBoardAttributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
	[tellBoardAttributes setObject:[NSColor selectedTextBackgroundColor]  forKey:NSBackgroundColorAttributeName];
	
	commandAttributes = [[NSMutableDictionary alloc] init];
	[commandAttributes setObject:[NSFont fontWithName:@"Bitstream Vera Sans Mono"  size:12.0] forKey:NSFontAttributeName];
	[commandAttributes setObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
	
	
	/*
	nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self
		   selector:@selector(windowWillClose:)
			   name:NSWindowWillCloseNotification
			 object:nil];  // pass window to observe only that window
	*/
	
	appBundle = [NSBundle mainBundle];
	NSString *path = [appBundle pathForSoundResource:@"Welcome message.wav"];
	welcomeSound = [[NSSound alloc] initWithContentsOfFile:path byReference:YES];
	path = [appBundle pathForSoundResource:@"Move.wav"];
	moveSound = [[NSSound alloc] initWithContentsOfFile:path byReference:YES];
	path = [appBundle pathForSoundResource:@"Gamestart.wav"];
	gameStartedSound = [[NSSound alloc] initWithContentsOfFile:path byReference:YES];
	path = [appBundle pathForSoundResource:@"tell.wav"];
	tellSound = [[NSSound alloc] initWithContentsOfFile:path byReference:YES];
	
	parser = [[Parser alloc] init];
	[parser setParserDelegate:self];
	[parser setAction:@selector(unmatchedData:) forDatagram:DG_UNMATCHED_INPUT];
	[parser setAction:@selector(whoami:) forDatagram:DG_WHO_AM_I];
	[parser setAction:@selector(myGameStarted:) forDatagram:DG_STARTED_OBSERVING];
	[parser setAction:@selector(myGameStarted:) forDatagram:DG_MY_GAME_STARTED];
	[parser setAction:@selector(myGameStarted:) forDatagram:DG_ISOLATED_BOARD];
	[parser setAction:@selector(myGameStarted:) forDatagram:DG_MY_GAME_CHANGE];
	[parser setAction:@selector(positionBegin:) forDatagram:DG_POSITION_BEGIN];
	[parser setAction:@selector(sendMoves:) forDatagram:DG_SEND_MOVES];
	[parser setAction:@selector(gameResult:) forDatagram:DG_GAME_RESULT];
	[parser setAction:@selector(gameResult:) forDatagram:DG_MY_GAME_RESULT];
	[parser setAction:@selector(flip:) forDatagram:DG_FLIP];
	[parser setAction:@selector(illegalMove:) forDatagram:DG_ILLEGAL_MOVE];
	[parser setAction:@selector(kibitz:) forDatagram:DG_KIBITZ];
	[parser setAction:@selector(personalTell:) forDatagram:DG_PERSONAL_TELL];
	[parser setAction:@selector(setClock:) forDatagram:DG_SET_CLOCK];
	[parser setAction:@selector(myRelationToGame:) forDatagram:DG_MY_RELATION_TO_GAME];
	[parser setAction:@selector(circle:) forDatagram:DG_CIRCLE];
	[parser setAction:@selector(circle:) forDatagram:DG_UNCIRCLE];
	[parser setAction:@selector(arrow:) forDatagram:DG_ARROW];
	[parser setAction:@selector(arrow:) forDatagram:DG_UNARROW];
	[parser setAction:@selector(takeback:) forDatagram:DG_TAKEBACK];
	[parser setAction:@selector(takeback:) forDatagram:DG_BACKWARD];
	[parser setAction:@selector(gameMessage:) forDatagram:DG_GAME_MESSAGE];
	[parser setAction:@selector(gamelistBegin:) forDatagram:DG_GAMELIST_BEGIN];
	[parser setAction:@selector(gamelistItem:) forDatagram:DG_GAMELIST_ITEM];	
	[parser setAction:@selector(loginFailed:) forDatagram:DG_LOGIN_FAILED];
	[parser setAction:@selector(logPGN:) forDatagram:DG_LOG_PGN];
	[parser setAction:@selector(peopleInMyChannel:) forDatagram:DG_PEOPLE_IN_MY_CHANNEL];
	[parser setAction:@selector(channelsShared:) forDatagram:DG_CHANNELS_SHARED];
	[parser setAction:@selector(channelTell:) forDatagram:DG_CHANNEL_TELL];
	[parser setAction:@selector(shout:) forDatagram:DG_SHOUT];
	[parser setAction:@selector(playersInMyGame:) forDatagram:DG_PLAYERS_IN_MY_GAME];
	
	return self;
}

- (void)dealloc
{
	[boardDict release];
	[gameListArray release];
	[parser release];
	[attributes release];
	[regularAttributes release];
	[tellAttributes release];
	[tellBoardAttributes release];
	[commandAttributes release];
	
	[welcomeSound release];
	[moveSound release];
	[gameStartedSound release];
	[tellSound release];
	
	[super dealloc];
}
	
- (void)awakeFromNib
{

}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	mainWindowController = [[MainWindowController alloc] initWithWindowNibName:@"MainWindow"];
	[mainWindowController setAppDelegate:self];
	[mainWindowController showWindow:self];
	[[mainWindowController window] setTitle:@"Pieces Console - The Internet Chess Club (not connected)"];
	[[mainWindowController window] makeMainWindow];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ( [defaults boolForKey:GCRememberLoginKey]) {
		NSLog(@"setting default values");
		[usernameTextField setStringValue:[defaults stringForKey:GCUsernameKey]];
		[passwordTextField setStringValue:[defaults stringForKey:GCPasswordKey]];
		[rememberCheckBox setState:YES];
		[automaticCheckBox setState:[defaults boolForKey:GCAutomaticLoginKey]];
	}
	
	if ([automaticCheckBox state]) {
		[self startConnection:self];
	}
	else {
	[NSApp beginSheet:loginSheet 
	   modalForWindow:[mainWindowController window]
		modalDelegate:nil	
	   didEndSelector:NULL
		  contextInfo:NULL];
	}
}

- (NSTextView *)getOutputView
{
	return outputView;
}

- (IBAction)showLoginSheet:(id)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ( [defaults boolForKey:GCRememberLoginKey]) {
		NSLog(@"setting default values");
		[usernameTextField setStringValue:[defaults stringForKey:GCUsernameKey]];
		[passwordTextField setStringValue:[defaults stringForKey:GCPasswordKey]];
		[rememberCheckBox setState:YES];
		[automaticCheckBox setState:[defaults boolForKey:GCAutomaticLoginKey]];
	}
	
	[NSApp beginSheet:loginSheet 
	   modalForWindow:[mainWindowController window]
		modalDelegate:nil	
	   didEndSelector:NULL
		  contextInfo:NULL];	
}

- (IBAction)retractLoginSheet:(id)sender
{
	[NSApp endSheet:loginSheet];
	[loginSheet orderOut:sender];
}

- (IBAction)startConnection:(id)sender
{
	// save login defaults
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([rememberCheckBox state]) {
		NSLog(@"saving state");
		[defaults setObject:[usernameTextField stringValue] forKey:GCUsernameKey];
		[defaults setObject:[passwordTextField stringValue] forKey:GCPasswordKey];
		[defaults setBool:YES forKey:GCRememberLoginKey];
		[defaults setBool:[automaticCheckBox state] forKey:GCAutomaticLoginKey];
	}
	else
		[defaults setBool:NO forKey:GCRememberLoginKey];
	
	[NSApp endSheet:loginSheet];
	[loginSheet orderOut:sender];
	

	//NSLog(@"sending username and password");
	NSString *username = [usernameTextField stringValue];
	//NSLog(@"Username: %@", username);
	NSString *password = [passwordTextField stringValue];
	//NSLog(@"Password: %@", password);
	NSString *server = @"";
	
	if ([serverPopUpButton indexOfSelectedItem] == 0) {
		server = @"207.99.83.228";
		NSLog(@"main server selected");
	}
	else {
		server = @"207.99.83.231";
		NSLog(@"backup server selected");
	}

	
	[parser startConnectionWithUsername:username password:password server:server];
}

- (void)appendData:(NSData *)d attributes:(NSMutableDictionary *)a
{
	float scrollerPosition = [[[outputView enclosingScrollView] verticalScroller] floatValue];
	
	NSString *s = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
	
	
	NSTextStorage *ts = [outputView textStorage];

	if (a != nil) {
		NSAttributedString *aString = [[NSAttributedString alloc] initWithString:s attributes:a];
		[ts appendAttributedString:aString];
		[aString release];
	}
	else {
		NSMutableDictionary *a2 = [[NSMutableDictionary alloc] init];
		[a2 setObject:[NSFont fontWithName:@"Bitstream Vera Sans Mono"  size:12.0] forKey:NSFontAttributeName];
		[a2 setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
		NSAttributedString *a2String = [[NSAttributedString alloc] initWithString:s attributes:a2];
		[ts appendAttributedString:a2String];
		[a2String release];
		[a2 release];		
	}
	
	
	[s release];
	
	
	
	//[[outputTV textStorage] appendAttributedString:aString];
	
	if ( scrollerPosition > 0.9999 ) 
		[outputView scrollRangeToVisible:NSMakeRange([ts length], 0)];
	

	// scroll outputView (the NSTextView) to the very bottom of the text
	[outputView scrollRangeToVisible:NSMakeRange([ts length], 0)];
}

- (void)appendString:(NSString *)s attributes:(NSMutableDictionary *)a
{
	float scrollerPosition = [[[outputView enclosingScrollView] verticalScroller] floatValue];
	
	
	NSTextStorage *ts = [outputView textStorage];
	
	if (a != nil) {
		NSAttributedString *aString = [[NSAttributedString alloc] initWithString:s attributes:a];
		[ts appendAttributedString:aString];
		[aString release];
	}
	else {
		NSMutableDictionary *a2 = [[NSMutableDictionary alloc] init];
		[a2 setObject:[NSFont fontWithName:@"Bitstream Vera Sans Mono"  size:12.0] forKey:NSFontAttributeName];
		[a2 setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
		NSAttributedString *a2String = [[NSAttributedString alloc] initWithString:s attributes:a2];
		[ts appendAttributedString:a2String];
		[a2String release];
		[a2 release];		
	}
	
	if ( scrollerPosition > 0.9999 ) 
		[outputView scrollRangeToVisible:NSMakeRange([ts length], 0)];
	
	
	// scroll outputView (the NSTextView) to the very bottom of the text
	[outputView scrollRangeToVisible:NSMakeRange([ts length], 0)];
}

- (void)appendAttributedString:(NSAttributedString *)aString
{
	float scrollerPosition = [[[outputView enclosingScrollView] verticalScroller] floatValue];
	
	NSTextStorage *ts = [outputView textStorage];
	
	[ts appendAttributedString:aString];
	
	if ( scrollerPosition > 0.9999 ) 
		[outputView scrollRangeToVisible:NSMakeRange([ts length], 0)];
	
}

- (IBAction)sendCommand:(id)sender
{
	NSString *commandString = [[textField stringValue] stringByAppendingString:@"\n"];
	NSData *commandStringData = [commandString dataUsingEncoding:NSUTF8StringEncoding];	
	[parser sendCommand:commandStringData];
	[textField setStringValue:@""];
	[textField selectText:self];
	[self appendData:[[NSString stringWithFormat:@"cmd> %@", commandString] dataUsingEncoding:NSUTF8StringEncoding] attributes:commandAttributes];
	[mainWindowController appendData:[[NSString stringWithFormat:@"cmd> %@", commandString] dataUsingEncoding:NSUTF8StringEncoding] attributes:commandAttributes];

}

- (void)sendCommandStr:(NSString *)str
{
	[parser sendCommand:[[str stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding]];
}	

- (BOOL)windowShouldClose:(id)sender
{
	// Search through our game list and see if one of their winwodws matches sender
	int i;
	NSArray* keys = [boardDict allKeys];
	
	for ( i = 0; i < [keys count]; ++i) {
		BoardController *board = [boardDict objectForKey:[keys objectAtIndex:i]];
		
		if ( [board window] == sender ) {
			return [board windowShouldClose:self];
		}
	}

	return YES;
}

- (void)windowWillClose:(NSNotification*)aNotification {
	
	
	// determine whether it is a board window that is closing
	NSArray* keys = [boardDict allKeys];
	for ( int i = 0; i < [keys count]; ++i) {
		BoardController *board = [boardDict objectForKey:[keys objectAtIndex:i]];
		if ( [board window] == [aNotification object] ) {
			[[board window] saveFrameUsingName:@"board frame"];
			[board windowWillClose:aNotification];
			NSLog(@"board for gamenumber:%@ found and will be removed", [board gameNumber]);
			[boardDict removeObjectForKey:[board gameNumber]];
			return;
		}
	}
	
	
	// See if we have the game list controller 
	for ( int i = 0; i < [gameListArray count]; ++i ) {
		GameListController* G = [gameListArray objectAtIndex:i];
		if ( [G window] == [aNotification object] ) {
			[G release];
			[gameListArray removeObjectAtIndex:i];
			return;
		}
	}
	
	//NSLog(@"window not found in any of our lists?");
	if ( [aNotification object] == window ) {
		/* We're closing! */
		//[self disconnect:self];
		[self sendCommandStr:@"quit"];
		[NSApp terminate:self];
	}
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode
		contextInfo:(void *)contextInfo
{
	[self showLoginSheet:self];	
}


- (IBAction)closeConnection:(id)sender
{
	//[self sendCommandStr:@"quit"];
	[parser disconnect];
}

- (void)disconnected
{
	NSLog(@"disconnected");
	
	connected = NO;
	[self appendString:@"Connection Closed" attributes:nil];
	[mainWindowController appendString:@"Connection Closed" attributes:nil];
	[[mainWindowController window] setTitle:@"Pieces Console - The Internet Chess Club (not connected)"];
	
}

- (BOOL)validateMenuItem:(NSMenuItem *)item {

    if ([item action] == @selector(showLoginSheet:) && connected == YES) {
        return NO;
    }
    if ([item action] == @selector(closeConnection:) && connected == NO) {
        return NO;
    }
    return YES;
}

#pragma mark -
#pragma mark DG methods

// non-datagram data
// for any data that is not a datagram, we simply append it to the textView
- (void) unmatchedData:(id)str {	
	[self appendString:str attributes:nil];
	[mainWindowController appendString:str attributes:nil];

}


/*
 0 DG_WHO_AM_I   
 Form: (myname titles)
 
 This is sent right after I login.  It tells the client
 what my name is.  This is needed because level 2 DGs do
 not use a "*" for my name (to avoid having to generate
 different messages for everybody) and because if I login with
 "g" the client needs to be told what my name is.
*/ 
- (void)whoami:(id)dgArray
{
	[dgArray retain];
	
	connected = YES;
	
	
	// because this datagram is sent right after I login, this meant that
	// I was able to successfully login, and thus can play the welcome message
	[welcomeSound play];
	[[mainWindowController window] setTitle:@"Pieces Console - The Internet Chess Club (connected)"];
	me = [[dgArray objectAtIndex:1] copy];


	[self sendCommandStr:@"set noautologout 1"];
	[self sendCommandStr:@"set interface=Pieces v0.3 (Mac OS X)"];
	[self sendCommandStr:@"set style 13"];
	[self sendCommandStr:@"set prompt 0"];
	[self sendCommandStr:@"set unobserve 0"];
	
	[dgArray release];
}


/*
 13 DG_GAME_RESULT
 Form: (gamenumber become-examined game_result_code score_string2 description-string ECO)
 
 This is sent when a played game ends.
 The "become-examined" bit is 1 if the game becomes an
 examined game.  If it is zero, then the game is gone.
 This may also be sent when you look at a game which isn't currently
 being played; i.e., with sposition, or when you refresh or begin to
 observe an examined game.
 
 There are three outcome codes, given in the following order:
 (1) game_result, e.g. "Mat" (the 3-letter codes used in game lists)
 (2) score_string2, "0-1", "1-0", "1/2-1/2", "*", or "aborted"
 (3) description_string, e.g. "White checkmated"
 
 The ECO field is new as of November 2001.  It may be "?" in many
 cases (maybe all cases) especially if it turns out that computing
 this is expensive, but we'll try it for now.
 */
- (void)gameResult:(id)dgArray
{
	NSArray *dgArrayKeys = [[NSArray alloc] initWithObjects:@"datagram", @"gamenumber", @"become-examined", 
							@"game_result_code", @"score_string2", @"description-string", @"ECO", nil];
	NSDictionary *dgDictionary = [[NSDictionary alloc] initWithObjects:dgArray forKeys:dgArrayKeys];
	BoardController *board = [boardDict objectForKey:[dgDictionary objectForKey:@"gamenumber"]];
	
	[board gameResult:[dgDictionary objectForKey:@"score_string2"]];

	
	if ([[dgDictionary objectForKey:@"become-examined"] intValue] == 0)
		[board setStatus:0];
	else
		[board setStatus:5];
	
	//NSLog(@"become examined: %i", [[dgDictionary objectForKey:@"become-examined"] intValue]);
	
	[dgDictionary release];
	[dgArrayKeys release];
}


/*
 15 DG_MY_GAME_STARTED
 This generates a DG that's exactly like
 DG_GAME_STARTED.  Except that I know it's my game, and that
 I just started playing or examining.  (If they're both
 turned on, then redundant messages are generated, but there's
 no need for them both to be on.)
 
 12 DG_GAME_STARTED - (as stated above, has same format, but not using this datagram number)
 
 Form:   (gamenumber whitename blackname wild-number rating-type rated
 white-initial white-increment black-initial black-increment
 played-game {ex-string} white-rating black-rating game-id
 white-titles black-titles irregular-legality irregular-semantics
 uses-plunkers fancy-timecontrol promote-to-king)
 
 Indicate to me the start of games.  (Or it may have started
 a while ago and I just logged in.)
 When this feature is activated, I get a list of all the games.
 It includes both regular and examined games.  The list may
 take a while to transmit.
 whitename and blackname may contain punctuation, and while they currently
 have no spaces and are 15 characters or less, don't count on that.
 rating-type is a string such as "Blitz".
 rated is 1 or 0.
 white-initial and black-initial are in minutes.
 white-increment and black-increment are in seconds.
 played-game is 1 for real games and 0 for examined games.
 ex-string might be "Ex: continuation", and is at most 30 characters.
 white-rating and black-rating are the player's relevant ratings at
 game start, and are 0 for unrated players.
 game-id is a number that can be used to specify a stored game, e.g. with
 "sposition #902425349".  So far, it's close to the Unix time of the
 game start, but that will no longer be true when we surpass 84000 games/day.
 irregular-legality is 0 normally, 1 if there are legal moves that wouldn't
 be legal in chess (i.e., turn off client-side legal move checking unless
 the client is familiar with this wild type)
 irregular-semantics is 0 normally, 1 for atomic chess and other variants
 where you can't update the board based on the last move by usual rules.
 (see also DG_SET_BOARD)
 uses-plunkers is 0 normally, 1 for bughouse and similar variants.
 fancy-timecontrol if non-null specifies a time control that supercedes the
 white-initial white-increment black-initial black-increment fields.
 The format is as in PGN, although we might extend that to allow Bronstein delays,
 time odds, and other strange situations.
 and to improve readability.  
 Examples you might actually see:
 40/7200:20/3600       (2 hours, plus an hour after 40th, 60th move, 80th move...)
 40/5400+30:900+30     (90 minutes, plus 15 minutes after 40th move, plus 30 second increment throughout)
 ?                     (unknown -- best not to display clocks) 
 -                     (untimed -- best not to display clocks)
 promote-to-king is 0 normally, 1 if it may sometimes be legal to promote a pawn to a king.
 */
- (void)myGameStarted:(id)dgArray
{
	[dgArray retain];
	NSArray *dgArrayKeys = [[NSArray alloc] initWithObjects:@"datagram", @"gamenumber", @"whitename", @"blackname", @"wild-number",
							@"rating-type", @"rated", @"white-initial", @"white-increment", @"black-initial", 
							@"black-increment", @"played game", @"ex-string", @"white-rating", @"black-rating", @"game-id",
							@"white-titles", @"black-titles", @"irregular-legality", @"irregular-semantics", @"uses-plunkers",
							@"fancy-timecontrol", @"promote-to-king", nil];
	
	NSDictionary *dgDictionary = [[NSDictionary alloc] initWithObjects:dgArray forKeys:dgArrayKeys];
		
	BoardController *match = nil;
	BOOL samegame = NO;
	
	match = [boardDict objectForKey:[dgDictionary objectForKey:@"gamenumber"]];
	
	if (!match) {
		NSArray *boardDictArray = [boardDict allKeys];
		
		for (int i=0; i< [boardDictArray count]; i++) {
			BoardController *b = [boardDict objectForKey:[boardDictArray objectAtIndex:i]];
			if ([b getStatus] == 0) {
				match = b;
				[boardDict removeObjectForKey:[boardDictArray objectAtIndex:i]];
				break;
			}
		}
	
	}
	else {
		[boardDict removeObjectForKey:[dgDictionary objectForKey:@"gamenumber"]];
		samegame = YES;
	}

	
	BoardController *board;
	
	if (match == nil) {
		board = [[BoardController alloc] init];
		[NSBundle loadNibNamed:@"Board" owner:board];
		[[board window] setDelegate:board];
		[board setBoardDelegate:self];
		[[board window] setFrameUsingName:@"board frame"];
		[board showWindow:self];
		
		[board reset];
		
		//[NSBundle loadNibNamed:@"Board" owner:board];
	}
	else {
		board = match;
		//[NSBundle loadNibNamed:@"Board" owner:board];
		if (samegame == NO)
			[board reset];
	}
	

	
	//[board reset];
	
	[board setGameNumber:[dgDictionary objectForKey:@"gamenumber"]];
	
	int dgType = [[dgDictionary objectForKey:@"datagram"] intValue];
	NSString *exString = [dgDictionary objectForKey:@"ex-string"];
	
	if ((dgType == 15 && [exString length] > 0) || (dgType == 18))
		[board setStatus:1];
	
	[board setWhitePlayer:[dgDictionary objectForKey:@"whitename"] withRating:[dgDictionary objectForKey:@"white-rating"] 
					title:[dgDictionary objectForKey:@"white-titles"]];
	[board setBlackPlayer:[dgDictionary objectForKey:@"blackname"] withRating:[dgDictionary objectForKey:@"black-rating"]
					title:[dgDictionary objectForKey:@"black-titles"]];
	[board setWhiteClock:[[dgDictionary objectForKey:@"white-initial"] longLongValue]*60];
	[board setBlackClock:[[dgDictionary objectForKey:@"black-initial"] longLongValue]*60];
	[board setInitialClock:[dgDictionary objectForKey:@"white-initial"] initialIncrement:[dgDictionary objectForKey:@"white-increment"]];
	[board setWildNumber:[[dgDictionary objectForKey:@"wild-number"] intValue]];
	
	[board setRated:[dgDictionary objectForKey:@"rated"] type:[dgDictionary objectForKey:@"rating-type"]];
	
	[board setWindowTitle];
	
	[board appendChat:[NSString stringWithFormat:@"Game %@ (%@ vs. %@)\n", 
					   [dgDictionary objectForKey:@"gamenumber"], 
					   [dgDictionary objectForKey:@"whitename"], 
					   [dgDictionary objectForKey:@"blackname"]] 
		   attributes:attributes];
	
	[boardDict setObject:board forKey:[dgDictionary objectForKey:@"gamenumber"]];
	
//	[board release];

	//[gameStartedSound play];
	
	
	[[board window] makeKeyAndOrderFront:self];
	[[board window] setDelegate:self];
	
	// start clock at beginning of the game
	//[board startClockCountDown];
	
	[dgDictionary release];
	[dgArrayKeys release];	
}


/*
 16 DG_MY_GAME_RESULT
 Same as DG_GAME_RESULT.  Generated for any game I'm playing,
 examining or observing.
*/

/*
 20 DG_PLAYERS_IN_MY_GAME
 To keep track of who is observing the games I'm
 observing (or playing or examining).
 
 If this is set then when I start observing (or playing or
 examining) a game, I get a sequence of messages like:
 
 (gamenumber playername symbol kibvalue)
 
 The symbol indicates if this player is observing, playing,
 or examining the game.
 
 O=observing
 PW=playing white
 PB=playing black
 SW=playing simul and is white
 SB=playing simul and is black
 E=Examining
 X=None (has left the table)     
 
 Note that the above are pair-wise mutually exclusive.
 
 The kibvalue indicates whether or not this player hears
 kibitzes or whispers.
 
 A player giving a simul might show up as PW when "at the board"
 and SW the rest of the time.
 */
- (void)playersInMyGame:(id)dgArray
{

}


/*
 22 DG_TAKEBACK
 Form: (gamenumber takeback-count)
 A takeback occurred in the game that I'm observing or playing.
 
 23 DG_BACKWARD
 Form: (gamenumber backup-count)
 A player backed up in an examined game.
 Also generated by the "revert" command.
 */
- (void)takeback:(id)dgArray
{
	NSArray *dgArrayKeys = [[NSArray alloc] initWithObjects:@"datagram", @"gamenumber", @"takeback-count", nil];
	NSDictionary *dgDictionary = [[NSDictionary alloc] initWithObjects:dgArray forKeys:dgArrayKeys];
	BoardController *board = [boardDict objectForKey:[dgDictionary objectForKey:@"gamenumber"]];
	
	int takebackCount = [[dgDictionary objectForKey:@"takeback-count"] intValue];
	
	[board takeback:takebackCount];
	
	[dgDictionary release];
	[dgArrayKeys release];
}


/*
 24 DG_SEND_MOVES
 A move was made.  Also sent when an examiner uses "forward".
 
 Form: (gamenumber algebraic-move smith-move time clock is-variation)
 where last five fields are OPTIONAL, controlled by
 the variables described above.
 
 With these and the DG_MOVE_LIST or DG_POSITION_BEGIN DGs, a smart
 client can reasonably disable sending of the board by using style 13.
 */
- (void)sendMoves:(id)dgArray
{
	NSArray *dgArrayKeys = [[NSArray alloc] initWithObjects:@"datagram", @"gamenumber", @"algebraic-move", @"smith-move",
							@"time", @"clock", nil];
	NSDictionary *dgDictionary = [[NSDictionary alloc] initWithObjects:dgArray forKeys:dgArrayKeys];
	BoardController *board = [boardDict objectForKey:[dgDictionary objectForKey:@"gamenumber"]];
	
	[board stopClockCountDown];
	[board setClock:[dgDictionary objectForKey:@"clock"]];
	[board algebraicMove:[dgDictionary objectForKey:@"algebraic-move"] smithMove:[dgDictionary objectForKey:@"smith-move"]];
	[board startClockCountDown];
	
	[moveSound play];
	
	[dgDictionary release];
	[dgArrayKeys release];
}


/*
 26 DG_KIBITZ
 This is the level 2 version of kibitz.
 Form: (gamenumber playername titles kib/whi ^Y{kib string^Y})
 kib/whi is 1 if it's a kibitz 0 if whisper.
 Normal form is inhibited if I get the level2 version.
 */
- (void)kibitz:(id)dgArray
{
	NSArray *dgArrayKeys = [[NSArray alloc] initWithObjects:@"datagram", @"gamenumber", @"playername", @"titles",
							@"kib/whi", @"kib string", nil];
	NSDictionary *dgDictionary = [[NSDictionary alloc] initWithObjects:dgArray forKeys:dgArrayKeys];
	BoardController *board = [boardDict objectForKey:[dgDictionary objectForKey:@"gamenumber"]];
	
	/*NSAttributedString *aString = [[NSAttributedString alloc] 
								   initWithString:[dgDictionary objectForKey:@"playername"] 
								   attributes:attributes];
	*/
	
	NSMutableDictionary *handleAttributes = [[NSMutableDictionary alloc] init];
	[handleAttributes setObject:[NSFont fontWithName:@"Lucida Grande Bold"  size:12.0] forKey:NSFontAttributeName];
	[handleAttributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
	
	NSMutableDictionary *myHandleAttributes = [[NSMutableDictionary alloc] init];
	[myHandleAttributes setObject:[NSFont fontWithName:@"Lucida Grande Bold"  size:12.0] forKey:NSFontAttributeName];
	[myHandleAttributes setObject:[NSColor redColor] forKey:NSForegroundColorAttributeName];

	NSMutableDictionary *actionAttributes = [[NSMutableDictionary alloc] init];
	[actionAttributes setObject:[NSFont fontWithName:@"Lucida Grande"  size:12.0] forKey:NSFontAttributeName];
	[actionAttributes setObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
	
	NSString *kibstring = [NSString stringWithFormat:@"%@%@ %@: %@", [dgDictionary objectForKey:@"playername"], 
						   ([[dgDictionary objectForKey:@"titles"] length] > 0 ? 
							[NSString stringWithFormat:@"(%@)",[dgDictionary objectForKey:@"titles"]] : @""), 
						   ([[dgDictionary objectForKey:@"kib/whi"] intValue] == 0 ? @"whispers" : @"kibitzes"), 
						   [dgDictionary objectForKey:@"kib string"]];
	
	[board appendChat:[dgDictionary objectForKey:@"playername"] 
		   attributes:([[dgDictionary objectForKey:@"playername"] isEqualToString:me] ? myHandleAttributes : handleAttributes)];
	[board appendChat:([[dgDictionary objectForKey:@"titles"] length] > 0 ? 
												   [NSString stringWithFormat:@"(%@) ",[dgDictionary objectForKey:@"titles"]] : @" ")
		   attributes:handleAttributes];
	[board appendChat:([[dgDictionary objectForKey:@"kib/whi"] intValue] == 0 ? @"whispers: " : @"kibitzes: ")
		   attributes:actionAttributes];
	[board appendChat:[NSString stringWithFormat:@"%@\n", [dgDictionary objectForKey:@"kib string"]] attributes:nil];
	
	//[board kibitz:kibstring];
	
	[myHandleAttributes release];
	[handleAttributes release];
	[actionAttributes release];
	
	[dgDictionary release];
	[dgArrayKeys release];
}


/*
 27 DG_PEOPLE_IN_MY_CHANNEL
 Show who is in my channels.
 
 (channel playername come/go)
 
 "come/go" is 1 if he/she is in the channel 0 if not in the
 channel.
 
 A sequence of these with come/go=1 is generated whenever I
 enter a channel.
 
 I do get one for myself when I enter or leave a channel.
 
 When someone connects, if they subscribe to channels it is as
 if they join each one, unless I have DG_CHANNELS_SHARED on
 which presents the relevant data more compactly (see below).
 When I connect, if I don't have DG_CHANNELS_SHARED on I get
 many DG_PEOPLE_IN_MY_CHANNEL messages instead, which can
 easily overflow my output buffer.
 */
- (void)peopleInMyChannel:(id)dgArray
{
	NSArray *dgArrayKeys = [[NSArray alloc] initWithObjects:@"datagram", @"channel", @"playername", @"come/go", nil];
	NSDictionary *dgDictionary = [[NSDictionary alloc] initWithObjects:dgArray forKeys:dgArrayKeys];
	
	
	if ([[dgDictionary objectForKey:@"playername"] isEqualToString:me]) {
		
		if ([[dgDictionary objectForKey:@"come/go"] isEqualToString:@"1"]) {
			
			//NSLog(@"joining channel: %@", [dgDictionary objectForKey:@"channel"]);
			
			[mainWindowController addChannel:[dgDictionary objectForKey:@"channel"]];
		}
		else {
			[mainWindowController removeChannel:[dgDictionary objectForKey:@"channel"]];
		}
	}
	
	[dgDictionary release];
	[dgArrayKeys release];
}

/*
28 DG_CHANNEL_TELL
The level 2 version of a channel tell.  If this is on, the
normal form is inhibited.

Form: (channel playername titles ^Y{tell string^Y} type)

Type is similar to DG_PERSONAL_TELL:  1 normally, but 4 for
an "atell" (typically a helper's response to your question).
 */
- (void)channelTell:(id)dgArray
{
	NSArray *dgArrayKeys = [[NSArray alloc] initWithObjects:@"datagram", @"channel", @"playername", @"titles", @"tell string", @"type", nil];
	NSDictionary *dgDictionary = [[NSDictionary alloc] initWithObjects:dgArray forKeys:dgArrayKeys];
	
	NSMutableAttributedString *tellString;
	
	NSLog(@"channel tell");
	
	NSMutableDictionary *channelAttributes = [[NSMutableDictionary alloc] init];
	[channelAttributes setObject:[NSFont fontWithName:@"Bitstream Vera Sans Mono"  size:12.0] forKey:NSFontAttributeName];
	[channelAttributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
	
	NSRange handleRange, tellRange;
	
	

	int handleLength, tellLength;
	
	tellLength = [[dgDictionary objectForKey:@"tell string"] length] + 2;
	
	if ([[dgDictionary objectForKey:@"titles"] length] > 0) {
		
		handleLength = [[dgDictionary objectForKey:@"playername"] length] + [[dgDictionary objectForKey:@"titles"] length] + 2;
		
		handleRange = NSMakeRange(0, handleLength);
		tellRange = NSMakeRange(handleLength, tellLength);
		
		tellString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@(%@): %@\n", 
								[dgDictionary objectForKey:@"playername"],
								[dgDictionary objectForKey:@"titles"],
								[dgDictionary objectForKey:@"tell string"]]];
	}
	else {
		
		handleLength = [[dgDictionary objectForKey:@"playername"] length];
		
		handleRange = NSMakeRange(0, handleLength);
		tellRange = NSMakeRange(handleLength, tellLength);
		
		tellString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: %@\n", 
																		[dgDictionary objectForKey:@"playername"],
																		[dgDictionary objectForKey:@"tell string"]]];
	
	}
	
	[tellString setAttributes:attributes range:handleRange];
	[tellString setAttributes:regularAttributes range:tellRange];
	
	[mainWindowController appendToChannel:[dgDictionary objectForKey:@"channel"] string:tellString];
	
	/*
	if ([[dgDictionary objectForKey:@"type"] intValue] == 4)
		[mainWindowController appendToChannel:[dgDictionary objectForKey:@"channel"]
																  String:tellString 
															  attributes:tellAttributes];
	else
		[mainWindowController appendToChannel:[dgDictionary objectForKey:@"channel"]
																  String:tellString 
															  attributes:channelAttributes];
	 */
	[channelAttributes release];
	[tellString release];
	[dgDictionary release];
	[dgArrayKeys release];
}
			

/*
 31 DG_PERSONAL_TELL
 The level 2 version of a personal tell.  If this is on, the
 normal form is not generated.
 
 Form: (playername titles ^Y{tell string^Y} type)
 
 The type is 0 for "say", 1 for "tell", 2 for "ptell" (from bughouse
 partner), 3 would be qtell if we sent qtells this way (which
 we don't, they go with DG_PERSONAL_QTELL), and 4 for "atell"
 (from admin or helper).
 */
- (void)personalTell:(id)dgArray
{
	[dgArray retain];
	
	NSArray *dgArrayKeys = [[NSArray alloc] initWithObjects:@"datagram", @"playername", @"titles", @"tell string", @"type", nil];
	NSDictionary *dgDictionary = [[NSDictionary alloc] initWithObjects:dgArray forKeys:dgArrayKeys];
	
	[tellSound play];
	
	NSString *saysOrTells;
	int type = [[dgDictionary objectForKey:@"type"] intValue];
	
	switch (type) {
		case 0:
			saysOrTells = @"says";
			break;
		case 1:
			saysOrTells = @"tells you";
			break;
		case 2:
			saysOrTells = @"(your bughouse partner) tells you";
			break;
		default:
			saysOrTells = @"";
			break;
	}
	
	BoardController *board = nil;
	
	NSArray *boardDictArray = [boardDict allKeys];
	
	for (int i=0; i< [boardDictArray count]; i++) {
		BoardController *b = [boardDict objectForKey:[boardDictArray objectAtIndex:i]];
		if (([[b getWhitePlayer] isEqualToString:[dgDictionary objectForKey:@"playername"]] && [[b getBlackPlayer] isEqualToString:me]) ||
		([[b getBlackPlayer] isEqualToString:[dgDictionary objectForKey:@"playername"]] && [[b getWhitePlayer] isEqualToString:me])) {
			board = b;
			
			if ([[dgDictionary objectForKey:@"titles"] length] == 0)
				[board appendChat:[NSString stringWithFormat:@"%@ %@: %@\n", [dgDictionary objectForKey:@"playername"], 
								   saysOrTells, 
								   [dgDictionary objectForKey:@"tell string"]] 
					  attributes:tellBoardAttributes];
			else
				[board appendChat:[NSString stringWithFormat:@"%@(%@) %@: %@\n", [dgDictionary objectForKey:@"playername"], 
								   [dgDictionary objectForKey:@"titles"], 
								   saysOrTells, 
								   [dgDictionary objectForKey:@"tell string"]] 
					  attributes:tellBoardAttributes];
			
			break;
		}
	}
	
	if (board == nil)
		if ([[dgDictionary objectForKey:@"titles"] length] == 0) {
			[self appendData:[[NSString stringWithFormat:@"%@ %@: %@\n", [dgDictionary objectForKey:@"playername"], 
							   saysOrTells, 
							  [dgDictionary objectForKey:@"tell string"]] dataUsingEncoding:NSUTF8StringEncoding] 
				  attributes:tellAttributes];
			[mainWindowController appendData:[[NSString stringWithFormat:@"%@ %@: %@\n", [dgDictionary objectForKey:@"playername"], 
							   saysOrTells, 
							   [dgDictionary objectForKey:@"tell string"]] dataUsingEncoding:NSUTF8StringEncoding] 
				  attributes:tellAttributes];
		} 
		else {
			[self appendData:[[NSString stringWithFormat:@"%@(%@) %@: %@\n", [dgDictionary objectForKey:@"playername"], 
							   [dgDictionary objectForKey:@"titles"], 
							   saysOrTells, 
							   [dgDictionary objectForKey:@"tell string"]] dataUsingEncoding:NSUTF8StringEncoding] 
				  attributes:tellAttributes];
			[mainWindowController appendData:[[NSString stringWithFormat:@"%@(%@) %@: %@\n", [dgDictionary objectForKey:@"playername"], 
							   [dgDictionary objectForKey:@"titles"], 
							   saysOrTells, 
							   [dgDictionary objectForKey:@"tell string"]] dataUsingEncoding:NSUTF8StringEncoding] 
				  attributes:tellAttributes];
		}
	
	[dgDictionary release];
	[dgArrayKeys release];
}


/*
32 DG_SHOUT
The level 2 form of shout, sshout and announce.  Inhibits
normal reception of these.

Form: (playername titles type ^Y{shout string^Y})

The type is 0 for regular shouts, 1 for "I" type shouts, 2
for sshouts and 3 for announcements.
 */
- (void)shout:(id)dgArray
{
	NSArray *dgArrayKeys = [[NSArray alloc] initWithObjects:@"datagram", @"playername", @"titles", @"types", @"shout string", nil];
	NSDictionary *dgDictionary = [[NSDictionary alloc] initWithObjects:dgArray forKeys:dgArrayKeys];

	switch ([[dgDictionary objectForKey:@"types"] intValue]) {
		case 0:
			NSLog(@"shout");
			NSMutableDictionary *shoutAttribute = [[NSMutableDictionary alloc] init];
			[shoutAttribute setObject:[NSFont fontWithName:@"Lucida Grande"  size:12.0] forKey:NSFontAttributeName];
			[shoutAttribute setObject:[NSColor darkGrayColor] forKey:NSForegroundColorAttributeName];
			if ([[dgDictionary objectForKey:@"titles"] length] > 0)
				[mainWindowController appendString:[NSString stringWithFormat:@"%@(%@) shouts: %@\n", 
												   [dgDictionary objectForKey:@"playername"],
												   [dgDictionary objectForKey:@"titles"],
												   [dgDictionary objectForKey:@"shout string"]]
										attributes:shoutAttribute];
			else
				[mainWindowController appendString:[NSString stringWithFormat:@"%@ shouts: %@\n", 
													   [dgDictionary objectForKey:@"playername"],
													   [dgDictionary objectForKey:@"shout string"]]
										attributes:shoutAttribute];
			[shoutAttribute release];
			break;
		case 1:
			NSLog(@"-->");
			NSMutableDictionary *iAttribute = [[NSMutableDictionary alloc] init];
			[iAttribute setObject:[NSFont fontWithName:@"Lucida Grande"  size:12.0] forKey:NSFontAttributeName];
			[iAttribute setObject:[NSColor darkGrayColor] forKey:NSForegroundColorAttributeName];
			if ([[dgDictionary objectForKey:@"titles"] length] > 0)
				[mainWindowController appendString:[NSString stringWithFormat:@"--> %@(%@) %@\n", 
													   [dgDictionary objectForKey:@"playername"],
													   [dgDictionary objectForKey:@"titles"],
													   [dgDictionary objectForKey:@"shout string"]]
										attributes:iAttribute];
			else
				[mainWindowController appendString:[NSString stringWithFormat:@"--> %@ %@\n", 
													[dgDictionary objectForKey:@"playername"],
													[dgDictionary objectForKey:@"shout string"]]
										attributes:iAttribute];
			[iAttribute release];
			break;
		case 2:
			NSLog(@"sshout");
			NSMutableDictionary *sshoutAttribute = [[NSMutableDictionary alloc] init];
			[sshoutAttribute setObject:[NSFont fontWithName:@"Lucida Grande"  size:12.0] forKey:NSFontAttributeName];
			[sshoutAttribute setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
			if ([[dgDictionary objectForKey:@"titles"] length] > 0)

			
				[mainWindowController appendString:[NSString stringWithFormat:@"%@(%@) s-shouts: %@\n", 
													   [dgDictionary objectForKey:@"playername"],
													   [dgDictionary objectForKey:@"titles"],
													   [dgDictionary objectForKey:@"shout string"]]
										attributes:sshoutAttribute];
			else
				[mainWindowController appendString:[NSString stringWithFormat:@"%@ s-shouts: %@\n", 
													[dgDictionary objectForKey:@"playername"],
													[dgDictionary objectForKey:@"shout string"]]
										attributes:sshoutAttribute];
			[sshoutAttribute release];
			break;
		case 3:
			NSLog(@"announcements");
			NSMutableDictionary *announcementAttribute = [[NSMutableDictionary alloc] init];
			[announcementAttribute setObject:[NSFont fontWithName:@"Lucida Grande Bold"  size:12.0] forKey:NSFontAttributeName];
			[announcementAttribute setObject:[NSColor redColor] forKey:NSForegroundColorAttributeName];
			
			if ([[dgDictionary objectForKey:@"titles"] length] > 0)
				[mainWindowController appendString:[NSString stringWithFormat:@"%@(%@) announces: %@\n", 
													   [dgDictionary objectForKey:@"playername"],
													   [dgDictionary objectForKey:@"titles"],
													   [dgDictionary objectForKey:@"shout string"]]
										attributes:announcementAttribute];
			else {
				[mainWindowController appendString:[NSString stringWithFormat:@"%@ announces: %@\n", 
													   [dgDictionary objectForKey:@"playername"],
													   [dgDictionary objectForKey:@"shout string"]] 
										attributes:announcementAttribute ];
				
			}

			[announcementAttribute release];

			break;
		default:
			break;
	}
	
	[dgDictionary release];
	[dgArrayKeys release];
}


/*
 38 DG_SET_CLOCK
 (gamenumber white-clock black-clock)
 Sent when a game I'm involved in has a clock adjusted, say by
 the moretime command.
 */
- (void)setClock:(id)dgArray
{
	[dgArray retain];
	
	NSArray *dgArrayKeys = [[NSArray alloc] initWithObjects:@"datagram", @"gamenumber", @"white-clock", @"black-clock", nil];
	NSDictionary *dgDictionary = [[NSDictionary alloc] initWithObjects:dgArray forKeys:dgArrayKeys];
	BoardController *board = [boardDict objectForKey:[dgDictionary objectForKey:@"gamenumber"]];
	
	long long time;
	int minutes;
	int seconds;

//	if ([[dgDictionary objectForKey:@"white-clock"] length] > 0) {
		NSLog(@"white player: %@", [board getWhitePlayer]);
		NSLog(@"setting white clock");
		time = [[dgDictionary objectForKey:@"white-clock"] longLongValue];
		
		if (time == 0) {
			minutes = 0;
			seconds = 0;
		}
		else {
			minutes = time/60;
			seconds = time%60;
		}
		[board setWhiteClock:time];
	
	//[board appendChat:[NSString stringWithFormat:@"%@'s clock set to: %02d:%02d", [board getWhitePlayer], minutes, seconds] attributes:attributes];
//	}
//	if ([[dgDictionary objectForKey:@"black-clock"] length] > 0) {
		NSLog(@"setting black clock");
		NSLog(@"black player: %@", [board getBlackPlayer]);
		time = [[dgDictionary objectForKey:@"black-clock"] longLongValue];
		
		if (time == 0) {
			minutes = 0;
			seconds = 0;
		}
		else {
			minutes = time/60;
			seconds = time%60;
		}
		
		[board setBlackClock:time];
	
	
		//[board appendChat:[NSString stringWithFormat:@"%@'s clock set to: %02d:%02d", [board getBlackPlayer], minutes, seconds] attributes:attributes];
//	}
	[dgDictionary release];
	[dgArrayKeys release];
}


/*
 39 DG_FLIP
 (gamenumber flip)
 flip=1 means I am Black or have asked to watch from Black's point of view.
 Normally precedes a DG_MOVE_LIST, and is sent in roughly the same
 situations, i.e. when I first see a game.  Also sent in response to
 the flip <game> command, in which case a dg_refresh follows.  The client
 should not have to display the board on receiving the dg_flip, because
 either a dg_move_list or a dg_refresh will follow.
 */
- (void)flip:(id)dgArray
{
	NSArray *dgArrayKeys = [[NSArray alloc] initWithObjects:@"datagram", @"gamenumber", @"flip", nil];
	NSDictionary *dgDictionary = [[NSDictionary alloc] initWithObjects:dgArray forKeys:dgArrayKeys];
	BoardController *board = [boardDict objectForKey:[dgDictionary objectForKey:@"gamenumber"]];
	
	if ([[dgDictionary objectForKey:@"flip"] intValue] == 1)
		[board flip];
	else
		[board unFlip];
	
	[dgDictionary release];
	[dgArrayKeys release];
}

/*
42 DG_ILLEGAL_MOVE
(gamenumber movestring reason)

Sent when I issued an illegal move (and am playing or examining).
The movestring is what I typed, up to a blank or 20 characters.
Reason codes include:
1 Bad or ambiguous notation
2 Illegal (covers most of rules of chess)
3 King in check (don't ask why this is singled out)
4 Not your move
5 Bughouse and don't have the piece you're trying to drop
6 Bughouse and drop-square isn't empty
7 Bughouse and pawn drop attempted on first or eighth rank
8 Special restriction in some future wild game type
9 Wait a few seconds before entering moves in examine mode
10 You lost on time before making that move
I get the text message anyway.
*/
- (void)illegalMove:(id)dgArray
{
	NSArray *dgArrayKeys = [[NSArray alloc] initWithObjects:@"datagram", @"gamenumber", @"movestring", @"reason", nil];
	NSDictionary *dgDictionary = [[NSDictionary alloc] initWithObjects:dgArray forKeys:dgArrayKeys];
	BoardController *board = [boardDict objectForKey:[dgDictionary objectForKey:@"gamenumber"]];
	
	[board illegalMove];
	
	[dgDictionary release];
	[dgArrayKeys release];	
}


/*
 43 DG_MY_RELATION_TO_GAME
 (gamenumber symbol)
 
 Same as DG_PLAYERS_IN_MY_GAME, but just for me, and only has
 the two fields gamenumber and symbol.
 */
- (void)myRelationToGame:(id)dgArray
{
	NSArray *dgArrayKeys = [[NSArray alloc] initWithObjects:@"datagram", @"gamenumber", @"symbol", nil];
	NSDictionary *dgDictionary = [[NSDictionary alloc] initWithObjects:dgArray forKeys:dgArrayKeys];
	BoardController *board = [boardDict objectForKey:[dgDictionary objectForKey:@"gamenumber"]];
	
	NSString *tmpStr = [dgDictionary objectForKey:@"symbol"];
	
	NSLog(@"symbol: %@", tmpStr);
	
	if ([tmpStr isEqualToString:@"O"])
		[board setStatus:5];
	else if ([tmpStr isEqualToString:@"PW"] || [tmpStr isEqualToString:@"SW"])
		[board setStatus:3];
	else if ([tmpStr isEqualToString:@"PB"] || [tmpStr isEqualToString:@"SB"])
		[board setStatus:4];
	else if ([tmpStr isEqualToString:@"E"])
		[board setStatus:1];
	else if ([tmpStr isEqualToString:@"X"])
		[board setStatus:0];
	else
		[board setStatus:0];
	
	[dgDictionary release];
	[dgArrayKeys release];	
}


/*
 46 DG_CHANNELS_SHARED
 (playername channels)
 
 A list of the channels that both the player and I are in.  Not
 sent if the list is empty.  Sent only when someone connects, and
 a list of them when I connect, or I do a set-2.
 Use DG_PEOPLE_IN_MY_CHANNEL to get updates about people joining
 or leaving channels.
 DG_CHANNELS_SHARED being on inhibits the sending of lists of
 DG_PEOPLE_IN_MY_CHANNEL messages on connection.
 This can still be a lot of characters, if you connect onto a
 crowded server while subscribed to many channels.  See appendix 3.
 */
- (void)channelsShared:(id)dgArray
{
	[dgArray retain];
	
	
	
	if ([[dgArray objectAtIndex:1] isEqualToString:me]) {
		
		//NSLog(@"channelsshared 0: %@", [dgArray objectAtIndex:0]);
		//NSLog(@"channelsshared 1: %@", [dgArray objectAtIndex:1]);

		
		int i;
		
		for (i = 2; i < [dgArray count]; i++) {
			//NSLog(@"channelsshared %i: %@", i, [dgArray objectAtIndex:i]);

			[mainWindowController addChannel:[dgArray objectAtIndex:i]];
		}
	}
	

	[dgArray release];
}


/*
59 DG_CIRCLE
Form: (gamenumber examiner coordinate) 

Sent to observers and examiners when an examiner does the circle command.
coordinate is of the form e4.  The idea is that the examiner can
highlight one or more squares with circles, and also draw arrows (see DG_ARROW),
and these should all vanish when the position changes (a move forward or back).
 
 89 DG_UNCIRCLE
 Form: (gamenumber examiner coordinate) 
 
 Sent to observers and examiners when an examiner does the uncircle command.
 coordinate is of the form e4.  Do you want these also to be sent when
 the position changes?  I'll assume not.  There is currently no guarantee
 that there was ever a circle there, so don't assume anything.
*/
- (void)circle:(id)dgArray 
{
	NSArray *dgArrayKeys = [[NSArray alloc] initWithObjects:@"datagram", @"gamenumber", @"examiner", @"coordinate", nil];
	NSDictionary *dgDictionary = [[NSDictionary alloc] initWithObjects:dgArray forKeys:dgArrayKeys];
	
	BoardController *board = [boardDict objectForKey:[dgDictionary objectForKey:@"gamenumber"]];
	
	if ([[dgDictionary objectForKey:@"datagram"] intValue] == DG_CIRCLE)
		[board appendChat:[NSString stringWithFormat:@"%@ circles %@\n", [dgDictionary objectForKey:@"examiner"], [dgDictionary objectForKey:@"coordinate"]]
			   attributes:attributes];
	else
		[board appendChat:[NSString stringWithFormat:@"%@ uncircles %@\n", [dgDictionary objectForKey:@"examiner"], [dgDictionary objectForKey:@"coordinate"]]
			   attributes:attributes];
	
	[board circle:[dgDictionary objectForKey:@"coordinate"]];
	
	[dgDictionary release];
	[dgArrayKeys release];
}

/*
 60 DG_ARROW
 Form: (gamenumber examiner origin destination)
 
 Sent to observers and examiners in response to an arrow command.
 e.g. (37 fishbait e2 e4)
 
 90 DG_UNARROW
 Form: (gamenumber examiner origin destination)
 
 Sent to observers and examiners in response to an unarrow command.
 e.g. (37 fishbait e2 e4)
 */

- (void)arrow:(id)dgArray 
{
	NSArray *dgArrayKeys = [[NSArray alloc] initWithObjects:@"datagram", @"gamenumber", @"examiner", @"origin", @"destination", nil];
	NSDictionary *dgDictionary = [[NSDictionary alloc] initWithObjects:dgArray forKeys:dgArrayKeys];
	
	BoardController *board = [boardDict objectForKey:[dgDictionary objectForKey:@"gamenumber"]];
	
	if ([[dgDictionary objectForKey:@"datagram"] intValue] == DG_ARROW) {
		[board appendChat:[NSString stringWithFormat:@"%@ draws an arrow from %@ to %@\n", [dgDictionary objectForKey:@"examiner"], 
						   [dgDictionary objectForKey:@"origin"], [dgDictionary objectForKey:@"destination"]]
			   attributes:attributes];
		[board arrowFrom:[dgDictionary objectForKey:@"origin"] to:[dgDictionary objectForKey:@"destination"]];
	}
	else {
		[board appendChat:[NSString stringWithFormat:@"%@ deletes the arrow from %@ to %@\n", [dgDictionary objectForKey:@"examiner"], 
						   [dgDictionary objectForKey:@"origin"], [dgDictionary objectForKey:@"destination"]]
			   attributes:attributes];
		[board unarrowFrom:[dgDictionary objectForKey:@"origin"] to:[dgDictionary objectForKey:@"destination"]];
	}
	
	[dgDictionary release];
	[dgArrayKeys release];
}


/*
69 DG_LOGIN_FAILED
(code explanation-string)
When the user's client gives us a name and password on the same line,
we should get either issue DG_WHO_AM_I indicating success, or 
one of these.  Maybe we send them in some of the password-on-separate-line
cases too.  Codes and explanation strings are currently as follows:

1 To register, please connect to the main server (chessclub.com).
2 Sorry, names may be at most 15 characters long.  Try again.
3 A name should be at least two characters long!  Try again.
4 Sorry, a name must begin with a letter and consist of letters and digits.  Try again.
5 <name> is a registered name.  If it is yours, type the password.
6 <name> is not a registered name.  [and you gave a password] 
7 <name> is not a registered name.  [n filtered]
8 <name> is not a registered name.  [but okay, hit return to enter]
9 Try again.    [user typed null password]
10 Something is wrong.
11 Invalid password.
12 The administrators have banned you from using this chess server.
13 Something is wrong.
14 <name>, whose name matches yours, is already logged in.  Sorry.
15 StratLabs client trial expired.
16 Sorry, but this server cannot process account renewals or new accounts. Please connect
to the main ICC server, chessclub.com, in order to activate your membership
17 The chess server is currently only admitting registered players.
18 The chess server is currently only admitting registered players. [full, no unregs
allowed on queue]
19 The chess server is full.  [quota]
20 You have entered the queue.  Your current position is %d.
21 To register, please use our web page www.chessclub.com/register.
22 The <name> account is restricted to using Blitzin and only on one particular computer.
*/
- (void)loginFailed:(id)dgArray
{
	NSArray *dgArrayKeys = [[NSArray alloc] 
							initWithObjects:@"datagram", @"code", @"explanation-string", nil];
	NSDictionary *dgDictionary = [[NSDictionary alloc] initWithObjects:dgArray forKeys:dgArrayKeys];
	
	
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert addButtonWithTitle:@"OK"];
	[alert setMessageText:@"Login Failed"];
	[alert setInformativeText:[dgDictionary objectForKey:@"explanation-string"]];
	[alert setAlertStyle:NSWarningAlertStyle];
	//[alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
	[alert runModal];
	
	[self showLoginSheet:self];
	
	[dgDictionary release];
	[dgArrayKeys release];
}
					  

/*
 72 DG_GAMELIST_BEGIN
 (command {parameters} nhits first last {summary})
 command is one of search, history, liblist, or stored.
 parameters were the arguments to the command.
 nhits is the number of items in the list, but in the case of search
 (and possibly in future in the case of libraries) we don't
 necessarily show you the whole list.  E.g. maybe we'll show
 items 1-20 (if your "height" is 24) and in that case first=1,
 last=20, and "more" can be used.  "First" is usually 1, not the
 the index of the first DG_GAMELIST_ITEM.  (Those indices are
 too screwy, wrapping modulo 100 in the case of history, and
 skipping integers in the case of libraries.)
 */
- (void)gamelistBegin:(id)dgArray
{
	NSArray *dgArrayKeys = [[NSArray alloc] 
							initWithObjects:@"datagram", @"command", @"parameters", @"nhits", @"first", @"last", @"summary", nil];
	NSDictionary *dgDictionary = [[NSDictionary alloc] initWithObjects:dgArray forKeys:dgArrayKeys];

	currentGameList = [[GameListController alloc] init];
	
	if ([[dgDictionary objectForKey:@"command"] isEqualToString:@"history"]) {
		if (  ! [NSBundle loadNibNamed:@"GameListHistory" owner:currentGameList] ) {
			NSLog(@"Nib for GameListHistory failed to load");
			currentGameList = nil;
		} else {
			[currentGameList setCallback:self];
			[gameListArray addObject:currentGameList];
			[currentGameList setListInfo:dgDictionary];
		}
	}
	else {
		if (  ! [NSBundle loadNibNamed:@"GameList" owner:currentGameList] ) {
			NSLog(@"Nib for GameList failed to load");
			currentGameList = nil;
		} else {
			[currentGameList setCallback:self];
			[gameListArray addObject:currentGameList];
			[currentGameList setListInfo:dgDictionary];
		}
	}
	[dgDictionary release];
	[dgArrayKeys release];
}


/*
 73 DG_GAMELIST_ITEM
 (index id event date time white-name white-rating black-name black-rating rated rating-type
 wild init-time-W inc-W init-time-B inc-B eco status color mode {note} here) 
 E.g. "16 898117179 ? 1998.06.17 16:59:39 heatwave 2461 SaabMaster 2383 1
 1 0 3 0 3 0 B90 0 0 0 0 {}"
 The index is a history number, search hit number, liblist index, or adjourned game index.
 The id is ICC's internal game id, and can be used e.g. "examine #898117179".
 Any fields containing spaces will be quoted with curly braces. 
 Unknown fields (or parts of a field in case of date & time) are given as ?, as per PGN.
 Event is usually ?, but could be a tournament id (typically 7 characters or less).
 Date is in the form YYYY.MM.DD, time is in the form HH:MM:SS (as per PGN spec),
 this is when the game started (and the format is as in PGN spec).
 Names are at most 15 characters, but are not necessarily ICC user names.
 Ratings may be - (meaning unrated) or numerical or ? (unknown).
 Rating-type is a small integer.  For now, 0=wild, 1=blitz, 2=standard,
 3=bullet, 4=bughouse.  But see DG_RATING_TYPE_KEY.
 A time control given as "-" means untimed.
 Status, color, and mode are how ICC records a game result or adjournment:
 Status is 0=win 1=draw 2=adjourned 3=abort.
 Color is 0=black 1=white, and is the side that lost (for status 0) or maybe acted.
 Mode is a small integer, and the meanings of the various status-mode pairs are
 (Assume color is 0 for these, and the 3-letter code is just what is in history output):
 status 0:
 mode 0:  (Res) Black resigns
 mode 1:  (Mat) Black checkmated
 mode 2:  (Fla) Black forfeits on time.
 mode 3:  (Adj) White declared the winner by adjudication
 mode 4:  (BQ)  Black disconnected and forfeits
 mode 5:  (BQ)  Black got disconnected and forfeits
 mode 6:  (BQ)  Unregistered player Black disconnected and forfeits
 mode 7:  (Res) Black's partner resigns
 mode 8:  (Mat) Black's partner checkmated
 mode 9:  (Fla) Black's partner forfeits on time
 mode 10: (BQ)  Black's partner disconnected and forfeits
 mode 11: (BQ)  Black disconnected and forfeits [obsolete?]
 mode 12: (1-0) White wins [specific reason unknown]
 status 1:
 mode 0:  (Agr) Game drawn by mutual agreement
 mode 1:  (Sta) Black stalemated
 mode 2:  (Rep) Game drawn by repetition
 mode 3:  (50)  Game drawn by the 50 move rule
 mode 4:  (TM)  Black ran out of time and White has no material to mate
 mode 5:  (NM)  Game drawn because neither player has mating material
 mode 6:  (NT)  Game drawn because both players ran out of time
 mode 7:  (Adj) Game drawn by adjudication
 mode 8:  (Agr) Partner's game drawn by mutual agreement
 mode 9:  (NT)  Partner's game drawn because both players ran out of time
 mode 10: (1/2) Game drawn [specific reason unknown]
 status 2:
 mode 0:  (?)   Game adjourned by mutual agreement
 mode 1:  (?)   Game adjourned when Black disconnected
 mode 2:  (?)   Game adjourned by system shutdown
 mode 3:  (?)   Game courtesyadjourned by Black
 mode 4:  (?)   Game adjourned by an administrator
 mode 5:  (?)   Game adjourned when Black got disconnected
 status 3:
 mode 0:  (Agr) Game aborted by mutual agreement
 mode 1:  (BQ)  Game aborted when Black disconnected
 mode 2:  (SD)  Game aborted by system shutdown
 mode 3:  (BA)  Game courtesyaborted by Black
 mode 4:  (Adj) Game aborted by an administrator
 mode 5:  (Sho) Game aborted because it's too short to adjourn
 mode 6:  (BQ)  Game aborted when Black's partner disconnected
 mode 7:  (Sho) Game aborted by Black at move 1
 mode 8:  (Sho) Game aborted by Black's partner at move 1
 mode 9:  (Sho) Game aborted because it's too short
 mode 10: (Adj) Game aborted because Black's account expired
 mode 11: (BQ)  Game aborted when Black got disconnected
 mode 12: (?)   No result [specific reason unknown]
 
 Note is the libannotate string that sometimes accompanies a library game.
 Here is 1 if it's a stored list and opponent is present, otherwise 0.
 */
- (void) gamelistItem:(id)dgArray
{
	NSArray *dgArrayKeys = [[NSArray alloc] 
							initWithObjects:@"datagram", @"index", @"id", @"event", @"date", @"time", @"white-name", @"white-rating", 
							@"black-name", @"black-rating", @"rated", @"rating-type", @"wild", @"init-time-W", @"int-W", 
							@"init-time-B", @"int-B", @"eco", @"status", @"color", @"mode", @"note", @"here", nil];
	NSDictionary *dgDictionary = [[NSDictionary alloc] initWithObjects:dgArray forKeys:dgArrayKeys];
	
	[currentGameList addGame:dgDictionary];
	
	[dgDictionary release];
	[dgArrayKeys release];
}


/*
 77 DG_GAME_MESSAGE
 (gamenumber string)
 Encapsulates the text generated by miscellaneous commands that
 affect a particular game, e.g. mexamine, setwhiteclock, draw.
 [Implementation may be complete or redundant with other DGs?]
 */
- (void)gameMessage:(id)dgArray
{
	NSArray *dgArrayKeys = [[NSArray alloc] initWithObjects:@"datagram", @"gamenumber", @"string", nil];
	NSDictionary *dgDictionary = [[NSDictionary alloc] initWithObjects:dgArray forKeys:dgArrayKeys];
	
	BoardController *board = [boardDict objectForKey:[dgDictionary objectForKey:@"gamenumber"]];

	[board appendChat:[dgDictionary objectForKey:@"string"] attributes:attributes];
	/*
	if ([[dgDictionary objectForKey:@"string"] rangeOfString:@"sets White's name to"] != NSNotFound) {
		//[board setBlackPlayer:<#(NSString *)bp#> withRating: title:<#(NSString *)t#>
	}
	else ([[dgDictionary objectForKey:@"string"] rangeOfString:@"sets Black's name to"] != NSNotFound) {
		;
	}
*/	
	[dgDictionary release];
	[dgArrayKeys release];
}


/*
 86 DG_LOG_PGN
 Sent only in response to the logpgn command.  The contents
 are the PGN form of the game, one ^Y{quoted^Y} argument per
 line.
 */
- (void)logPGN:(id)dgArray
{
	[dgArray retain];
		
	NSString *pgnString = @"";
	
	for (int i = 1; i < [dgArray count]; i++) {
		pgnString = [pgnString stringByAppendingFormat:@"%@\n", [dgArray objectAtIndex:i]];
	}
	
	currentGameList = nil;
	
	
	for (GameListController *glc in gameListArray) {
		if ([[glc window] isKeyWindow]) {
			currentGameList = glc;
			break;
		}
	}
	
	if (currentGameList) {
		NSSavePanel *panel = [NSSavePanel savePanel];
		[panel setRequiredFileType:@"pgn"];
		[panel beginSheetForDirectory:nil 
								 file:nil 
					   modalForWindow:[currentGameList window] 
						modalDelegate:self 
					   didEndSelector:@selector(didEnd:returnCode:contextInfo:) 
						  contextInfo:[pgnString copy]];

	}
	else {
		NSSavePanel *panel = [NSSavePanel savePanel];
		[panel setRequiredFileType:@"pgn"];
		[panel beginSheetForDirectory:nil 
								 file:nil 
					   modalForWindow:consoleWindow 
						modalDelegate:self 
					   didEndSelector:@selector(didEnd:returnCode:contextInfo:) 
						  contextInfo:[pgnString copy]];

	}
		
	[dgArray release];
}

// Helper function for logPGN:
- (void)didEnd:(NSSavePanel *)sheet returnCode:(int)code contextInfo:(void *)contextInfo
{
	if (code != NSOKButton)
		return;
		
	NSData *data = [(NSString *)contextInfo dataUsingEncoding:NSUTF8StringEncoding];
	NSString *path = [sheet filename];
	NSError *error;
	BOOL successful = [data writeToFile:path options:0 error:&error];
	
	if (!successful) {
		NSAlert *a = [NSAlert alertWithError:error];
		[a runModal];
	}
	
}



/*
 101 DG_POSITION_BEGIN
 (gamenumber {initial-FEN} nmoves-to-follow)
 Designed as a replacement for DG_MOVE_LIST.  Advantages are that
 the initial position can specify Black on move, and can specify
 castling rights, en passant legality, and initial move number
 (but you could ignore the move number if you want).  And also
 DG_MOVE_LIST was sometimes too big for a really long game, while
 with this method no DG is excessively long.  If you have this on and
 also have DG_SEND_MOVES on, then you get this followed by
 nmoves-to-follow DG_SEND_MOVES.  If the initial position is the
 standard one, the initial-FEN field can be null (but don't count on it).
 DG_POSITION_BEGIN2 might be slightly more convenient.
 */
- (void)positionBegin:(id)dgArray
{
	NSArray *dgArrayKeys = [[NSArray alloc] initWithObjects:@"datagram", @"gamenumber", @"initial-FEN", @"nmoves-to-follow", nil];
	NSDictionary *dgDictionary = [[NSDictionary alloc] initWithObjects:dgArray forKeys:dgArrayKeys];
	
	BoardController *board = [boardDict objectForKey:[dgDictionary objectForKey:@"gamenumber"]];
	
	[board numMovesToFollow:[[dgDictionary objectForKey:@"nmoves-to-follow"] intValue]];
	[board setFen:[dgDictionary objectForKey:@"initial-FEN"]];
	
	
	[dgDictionary release];
	[dgArrayKeys release];
}


@end
