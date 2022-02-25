//
//  BoardController.m
//  ICC Test App
//

#import "BoardController.h"


@implementation BoardController

//@synthesize topPlayer;
//@synthesize bottomPlayer;

static NSString *FlipToolbarItemIdentifier = @"My Flip Toolbar Item";

static NSString *DrawToolbarItemIdentifier = @"My Draw Toolbar Item";
static NSString *ResignToolbarItemIdentifier = @"My Resign Toolbar Item";
static NSString *AbortToolbarItemIdentifier = @"My Abort Toolbar Item";
static NSString *AdjournToolbarItemIdentifier = @"My Adjourn Toolbar Item";

static NSString *FlagToolbarItemIdentifier = @"My Flag Toolbar Item";
static NSString *Moretime60ToolbarItemIdentifier = @"My Moretime Sixty Toolbar Item";

static NSString *TakebackToolbarItemIdentifier = @"My Takeback Toolbar Item";
static NSString *Takeback2ToolbarItemIdentifier = @"My Takeback Two Toolbar Item";

static NSString *RevertToolbarItemIdentifier = @"My Revert Toolbar Item";
static NSString *BackToolbarItemIdentifier = @"My Back Toolbar Item";
static NSString *ForwardToolbarItemIdentifier = @"My Forward Toolbar Item";
static NSString *StartToolbarItemIdentifier = @"My Start Toolbar Item";
static NSString *EndToolbarItemIdentifier = @"My End Toolbar Item";

- (id)init
{
	if (![super init])
		return nil;
	
	
	promotionString = [[NSString alloc] init];
	
	whiteMove = YES;
	whiteAtBottom = YES;
	numMoves = 1;
	
	whiteClock = 100000;
	blackClock = 100000;

	whiteArray = [[NSMutableArray alloc] init];
	blackArray = [[NSMutableArray alloc] init];

	[topResult setTextColor:[NSColor whiteColor]];
	[bottomResult setTextColor:[NSColor whiteColor]];
	
	[topResult setStringValue:@" "];
	[bottomResult setStringValue:@" "];
	[topClock setStringValue:@"0:00"];
	[bottomClock setStringValue:@"0:00"];
	
	positionsArray = [[NSMutableArray alloc] init];
	
	[row1 setStringValue:@"A"];
	[row2 setStringValue:@"B"];
	[row3 setStringValue:@"C"];
	[row4 setStringValue:@"D"];
	[row5 setStringValue:@"E"];
	[row6 setStringValue:@"F"];
	[row7 setStringValue:@"G"];
	[row8 setStringValue:@"H"];
	
	[col1 setStringValue:@"1"];
	[col2 setStringValue:@"2"];
	[col3 setStringValue:@"3"];
	[col4 setStringValue:@"4"];
	[col5 setStringValue:@"5"];
	[col6 setStringValue:@"6"];
	[col7 setStringValue:@"7"];
	[col8 setStringValue:@"8"];
	
	[boardView setDelegate:self];
	
	return self;
}


- (void)awakeFromNib
{	
	[movesGCTableView setTarget:self];
	[movesGCTableView setAction:@selector(clickedMoveList:)];
	
	[[self window] setContentAspectRatio:NSMakeSize(1.0, 1.0)];
	
	playToolbar = [[NSToolbar alloc] initWithIdentifier:@"play toolbar"];
	examineToolbar = [[NSToolbar alloc] initWithIdentifier:@"examine toolbar"];
	observeToolbar = [[NSToolbar alloc] initWithIdentifier:@"observe toolbar"];
	
	[examineToolbar setAllowsUserCustomization:NO];
	[examineToolbar setAutosavesConfiguration:YES];
	[examineToolbar setDisplayMode:NSToolbarDisplayModeDefault];
	[examineToolbar setSizeMode:NSToolbarSizeModeSmall];
	[examineToolbar setDelegate:self];
	
	[playToolbar setAllowsUserCustomization:NO];
	[playToolbar setAutosavesConfiguration:YES];
	[playToolbar setDisplayMode:NSToolbarDisplayModeDefault];
	[playToolbar setSizeMode:NSToolbarSizeModeSmall];
	[playToolbar setDelegate:self];
	
	[observeToolbar setAllowsUserCustomization:NO];
	[observeToolbar setAutosavesConfiguration:YES];
	[observeToolbar setDisplayMode:NSToolbarDisplayModeDefault];
	[observeToolbar setSizeMode:NSToolbarSizeModeSmall];
	[observeToolbar setDelegate:self];
	
	
}

- (void)dealloc
{
	[whiteArray release];
	[blackArray release];
	[positionsArray release];
	[promotionString release];
	
	[playToolbar release];
	[examineToolbar release];
	[observeToolbar release];
	
	[super dealloc];
}

- (void)setBoardDelegate:(id)d
{
	boardDelegate = d;
}

- (void)setGameNumber:(NSString *)gn 
{
	[gn retain];
	gamenumber = gn;
	[gn release];
}

- (NSString *)gameNumber
{
	return gamenumber;
}

- (void)setRated:(NSString *)ratedStr type:(NSString *)ratingTypeStr
{
	[ratedStr retain];
	[ratingTypeStr retain];
	
	if ([ratedStr intValue] == 1)
		rated = YES;
	else
		rated = NO;
	
	ratingType = [ratingTypeStr copy];

	[ratedStr release];
	[ratingTypeStr release];
}

