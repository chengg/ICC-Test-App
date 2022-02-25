//
//  BoardView.h
//  ICC Test App
//


#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
//#import <QuartzCore/CoreAnimation.h>
#include "AJHBezierUtils.h"

@class BoardController;

typedef enum  {
	BV_WPAWN = 0,
	BV_WKNIGHT,
	BV_WBISHOP,
	BV_WROOK,
	BV_WQUEEN,
	BV_WKING,
	BV_BPAWN,
	BV_BKNIGHT,
	BV_BBISHOP,
	BV_BROOK,
	BV_BQUEEN,
	BV_BKING,
	BV_EMPTY
} BOARDVIEW_PIECES;

typedef enum { 
	BV_DEAD = 0,
	BV_USEREXAMINE = 1,
	BV_NEW = 2,
	BV_USERWHITE = 3,
	BV_USERBLACK = 4,
	BV_USEROBS = 5
} BV_STATUS;

@interface BoardView : NSView {
		
	NSNotificationCenter *nc;
	
	NSArray *pieceNames;
	
	NSMutableArray *capturedPieces;
	
	// board layer and delegate for the board layer
	//CALayer *boardLayer;
	//Board *board;
	
	int numMovesToFollow;
	
	// the squares where the user moved a piece from and to
	int myFromSquare;
	int myToSquare;
	
	// points to piece layer being dragged
	//CALayer *draggedLayer;
	
	// keeps track of the square the user moved a piece from
	// so that if the user made an illegal move we know where to retract that piece to
	int lastMoveFromSquare;
	
	// keeps track of whether it is the user that moved the piece (as opposed to, for example, the user's opponent)
	BOOL myMovedPiece;
	
	// keep track whether the board is currently flipped, and whether that is different from the previous orientation
	BOOL flipped;
	BOOL prevFlip;
	
	BOOL userSelectedMove;
	
	// application bundle
	NSBundle *appBundle;
	
	// Keeping track of the point where we moused down and the current point if we're dragging the mouse
	NSPoint downPoint;
	NSPoint currentPoint;
	
	// BoardView delegate
	id bvDelegate;
	
	// Status of game
	BV_STATUS status;
	
	// Keep track of the dimensions of a chess board square
	float squareHeight;
	float squareWidth;
	NSSize squareSize;
	
	// Path to access the piece images
	NSString *imagePath;
	
	
	
	NSImage *wr;
	NSImage *wn;
	NSImage *wb;
	NSImage *wq;
	NSImage *wk;
	NSImage *wp;
	
	NSImage *br;
	NSImage *bn;
	NSImage *bb;
	NSImage *bq;
	NSImage *bk;
	NSImage *bp;
	
	// 1) Are we currently dragging a piece?
	// 2) Dragged piece.
	// 3) Image of dragged piece.
	BOOL dragging;
	BOARDVIEW_PIECES draggedPiece;
	NSImage *imageOfDraggedPiece;
	
	// squares to draw square around
	int fromSquare;
	int toSquare;
	
	// player move squares
	int moveFromSquare;
	int moveToSquare;

	
	// right click squares
	int rightFromSquare;
	int rightToSquare;
	
	int circleArray[64];
	NSMutableArray *fromArrowArray;
	NSMutableArray *toArrowArray;
	
	// Number of half-moves (every move, whether black or white, increments this)
	int numHalfMoves;
	
	// The wild number of the game.
	// Not used right now but might be useful in the future
	int wildNumber;
	
	// An array of FEN-encoded positions that is added to after every move.
	// It is used for takebacks and going backwards
	NSMutableArray *positionsArray;
	
	// internally keeping track of the pieces
	BOARDVIEW_PIECES displayBoard[64];
	BOARDVIEW_PIECES internalBoard[64];
	
}
- (void)setDelegate:(id)o;
//CGImageRef LoadImageFromMainBundle(CFStringRef imageName, CFStringRef dirName);
- (void)numMovesToFollow:(int)num;
- (void)setWildNumber:(int)wild;
- (void)setStatus:(BV_STATUS)s;
- (void)reset;
- (void)flip:(BOOL)b;
- (void)move:(NSString *)smithMove;
- (void)takeback;
/*
- (CALayer *)animateFrom:(int)s1 to:(int)s2;
- (NSPoint)randomOffViewPosition;
- (CALayer *)unanimatedFrom:(int)fromS to:(int)toS;
*/
- (void)circle:(NSString *)coordinate;
- (void)arrowFrom:(NSString *)fromS to:(NSString *)toS;
- (void)unarrowFrom:(NSString *)fromS to:(NSString *)toS;
- (void)deleteAllCircles;
- (void)addOrDeleteCircle:(int)squareNumber;
- (void)deleteAllArrows;
- (void)addArrowFrom:(int)fromS to:(int)toS;
- (void)deleteArrowFrom:(int)fromS to:(int)toS;
- (int)coordinateToSquareNumber:(NSString *)coordinateString;

- (void)illegalMove;
-(void)externalSetFen:(NSString* )fen;
- (void)setFen:(NSString* )fen;
- (void)displaySetFen:(NSString *)fen;
- (NSString *)fen;
char CVPieceToChar(BOARDVIEW_PIECES p);
- (int)pointToSquare:(NSPoint)point;
- (BOOL)isWhitePiece:(int)i;
- (NSImage *)imageOfPiece:(BOARDVIEW_PIECES)piece;
- (NSString *)algebraicSquare:(int)numSquare;
- (void)resizeView:(NSNotification*)aNotification;
@end
