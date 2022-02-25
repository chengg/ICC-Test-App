//
//  BoardView.m
//  ICC Test App
//


#import "BoardView.h"

#define RANDFLOAT() (random() % 128 / 128.0)

@implementation BoardView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		
		[self setPostsFrameChangedNotifications:YES];
		
		nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self
			   selector:@selector(resizeView:)
				   name:NSViewFrameDidChangeNotification
				 object:self];
		
		
						
		capturedPieces = [[NSMutableArray alloc] init];

		
		for (int i = 0; i < 64; i++) {
			circleArray[i] = 0;
		}
		
		fromArrowArray = [[NSMutableArray alloc] init];
		toArrowArray = [[NSMutableArray alloc] init];
		
		
		// default status: dead board
		status = BV_DEAD;
		
		// no moves so far
		numHalfMoves = 0;
		
		// default is not flipped
		flipped = NO;
		prevFlip = NO;
		
		userSelectedMove = NO;
		
		// initialize moving squares to -1 to make sure we don't confuse them with real squares
		fromSquare = toSquare = -1;
		moveFromSquare = moveToSquare = -1;
		
		// no pieces moved by the user
		myMovedPiece = NO;
		
		// initialize appBundle to be the main bundle of the application
		appBundle = [NSBundle mainBundle];	
		
		// initialize each square to be empty
		for (int i=0; i<64; ++i) { 
			displayBoard[i] = BV_EMPTY;
			internalBoard[i] = BV_EMPTY;
		}
		
		
		// Initialize the array that will store every position
		positionsArray = [[NSMutableArray alloc] initWithCapacity:5];
		
		
		[self setNeedsDisplay:YES];
    }
	
    return self;
}

- (void)dealloc
{
	[capturedPieces release];
	
	
	[positionsArray release];
	[super dealloc];
}

- (void)setDelegate:(id)o
{
	bvDelegate = o;
}

- (void)awakeFromNib
{
	
	NSRect b = [self bounds];
	
	squareWidth = b.size.width / 8.0;
	squareHeight = b.size.height / 8.0;
	
	if (squareWidth > squareHeight)
		[self loadImageWithSize:squareWidth];
	else
		[self loadImageWithSize:squareHeight];
	
}