- (void)setInitialClock:(NSString *)clockStr initialIncrement:(NSString *)incrementStr
{
	[clockStr retain];
	[incrementStr retain];
	
	initialClock = [clockStr intValue];
	increment = [incrementStr intValue];
	
	[clockStr release];
	[incrementStr release];
}
	
	
- (void)setFen:(NSString *)f
{
	NSArray *fArray = [f componentsSeparatedByString:@" "];
	
//	for(NSString *abc in fArray)
//		NSLog(abc);
	
	if ([fArray count] > 1) {
		if ([[fArray objectAtIndex:1] compare:@"w"] == NSOrderedSame) {
			whiteMove = YES;
		}
		else if ([[fArray objectAtIndex:1] compare:@"b"] == NSOrderedSame) {
			whiteMove = NO;
		}
		else
			whiteMove = YES;
	}
	
	
	// this is pretty much triggered if a custom position is set
	// such as placing a piece in an examined game.
	// in that case, the custom position becomes the default position with no previous moves
	if ([fArray count] >= 6) {
		numMoves = [[fArray objectAtIndex:5] intValue];
		[whiteArray removeAllObjects];
		[blackArray removeAllObjects];
		if (!whiteMove)
			[whiteArray addObject:@"..."];
	}
	else {
		numMoves = 0;
		[whiteArray removeAllObjects];
		[blackArray removeAllObjects];
	}
		
	
	[boardView externalSetFen:[NSString stringWithFormat:@"%@ ",[fArray objectAtIndex:0]]];
	
}

- (void)reset 
{
	status = 2;
	numMoves = 1;
	whiteMove = YES;
	whiteAtBottom = YES;
	whiteClock = 0;
	blackClock = 0;
	whiteTitle = @"";
	blackTitle = @"";
	
	[positionsArray removeAllObjects];
	
	[topResult setStringValue:@""];
	[bottomResult setStringValue:@""];
	
	[whiteArray removeAllObjects];
	[blackArray removeAllObjects];
	
	[movesGCTableView reloadData];
	
	[whitePromotionWindow setIsVisible:NO];
	[blackPromotionWindow setIsVisible:NO];
	
	[boardView reset];
}

- (void)setWildNumber:(int)wn
{
	wildNumber = wn;
	[boardView setWildNumber:wildNumber];
}


- (void)setNumMoves:(long)nm
{
	numMoves = nm;
}

- (void)setWhiteMove:(BOOL)move
{
	whiteMove = move;
}

- (void)setBlackPlayer:(NSString*)bp withRating:(NSString *)br title:(NSString *)t
{
	[bp retain];
	[br retain];
	[t retain];
	blackPlayer = [bp copy];

	NSLog(@"black player: %@", bp);
		
	blackPlayerAndRating = ([t length] == 0 ? [NSString stringWithFormat:@"%@ (%@)", blackPlayer, [br copy]] : 
							[NSString stringWithFormat:@"%@ %@ (%@)", [t copy], blackPlayer, [br copy]]);
	
	blackTitle = [t copy];
	
	if (whiteAtBottom)
		[topPlayer setStringValue:blackPlayerAndRating];
	else
		[bottomPlayer setStringValue:blackPlayerAndRating];
	[bp release];
	[br release];
	[t release];
}
- (void)setWhitePlayer:(NSString *)wp withRating:(NSString *)wr title:(NSString *)t
{
	[wp retain];
	[wr retain];
	[t retain];
	
	whitePlayer = [wp copy];
	
	NSLog(@"white player: %@", wp);
	
	whitePlayerAndRating = ([t length] == 0 ? [NSString stringWithFormat:@"%@ (%@)", whitePlayer, [wr copy]] : 
							[NSString stringWithFormat:@"%@ %@ (%@)", [t copy], whitePlayer, [wr copy]]);

	whiteTitle = [t copy];
	
	if (whiteAtBottom)
		[bottomPlayer setStringValue:whitePlayerAndRating];
	else
		[topPlayer setStringValue:whitePlayerAndRating];
	
	[wp release];
	[wr release];
	[t release];
}

- (NSString *)getBlackPlayer
{
	return blackPlayer;
}

- (NSString *)getWhitePlayer 
{
	return whitePlayer;
}


- (void)algebraicMove:(NSString *)algebraic smithMove:(NSString *)smith
{
	[boardView move:smith];
	
	[positionsArray addObject:[boardView fen]];
	
	if (whiteMove) {
		[whiteArray addObject:algebraic];	
		whiteMove = NO;
	}
	else {
		[blackArray addObject:algebraic];

		whiteMove = YES;
		numMoves++;
	}

	if (whiteMove && whiteAtBottom || !whiteMove && !whiteAtBottom) {
		[bottomClock setBackgroundColor:[NSColor darkGrayColor]];
		[bottomClock setTextColor:[NSColor whiteColor]];
		[topClock setBackgroundColor:[NSColor windowBackgroundColor]];
		//[topClock setTextColor:[NSColor blackColor]];
		[topClock setTextColor:[NSColor grayColor]];
		[bottomResult setBackgroundColor:[NSColor blackColor]];
		[topResult setBackgroundColor:[NSColor windowBackgroundColor]];

	}
	else {
		[topClock setBackgroundColor:[NSColor darkGrayColor]];
		[topClock setTextColor:[NSColor whiteColor]];
		[bottomClock setBackgroundColor:[NSColor windowBackgroundColor]];
		//[bottomClock setTextColor:[NSColor blackColor]];
		[bottomClock setTextColor:[NSColor grayColor]];
		[topResult setBackgroundColor:[NSColor blackColor]];
		[bottomResult setBackgroundColor:[NSColor windowBackgroundColor]];

	}
	
	[movesGCTableView reloadData];
	
	if ([whiteArray count] > [blackArray count]) {
		[movesGCTableView selectRow:[whiteArray count] - 1 column:1];	
	}
	else
		[movesGCTableView selectRow:[blackArray count] - 1 column:2];	
	
}

- (void)takeback:(int)takebackCount
{
	[positionsArray removeLastObject];
	
	for (int i=0; i<takebackCount; i++) {
		[boardView takeback];
		
		// erase moves in the movesTableView
		// if length of blackmoves is equal to length of whitemoves,
		// we remove the last blackmove. Otherwise we remove the last whitemove.
		if ([blackArray count] == [whiteArray count]) {
			NSLog(@"taking back black");
			[blackArray removeLastObject];
			whiteMove = NO;
			numMoves--;
		}
		else {
			NSLog(@"taking back white");
			[whiteArray removeLastObject];
			whiteMove = YES;
		}
			
		// refresh the movesTableView
		[movesGCTableView reloadData];

		if ([blackArray count] == [whiteArray count]) 
			[movesGCTableView selectRow:[blackArray count] - 1 column:2];
		else
			[movesGCTableView selectRow:[whiteArray count] - 1 column:1];
		
		// make sure the clock background color changes along with the takeback
		if (whiteMove && whiteAtBottom || !whiteMove && !whiteAtBottom) {
			[bottomClock setBackgroundColor:[NSColor darkGrayColor]];
			[bottomClock setTextColor:[NSColor whiteColor]];
			[topClock setBackgroundColor:[NSColor windowBackgroundColor]];
			//[topClock setTextColor:[NSColor blackColor]];
			[topClock setTextColor:[NSColor grayColor]];
			[bottomResult setBackgroundColor:[NSColor blackColor]];
			[topResult setBackgroundColor:[NSColor windowBackgroundColor]];

		}
		else {
			[topClock setBackgroundColor:[NSColor darkGrayColor]];
			[topClock setTextColor:[NSColor whiteColor]];
			[bottomClock setBackgroundColor:[NSColor windowBackgroundColor]];
			//[bottomClock setTextColor:[NSColor blackColor]];
			[bottomClock setTextColor:[NSColor grayColor]];
			[topResult setBackgroundColor:[NSColor blackColor]];
			[bottomResult setBackgroundColor:[NSColor windowBackgroundColor]];

			
		}
		
	}
}

- (void)setClock:(NSString *)clock
{
	long long time;
	
	NSScanner* scanner = [NSScanner scannerWithString:clock];
	long long valueToGet;
	if([scanner scanLongLong:&valueToGet] == YES) {
		time = valueToGet;
	}
	else
		time = 0;
	
	
	if (whiteMove) {
		whiteClock = time;
		[self setWhiteClock:valueToGet];
	}
	else {
		blackClock = time;
		[self setBlackClock:valueToGet];
	}
}