- (void)loadImageWithSize:(float)size
{
	
	static int previousSize = 0;
	
	int rightSize = 0;
	
	int array[16] = {122, 112, 102, 92, 84, 76, 68, 60, 54, 48, 42, 36, 32, 28, 24, 20};
	
	int currentSize = 132;
	
	for (int i = 0; i < 16; i++) {
		if (size > array[i]) {
			rightSize = currentSize;
			break;
		}
		currentSize = array[i];
	}
	
	if (rightSize == 0) {
		rightSize = 20;
	}
	
	if (rightSize == previousSize) {
		return;
	}
	else
		previousSize = rightSize;
	
	NSString *bundlePath = [appBundle bundlePath];
	bundlePath = [bundlePath stringByAppendingPathComponent:@"/Contents/Resources"];
	NSString *iPath = [NSString stringWithFormat:@"/merida/%i", rightSize];
	bundlePath = [bundlePath stringByAppendingPathComponent:iPath];
	
    // load images of the chess pieces
	wr = [[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/wr.png", bundlePath]];
	wn = [[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/wn.png", bundlePath]];
	wb = [[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/wb.png", bundlePath]];
	wq = [[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/wq.png", bundlePath]];
	wk = [[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/wk.png", bundlePath]];
	wp = [[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/wp.png", bundlePath]];
	
	br = [[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/br.png", bundlePath]];
	bn = [[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/bn.png", bundlePath]];
	bb = [[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/bb.png", bundlePath]];
	bq = [[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/bq.png", bundlePath]];
	bk = [[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/bk.png", bundlePath]];
	bp = [[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/bp.png", bundlePath]];
	
	[self setNeedsDisplay:YES];
	

}


- (void)numMovesToFollow:(int)num 
{
	numMovesToFollow = num;
}

- (void)setWildNumber:(int)wild
{
	wildNumber = wild;
}

- (void)setStatus:(BV_STATUS)s
{
	status = s;
}

- (void)reset 
{	
	[capturedPieces removeAllObjects];
	
	for (int i = 0; i < 64; i++) {
		circleArray[i] = 0;
	}
	
	if (squareWidth > squareHeight)
		[self loadImageWithSize:squareWidth];
	else
		[self loadImageWithSize:squareHeight];
	
	numMovesToFollow = 0;
	myMovedPiece = NO;

	flipped = NO;
	prevFlip = NO;
	
	userSelectedMove = NO;
	
	status = BV_DEAD;
	numHalfMoves = 0;
	
	dragging = NO;
	fromSquare = toSquare = -1;
	moveFromSquare = moveToSquare = -1;
	
	rightFromSquare = rightToSquare = -1;
	
	[positionsArray removeAllObjects];	

	for (int i=0; i<64; ++i) { 
		displayBoard[i] = BV_EMPTY;
		internalBoard[i] = BV_EMPTY;
	}
	
	NSRect b = [self bounds];
	
	squareWidth = b.size.width / 8.0;
	squareHeight = b.size.height / 8.0;
	
	if (squareWidth > squareHeight)
		[self loadImageWithSize:squareWidth];
	else
		[self loadImageWithSize:squareHeight];

}

// flip the display of the chess board
// flipped means black pieces on bottom, not flipped means white pieces on bottom
- (void)flip:(BOOL)o
{
	int i;
	
	if (o == YES) {
		NSLog(@"board flip");
		flipped = YES;
		
	}
	else if (o == NO) {
		NSLog(@"board no flip");
		flipped = NO;
	}
	[self setNeedsDisplay:YES];
}

// This is called only from the BoardController
// We never call this function internally, only setFen()
-(void)externalSetFen:(NSString*)fenStr 
{
	int row = 7;
	int col = 0;
	int fi = 0;
	int index;
	int i;
	
	[positionsArray removeAllObjects];
	[positionsArray addObject:fenStr];
	numHalfMoves = 0;
	
	const char* fen = [fenStr cStringUsingEncoding:NSASCIIStringEncoding];
	
	for (i=0; i<64; ++i) 
		internalBoard[i] = BV_EMPTY;
	
	while (fen[fi] != ' ') {
		index = 8*row + col;
		switch (fen[fi]) {
			case 'R': internalBoard[index] = BV_WROOK; break;
			case 'N': internalBoard[index] = BV_WKNIGHT; break;
			case 'B': internalBoard[index] = BV_WBISHOP; break;
			case 'Q': internalBoard[index] = BV_WQUEEN; break;
			case 'K': internalBoard[index] = BV_WKING; break;
			case 'P': internalBoard[index] = BV_WPAWN; break;
				
			case 'r': internalBoard[index] = BV_BROOK; break;
			case 'n': internalBoard[index] = BV_BKNIGHT; break;
			case 'b': internalBoard[index] = BV_BBISHOP; break;
			case 'q': internalBoard[index] = BV_BQUEEN; break;
			case 'k': internalBoard[index] = BV_BKING; break;
			case 'p': internalBoard[index] = BV_BPAWN; break;
			case '-': break;
			case '/': --row; col = -1; break;
			default:
				col += fen[fi] - '1';
		}
		++col;
		++fi;
	}
	
	for (i=0; i<64; ++i) 
	{
		displayBoard[i] = internalBoard[i];
	}
	
	[self setNeedsDisplay:YES];
}

// we call this internally if there is a takeback and we need to interpret the FEN string
// contained in positionsArray
-(void)setFen:(NSString*)fenStr 
{
	[fenStr retain];
	
	int row = 7;
	int col = 0;
	int fi = 0;
	int index;
	int i;
	
	
	
	// this should never happen, but just in case
	if (numHalfMoves == 0) {
		[positionsArray removeAllObjects];
		[positionsArray addObject:fenStr];
	}
		
	const char* fen = [fenStr cStringUsingEncoding:NSASCIIStringEncoding];
	

	for (i=0; i<64; ++i) 
		internalBoard[i] = BV_EMPTY;
	
	while (fen[fi] != ' ') {
		index = 8*row + col;
		switch (fen[fi]) {
			case 'R': internalBoard[index] = BV_WROOK; break;
			case 'N': internalBoard[index] = BV_WKNIGHT; break;
			case 'B': internalBoard[index] = BV_WBISHOP; break;
			case 'Q': internalBoard[index] = BV_WQUEEN; break;
			case 'K': internalBoard[index] = BV_WKING; break;
			case 'P': internalBoard[index] = BV_WPAWN; break;
				
			case 'r': internalBoard[index] = BV_BROOK; break;
			case 'n': internalBoard[index] = BV_BKNIGHT; break;
			case 'b': internalBoard[index] = BV_BBISHOP; break;
			case 'q': internalBoard[index] = BV_BQUEEN; break;
			case 'k': internalBoard[index] = BV_BKING; break;
			case 'p': internalBoard[index] = BV_BPAWN; break;
			case '-': break;
			case '/': --row; col = -1; break;
			default:
				col += fen[fi] - '1';
		}
		++col;
		++fi;
	}
	
	for (i=0; i<64; i++) 
	{
		displayBoard[i] = internalBoard[i];
	}
	
	[self setNeedsDisplay:YES];
	
	[fenStr release];
}

// This is called only from the BoardController
// We never call this function internally, only setFen()
// displays a particular Fen
-(void)displaySetFen:(NSString*)fenStr 
{
	NSLog(@"set position");
	
	userSelectedMove = YES;
	
	int row = 7;
	int col = 0;
	int fi = 0;
	int index;
	int i;
	
	
	const char* fen = [fenStr cStringUsingEncoding:NSASCIIStringEncoding];
	
	for (i=0; i<64; ++i) 
		displayBoard[i] = BV_EMPTY;
	
	while (fen[fi] != ' ') {
		index = 8*row + col;
		switch (fen[fi]) {
			case 'R': displayBoard[index] = BV_WROOK; break;
			case 'N': displayBoard[index] = BV_WKNIGHT; break;
			case 'B': displayBoard[index] = BV_WBISHOP; break;
			case 'Q': displayBoard[index] = BV_WQUEEN; break;
			case 'K': displayBoard[index] = BV_WKING; break;
			case 'P': displayBoard[index] = BV_WPAWN; break;
				
			case 'r': displayBoard[index] = BV_BROOK; break;
			case 'n': displayBoard[index] = BV_BKNIGHT; break;
			case 'b': displayBoard[index] = BV_BBISHOP; break;
			case 'q': displayBoard[index] = BV_BQUEEN; break;
			case 'k': displayBoard[index] = BV_BKING; break;
			case 'p': displayBoard[index] = BV_BPAWN; break;
			case '-': break;
			case '/': --row; col = -1; break;
			default:
				col += fen[fi] - '1';
		}
		++col;
		++fi;
	}
		
	[self setNeedsDisplay:YES];
}


// encodes current position represented by internalBoard[] into a FEN string
- (NSString *)fen 
{	
	char buffer[120];
	int  bi = 0;
	
	int r, c;
	int empty = 0;
	
	for (r = 7; r >= 0; --r) {
		for (c = 0; c < 8; ++c) {
			int index = 8*r+c;
			
			char piece = CVPieceToChar(internalBoard[index]);
			
			if ( piece == '-' ) ++empty;
			else {
				if (empty > 0) {
					buffer[bi++] = empty + '0';
					empty = 0;
				}
				buffer[bi++] = piece;
			}
		}
		if ( empty > 0 ) {
			buffer[bi++] = empty + '0';
			empty = 0;
		}
		if ( r > 0 ) buffer[bi++] = '/';
	}
	buffer[bi++] = ' ';
	buffer[bi++] = 0;
	
	NSLog (@"done with fen");
	return [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
}



// helper function for fen()
// not used elsewhere
char CVPieceToChar(BOARDVIEW_PIECES p) 
{
	char array[] = "PNBRQKpnbrqk-?";
	
	assert(array[BV_WPAWN] == 'P');
	assert(array[BV_WKNIGHT] == 'N');
	assert(array[BV_WBISHOP] == 'B');
	assert(array[BV_WROOK] == 'R');
	assert(array[BV_WQUEEN] == 'Q');
	assert(array[BV_WKING] == 'K');
	assert(array[BV_BPAWN] == 'p');
	assert(array[BV_BKNIGHT] == 'n');
	assert(array[BV_BBISHOP] == 'b');
	assert(array[BV_BROOK] == 'r');
	assert(array[BV_BQUEEN] == 'q');
	assert(array[BV_BKING] == 'k');
	assert(array[BV_EMPTY] == '-');
	
	int k = (int)p;
	if (k > BV_EMPTY) k = BV_EMPTY+1;
	return array[k];
}


// given a point, return the corresponding square number (0 to 63) containing that point
// useful for mouse functions
- (int)pointToSquare:(NSPoint)point 
{
	int tempx, tempy;
	NSRect bounds = [self bounds];
	
	if (point.x > bounds.size.width || point.y > bounds.size.height || point.x < 0.0 || point.y < 0.0)
		return -1;
	else {
		tempx = ((int)point.x -  (int)point.x % (int)(bounds.size.width/8)) / ((int)bounds.size.width / 8);
		tempy = ((int)point.y -  (int)point.y % (int)(bounds.size.height/8)) / ((int)bounds.size.height / 8);
		
		if (flipped == NO) {
			return tempx + (tempy * 8);
		}
		else {
			return 63 - (tempx + (tempy * 8));
		}
	}
}

// below functions have Core Animation code commented out... tried playing around with CA to animate piece moves but
// animation takes too much time for short time controls in chess
- (BOOL)isWhitePiece:(int)i
{
	if (internalBoard[i] == BV_WPAWN || 
		internalBoard[i] == BV_WROOK || 
		internalBoard[i] == BV_WKNIGHT || 
		internalBoard[i] == BV_WBISHOP || 
		internalBoard[i] == BV_WQUEEN || 
		internalBoard[i] == BV_WKING)
		return YES;
	else
		return NO;
}

- (BOOL)pieceIsWhitePiece:(BOARDVIEW_PIECES)i
{
	if (i == BV_WPAWN || 
		i == BV_WROOK || 
		i == BV_WKNIGHT || 
		i == BV_WBISHOP || 
		i == BV_WQUEEN || 
		i == BV_WKING)
		return YES;
	else
		return NO;
}

// receives move and sets board with new move
- (void)move:(NSString *)smithMove
{
    // delete all circles and arrow annotations drawn on board
	[self deleteAllArrows];
	[self deleteAllCircles];
	
	if (userSelectedMove) {
		[self setFen:[positionsArray lastObject]];
		userSelectedMove = NO;
	}
	
	// array containing start square (square[0]) and end square (square[1])
	int square[2];
	
	// Now we parse smithMove string
	
	// a placed piece move such as Q@f6
	if ([smithMove rangeOfString:@"@"].location != NSNotFound) {
		

		int tmpSquare = [self coordinateToSquareNumber:[smithMove substringWithRange:NSMakeRange(2, 2)]];
		
		NSLog(@"placed move piece: %c at: %i", [smithMove characterAtIndex:0], tmpSquare);
		
		char piece = [smithMove characterAtIndex:0];
		
		if (numHalfMoves % 2 == 1) {
			// black move
			
			switch (piece) {
				case 'P':
					//[placeLayer setContents:(id)bp1];
					//[[self layer] addSublayer:placeLayer];
					//[placeLayer display];
					internalBoard[tmpSquare] = BV_BPAWN;
					displayBoard[tmpSquare] = internalBoard[tmpSquare];
					break;
				case 'R':
					//[placeLayer setContents:(id)br1];
					//[[self layer] addSublayer:placeLayer];
					//[placeLayer display];
					internalBoard[tmpSquare] = BV_BROOK;
					displayBoard[tmpSquare] = internalBoard[tmpSquare];
					break;
				case 'N':
					//[placeLayer setContents:(id)bn1];
					//[[self layer] addSublayer:placeLayer];
					//[placeLayer display];
					internalBoard[tmpSquare] = BV_BKNIGHT;
					displayBoard[tmpSquare] = internalBoard[tmpSquare];
					break;
				case 'B':
					//[placeLayer setContents:(id)bb1];
					//[[self layer] addSublayer:placeLayer];
					//[placeLayer display];
					internalBoard[tmpSquare] = BV_BBISHOP;
					displayBoard[tmpSquare] = internalBoard[tmpSquare];
					break;
				case 'Q':
					//[placeLayer setContents:(id)bq1];
					//[[self layer] addSublayer:placeLayer];
					//[placeLayer display];
					internalBoard[tmpSquare] = BV_BQUEEN;
					displayBoard[tmpSquare] = internalBoard[tmpSquare];
					break;
				case 'K':
					//[placeLayer setContents:(id)bk1];
					//[[self layer] addSublayer:placeLayer];
					//[placeLayer display];
					internalBoard[tmpSquare] = BV_BKING;
					displayBoard[tmpSquare] = internalBoard[tmpSquare];
					break;
				default:
					break;
			}
		}
		else {
			// white move
			switch (piece) {
				case 'P':
					//[placeLayer setContents:(id)wp1];
					//[[self layer] addSublayer:placeLayer];
					//[placeLayer display];
					internalBoard[tmpSquare] = BV_WPAWN;
					displayBoard[tmpSquare] = internalBoard[tmpSquare];
					break;
				case 'R':
					//[placeLayer setContents:(id)wr1];
					//[[self layer] addSublayer:placeLayer];
					//[placeLayer display];
					internalBoard[tmpSquare] = BV_WROOK;
					displayBoard[tmpSquare] = internalBoard[tmpSquare];
					break;
				case 'N':
					//[placeLayer setContents:(id)wn1];
					//[[self layer] addSublayer:placeLayer];
					internalBoard[tmpSquare] = BV_WKNIGHT;
					displayBoard[tmpSquare] = internalBoard[tmpSquare];
					//[placeLayer display];
					break;
				case 'B':
					//[placeLayer setContents:(id)wb1];
					//[[self layer] addSublayer:placeLayer];
					//[placeLayer display];
					internalBoard[tmpSquare] = BV_WBISHOP;
					displayBoard[tmpSquare] = internalBoard[tmpSquare];
					break;
				case 'Q':
					//[placeLayer setContents:(id)wq1];
					//[[self layer] addSublayer:placeLayer];
					//[placeLayer display];
					internalBoard[tmpSquare] = BV_WQUEEN;
					displayBoard[tmpSquare] = internalBoard[tmpSquare];
					break;
				case 'K':
					//[placeLayer setContents:(id)wk1];
					//[[self layer] addSublayer:placeLayer];
					//[placeLayer display];
					internalBoard[tmpSquare] = BV_WKING;
					displayBoard[tmpSquare] = internalBoard[tmpSquare];
					break;
				default:
					break;
			}
		}
		
	}
	else {
		// normal move 
		
		int squareCount;
		
		char tmpChar[2];
		tmpChar[1] = '\0';
		
		for (int i=0; i<3; i+=2) {
			if (i == 2)
				squareCount = 1;
			else
				squareCount = 0;
			switch ([smithMove characterAtIndex:i]) {
				case 'a':
					square[squareCount] = 0;
					break;
				case 'b':
					square[squareCount] = 1;
					break;
				case 'c':
					square[squareCount] = 2;
					break;
				case 'd':
					square[squareCount] = 3;
					break;
				case 'e':
					square[squareCount] = 4;
					break;
				case 'f':
					square[squareCount] = 5;
					break;
				case 'g':
					square[squareCount] = 6;
					break;
				case 'h':
					square[squareCount] = 7;
					break;
				default:
					break;
			}
		}
		
		for (int i=1; i<=3; i+=2) {
			if (i == 3)
				squareCount = 1;
			else
				squareCount = 0;
			
			tmpChar[0] = [smithMove characterAtIndex:i];
			
			int num = atoi(tmpChar);
					
			square[squareCount] += (num - 1) * 8;
			
		}
		
		fromSquare = square[0];
		toSquare = square[1];
		

		// set so that the internal representation of the destination square is set to the piece
		// moved from the initial square
		internalBoard[square[1]] = internalBoard[square[0]];
		

		// parsing extra characters after the move, such as castling, en passant, and pawn promotion
		// we don't care about captured pieces
		
		// smithMove is a six character string
		if ([smithMove length] > 5) {
			
			// parse the 6th character, which is pawn promotion
			switch ([smithMove characterAtIndex:5]) {
				case 'Q':
					
					/*
					if (square[1] > square[0])
						[toPieceLayer setContents:(id)wq1];
					else
						[toPieceLayer setContents:(id)bq1];
					 */
					
					
					if (internalBoard[square[0]] < BV_BPAWN) {
						internalBoard[square[1]] = BV_WQUEEN;
					}
					else {
						internalBoard[square[1]] = BV_BQUEEN;
					}
					break;
				case 'R':
					/*
					if (square[1] > square[0])
						[toPieceLayer setContents:(id)wr1];
					else
						[toPieceLayer setContents:(id)br1];
					 */
					
					if (internalBoard[square[0]] < BV_BPAWN) {
						internalBoard[square[1]] = BV_WROOK;

					}
					else {
						internalBoard[square[1]] = BV_BROOK;

					}
					break;
				case 'B':
					/*
					if (square[1] > square[0])
						[toPieceLayer setContents:(id)wb1];
					else
						[toPieceLayer setContents:(id)bb1];
					*/
					
					if (internalBoard[square[0]] < BV_BPAWN) {
						internalBoard[square[1]] = BV_WBISHOP;
					}
					else {
						internalBoard[square[1]] = BV_BBISHOP;
					}
					break;
				case 'N':
					/*
					if (square[1] > square[0])
						[toPieceLayer setContents:(id)wn1];
					else
						[toPieceLayer setContents:(id)bn1];
					*/
					if (internalBoard[square[0]] < BV_BPAWN) {
						internalBoard[square[1]] = BV_WKNIGHT;
					}
					else {
						internalBoard[square[1]] = BV_BKNIGHT;
					}
					break;
				default:
					break;
			}
			
			// parse 5th character, which is en passant or castling
			switch ([smithMove characterAtIndex:4]) {
				case 'E': // enpassant
					/*
					if (!flipped) {
						if (square[1] > square[0]) {
							for (CALayer *pLayer in [[self layer] sublayers]) {
								if ( [[pLayer name] intValue] == square[1] - 8 ) {
									pieceToRemove = pLayer;
									break;
								}
							}
							if (pieceToRemove)
								[pieceToRemove removeFromSuperlayer];
						}
						else {
							for (CALayer *pLayer in [[self layer] sublayers]) {
								if ( [[pLayer name] intValue] == square[1]+8) {
									pieceToRemove = pLayer;
									break;
								}
							}
							if (pieceToRemove)
								[pieceToRemove removeFromSuperlayer];
						}
					}
					else {
						if ( (63 - square[1]) > (63 - square[0])) {
							for (CALayer *pLayer in [[self layer] sublayers]) {
								if ( [[pLayer name] intValue] == 63 - (square[1] + 8) ) {
									pieceToRemove = pLayer;
									break;
								}
							}
							if (pieceToRemove)
								[pieceToRemove removeFromSuperlayer];
						}
						else {
							for (CALayer *pLayer in [[self layer] sublayers]) {
								if ( [[pLayer name] intValue] == 63 - (square[1] - 8) ) {
									pieceToRemove = pLayer;
									break;
								}
							}
							if (pieceToRemove)
								[pieceToRemove removeFromSuperlayer];
						}
					}				
					*/
					if (internalBoard[square[0]] < BV_BPAWN) {
						internalBoard[square[1] - 8] = BV_EMPTY;
						displayBoard[square[1] - 8] = BV_EMPTY;
					}
					else {
						internalBoard[square[1] + 8] = BV_EMPTY;
						displayBoard[square[1] + 8] = BV_EMPTY;
					}
					break;

				case 'c': // kingside castling, king already at end square
					if (square[0] < 8) { // white kingside castling
						/*
						if (!flipped) {
							if (numMovesToFollow == 0) 
								[self animateFrom:7 to:5];
							//else
							//	[self unanimatedFrom:7 to:5];
						}
						else {
							if (numMovesToFollow == 0)
								[self animateFrom:56 to:58];
							//else
							//	[self unanimatedFrom:56 to:58];
						}
						*/
						internalBoard[5] = BV_WROOK;
						internalBoard[7] = BV_EMPTY;
						displayBoard[5] = BV_WROOK;
						displayBoard[7] = BV_EMPTY;
					}
					else { // black kingside castling
						/*
						if (!flipped) {
							if (numMovesToFollow == 0) 
								[self animateFrom:63 to:61];
							//else
							//	[self unanimatedFrom:63 to:61];
						}
						else {
							if (numMovesToFollow == 0)
								[self animateFrom:0 to:2];
							//else
							//	[self unanimatedFrom:0 to:2];
						}
						*/
						
						internalBoard[61] = BV_BROOK;
						internalBoard[63] = BV_EMPTY;
						displayBoard[61] = BV_BROOK;
						displayBoard[63] = BV_EMPTY;
					}
					break;
				case 'C': // queenside castling, king already at end square

					if (square[0] < 8) { // white kingside castling
						/*
						if (!flipped) {
							if (numMovesToFollow == 0) 
								[self animateFrom:0 to:3];
							//else
							//	[self unanimatedFrom:0 to:3];
						}
						else {
							if (numMovesToFollow == 0)
								[self animateFrom:63 to:60];
							//else
							//	[self unanimatedFrom:63 to:60];
						}
						*/
						
						internalBoard[3] = BV_WROOK;
						internalBoard[0] = BV_EMPTY;
						displayBoard[3] = BV_WROOK;
						displayBoard[0] = BV_EMPTY;
						
					}
					else { // black kingside castling
						/*
						if (!flipped) {
							if (numMovesToFollow == 0) 
								[self animateFrom:56 to:59];
							//else
							//	[self unanimatedFrom:56 to:59];
						}
						else {
							if (numMovesToFollow == 0)
								[self animateFrom:7 to:4];
							//else
							//	[self unanimatedFrom:7 to:4];
						}
						*/	
						internalBoard[59] = BV_BROOK;
						internalBoard[56] = BV_EMPTY;
						displayBoard[59] = BV_BROOK;
						displayBoard[56] = BV_EMPTY;
					}
					break;
				default:
					break;
			}
		}
		
		// smithMove has 5 characters
		else if ([smithMove length] == 5) {
			switch ([smithMove characterAtIndex:4]) {
				case 'Q':
					/*
					if (square[1] > square[0])
						[toPieceLayer setContents:(id)wq1];
					else
						[toPieceLayer setContents:(id)bq1];				
					*/
					if (internalBoard[square[0]] < BV_BPAWN) {
						internalBoard[square[1]] = BV_WQUEEN;
					}
					else {
						internalBoard[square[1]] = BV_BQUEEN;
					}
					break;
				case 'R':
					/*
					if (square[1] > square[0])
						[toPieceLayer setContents:(id)wr1];
					else
						[toPieceLayer setContents:(id)br1];	
					 */
					
					if (internalBoard[square[0]] < BV_BPAWN) {
						internalBoard[square[1]] = BV_WROOK;
						
					}
					else {
						internalBoard[square[1]] = BV_BROOK;
						
					}
					break;
				case 'B':
					/*
					if (square[1] > square[0])
						[toPieceLayer setContents:(id)wb1];
					else
						[toPieceLayer setContents:(id)bb1];
					*/
					
					if (internalBoard[square[0]] < BV_BPAWN) {
						internalBoard[square[1]] = BV_WBISHOP;
					}
					else {
						internalBoard[square[1]] = BV_BBISHOP;
					}
					break;
				case 'N':
					/*
					if (square[1] > square[0])
						[toPieceLayer setContents:(id)wn1];
					else
						[toPieceLayer setContents:(id)bn1];
					*/
					
					if (internalBoard[square[0]] < BV_BPAWN) {
						internalBoard[square[1]] = BV_WKNIGHT;
					}
					else {
						internalBoard[square[1]] = BV_BKNIGHT;
					}
					break;
				case 'E': // enpassant
					/*
					if (!flipped) {
						if (square[1] > square[0]) {
							for (CALayer *pLayer in [[self layer] sublayers]) {
								if ( [[pLayer name] intValue] == square[1] - 8 ) {
									pieceToRemove = pLayer;
									break;
								}
							}
							if (pieceToRemove)
								[pieceToRemove removeFromSuperlayer];
						}
						else {
							for (CALayer *pLayer in [[self layer] sublayers]) {
								if ( [[pLayer name] intValue] == square[1]+8) {
									pieceToRemove = pLayer;
									break;
								}
							}
							if (pieceToRemove)
								[pieceToRemove removeFromSuperlayer];
						}
					}
					else {
						if ( (63 - square[1]) > (63 - square[0])) {
							for (CALayer *pLayer in [[self layer] sublayers]) {
								if ( [[pLayer name] intValue] == 63 - (square[1] + 8) ) {
									pieceToRemove = pLayer;
									break;
								}
							}
							if (pieceToRemove)
								[pieceToRemove removeFromSuperlayer];
						}
						else {
							for (CALayer *pLayer in [[self layer] sublayers]) {
								if ( [[pLayer name] intValue] == 63 - (square[1] - 8) ) {
									pieceToRemove = pLayer;
									break;
								}
							}
							if (pieceToRemove)
								[pieceToRemove removeFromSuperlayer];
						}
					}
					*/
					
					if (internalBoard[square[0]] < BV_BPAWN) {
						internalBoard[square[1] - 8] = BV_EMPTY;
						displayBoard[square[1] - 8] = BV_EMPTY;
					}
					else {
						internalBoard[square[1] + 8] = BV_EMPTY;
						displayBoard[square[1] + 8] = BV_EMPTY;
					}
					break;
					
				case 'c': // kingside castling, king already at end square
					if (square[0] == 4) { // white kingside castling
						/*
						if (!flipped) {
							if (numMovesToFollow == 0) 
								[self animateFrom:7 to:5];
							//else
							//	[self unanimatedFrom:7 to:5];
						}
						else {
							if (numMovesToFollow == 0)
								[self animateFrom:56 to:58];
							//else
							//	[self unanimatedFrom:56 to:58];
						}
						*/
						
						internalBoard[5] = BV_WROOK;
						internalBoard[7] = BV_EMPTY;
						displayBoard[5] = BV_WROOK;
						displayBoard[7] = BV_EMPTY;
					}
					else { // black kingside castling
						/*
						if (!flipped) {
							if (numMovesToFollow == 0) 
								[self animateFrom:63 to:61];
							//else
							//	[self unanimatedFrom:63 to:61];
						}
						else {
							if (numMovesToFollow == 0)
								[self animateFrom:0 to:2];
							//else
							//	[self unanimatedFrom:0 to:2];
						}
						*/
						
						internalBoard[61] = BV_BROOK;
						internalBoard[63] = BV_EMPTY;
						displayBoard[61] = BV_BROOK;
						displayBoard[63] = BV_EMPTY;
					}
					break;
				case 'C': // queenside castling, king already at end square
					
					if (square[0] == 4) { // white kingside castling
						/*
						if (!flipped) {
							if (numMovesToFollow == 0) 
								[self animateFrom:0 to:3];
							//else
							//	[self unanimatedFrom:0 to:3];
						}
						else {
							if (numMovesToFollow == 0)
								[self animateFrom:63 to:60];
							//else
							//	[self unanimatedFrom:63 to:60];
						}
						*/
						
						internalBoard[3] = BV_WROOK;
						internalBoard[0] = BV_EMPTY;
						displayBoard[3] = BV_WROOK;
						displayBoard[0] = BV_EMPTY;
						
					}
					else { // black kingside castling
						/*
						if (!flipped) {
							if (numMovesToFollow == 0) 
								[self animateFrom:56 to:59];
							//else
							//	[self unanimatedFrom:56 to:59];
						}
						else {
							if (numMovesToFollow == 0)
								[self animateFrom:7 to:4];
							//else
							//	[self unanimatedFrom:7 to:4];
						}
						*/
						internalBoard[59] = BV_BROOK;
						internalBoard[56] = BV_EMPTY;
						displayBoard[59] = BV_BROOK;
						displayBoard[56] = BV_EMPTY;
					}
					break;
				default:
					break;	
			}
		}	
		

		
		internalBoard[square[0]] = BV_EMPTY;
		
		if (myMovedPiece) {
			displayBoard[square[0]] = BV_EMPTY;
			displayBoard[square[1]] = internalBoard[square[1]];
		
			myMovedPiece = NO;
		}
		
		displayBoard[square[0]] = BV_EMPTY;
		displayBoard[square[1]] = internalBoard[square[1]];
		
	}
	
	
	// for takeback purposes
	numHalfMoves++;
	NSString *posFen = [self fen];
	if (posFen != nil)
		[positionsArray addObject:posFen];

	
	if (numMovesToFollow > 0) {
		numMovesToFollow--;
		
		if (numMovesToFollow == 0)
			[self setFen:[self fen]];
	}
	
	// send pre-move, if any
	if (status == BV_USERWHITE && numHalfMoves % 2 == 0 && moveFromSquare != -1 && moveToSquare != -1) {
		[bvDelegate sendCommandStr:[NSString stringWithFormat:@"%@%@", 
									[self algebraicSquare:moveFromSquare], [self algebraicSquare:moveToSquare]]];
		moveFromSquare = -1;
		moveToSquare = -1;
		myMovedPiece = YES;
	}
	else if (status == BV_USERBLACK && numHalfMoves % 2 != 0 && moveFromSquare != -1 && moveToSquare != -1) {
		[bvDelegate sendCommandStr:[NSString stringWithFormat:@"%@%@", 
									[self algebraicSquare:moveFromSquare], [self algebraicSquare:moveToSquare]]];
		moveFromSquare = -1;
		moveToSquare = -1;
		
		myMovedPiece = YES;
	}
	
	[self setNeedsDisplay:YES];
}

- (void)takeback
{
	userSelectedMove = NO;
	
	
	if (numHalfMoves > 0) {
		[positionsArray removeLastObject];
		[self setFen:[positionsArray lastObject]];
		numHalfMoves--;
	}
	
	[self deleteAllArrows];
	[self deleteAllCircles];
	
	fromSquare = -1;
	toSquare = -1;
	
	[self setNeedsDisplay:YES];
	
}

- (NSRect)rectOfSquare:(int)square
{
	if (!flipped) {
		return NSMakeRect((square % 8) * squareWidth, (square / 8) * squareHeight, squareWidth, squareHeight);
	} else {
		return NSMakeRect(((63 - square) % 8) * squareWidth, ((63 - square) / 8) * squareHeight, squareWidth, squareHeight);
	}
}


- (void)circle:(NSString *)coordinate
{
	int squareNumber;
	
	char tmpChar[2];
	tmpChar[1] = '\0';
		

	switch ([coordinate characterAtIndex:0]) {
		case 'a':
			squareNumber = 0;
			break;
		case 'b':
			squareNumber = 1;
			break;
		case 'c':
			squareNumber = 2;
			break;
		case 'd':
			squareNumber = 3;
			break;
		case 'e':
			squareNumber = 4;
			break;
		case 'f':
			squareNumber = 5;
			break;
		case 'g':
			squareNumber = 6;
			break;
		case 'h':
			squareNumber = 7;
			break;
		default:
			break;
	}
		
	tmpChar[0] = [coordinate characterAtIndex:1];
	int num = atoi(tmpChar);
	squareNumber += (num - 1) * 8;
	
	[self addOrDeleteCircle:squareNumber];
	[self setNeedsDisplay:YES];
	
}

- (void)arrowFrom:(NSString *)fromS to:(NSString *)toS
{
	int fSquare, tSquare;
	
	fSquare = [self coordinateToSquareNumber:fromS];
	tSquare = [self coordinateToSquareNumber:toS];
	
	[self addArrowFrom:fSquare to:tSquare];
	[self setNeedsDisplay:YES];
	
}

- (void)unarrowFrom:(NSString *)fromS to:(NSString *)toS
{
	int fSquare, tSquare;
	
	fSquare = [self coordinateToSquareNumber:fromS];
	tSquare = [self coordinateToSquareNumber:toS];
	
	[self deleteArrowFrom:fSquare to:tSquare];
	[self setNeedsDisplay:YES];
	
}

- (void)deleteAllCircles
{
	for (int i = 0; i < 64; i++) {
		circleArray[i] = 0;
	}
}

- (void)addOrDeleteCircle:(int)squareNumber
{	
	if (squareNumber < 0 || squareNumber > 63)
		return;
	
	NSLog(@"add circle at: %i", squareNumber);
	
	if (circleArray[squareNumber] == 1) 
		circleArray[squareNumber] = 0;
	else
		circleArray[squareNumber] = 1;
	
}

- (void)deleteAllArrows
{
	[fromArrowArray removeAllObjects];
	[toArrowArray removeAllObjects];
}

- (void)addArrowFrom:(int)fromS to:(int)toS
{
	[fromArrowArray addObject:[NSNumber numberWithInt:fromS]];
	[toArrowArray addObject:[NSNumber numberWithInt:toS]];
}

- (void)deleteArrowFrom:(int)fromS to:(int)toS
{
	for (int i = 0; i < [fromArrowArray count]; i++) {
		if ([[fromArrowArray objectAtIndex:i] intValue] == fromS && [[toArrowArray objectAtIndex:i] intValue] == toS) {
			[fromArrowArray removeObjectAtIndex:i];
			[toArrowArray removeObjectAtIndex:i];
			break;
		}
	}
}

- (int)coordinateToSquareNumber:(NSString *)coordinateString
{
	int squareNumber;
	
	char tmpChar[2];
	tmpChar[1] = '\0';
	
	
	switch ([coordinateString characterAtIndex:0]) {
		case 'a':
			squareNumber = 0;
			break;
		case 'b':
			squareNumber = 1;
			break;
		case 'c':
			squareNumber = 2;
			break;
		case 'd':
			squareNumber = 3;
			break;
		case 'e':
			squareNumber = 4;
			break;
		case 'f':
			squareNumber = 5;
			break;
		case 'g':
			squareNumber = 6;
			break;
		case 'h':
			squareNumber = 7;
			break;
		default:
			break;
	}
	
	tmpChar[0] = [coordinateString characterAtIndex:1];
	int num = atoi(tmpChar);
	squareNumber += (num - 1) * 8;

	return squareNumber;
}

	
// An illegal move was made
- (void)illegalMove
{
	// just set displayBoard to internalBoard
	
	for (int i=0; i<64; i++) { 
		displayBoard[i] = internalBoard[i];
	}
	
	fromSquare = -1;
	toSquare = -1;
	
	[self setNeedsDisplay:YES];
	
	/*
	// Set position to previous position
	if (numHalfMoves > 0)
		[self setFen:[positionsArray lastObject]];
	else {
		CALayer *tmpLayer;
		for (CALayer *pLayer in [[self layer] sublayers]) {
			if ([[pLayer name] intValue] == lastMoveFromSquare) { 
				tmpLayer = pLayer;
				break;
			}
		}
		
		if (tmpLayer)
			[tmpLayer setPosition:CGPointMake((lastMoveFromSquare % 8) * squareWidth, (lastMoveFromSquare / 8) * squareHeight)];
	}
	 */
}

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
		
	NSRect imageRect, drawingRect;
	
	NSRect bounds = [self bounds];
	
	
	[[NSGraphicsContext currentContext] setShouldAntialias:YES];
	
	[[NSColor darkGrayColor] set];

	float yPoint, xPoint;
	int i;
	int k = 0;
	
	squareHeight = bounds.size.height/8;
	squareWidth = bounds.size.width/8;
	
	squareSize = NSMakeSize(squareWidth, squareHeight);
	
	
	[NSBezierPath strokeRect:bounds];
	
	BOOL whiteColor = NO;
	float paintWidth;
	float paintHeight;
	// draw the chess board
	for ( yPoint = bounds.origin.y; yPoint < bounds.size.height; yPoint += squareHeight) {
		for ( xPoint = bounds.origin.x; xPoint < bounds.size.width; xPoint += squareWidth) {
			
			if (xPoint + squareWidth > bounds.size.width)
				paintWidth = bounds.size.width - xPoint;
			else
				paintWidth = squareWidth;
			
			if (yPoint + squareHeight > bounds.size.height)
				paintHeight = bounds.size.height - yPoint;
			else
				paintHeight = squareHeight;
				
			
			if (!whiteColor) {
				[[NSColor darkGrayColor] set];
				[NSBezierPath fillRect:NSMakeRect(xPoint, yPoint, paintWidth, paintHeight)];
				//imageRect = NSMakeRect(xPoint, yPoint, squareWidth, squareHeight);
				//drawingRect = imageRect;
				whiteColor = YES;
				//[darkwood drawInRect:drawingRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
			} else {
				[[NSColor clearColor] set];
				[NSBezierPath fillRect:NSMakeRect(xPoint, yPoint, paintWidth, paintHeight)];
				//imageRect = NSMakeRect(xPoint, yPoint, squareWidth, squareHeight);
				//drawingRect = imageRect;
				whiteColor = NO;
				//[lightwood drawInRect:drawingRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
			}
		}
		
		k++;
		if (k%2 == 0)
			whiteColor = NO;
		else
			whiteColor = YES;
	}
	
	
	if (dragging) {
		[NSGraphicsContext saveGraphicsState];
		
		//NSSetFocusRingStyle(NSFocusRingOnly);
		
		[[NSColor keyboardFocusIndicatorColor] set];
		//[[NSColor selectedControlColor] set];
		NSBezierPath *path = [NSBezierPath bezierPath];
		[path setLineWidth:3.0];
		if (flipped == NO && fromSquare != -1 && toSquare != -1) {
			[path appendBezierPathWithRect:NSMakeRect((bounds.origin.x) + 1 + ((bounds.size.width/8) * (fromSquare%8)), 
												(bounds.origin.y) + 1 + ((bounds.size.height/8) * (fromSquare/8)), 
												-2 + bounds.size.width/8, -2 + bounds.size.height/8)];
			[path stroke];
			[path removeAllPoints];
			[path appendBezierPathWithRect:NSMakeRect((bounds.origin.x) + 1 + ((bounds.size.width/8) * (toSquare%8)), 
												(bounds.origin.y) + 1 + ((bounds.size.height/8) * (toSquare/8)), 
												-2 + bounds.size.width/8, -2 + bounds.size.height/8)];
			[path stroke];
			[path removeAllPoints];
		}
		else if (flipped == YES && fromSquare != -1 && toSquare != -1) {
			
			[path appendBezierPathWithRect:NSMakeRect((bounds.origin.x) + 1 + (((63-fromSquare)%8) * (bounds.size.width/8)),
												(bounds.origin.y) + 1 + (((63-fromSquare)/8) * (bounds.size.height/8)), 
												-2 + bounds.size.width/8, -2 + bounds.size.height/8)];
			[path stroke];
			[path removeAllPoints];
			[path appendBezierPathWithRect:NSMakeRect((bounds.origin.x) + 1 + (((63-toSquare)%8) * (bounds.size.width/8)),
												(bounds.origin.y) + 1 + (((63-toSquare)/8) * (bounds.size.height/8)), 
												-2 + bounds.size.width/8, -2 + bounds.size.height/8)];
			[path stroke];
			[path removeAllPoints];
		}
		[NSGraphicsContext restoreGraphicsState];
	}
	
		
	
	
	// draw the pieces
	if (flipped == NO) {
		for (i=0; i<64; i++) {
			switch (displayBoard[i]) {
				case BV_WPAWN:
					imageRect.origin = NSMakePoint((CGFloat)((i%8) * (bounds.size.width/8.0)), (CGFloat)((i/8) * (bounds.size.height/8.0)));
					imageRect.size = squareSize;
					drawingRect = imageRect;
					[wp drawInRect:drawingRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
					break;
				case BV_WROOK:
					imageRect.origin = NSMakePoint((CGFloat)((i%8) * (bounds.size.width/8.0)), (CGFloat)((i/8) * (bounds.size.height/8.0)));
					imageRect.size = squareSize;
					drawingRect = imageRect;
					[wr drawInRect:drawingRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
					break;
				case BV_WKNIGHT:
					imageRect.origin = NSMakePoint((CGFloat)((i%8) * (bounds.size.width/8.0)), (CGFloat)((i/8) * (bounds.size.height/8.0)));
					imageRect.size = squareSize;
					drawingRect = imageRect;
					[wn drawInRect:drawingRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
					
					
					
					//[@"b" drawAtPoint:NSMakePoint((CGFloat)((i%8) * (bounds.size.width/8.0)), (CGFloat)((i/8) * (bounds.size.height/8.0))) withAttributes:backAttributes];
					//[@"B" drawAtPoint:NSMakePoint((CGFloat)((i%8) * (bounds.size.width/8.0)), (CGFloat)((i/8) * (bounds.size.height/8.0))) withAttributes:attributes];
					
					
					break;
				case BV_WBISHOP:
					imageRect.origin = NSMakePoint((CGFloat)((i%8) * (bounds.size.width/8.0)), (CGFloat)((i/8) * (bounds.size.height/8.0)));
					imageRect.size = squareSize;
					drawingRect = imageRect;
					[wb drawInRect:drawingRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
					
					//[@"c" drawAtPoint:NSMakePoint((CGFloat)((i%8) * (bounds.size.width/8.0)), (CGFloat)((i/8) * (bounds.size.height/8.0))) withAttributes:backAttributes];
					//[@"C" drawAtPoint:NSMakePoint((CGFloat)((i%8) * (bounds.size.width/8.0)), (CGFloat)((i/8) * (bounds.size.height/8.0))) withAttributes:attributes];
					
					break;
				case BV_WQUEEN:
					imageRect.origin = NSMakePoint((CGFloat)((i%8) * (bounds.size.width/8.0)), (CGFloat)((i/8) * (bounds.size.height/8.0)));
					imageRect.size = squareSize;
					drawingRect = imageRect;
					[wq drawInRect:drawingRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
					
					//[@"e" drawAtPoint:NSMakePoint((CGFloat)((i%8) * (bounds.size.width/8.0)), (CGFloat)((i/8) * (bounds.size.height/8.0))) withAttributes:backAttributes];
					//[@"E" drawAtPoint:NSMakePoint((CGFloat)((i%8) * (bounds.size.width/8.0)), (CGFloat)((i/8) * (bounds.size.height/8.0))) withAttributes:attributes];
					
					break;
				case BV_WKING:
					imageRect.origin = NSMakePoint((CGFloat)((i%8) * (bounds.size.width/8.0)), (CGFloat)((i/8) * (bounds.size.height/8.0)));
					imageRect.size = squareSize;
					drawingRect = imageRect;
					[wk drawInRect:drawingRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
					
					//[@"f" drawAtPoint:NSMakePoint((CGFloat)((i%8) * (bounds.size.width/8.0)), (CGFloat)((i/8) * (bounds.size.height/8.0))) withAttributes:backAttributes];
					//[@"F" drawAtPoint:NSMakePoint((CGFloat)((i%8) * (bounds.size.width/8.0)), (CGFloat)((i/8) * (bounds.size.height/8.0))) withAttributes:attributes];
					
					
					break;
				case BV_BPAWN:
					imageRect.origin = NSMakePoint((CGFloat)((i%8) * (bounds.size.width/8.0)), (CGFloat)((i/8) * (bounds.size.height/8.0)));
					imageRect.size = squareSize;
					drawingRect = imageRect;
					[bp drawInRect:drawingRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
					
					//[@"a" drawAtPoint:NSMakePoint((CGFloat)((i%8) * (bounds.size.width/8.0)), (CGFloat)((i/8) * (bounds.size.height/8.0))) withAttributes:attributes];
					
					//imageRect = NSMakeRect((CGFloat)((i%8) * (bounds.size.width/8.0)), (CGFloat)((i/8) * (bounds.size.height/8.0)), bounds.size.width/8, bounds.size.height/8);
					//[self drawString:@"a" centeredIn:imageRect];
					
					break;
				case BV_BROOK:
					imageRect.origin = NSMakePoint((CGFloat)((i%8) * (bounds.size.width/8.0)), (CGFloat)((i/8) * (bounds.size.height/8.0)));
					imageRect.size = squareSize;
					drawingRect = imageRect;
					[br drawInRect:drawingRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
					
					//[@"d" drawAtPoint:NSMakePoint((CGFloat)((i%8) * (bounds.size.width/8.0)), (CGFloat)((i/8) * (bounds.size.height/8.0))) withAttributes:attributes];
					
					break;
				case BV_BKNIGHT:
					imageRect.origin = NSMakePoint((CGFloat)((i%8) * (bounds.size.width/8.0)), (CGFloat)((i/8) * (bounds.size.height/8.0)));
					imageRect.size = squareSize;
					drawingRect = imageRect;
					[bn drawInRect:drawingRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
					
					//[@"b" drawAtPoint:NSMakePoint((CGFloat)((i%8) * (bounds.size.width/8.0)), (CGFloat)((i/8) * (bounds.size.height/8.0))) withAttributes:attributes];
					
					break;
				case BV_BBISHOP:
					imageRect.origin = NSMakePoint((CGFloat)((i%8) * (bounds.size.width/8.0)), (CGFloat)((i/8) * (bounds.size.height/8.0)));
					imageRect.size = squareSize;
					drawingRect = imageRect;
					[bb drawInRect:drawingRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
					
					//[@"c" drawAtPoint:NSMakePoint((CGFloat)((i%8) * (bounds.size.width/8.0)), (CGFloat)((i/8) * (bounds.size.height/8.0))) withAttributes:attributes];
					
					break;
				case BV_BQUEEN:
					imageRect.origin = NSMakePoint((CGFloat)((i%8) * (bounds.size.width/8.0)), (CGFloat)((i/8) * (bounds.size.height/8.0)));
					imageRect.size = squareSize;
					drawingRect = imageRect;
					[bq drawInRect:drawingRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
					
					//[@"e" drawAtPoint:NSMakePoint((CGFloat)((i%8) * (bounds.size.width/8.0)), (CGFloat)((i/8) * (bounds.size.height/8.0))) withAttributes:attributes];
					
					break;
				case BV_BKING:
					imageRect.origin = NSMakePoint((CGFloat)((i%8) * (bounds.size.width/8.0)), (CGFloat)((i/8) * (bounds.size.height/8.0)));
					imageRect.size = squareSize;
					drawingRect = imageRect;
					[bk drawInRect:drawingRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
					
					//[@"f" drawAtPoint:NSMakePoint((CGFloat)((i%8) * (bounds.size.width/8.0)), (CGFloat)((i/8) * (bounds.size.height/8.0))) withAttributes:attributes];
					
					break;

			}
		}
	}
	else
	{
		for (i=63; i>=0; i--) {
			switch (displayBoard[i]) {
				case BV_WPAWN:
					imageRect.origin = NSMakePoint((CGFloat)(((63-i)%8) * (bounds.size.width/8.0)), (CGFloat)(((63-i)/8) * (bounds.size.height/8.0)));
					imageRect.size = squareSize;
					drawingRect = imageRect;
					[wp drawInRect:drawingRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
					
					//imageRect = NSMakeRect((CGFloat)((i%8) * (bounds.size.width/8.0)), (CGFloat)((i/8) * (bounds.size.height/8.0)), bounds.size.width/8, bounds.size.height/8);
					//[self drawString:@"p" centeredIn:imageRect];
					break;
				case BV_WROOK:
					imageRect.origin = NSMakePoint((CGFloat)(((63-i)%8) * (bounds.size.width/8.0)), (CGFloat)(((63-i)/8) * (bounds.size.height/8.0)));
					imageRect.size = squareSize;
					drawingRect = imageRect;
					[wr drawInRect:drawingRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
					break;
				case BV_WKNIGHT:
					imageRect.origin = NSMakePoint((CGFloat)(((63-i)%8) * (bounds.size.width/8.0)), (CGFloat)(((63-i)/8) * (bounds.size.height/8.0)));
					imageRect.size = squareSize;
					drawingRect = imageRect;
					[wn drawInRect:drawingRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
					break;
				case BV_WBISHOP:
					imageRect.origin = NSMakePoint((CGFloat)(((63-i)%8) * (bounds.size.width/8.0)), (CGFloat)(((63-i)/8) * (bounds.size.height/8.0)));
					imageRect.size = squareSize;
					drawingRect = imageRect;
					[wb drawInRect:drawingRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
					break;
				case BV_WQUEEN:
					imageRect.origin = NSMakePoint((CGFloat)(((63-i)%8) * (bounds.size.width/8.0)), (CGFloat)(((63-i)/8) * (bounds.size.height/8.0)));
					imageRect.size = squareSize;
					drawingRect = imageRect;
					[wq drawInRect:drawingRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
					break;
				case BV_WKING:
					imageRect.origin = NSMakePoint((CGFloat)(((63-i)%8) * (bounds.size.width/8.0)), (CGFloat)(((63-i)/8) * (bounds.size.height/8.0)));
					imageRect.size = squareSize;
					drawingRect = imageRect;
					[wk drawInRect:drawingRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
					break;
				case BV_BPAWN:
					imageRect.origin = NSMakePoint((CGFloat)(((63-i)%8) * (bounds.size.width/8.0)), (CGFloat)(((63-i)/8) * (bounds.size.height/8.0)));
					imageRect.size = squareSize;
					drawingRect = imageRect;
					[bp drawInRect:drawingRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
					
					//imageRect = NSMakeRect((CGFloat)((i%8) * (bounds.size.width/8.0)), (CGFloat)((i/8) * (bounds.size.height/8.0)), bounds.size.width/8, bounds.size.height/8);
					//[self drawString:@"a" centeredIn:imageRect];
					
					break;
				case BV_BROOK:
					imageRect.origin = NSMakePoint((CGFloat)(((63-i)%8) * (bounds.size.width/8.0)), (CGFloat)(((63-i)/8) * (bounds.size.height/8.0)));
					imageRect.size = squareSize;
					drawingRect = imageRect;
					[br drawInRect:drawingRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
					break;
				case BV_BKNIGHT:
					imageRect.origin = NSMakePoint((CGFloat)(((63-i)%8) * (bounds.size.width/8.0)), (CGFloat)(((63-i)/8) * (bounds.size.height/8.0)));
					imageRect.size = squareSize;
					drawingRect = imageRect;
					[bn drawInRect:drawingRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
					break;
				case BV_BBISHOP:
					imageRect.origin = NSMakePoint((CGFloat)(((63-i)%8) * (bounds.size.width/8.0)), (CGFloat)(((63-i)/8) * (bounds.size.height/8.0)));
					imageRect.size = squareSize;
					drawingRect = imageRect;
					[bb drawInRect:drawingRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
					break;
				case BV_BQUEEN:
					imageRect.origin = NSMakePoint((CGFloat)(((63-i)%8) * (bounds.size.width/8.0)), (CGFloat)(((63-i)/8) * (bounds.size.height/8.0)));
					imageRect.size = squareSize;
					drawingRect = imageRect;
					[bq drawInRect:drawingRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
					break;
				case BV_BKING:
					imageRect.origin = NSMakePoint((CGFloat)(((63-i)%8) * (bounds.size.width/8.0)), (CGFloat)(((63-i)/8) * (bounds.size.height/8.0)));
					imageRect.size = squareSize;
					drawingRect = imageRect;
					[bk drawInRect:drawingRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
					break;
					
			}
		}
	}
	
	if (!dragging) {
		[[[NSColor redColor] colorWithAlphaComponent:0.25] set];
		
		
		[NSBezierPath setDefaultLineJoinStyle:NSRoundLineJoinStyle];
		NSBezierPath *moveArrowPath = [NSBezierPath bezierPath];
		
		[moveArrowPath setLineWidth:8.0];
		
		if (!flipped) {
			[moveArrowPath moveToPoint:NSMakePoint((bounds.origin.x) + ((fromSquare % 8) * squareWidth) + squareWidth/2, 
												   (bounds.origin.y) + ((fromSquare / 8) * squareHeight) + squareHeight/2)];
			[moveArrowPath lineToPoint:NSMakePoint((bounds.origin.x) + ((toSquare % 8) * squareWidth) + squareWidth/2, 
												   (bounds.origin.y) + ((toSquare / 8) * squareHeight) + squareHeight/2)];
			//[moveArrowPath stroke];
		}
		else {
			[moveArrowPath moveToPoint:NSMakePoint((bounds.origin.x) + (((63 - fromSquare) % 8) * squareWidth) + squareWidth/2, 
												   (bounds.origin.y) + (((63 - fromSquare) / 8) * squareHeight) + squareHeight/2)];
			[moveArrowPath lineToPoint:NSMakePoint((bounds.origin.x) + (((63 - toSquare) % 8) * squareWidth) + squareWidth/2, 
												   (bounds.origin.y) + (((63 - toSquare) / 8) * squareHeight) + squareHeight/2)];
			//[moveArrowPath stroke];
		}
		[moveArrowPath appendBezierPath:[moveArrowPath bezierPathWithArrowHeadForEndOfLength:squareWidth/2 angle:45]];
		[moveArrowPath stroke];
		[moveArrowPath removeAllPoints];
	}
	
	// draw circles
	[[[NSColor keyboardFocusIndicatorColor] colorWithAlphaComponent:0.5] set];
	
	NSBezierPath *oPath;
	for (int i = 0; i < 64; i++) {
		if (circleArray[i] == 1) {
			NSLog(@"circling: %i", i);
			if (! flipped)
				[NSBezierPath fillRect:NSMakeRect((i % 8) * squareWidth, 
																		   (i / 8) * squareHeight, 
																		   squareWidth, 
																		   squareHeight)];
			else
				[NSBezierPath fillRect:NSMakeRect(((63 - i) % 8) * squareWidth, 
																		   ((63 - i) / 8) * squareHeight, 
																		   squareWidth, 
																		   squareHeight) ];
			//[oPath setLineWidth:5.0];
			//[oPath stroke];
		}
	}

	// arrows
	
	[[[NSColor keyboardFocusIndicatorColor] colorWithAlphaComponent:0.5] set];
	
	[NSBezierPath setDefaultLineJoinStyle:NSRoundLineJoinStyle];
	NSBezierPath *aPath = [NSBezierPath bezierPath];
	
	[aPath setLineWidth:8.0];
	
	for (int i = 0; i < [fromArrowArray count]; i++) {
		if (!flipped) {
			[aPath moveToPoint:NSMakePoint((bounds.origin.x) + (([[fromArrowArray objectAtIndex:i] intValue] % 8) * squareWidth) + squareWidth/2, 
										   (bounds.origin.y) + (([[fromArrowArray objectAtIndex:i] intValue] / 8) * squareHeight) + squareHeight/2)];
			[aPath lineToPoint:NSMakePoint((bounds.origin.x) + (([[toArrowArray objectAtIndex:i] intValue] % 8) * squareWidth) + squareWidth/2, 
										   (bounds.origin.y) + (([[toArrowArray objectAtIndex:i] intValue] / 8) * squareHeight) + squareHeight/2)];
		}
		else {
			[aPath moveToPoint:NSMakePoint((bounds.origin.x) + (((63 - [[fromArrowArray objectAtIndex:i] intValue]) % 8) * squareWidth) + squareWidth/2, 
										   (bounds.origin.y) + (((63 - [[fromArrowArray objectAtIndex:i] intValue]) / 8) * squareHeight) + squareHeight/2)];
			[aPath lineToPoint:NSMakePoint((bounds.origin.x) + (((63 - [[toArrowArray objectAtIndex:i] intValue]) % 8) * squareWidth) + squareWidth/2, 
										   (bounds.origin.y) + (((63 - [[toArrowArray objectAtIndex:i] intValue]) / 8) * squareHeight) + squareHeight/2)];
		}
		[aPath appendBezierPath:[aPath bezierPathWithArrowHeadForEndOfLength:squareWidth/2 angle:45]];
		//[arrow closePath];
		//[arrow fill];
		[aPath stroke];
		[aPath removeAllPoints];
	}
	
	if (dragging) {
		imageRect.origin = NSMakePoint(currentPoint.x - squareSize.width/2, currentPoint.y - squareSize.height/2);
		imageRect.size = squareSize;
		drawingRect = imageRect;
		NSShadow *shadow = [[NSShadow alloc] init];
		[shadow setShadowOffset:NSMakeSize(2.0,-2.0)];
		[shadow setShadowBlurRadius:2.0];
		[shadow setShadowColor:[NSColor shadowColor]];
		[shadow set];
		[imageOfDraggedPiece drawInRect:drawingRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	}
}



// Converts square number to algebraic notation of square.
// It's used for sending moves a user makes 
- (NSString *)algebraicSquare:(int)numSquare
{
	int col, row;
	
	char aSquare[3];
	aSquare[2] = '\0';
	
	col = numSquare % 8;
	row = numSquare / 8;
	
	switch (row) {
		case 0:
			aSquare[1] = '1';
			break;
		case 1:
			aSquare[1] = '2';
			break;
		case 2:
			aSquare[1] = '3';
			break;
		case 3:
			aSquare[1] = '4';
			break;
		case 4:
			aSquare[1] = '5';
			break;
		case 5:
			aSquare[1] = '6';
			break;
		case 6:
			aSquare[1] = '7';
			break;
		case 7:
			aSquare[1] = '8';
			break;
		default:
			break;
	}
	
	switch (col) {
		case 0:
			aSquare[0] = 'a';
			break;
		case 1:
			aSquare[0] = 'b';
			break;
		case 2:
			aSquare[0] = 'c';
			break;
		case 3:
			aSquare[0] = 'd';
			break;
		case 4:
			aSquare[0] = 'e';
			break;
		case 5:
			aSquare[0] = 'f';
			break;
		case 6:
			aSquare[0] = 'g';
			break;
		case 7:
			aSquare[0] = 'h';
			break;
		default:
			break;
	}
	
	return [NSString stringWithCString:aSquare encoding:NSASCIIStringEncoding];
}



// takes a BOARDVIEW_PIECES and returns an NSImage of that piece
- (NSImage *)imageOfPiece:(BOARDVIEW_PIECES)piece
{
	switch (piece) {
		case BV_WPAWN:
			return wp;
			break;
		case BV_WROOK:
			return wr;
			break;
		case BV_WKNIGHT:
			return wn;
			break;
		case BV_WBISHOP:
			return wb;
			break;
		case BV_WQUEEN:
			return wq;
			break;
		case BV_WKING:
			return wk;
			break;
		case BV_BPAWN:
			return bp;
			break;
		case BV_BROOK:
			return br;
			break;
		case BV_BKNIGHT:
			return bn;
			break;
		case BV_BBISHOP:
			return bb;
			break;
		case BV_BQUEEN:
			return bq;
			break;
		case BV_BKING:
			return bk;
			break;
		default:
			return nil;
			//break;
	}
	 
	 
}



// We want the mouse down to drag pieces, not the window
- (BOOL)mouseDownCanMoveWindow 
{
	return NO;
}

- (void)resizeView:(NSNotification*)aNotification
{	
	//[CATransaction flush];
	//[CATransaction begin];
	//[CATransaction setValue:(id)kCFBooleanTrue
	//				forKey:kCATransactionDisableActions];
	
	CGRect b = [[self layer] bounds];
	
	squareWidth = b.size.width / 8.0;
	squareHeight = b.size.height / 8.0;
	
	if (squareWidth > squareHeight)
		[self loadImageWithSize:squareWidth];
	else
		[self loadImageWithSize:squareHeight];
	
	//int limit = [[[self layer] sublayers] count];
	
	/*
	CALayer *pieceLayer;
	for (int i = 0; i < limit; i++) {
		pieceLayer= [[[self layer] sublayers] lastObject];
		[pieceLayer removeFromSuperlayer];
	}
	
	[boardLayer setBounds:b];
	[[self layer] addSublayer:boardLayer];
	[boardLayer display];

	for (int i = 0; i < 64; i++) 
	{
		internalBoard[i];
		if (!flipped) {
			switch (internalBoard[i]) {
					
				case BV_WPAWN:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)wp1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", i]];
					[pieceLayer setPosition:CGPointMake((i % 8) * squareWidth, (i / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_BPAWN:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)bp1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", i]];
					[pieceLayer setPosition:CGPointMake((i % 8) * squareWidth, (i / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_WROOK:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)wr1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", i]];
					[pieceLayer setPosition:CGPointMake((i % 8) * squareWidth, (i / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_WKNIGHT:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)wn1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", i]];
					[pieceLayer setPosition:CGPointMake((i % 8) * squareWidth, (i / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_WBISHOP:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
				[pieceLayer setContents:(id)wb1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", i]];
					[pieceLayer setPosition:CGPointMake((i % 8) * squareWidth, (i / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_WQUEEN:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)wq1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", i]];
					[pieceLayer setPosition:CGPointMake((i % 8) * squareWidth, (i / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_WKING:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)wk1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", i]];
					[pieceLayer setPosition:CGPointMake((i % 8) * squareWidth, (i / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_BROOK:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)br1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", i]];
					[pieceLayer setPosition:CGPointMake((i % 8) * squareWidth, (i / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_BKNIGHT:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)bn1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", i]];
					[pieceLayer setPosition:CGPointMake((i % 8) * squareWidth, (i / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_BBISHOP:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)bb1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", i]];
					[pieceLayer setPosition:CGPointMake((i % 8) * squareWidth, (i / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_BQUEEN:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)bq1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", i]];
					[pieceLayer setPosition:CGPointMake((i % 8) * squareWidth, (i / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_BKING:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)bk1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", i]];
					[pieceLayer setPosition:CGPointMake((i % 8) * squareWidth, (i / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				default:
					break;
			}
		}
		else {
			switch (internalBoard[i]) {
				case BV_WPAWN:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)wp1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", (63 - i)]];
					[pieceLayer setPosition:CGPointMake(((63 - i) % 8) * squareWidth, ((63 - i) / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_BPAWN:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)bp1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", (63 - i)]];
					[pieceLayer setPosition:CGPointMake(((63 - i) % 8) * squareWidth, ((63 - i) / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_WROOK:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)wr1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", (63 - i)]];
					[pieceLayer setPosition:CGPointMake(((63 - i) % 8) * squareWidth, ((63 - i) / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_WKNIGHT:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)wn1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", (63 - i)]];
					[pieceLayer setPosition:CGPointMake(((63 - i) % 8) * squareWidth, ((63 - i) / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_WBISHOP:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)wb1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", (63 - i)]];
					[pieceLayer setPosition:CGPointMake(((63 - i) % 8) * squareWidth, ((63 - i) / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_WQUEEN:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)wq1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", (63 - i)]];
					[pieceLayer setPosition:CGPointMake(((63 - i) % 8) * squareWidth, ((63 - i) / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_WKING:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)wk1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", (63 - i)]];
					[pieceLayer setPosition:CGPointMake(((63 - i) % 8) * squareWidth, ((63 - i) / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_BROOK:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)br1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", (63 - i)]];
					[pieceLayer setPosition:CGPointMake(((63 - i) % 8) * squareWidth, ((63 - i) / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_BKNIGHT:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)bn1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", (63 - i)]];
					[pieceLayer setPosition:CGPointMake(((63 - i) % 8) * squareWidth, ((63 - i) / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_BBISHOP:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)bb1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", (63 - i)]];
					[pieceLayer setPosition:CGPointMake(((63 - i) % 8) * squareWidth, ((63 - i) / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_BQUEEN:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)bq1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", (63 - i)]];
					[pieceLayer setPosition:CGPointMake(((63 - i) % 8) * squareWidth, ((63 - i) / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_BKING:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)bk1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", (63 - i)]];
					[pieceLayer setPosition:CGPointMake(((63 - i) % 8) * squareWidth, ((63 - i) / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				default:
					break;
			}
		}
		
	}

	
	
	[CATransaction commit];
	 */
}


/*
- (void)viewDidEndLiveResize
{
	NSLog(@"view did end live resize");
	
	[CATransaction flush];
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue
					 forKey:kCATransactionDisableActions];
	
	CGRect b = [[self layer] bounds];
	
	if (abs(b.size.width) > abs(b.size.height)) {
		[[self layer] setBounds:CGRectMake(b.origin.x, b.origin.y, b.size.height, b.size.height)];
	}
	else {
		[[self layer] setBounds:CGRectMake(b.origin.x, b.origin.y, b.size.width, b.size.width)];

	}
	
	b = [[self layer] bounds];
	
	squareWidth = b.size.width / 8.0;
	squareHeight = b.size.height / 8.0;
	
	squareSize = NSMakeSize(squareWidth, squareHeight);
	
	if (squareWidth > squareHeight)
		[self loadImageWithSize:squareWidth];
	else
		[self loadImageWithSize:squareHeight];
	
	int limit = [[[self layer] sublayers] count];
	
	for (int i = 0; i < limit; i++) {
		CALayer *layers = [[[self layer] sublayers] lastObject];
		[layers removeFromSuperlayer];
	}
	
	CALayer *bLayer = [CALayer layer];
	[bLayer setAnchorPoint:CGPointMake(0, 0)];
	[bLayer setBounds:b];
	[bLayer setName:@"64"];
	[bLayer setDelegate:board];
	
	
	[[self layer] addSublayer:bLayer];
	[bLayer display];
	boardLayer = bLayer;
	
	CALayer *pieceLayer;
	for (int i = 0; i < 64; i++) 
	{
		internalBoard[i];
		if (!flipped) {
			switch (internalBoard[i]) {
					
				case BV_WPAWN:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)wp1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", i]];
					[pieceLayer setPosition:CGPointMake((i % 8) * squareWidth, (i / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_BPAWN:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)bp1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", i]];
					[pieceLayer setPosition:CGPointMake((i % 8) * squareWidth, (i / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_WROOK:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)wr1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", i]];
					[pieceLayer setPosition:CGPointMake((i % 8) * squareWidth, (i / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_WKNIGHT:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)wn1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", i]];
					[pieceLayer setPosition:CGPointMake((i % 8) * squareWidth, (i / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_WBISHOP:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)wb1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", i]];
					[pieceLayer setPosition:CGPointMake((i % 8) * squareWidth, (i / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_WQUEEN:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)wq1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", i]];
					[pieceLayer setPosition:CGPointMake((i % 8) * squareWidth, (i / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_WKING:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)wk1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", i]];
					[pieceLayer setPosition:CGPointMake((i % 8) * squareWidth, (i / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_BROOK:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)br1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", i]];
					[pieceLayer setPosition:CGPointMake((i % 8) * squareWidth, (i / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_BKNIGHT:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)bn1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", i]];
					[pieceLayer setPosition:CGPointMake((i % 8) * squareWidth, (i / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_BBISHOP:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)bb1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", i]];
					[pieceLayer setPosition:CGPointMake((i % 8) * squareWidth, (i / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_BQUEEN:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)bq1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", i]];
					[pieceLayer setPosition:CGPointMake((i % 8) * squareWidth, (i / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_BKING:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)bk1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", i]];
					[pieceLayer setPosition:CGPointMake((i % 8) * squareWidth, (i / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				default:
					break;
			}
		}
		else {
			switch (internalBoard[i]) {
				case BV_WPAWN:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)wp1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", (63 - i)]];
					[pieceLayer setPosition:CGPointMake(((63 - i) % 8) * squareWidth, ((63 - i) / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_BPAWN:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)bp1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", (63 - i)]];
					[pieceLayer setPosition:CGPointMake(((63 - i) % 8) * squareWidth, ((63 - i) / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_WROOK:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)wr1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", (63 - i)]];
					[pieceLayer setPosition:CGPointMake(((63 - i) % 8) * squareWidth, ((63 - i) / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_WKNIGHT:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)wn1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", (63 - i)]];
					[pieceLayer setPosition:CGPointMake(((63 - i) % 8) * squareWidth, ((63 - i) / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_WBISHOP:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)wb1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", (63 - i)]];
					[pieceLayer setPosition:CGPointMake(((63 - i) % 8) * squareWidth, ((63 - i) / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_WQUEEN:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)wq1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", (63 - i)]];
					[pieceLayer setPosition:CGPointMake(((63 - i) % 8) * squareWidth, ((63 - i) / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_WKING:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)wk1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", (63 - i)]];
					[pieceLayer setPosition:CGPointMake(((63 - i) % 8) * squareWidth, ((63 - i) / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_BROOK:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)br1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", (63 - i)]];
					[pieceLayer setPosition:CGPointMake(((63 - i) % 8) * squareWidth, ((63 - i) / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_BKNIGHT:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)bn1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", (63 - i)]];
					[pieceLayer setPosition:CGPointMake(((63 - i) % 8) * squareWidth, ((63 - i) / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_BBISHOP:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)bb1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", (63 - i)]];
					[pieceLayer setPosition:CGPointMake(((63 - i) % 8) * squareWidth, ((63 - i) / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_BQUEEN:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)bq1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", (63 - i)]];
					[pieceLayer setPosition:CGPointMake(((63 - i) % 8) * squareWidth, ((63 - i) / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				case BV_BKING:
					pieceLayer = [CALayer layer];
					[pieceLayer setAnchorPoint:CGPointMake(0,0)];
					[pieceLayer setFrame:CGRectMake(0, 0, squareWidth, squareHeight)];
					[pieceLayer setDelegate:self];
					[pieceLayer setContents:(id)bk1];
					[pieceLayer setName:[NSString stringWithFormat:@"%i", (63 - i)]];
					[pieceLayer setPosition:CGPointMake(((63 - i) % 8) * squareWidth, ((63 - i) / 8) * squareHeight)];
					[[self layer] addSublayer:pieceLayer];
					[pieceLayer display];
					break;
				default:
					break;
			}
		}
		
	}
	
	[CATransaction commit];

}
*/

#pragma mark -
#pragma mark MouseEvents

- (void)mouseDown:(NSEvent *)event 
{
	
	NSPoint p = [event locationInWindow];
	downPoint = [self convertPoint:p fromView:nil];
	currentPoint = downPoint;
	
	moveFromSquare = [self pointToSquare:currentPoint];
	lastMoveFromSquare = moveFromSquare;
	
	if (userSelectedMove) {
		[self setFen:[positionsArray lastObject]];
		userSelectedMove = NO;
	}
	
	
	if (moveFromSquare == -1 || (status == BV_DEAD || status == BV_USEROBS || status == BV_NEW)) {
		dragging = NO;
		moveFromSquare = -1;
	}
	else if (internalBoard[moveFromSquare] != BV_EMPTY && 
			 ((status == BV_USEREXAMINE && (((numHalfMoves % 2 == 0) && [self isWhitePiece:moveFromSquare]) || ((numHalfMoves % 2 != 0) && ![self isWhitePiece:moveFromSquare]))) ||
		((status == BV_USERWHITE && [self isWhitePiece:moveFromSquare]) || ( status == BV_USERBLACK && ![self isWhitePiece:moveFromSquare])))) {
		dragging = YES;
		draggedPiece = internalBoard[moveFromSquare];
		imageOfDraggedPiece = [self imageOfPiece:draggedPiece];
		displayBoard[moveFromSquare] = BV_EMPTY;
		fromSquare = moveFromSquare;
		
		[[NSCursor closedHandCursor] push];
				 
		// get the piece that we are selecting
		//draggedLayer = [[self layer] hitTest:CGPointMake(currentPoint.x, currentPoint.y)];
		
		/*
		if ([[draggedLayer name] intValue] < 0 || [[draggedLayer name] intValue] > 63) {
			draggedLayer = nil;
			dragging = NO;
		}
		
		// something went wrong, so we don't want to continue dragging
		if (!draggedLayer) {
			dragging = NO;
		}
		else {
			[CATransaction flush];
			[CATransaction begin];
			[CATransaction setValue:(id)kCFBooleanTrue
							 forKey:kCATransactionDisableActions];

			// we want the dragged piece layer to be above all other layers
			[draggedLayer removeFromSuperlayer];
			[[self layer] insertSublayer:draggedLayer atIndex:[[[self layer] sublayers] count]];
			
			
			[draggedLayer setShadowOpacity:1.0];
			[draggedLayer setAnchorPoint:CGPointMake(0.5, 0.5)];
			[draggedLayer setPosition:CGPointMake(currentPoint.x, currentPoint.y)];			
			[CATransaction commit];		
			[[NSCursor closedHandCursor] push];
			
			[board fromSquare:moveFromSquare toSquare:moveFromSquare];
			[boardLayer setNeedsDisplay];
		}
		*/
	}
	
	[self setNeedsDisplay:YES];
	
	
	
}

- (void)mouseDragged:(NSEvent *)event 
{
	if (dragging) {
	
		NSPoint p = [event locationInWindow];
		currentPoint = [self convertPoint:p fromView:nil];
		
		[self setNeedsDisplay:YES];
		
		
		/*
		[CATransaction flush];
		[CATransaction begin];
		[CATransaction setValue:(id)kCFBooleanTrue
						 forKey:kCATransactionDisableActions];
		*/
		if (currentPoint.x > [self bounds].size.width)
			currentPoint.x = [self bounds].size.width - (squareWidth/2);
		if (currentPoint.x < 0)
			currentPoint.x = 0 + (squareWidth/2);
		if (currentPoint.y > [self bounds].size.height)
			currentPoint.y = [self bounds].size.height - (squareHeight/2);
		if (currentPoint.y < 0)
			currentPoint.y = 0 + (squareHeight/2);
		
		fromSquare = moveFromSquare;
		toSquare = [self pointToSquare:currentPoint];
		/*
		[board fromSquare:fromSquare toSquare:toSquare];
		[boardLayer setNeedsDisplay];
		*/
		//CGPoint newPos = [draggedLayer.superlayer convertPoint: NSPointToCGPoint(currentPoint) 
		//				  fromLayer: self.layer];

		//CGPoint newPos = CGPointMake(currentPoint.x, currentPoint.y);
		
		//draggedLayer.position = newPos;
		
		//[CATransaction commit];		
	}
}

- (void)mouseUp:(NSEvent *)event
{
	NSPoint screenPoint = [NSEvent mouseLocation];
	
	NSPoint p = [event locationInWindow];
	currentPoint = [self convertPoint:p fromView:nil];
	
	if (dragging == YES) {
		
		[NSCursor pop];
		
		if (currentPoint.x > [self bounds].size.width)
			currentPoint.x = [self bounds].size.width - (squareWidth/2);
		if (currentPoint.x < 0)
			currentPoint.x = 0 + (squareWidth/2);
		if (currentPoint.y > [self bounds].size.height)
			currentPoint.y = [self bounds].size.height - (squareHeight/2);
		if (currentPoint.y < 0)
			currentPoint.y = 0 + (squareHeight/2);
		
		// Stop indicating that we're dragging
		dragging = NO;
		
		// Convert point where mouseUp occurs to a square, and assign that to moveToSquare
		moveToSquare = [self pointToSquare:currentPoint];
		
		// Make sure that both squares in the move are valid squares
		if (moveFromSquare != -1 && moveToSquare != -1) {
			
			// If the color of the side to move is the same as the color of the dragged piece,
			// we send a command to execute the dragged move.
			//
			// Otherwise, if we're not in examine mode (status is either BV_USERWHITE or BV_USERBLACK,
			// we don't send the move immediately but handle sending the dragged move later after we 
			// receive a move from the server. (In other words, we pre-move the dragged move).
			
			if ((numHalfMoves % 2 == 0 && [self pieceIsWhitePiece:draggedPiece] == YES) || (numHalfMoves % 2 != 0 && [self pieceIsWhitePiece:draggedPiece] == NO)) {
				
				// remove dragged piece from initial square
				displayBoard[moveFromSquare] = BV_EMPTY;
				
				// place dragged piece on the destination square
				displayBoard[moveToSquare] = internalBoard[moveFromSquare];
				
				/*
				[CATransaction flush];
				[CATransaction begin];
				[CATransaction setValue:(id)kCFBooleanTrue
								 forKey:kCATransactionDisableActions];
				[draggedLayer setShadowOpacity:0.0];
				[draggedLayer setAnchorPoint:CGPointMake(0, 0)];
				if (!flipped) {
					[draggedLayer setPosition:CGPointMake((moveToSquare % 8) * squareWidth, (moveToSquare / 8) * squareHeight)];
				} else {
					[draggedLayer setPosition:CGPointMake(((63 - moveToSquare) % 8) * squareWidth, ((63 - moveToSquare) / 8) * squareHeight)];
				}
				[CATransaction commit];
				*/
				//draggedLayer = nil;
				
				fromSquare = moveFromSquare;
				toSquare = moveToSquare;
				
				//[board fromSquare:fromSquare toSquare:toSquare];
				//[boardLayer setNeedsDisplay];
				moveFromSquare = -1;
				moveToSquare = -1;
				
				NSLog(@"sending move to BoardController");

				if ((draggedPiece == BV_WPAWN && (fromSquare >= 48 && fromSquare <= 55) && (toSquare >= 56 && toSquare <= 63)) ||
					(draggedPiece == BV_BPAWN && (fromSquare >= 8 && fromSquare <= 15) && (toSquare >= 0 && toSquare <= 7))) {
					[bvDelegate promoteFrom:[self algebraicSquare:fromSquare] 
										 to:[self algebraicSquare:toSquare] 
									  color:[self pieceIsWhitePiece:draggedPiece]
									atPoint:screenPoint];
				}
				else {
					[bvDelegate sendCommandStr:[NSString stringWithFormat:@"%@%@", 
												[self algebraicSquare:fromSquare], [self algebraicSquare:toSquare]]];
				}
				myMovedPiece = YES;
			}
			else if ((status == BV_USERWHITE && numHalfMoves % 2 != 0) || (status == BV_USERBLACK && numHalfMoves % 2 == 0)) {
			
				// pre move:
				// pre moving is handled in move:
				// so we just highlight the squares for now
				
				displayBoard[moveFromSquare] = internalBoard[moveFromSquare];
				displayBoard[moveToSquare] = internalBoard[moveToSquare];
				
				/*
				[CATransaction flush];
				[CATransaction begin];
				[CATransaction setValue:(id)kCFBooleanTrue
								 forKey:kCATransactionDisableActions];
				[draggedLayer setShadowOpacity:0.0];
				[draggedLayer setAnchorPoint:CGPointMake(0, 0)];
				if (!flipped) {
					NSLog(@"To Square: %i", moveToSquare);
					[draggedLayer setPosition:CGPointMake((moveToSquare % 8) * squareWidth, (moveToSquare / 8) * squareHeight)];
				} else {
					NSLog(@"To Square: %i", 63 - moveToSquare);
					[draggedLayer setPosition:CGPointMake(((63 - moveToSquare) % 8) * squareWidth, ((63 - moveToSquare) / 8) * squareHeight)];
				}
				[CATransaction commit];
				[draggedLayer display];
				draggedLayer = nil;
				 */
				
				fromSquare = moveFromSquare;
				toSquare = moveToSquare;
				
				//[board fromSquare:fromSquare toSquare:toSquare];
				//[boardLayer setNeedsDisplay];
			}
			else {
				for (int i=0; i<64; i++) { 
					displayBoard[i] = internalBoard[i];
				}
				if (numHalfMoves > 0)
					[self setFen:[positionsArray lastObject]];
				/*
				else 
					if (draggedLayer && moveFromSquare != -1) {
						[draggedLayer setShadowOpacity:0.0];
						[draggedLayer setAnchorPoint:CGPointMake(0, 0)];
						if (!flipped)
							[draggedLayer setPosition:CGPointMake((lastMoveFromSquare % 8) * squareWidth, (lastMoveFromSquare / 8) * squareHeight)];
						else
							[draggedLayer setPosition:CGPointMake(((63 - lastMoveFromSquare) % 8) * squareWidth, ((63 - lastMoveFromSquare) / 8) * squareHeight)];
					}
				draggedLayer = nil;
				*/
				
				moveFromSquare = -1;
				moveToSquare = -1;
				
				//[board fromSquare:-1 toSquare:-1];
			}
		} else {
			for (int i=0; i<64; i++) { 
				displayBoard[i] = internalBoard[i];
			}
			if (numHalfMoves > 0)
				[self setFen:[positionsArray lastObject]];
			/*
			else
				if (draggedLayer && moveFromSquare != -1) {
					[draggedLayer setShadowOpacity:0.0];
					[draggedLayer setAnchorPoint:CGPointMake(0, 0)];
					if (!flipped)
						[draggedLayer setPosition:CGPointMake((lastMoveFromSquare % 8) * squareWidth, (lastMoveFromSquare / 8) * squareHeight)];
					else
						[draggedLayer setPosition:CGPointMake(((63 - lastMoveFromSquare) % 8) * squareWidth, ((63 - lastMoveFromSquare) / 8) * squareHeight)];
				}
			draggedLayer = nil;
			 */
			moveFromSquare = -1;
			moveToSquare = -1;
			//[board fromSquare:-1 toSquare:-1];
		}
	}
	else {	
		for (int i=0; i<64; i++) { 
			displayBoard[i] = internalBoard[i];
		}
		if (numHalfMoves > 0)			
			[self setFen:[positionsArray lastObject]];
		/*
		else
			if (draggedLayer && moveFromSquare != -1) {
				[draggedLayer setShadowOpacity:0.0];
				[draggedLayer setAnchorPoint:CGPointMake(0, 0)];
				if (!flipped)
					[draggedLayer setPosition:CGPointMake((lastMoveFromSquare % 8) * squareWidth, (lastMoveFromSquare / 8) * squareHeight)];
				else
					[draggedLayer setPosition:CGPointMake(((63 - lastMoveFromSquare) % 8) * squareWidth, ((63 - lastMoveFromSquare) / 8) * squareHeight)];
			}
		draggedLayer = nil;
		 */
		moveFromSquare = -1;
		moveToSquare = -1;
		//[board fromSquare:-1 toSquare:-1];
	}
	
	[self setNeedsDisplay:YES];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	NSPoint p = [theEvent locationInWindow];
	p = [self convertPoint:p fromView:nil];
	
	rightFromSquare = [self pointToSquare:p];	
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
	NSPoint p = [theEvent locationInWindow];
	p = [self convertPoint:p fromView:nil];
	
	rightToSquare = [self pointToSquare:p];
	
	if (rightFromSquare != -1 && rightToSquare != -1) {
		if (rightFromSquare == rightToSquare) {
			[bvDelegate sendCommandStr:[NSString stringWithFormat:@"circle %@", [self algebraicSquare:rightToSquare]]];
			
			rightFromSquare = -1;
			rightToSquare = -1;
		}
		else {
			[bvDelegate sendCommandStr:[NSString stringWithFormat:@"arrow %@ %@", [self algebraicSquare:rightFromSquare], 
										[self algebraicSquare:rightToSquare]]];
			
			rightFromSquare = -1;
			rightToSquare = -1;
		}
	}




}
	

@end