- (void)setWhiteClock:(long long)wc
{
	whiteClock = wc;
	
	int minutes = whiteClock/60;
	int seconds = whiteClock%60;
	
	NSString *clockStr = [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
	
	if (whiteAtBottom)
		[bottomClock setStringValue:clockStr];
	else
		[topClock setStringValue:clockStr];
}

- (void) setBlackClock:(long long)bc
{
	blackClock = bc;

	
	int minutes = blackClock/60;
	int seconds = blackClock%60;
	
	NSString *clockStr = [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
	
	if (whiteAtBottom)
		[topClock setStringValue:clockStr];
	else
		[bottomClock setStringValue:clockStr];
}

- (void)appendChat:(NSString *)chatStr attributes:(NSMutableDictionary *)a;
{
	
	
	NSTextStorage *ts = [chatView textStorage];
	
	float scrollerPosition = [[[chatView enclosingScrollView] verticalScroller] floatValue];
	
	NSString *chatStrN = [chatStr retain];
	
	// if attributes are appended
	if (a != nil) {
		NSAttributedString *aString = [[NSAttributedString alloc] initWithString:chatStrN attributes:a];
		[ts appendAttributedString:aString];
		[aString release];
	}
	else {
		NSMutableDictionary *a2 = [[NSMutableDictionary alloc] init];
		//[a2 setObject:[NSFont fontWithName:@"Bitstream Vera Sans Mono"  size:12.0] forKey:NSFontAttributeName];
		[a2 setObject:[NSFont fontWithName:@"Lucida Grande"  size:12.0] forKey:NSFontAttributeName];
		[a2 setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
		NSAttributedString *a2String = [[NSAttributedString alloc] initWithString:chatStrN attributes:a2];
		[ts appendAttributedString:a2String];
		[a2String release];
		[a2 release];		
	}
	
	
	if ( scrollerPosition > 0.9999 ) 
		[chatView scrollRangeToVisible:NSMakeRange([[chatView textStorage] length], 0)];
	
	
	// scroll movesView (the NSTextView) to the very bottom of the text
	[chatView scrollRangeToVisible:NSMakeRange([ts length], 0)];
}


- (void)stopClockCountDown
{
	if (countDownTimer != nil)
		[countDownTimer invalidate];
}
- (void)startClockCountDown
{
	countDownTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(countDown) userInfo:nil repeats:YES];
}

- (void)countDown
{
	int minutes, seconds;
	
	if (whiteMove && status != 1) {
		whiteClock -= 1;
		minutes = whiteClock/60;
		seconds = whiteClock%60;
		if (whiteAtBottom)
			[bottomClock setStringValue:[NSString stringWithFormat:@"%02d:%02d", minutes, seconds]];
		else
			[topClock setStringValue:[NSString stringWithFormat:@"%02d:%02d", minutes, seconds]];
			
	}
	else if (!whiteMove && status != 1) {
		blackClock -= 1;
		minutes = blackClock/60;
		seconds = blackClock%60;
		if (whiteAtBottom)
			[topClock setStringValue:[NSString stringWithFormat:@"%02d:%02d", minutes, seconds]];
		else
			[bottomClock setStringValue:[NSString stringWithFormat:@"%02d:%02d", minutes, seconds]];
	}
}

- (void)gameResult:(NSString *)resultStr
{
	[resultStr retain];
	
	// stop counting down the clocks
	if (countDownTimer != nil) {
		[countDownTimer invalidate];
		countDownTimer = nil;
	}
		
	// set clock background color to window's color and set clock text color to black
	//[bottomClock setTextColor:[NSColor blackColor]];
	[bottomClock setTextColor:[NSColor grayColor]];
	//[topClock setTextColor:[NSColor blackColor]];
	[topClock setTextColor:[NSColor grayColor]];
	[bottomClock setBackgroundColor:[NSColor windowBackgroundColor]];
	[topClock setBackgroundColor:[NSColor windowBackgroundColor]];
	[bottomResult setBackgroundColor:[NSColor windowBackgroundColor]];
	[topResult setBackgroundColor:[NSColor windowBackgroundColor]];
	
	[bottomResult setTextColor:[NSColor whiteColor]];
	[topResult setTextColor:[NSColor whiteColor]];
	
	//[movesView setFont:[NSFont fontWithName:@"Helvetica Neue" size:12.0]];
	
	if ([resultStr isEqualToString:@"1-0"]) {
		if (whiteAtBottom) {
			[bottomResult setStringValue:@"\u2713"];
			[topResult setStringValue:@""];
		}
		else {
			[topResult setStringValue:@"\u2713"];
			[bottomResult setStringValue:@""];
		}
	}
	else if ([resultStr isEqualToString:@"0-1"]) {
		if (!whiteAtBottom) {
			[bottomResult setStringValue:@"\u2713"];
			[topResult setStringValue:@""];
		}
		else {
			[topResult setStringValue:@"\u2713"];
			[bottomResult setStringValue:@""];
		}
	}
	else if ([resultStr isEqualToString:@"1/2-1/2"]) {
		[topResult setStringValue:@"\u00BD"];
		[bottomResult setStringValue:@"\u00BD"];
	}
	else {
		[topResult setStringValue:@""];
		[bottomResult setStringValue:@""];
	}
	[resultStr release];
}

- (BV_STATUS)getStatus
{
	return status;
}

- (void)setStatus:(BV_STATUS)s
{
	NSLog(@"setting status to:%i", s);
	status = s;
	
	if (status == 0) {
		if (countDownTimer != nil) {
			[countDownTimer invalidate];
			countDownTimer = nil;
		}
		
		// set clock background color to window's color and set clock text color to black
		//[bottomClock setTextColor:[NSColor blackColor]];
		[bottomClock setTextColor:[NSColor grayColor]];
		//[topClock setTextColor:[NSColor blackColor]];
		[topClock setTextColor:[NSColor grayColor]];
		[bottomClock setBackgroundColor:[NSColor windowBackgroundColor]];
		[topClock setBackgroundColor:[NSColor windowBackgroundColor]];
		[bottomResult setBackgroundColor:[NSColor windowBackgroundColor]];
		[topResult setBackgroundColor:[NSColor windowBackgroundColor]];
	}		
	
	
	switch (status) {
		case BV_USEROBS:
			[commandButton selectItemWithTitle:@"Whisper:"];
			[[self window] setToolbar:observeToolbar];
			break;
		case BV_USEREXAMINE:
			[commandButton selectItemWithTitle:@"Command:"];
			[[self window] setToolbar:examineToolbar];
			break;
		case BV_USERWHITE:
		case BV_USERBLACK:	
			[commandButton selectItemWithTitle:@"Command:"];
			[[self window] setToolbar:playToolbar];
			break;
		default:
			[commandButton selectItemWithTitle:@"Command:"];
			[[self window] setToolbar:observeToolbar];
			break;
	}
	
	[self setWindowTitle];
	
	[boardView setStatus:s];
	
}

- (void)flip
{
	NSLog(@"flipping");
	
	whiteAtBottom = NO;
	
	[row1 setStringValue:@"H"];
	[row2 setStringValue:@"G"];
	[row3 setStringValue:@"F"];
	[row4 setStringValue:@"E"];
	[row5 setStringValue:@"D"];
	[row6 setStringValue:@"C"];
	[row7 setStringValue:@"B"];
	[row8 setStringValue:@"A"];
	
	[col1 setStringValue:@"8"];
	[col2 setStringValue:@"7"];
	[col3 setStringValue:@"6"];
	[col4 setStringValue:@"5"];
	[col5 setStringValue:@"4"];
	[col6 setStringValue:@"3"];
	[col7 setStringValue:@"2"];
	[col8 setStringValue:@"1"];
	
	[topPlayer setStringValue:whitePlayerAndRating];
	[bottomPlayer setStringValue:blackPlayerAndRating];
	
//	[topPlayer setTitle:whitePlayerAndRating];
//	[bottomPlayer setTitle:blackPlayerAndRating];

	
	[self setBlackClock:blackClock];
	[self setWhiteClock:whiteClock];
	
//	[topClock setStringValue:whiteClock];
//	[bottomClock setStringValue:blackClock];
	
	if (whiteMove && status > 0) {
		[topClock setBackgroundColor:[NSColor darkGrayColor]];
		[topClock setTextColor:[NSColor whiteColor]];
		[bottomClock setBackgroundColor:[NSColor windowBackgroundColor]];
		//[bottomClock setTextColor:[NSColor blackColor]];
		[bottomClock setTextColor:[NSColor grayColor]];
		[topResult setBackgroundColor:[NSColor blackColor]];
		[bottomResult setBackgroundColor:[NSColor windowBackgroundColor]];

	}
	else if (!whiteMove && status > 0) {
		[bottomClock setBackgroundColor:[NSColor darkGrayColor]];
		[bottomClock setTextColor:[NSColor whiteColor]];
		[topClock setBackgroundColor:[NSColor windowBackgroundColor]];
		//[topClock setTextColor:[NSColor blackColor]];
		[topClock setTextColor:[NSColor grayColor]];
		[bottomResult setBackgroundColor:[NSColor blackColor]];
		[topResult setBackgroundColor:[NSColor windowBackgroundColor]];

	}
	

	
	NSString *tmpBottomResult = [bottomResult stringValue];
	[bottomResult setStringValue:[topResult stringValue]];
	[topResult setStringValue:tmpBottomResult];
	[tmpBottomResult release];
		
	
	[boardView flip:YES];
}

- (void)unFlip;
{
	NSLog(@"flipping back");
	whiteAtBottom = YES;

	[row1 setStringValue:@"A"];
	[row2 setStringValue:@"B"];
	[row3 setStringValue:@"C"];
	[row4 setStringValue:@"D"];
	[row5 setStringValue:@"E"];
	[row6 setStringValue:@"F"];
	[row7 setStringValue:@"G"];
	[row8 setStringValue:@"H"];
	
	[col1 setStringValue:@"1"];
	[col2 setStringValue:@"2"];
	[col3 setStringValue:@"3"];
	[col4 setStringValue:@"4"];
	[col5 setStringValue:@"5"];
	[col6 setStringValue:@"6"];
	[col7 setStringValue:@"7"];
	[col8 setStringValue:@"8"];
	
	[bottomPlayer setStringValue:whitePlayerAndRating];
	[topPlayer setStringValue:blackPlayerAndRating];
	
//	[bottomPlayer setTitle:whitePlayerAndRating];
//	[topPlayer setTitle:blackPlayerAndRating];
	
	[self setBlackClock:blackClock];
	[self setWhiteClock:whiteClock];
	
	
//	[bottomClock setStringValue:whiteClock];
//	[topClock setStringValue:blackClock];
	
	if (!whiteMove && status > 0) {
		[topClock setBackgroundColor:[NSColor darkGrayColor]];
		[topClock setTextColor:[NSColor whiteColor]];
		[bottomClock setBackgroundColor:[NSColor windowBackgroundColor]];
		//[bottomClock setTextColor:[NSColor blackColor]];
		[bottomClock setTextColor:[NSColor grayColor]];
		[topResult setBackgroundColor:[NSColor blackColor]];
		[bottomResult setBackgroundColor:[NSColor windowBackgroundColor]];

	}
	else if (whiteMove && status > 0) {
		[bottomClock setBackgroundColor:[NSColor darkGrayColor]];
		[bottomClock setTextColor:[NSColor whiteColor]];
		[topClock setBackgroundColor:[NSColor windowBackgroundColor]];
		//[topClock setTextColor:[NSColor blackColor]];
		[topClock setTextColor:[NSColor grayColor]];
		[bottomResult setBackgroundColor:[NSColor blackColor]];
		[topResult setBackgroundColor:[NSColor windowBackgroundColor]];

	}

	NSString *tmpBottomResult = [bottomResult stringValue];
	[bottomResult setStringValue:[topResult stringValue]];
	[topResult setStringValue:tmpBottomResult];
	[tmpBottomResult release];
	
	[boardView flip:NO];
}

- (void)kibitz:(NSString *)kibStr
{
	[self appendChat:kibStr attributes:nil];
}

- (void)illegalMove
{
	NSLog(@"boardcontroller illegalmove");
	
	[boardView illegalMove];
}

- (void)numMovesToFollow:(int)num 
{
	[boardView numMovesToFollow:num];
}

- (void)circle:(NSString *)coordinate
{
	[boardView circle:coordinate];
}

- (void)arrowFrom:(NSString *)fromS to:(NSString *)toS
{
	[boardView arrowFrom:fromS to:toS];
}

- (void)unarrowFrom:(NSString *)fromS to:(NSString *)toS
{
	[boardView unarrowFrom:fromS to:toS];
}

- (BOOL)windowShouldClose:(id)sender
{
	NSLog(@"windowShouldClose");
	
	if ( status == BV_USERWHITE || status == BV_USERBLACK) {
		NSBeginAlertSheet(@"You are currently playing a game.", 
						  @"Cancel", 
						  nil, 
						  @"Close this Window and Resign", 
						  [self window], 
						  self, 
						  @selector(sheetDidEndShouldClose:returnCode:contextInfo:), 
						  NULL, sender, 
						  @"Closing the window will resign your game.");
		return NO;
	}
	else {
		return YES;
	}
}

- (void)sheetDidEndShouldClose:(NSAlert *)alert 
					returnCode:(NSInteger)returnCode
				   contextInfo:(void *)contextInfo
{
	if (returnCode != NSAlertDefaultReturn)
		[[self window] close];
		
}

- (void)windowWillClose:(NSNotification *)aNotification 
{	
	NSLog(@"board window will close");
	
	
	
	if ( status == BV_USERWHITE || status == BV_USERBLACK ) {
		NSLog(@"user is white or black");
		[boardDelegate sendCommandStr:@"resign\n"];
	} else if ( status == BV_USEREXAMINE ) {
		NSLog(@"send unexamine");
		[boardDelegate sendCommandStr:@"unexamine\n"];	
	} else if ( status == BV_USEROBS ) {
		NSLog(@"send unob");
		[boardDelegate sendCommandStr:[NSString stringWithFormat:@"unobserve %@\n", gamenumber]];
	} else {
		NSLog(@"some other status: %i", status);
	}
}

- (void)promoteFrom:(NSString *)fromString to:(NSString *)toString color:(BOOL)isWhite atPoint:(NSPoint)screenPoint
{
	promotionString = [[NSString stringWithFormat:@"%@%@=", [fromString retain], [toString retain]] retain];
	
	if (isWhite) {
		[whitePromotionWindow setFrameTopLeftPoint:screenPoint];
		[whitePromotionWindow setIsVisible:YES];
	}
	else {
		[blackPromotionWindow setFrameTopLeftPoint:screenPoint];
		[blackPromotionWindow setIsVisible:YES];
	}
}

- (IBAction)promoteToQueen:(id)sender
{
	if ([whitePromotionWindow isVisible])
		[whitePromotionWindow setIsVisible:NO];
	
	if ([blackPromotionWindow isVisible])
		[blackPromotionWindow setIsVisible:NO];
		
	[self sendCommandStr:[promotionString stringByAppendingFormat:@"Q"]];
}

- (IBAction)promoteToRook:(id)sender
{
	if ([whitePromotionWindow isVisible])
		[whitePromotionWindow setIsVisible:NO];
	
	if ([blackPromotionWindow isVisible])
		[blackPromotionWindow setIsVisible:NO];
	
	[self sendCommandStr:[promotionString stringByAppendingFormat:@"R"]];
}

- (IBAction)promoteToBishop:(id)sender
{
	if ([whitePromotionWindow isVisible])
		[whitePromotionWindow setIsVisible:NO];
	
	if ([blackPromotionWindow isVisible])
		[blackPromotionWindow setIsVisible:NO];
	
	[self sendCommandStr:[promotionString stringByAppendingFormat:@"B"]];
}

- (IBAction)promoteToKnight:(id)sender
{
	if ([whitePromotionWindow isVisible])
		[whitePromotionWindow setIsVisible:NO];
	
	if ([blackPromotionWindow isVisible])
		[blackPromotionWindow setIsVisible:NO];
	
	[self sendCommandStr:[promotionString stringByAppendingFormat:@"N"]];
}
	 

- (void)setWindowTitle
{
	NSString *initialClockStr = [NSString stringWithFormat:@"%d", initialClock];
	NSString *incrementStr = [NSString stringWithFormat:@"%d", increment];
	NSString *ratedStr;
	
	if (rated == YES)
		ratedStr = @"rated";
	else
		ratedStr = @"unrated";
	
	
	if (status == BV_USEREXAMINE) {
		[[self window] setTitle:[NSString stringWithFormat:@"Game %@: %@ %@ - %@ %@ (Examining Game)", gamenumber, whiteTitle, whitePlayer, blackTitle, blackPlayer]];
	}
	else {
		[[self window] setTitle:[NSString stringWithFormat:@"Game %@: %@ %@ - %@ %@ (%@ %@ %@ %@)", gamenumber, whiteTitle, whitePlayer, blackTitle, blackPlayer, 
							 ratedStr, ratingType, initialClockStr, incrementStr]];
	}
}

- (IBAction)sendFingerCommand:(id)sender
{
	if ([sender isEqualTo:topPlayer]) {
		if (whiteAtBottom)
			[self sendCommandStr:[NSString stringWithFormat:@"finger %@", blackPlayer]];
		else
			[self sendCommandStr:[NSString stringWithFormat:@"finger %@", whitePlayer]];
	}
	else if ([sender isEqualTo:bottomPlayer]) {
		if (whiteAtBottom)
			[self sendCommandStr:[NSString stringWithFormat:@"finger %@", whitePlayer]];
		else
			[self sendCommandStr:[NSString stringWithFormat:@"finger %@", blackPlayer]];
	}
}

- (IBAction)sendCommand:(id)sender
{	
	if ([[[commandButton selectedItem] title] isEqualToString:@"Command:"]) {
		[boardDelegate sendCommandStr:[textField stringValue]];
		NSMutableDictionary *commandAttributes = [[NSMutableDictionary alloc] init];
		[commandAttributes setObject:[NSFont fontWithName:@"Lucida Grande"  size:12.0] forKey:NSFontAttributeName];
		[commandAttributes setObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
		[self appendChat:[NSString stringWithFormat:@"cmd> %@\n", [textField stringValue]] attributes:commandAttributes];
		[commandAttributes release];
		
	}
	else if ([[[commandButton selectedItem] title] isEqualToString:@"Whisper:"]) {
		[boardDelegate sendCommandStr:[NSString stringWithFormat:@"whisperto %@ %@", gamenumber, [textField stringValue]]];	
	}
	else if ([[[commandButton selectedItem] title] isEqualToString:@"Kibitz:"]) {
		[boardDelegate sendCommandStr:[NSString stringWithFormat:@"kibitzto %@ %@", gamenumber, [textField stringValue]]];	
	}
	else if ([[[commandButton selectedItem] title] isEqualToString:@"Say:"]) {
		[boardDelegate sendCommandStr:[NSString stringWithFormat:@"say %@", [textField stringValue]]];
	}
	
	[textField setStringValue:@""];
	[textField selectText:self];
	
}
	

- (void)sendCommandStr:(NSString *)str 
{
	NSLog(@"command sent");
	
	[boardDelegate sendCommandStr:str];
}

- (IBAction)back1:(id)sender
{
	[self sendCommandStr:@"back 1"];
}

- (IBAction)forward1:(id)sender
{
	[self sendCommandStr:@"forward 1"];
}

- (IBAction)back999:(id)sender
{
	[self sendCommandStr:@"back 999"];
}

- (IBAction)forward999:(id)sender
{
	[self sendCommandStr:@"forward 999"];
}

- (IBAction)revert:(id)sender
{
	NSLog(@"sending revert");
	[self sendCommandStr:@"revert"];
}

- (IBAction)toolFlip:(id)sender
{
	[self sendCommandStr:[NSString stringWithFormat:@"flip %@", gamenumber]];
}

- (IBAction)toolDraw:(id)sender
{
	[self sendCommandStr:@"draw"];
}

- (IBAction)toolResign:(id)sender
{
	[self sendCommandStr:@"resign"];
}

- (IBAction)toolAbort:(id)sender
{
	[self sendCommandStr:@"abort"];
}

- (IBAction)toolAdjourn:(id)sender
{
	[self sendCommandStr:@"adjourn"];
}

- (IBAction)toolFlag:(id)sender
{
	[self sendCommandStr:@"flag"];
}

- (IBAction)toolMoreTimeSixty:(id)sender
{
	[self sendCommandStr:@"moretime 60"];
}

- (IBAction)toolTakeback:(id)sender
{
	[self sendCommandStr:@"takeback"];
}

- (IBAction)toolTakeback2:(id)sender
{
	[self sendCommandStr:@"takeback 2"];
}


- (NSSize)windowDidResize:(NSWindow *)sender toSize:(NSSize)frameSize
{		
	NSLog(@"resize");
	//frameSize.width = (frameSize.height);
	
	
	if ([whiteArray count] > [blackArray count]) {
		[movesGCTableView selectRow:[whiteArray count] - 1 column:1];	
	}
	else
		[movesGCTableView selectRow:[blackArray count] - 1 column:2];

	[movesGCTableView reloadData];
	
	return frameSize;
}

- (BOOL)windowShouldZoom:(NSWindow *)window toFrame:(NSRect)proposedFrame
{
	
	NSLog(@"windowShouldZoom");
	
	[boardView setNeedsDisplay:YES];
	
	return YES;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
	NSString *methodName = NSStringFromSelector(aSelector);
	//NSLog(@"respondsToSelector:%@", methodName);
	return [super respondsToSelector:aSelector];
}

#pragma mark -
#pragma mark NSToolbar delegate methods

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    
	if (toolbar == observeToolbar)
		return [NSArray arrayWithObjects:FlipToolbarItemIdentifier, nil];
	
	else if (toolbar == examineToolbar)
		return [NSArray arrayWithObjects:FlipToolbarItemIdentifier, StartToolbarItemIdentifier, BackToolbarItemIdentifier, RevertToolbarItemIdentifier, 
				ForwardToolbarItemIdentifier, EndToolbarItemIdentifier, nil];
	
	else if (toolbar == playToolbar) 
		return [NSArray arrayWithObjects:FlipToolbarItemIdentifier, DrawToolbarItemIdentifier, ResignToolbarItemIdentifier, 
				AbortToolbarItemIdentifier, AdjournToolbarItemIdentifier, FlagToolbarItemIdentifier,
				Moretime60ToolbarItemIdentifier, TakebackToolbarItemIdentifier, Takeback2ToolbarItemIdentifier, nil];
	else {
		return [NSArray arrayWithObject:nil];
	}

}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *)toolbar 
{
	if (toolbar == observeToolbar)
		return [NSArray arrayWithObjects:FlipToolbarItemIdentifier, nil];
	
	else if (toolbar == examineToolbar)
		return [NSArray arrayWithObjects:FlipToolbarItemIdentifier, StartToolbarItemIdentifier, BackToolbarItemIdentifier, RevertToolbarItemIdentifier, 
				ForwardToolbarItemIdentifier, EndToolbarItemIdentifier, nil];
	
	else if (toolbar == playToolbar) 
		return [NSArray arrayWithObjects:FlipToolbarItemIdentifier, DrawToolbarItemIdentifier, ResignToolbarItemIdentifier, 
				AbortToolbarItemIdentifier, AdjournToolbarItemIdentifier, FlagToolbarItemIdentifier,
				Moretime60ToolbarItemIdentifier, TakebackToolbarItemIdentifier, Takeback2ToolbarItemIdentifier, nil];
	else {
		return [NSArray arrayWithObject:nil];
	}
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
     itemForItemIdentifier:(NSString *)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem *toolbarItem = nil;
	
    if ([itemIdentifier isEqualTo:FlipToolbarItemIdentifier]) {
        toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
        [toolbarItem setLabel:@"Flip"];
        [toolbarItem setPaletteLabel:[toolbarItem label]];
        [toolbarItem setToolTip:@"Flip Board"];
        [toolbarItem setImage:[NSImage imageNamed:@"NSRefreshFreestandingTemplate"]];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(toolFlip:)];
    } else if ([itemIdentifier isEqualTo:DrawToolbarItemIdentifier]) {
		toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
        [toolbarItem setLabel:@"Draw"];
        [toolbarItem setPaletteLabel:[toolbarItem label]];
        [toolbarItem setToolTip:@"Offer/Accept Draw"];
        [toolbarItem setImage:[NSImage imageNamed:@"NSDotMac"]];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(toolDraw:)];		
    } else if ([itemIdentifier isEqualTo:ResignToolbarItemIdentifier]) {
		toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
        [toolbarItem setLabel:@"Resign"];
        [toolbarItem setPaletteLabel:[toolbarItem label]];
        [toolbarItem setToolTip:@"Resign Game"];
        [toolbarItem setImage:[NSImage imageNamed:@"NSStopProgressFreestandingTemplate"]];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(toolResign:)];		
    } else if ([itemIdentifier isEqualTo:AbortToolbarItemIdentifier]) {
		toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
        [toolbarItem setLabel:@"Abort"];
        [toolbarItem setPaletteLabel:[toolbarItem label]];
        [toolbarItem setToolTip:@"Abort Game"];
        [toolbarItem setImage:[NSImage imageNamed:@"NSStopProgressTemplate"]];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(toolAbort:)];		
    } else if ([itemIdentifier isEqualTo:AdjournToolbarItemIdentifier]) {
		toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
        [toolbarItem setLabel:@"Adjourn"];
        [toolbarItem setPaletteLabel:[toolbarItem label]];
        [toolbarItem setToolTip:@"Adjourn Game"];
        [toolbarItem setImage:[NSImage imageNamed:@"NSIChatTheaterTemplate"]];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(toolAdjourn:)];		
    } else if ([itemIdentifier isEqualTo:FlagToolbarItemIdentifier]) {
		toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
        [toolbarItem setLabel:@"Flag"];
        [toolbarItem setPaletteLabel:[toolbarItem label]];
        [toolbarItem setToolTip:@"Claim Win on Time"];
        [toolbarItem setImage:[NSImage imageNamed:@"NSRemoveTemplate"]];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(toolFlag:)];		
    } else if ([itemIdentifier isEqualTo:Moretime60ToolbarItemIdentifier]) {
		toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
        [toolbarItem setLabel:@"More Time 60"];
        [toolbarItem setPaletteLabel:[toolbarItem label]];
        [toolbarItem setToolTip:@"Give Your Opponent 60 More Seconds"];
        [toolbarItem setImage:[NSImage imageNamed:@"Clock.icns"]];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(toolMoreTimeSixty:)];		
    } else if ([itemIdentifier isEqualTo:TakebackToolbarItemIdentifier]) {
		toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
        [toolbarItem setLabel:@"Takeback"];
        [toolbarItem setPaletteLabel:[toolbarItem label]];
        [toolbarItem setToolTip:@"Takeback Move"];
        [toolbarItem setImage:[NSImage imageNamed:@"NSUser"]];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(toolTakeback:)];		
    } else if ([itemIdentifier isEqualTo:Takeback2ToolbarItemIdentifier]) {
		toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
        [toolbarItem setLabel:@"Takeback 2"];
        [toolbarItem setPaletteLabel:[toolbarItem label]];
        [toolbarItem setToolTip:@"Takeback 2 moves"];
        [toolbarItem setImage:[NSImage imageNamed:@"NSUserAccounts"]];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(toolTakeback2:)];		
    } else if ([itemIdentifier isEqualTo:RevertToolbarItemIdentifier]) {
		toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
        [toolbarItem setLabel:@"Revert"];
        [toolbarItem setPaletteLabel:[toolbarItem label]];
        [toolbarItem setToolTip:@"Revert Position"];
        [toolbarItem setImage:[NSImage imageNamed:@"NSRefreshFreestandingTemplate"]];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(revert:)];		
    } else if ([itemIdentifier isEqualTo:BackToolbarItemIdentifier]) {
		toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
        [toolbarItem setLabel:@"Backward"];
        [toolbarItem setPaletteLabel:[toolbarItem label]];
        [toolbarItem setToolTip:@"Move Backwards By One Move"];
        [toolbarItem setImage:[NSImage imageNamed:@"NSGoLeftTemplate"]];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(back1:)];		
    } else if ([itemIdentifier isEqualTo:ForwardToolbarItemIdentifier]) {
		toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
        [toolbarItem setLabel:@"Forward"];
        [toolbarItem setPaletteLabel:[toolbarItem label]];
        [toolbarItem setToolTip:@"Move Forwards By One Move"];
        [toolbarItem setImage:[NSImage imageNamed:@"NSGoRightTemplate"]];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(forward1:)];		
    } else if ([itemIdentifier isEqualTo:StartToolbarItemIdentifier]) {
		toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
        [toolbarItem setLabel:@"Start"];
        [toolbarItem setPaletteLabel:[toolbarItem label]];
        [toolbarItem setToolTip:@"Go To Starting Position"];
        [toolbarItem setImage:[NSImage imageNamed:@"NSGoLeftTemplate"]];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(back999:)];		
    } else if ([itemIdentifier isEqualTo:EndToolbarItemIdentifier]) {
		toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
        [toolbarItem setLabel:@"End"];
        [toolbarItem setPaletteLabel:[toolbarItem label]];
        [toolbarItem setToolTip:@"Go To Ending Position"];
        [toolbarItem setImage:[NSImage imageNamed:@"NSGoRightTemplate"]];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(forward999:)];		
    }
	
	
	
    return [toolbarItem autorelease];
}

#pragma mark -
#pragma mark movesGCTableView delegate methods

- (int)rowsForTable:(GCTableView *)gc 
{
	int c = [whiteArray count];
	
	c = ( c > 0 ? c : 1);
	
	return c;
}


- (id)stringForTable:(GCTableView *)gc forRow:(int)row column:(int)col 
{
	int wc = [whiteArray count];
	int bc = [blackArray count];
	
	if ( col == 0 )
		return [NSString stringWithFormat:@"%d.", row+1];
	else if (wc == 0)
		return nil;
	else {
		if ( row == wc ) {
			return nil;
		} else if ( row == bc ) {
			if ( col==1 ) 
				return [whiteArray objectAtIndex:row];
			else 
				return @"";
		} else {
			if ( col==1 ) 
				return [whiteArray objectAtIndex:row];
			else 
				return [blackArray objectAtIndex:row];
		}
	}
}


- (void)clickedMoveList:(id)sender
{
	int row = [movesGCTableView selectedRow];
	int col = [movesGCTableView selectedColumn];
	int pos = (row * 2) + col - 1;
	
	NSLog(@"clicked move list");
	
	if ([positionsArray count] > pos) 
		[boardView displaySetFen:[positionsArray objectAtIndex:pos]];
}

- (IBAction)moveForward:(id)sender
{
	int row = [movesGCTableView selectedRow];
	int col = [movesGCTableView selectedColumn];
	
	if (col == 1)
		col = 2;
	else {
		row++;
		col = 1;
	}
	
	if ((col == 1 && [whiteArray count] > row) || (col == 2 && [blackArray count] > row))
		[movesGCTableView selectRow:row column:col];
		
	int pos = (row * 2) + col - 1;
	
	if ([positionsArray count] > pos) 
		[boardView displaySetFen:[positionsArray objectAtIndex:pos]];
}

- (IBAction)moveBack:(id)sender 
{
	int row = [movesGCTableView selectedRow];
	int col = [movesGCTableView selectedColumn];
	
	if (col == 1) {
		col = 2;
		row--;
	}
	else {
		col = 1;
	}
	
	if ((col == 1 && [whiteArray count] > row) || (col == 2 && row >= 0 && [blackArray count] > row))
		[movesGCTableView selectRow:row column:col];
	
	int pos = (row * 2) + col - 1;
	
	if ([positionsArray count] > pos) 
		[boardView displaySetFen:[positionsArray objectAtIndex:pos]];
}

- (IBAction)moveToEnd:(id)sender
{
	int col, row;
	
	if ([blackArray count] == [whiteArray count] && [blackArray count] > 0) {
		col = 2;
		row = [blackArray count] - 1;
	}
	else if ([whiteArray count] > 0) {
		col = 1;
		row = [whiteArray count] - 1;
	}
	
	[movesGCTableView selectRow:row column:col];
	
	int pos = (row * 2) + col - 1;
	
	if ([positionsArray count] > pos) 
		[boardView displaySetFen:[positionsArray objectAtIndex:pos]];
	
}

- (IBAction)moveToStart:(id)sender
{
	int col = 1;
	int row = 0;

	[movesGCTableView selectRow:row column:col];

	int pos = (row * 2) + col - 1;

	if ([positionsArray count] > pos) 
		[boardView displaySetFen:[positionsArray objectAtIndex:pos]];
}

@end
