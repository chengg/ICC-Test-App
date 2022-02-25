//
//  BoardController.h
//  ICC Test App
//


#import <Cocoa/Cocoa.h>
#import "BoardView.h"
#include "GCTableView.h"
#import <BWToolkitFramework/BWToolkitFramework.h>


@class BoardView;
@class GCTableView;

@interface BoardController : NSWindowController <GCTableDatasource> {
	
	
	NSToolbar *playToolbar;
	NSToolbar *examineToolbar;
	NSToolbar *observeToolbar;
	
	
	IBOutlet NSWindow *whitePromotionWindow;
	IBOutlet NSWindow *blackPromotionWindow;
	NSString *promotionString;
	
	IBOutlet NSTextField *row1;
	IBOutlet NSTextField *row2;
	IBOutlet NSTextField *row3;
	IBOutlet NSTextField *row4;
	IBOutlet NSTextField *row5;
	IBOutlet NSTextField *row6;
	IBOutlet NSTextField *row7;
	IBOutlet NSTextField *row8;
	
	IBOutlet NSTextField *col1;
	IBOutlet NSTextField *col2;
	IBOutlet NSTextField *col3;
	IBOutlet NSTextField *col4;
	IBOutlet NSTextField *col5;
	IBOutlet NSTextField *col6;
	IBOutlet NSTextField *col7;
	IBOutlet NSTextField *col8;
	
	IBOutlet GCTableView *movesGCTableView;

	IBOutlet BoardView *boardView;
	
	IBOutlet NSPopUpButton *commandButton;
	IBOutlet NSTextField *textField;
	
	IBOutlet NSTextView *chatView;
	
	IBOutlet NSTextField *topPlayer;
	IBOutlet NSTextField *bottomPlayer;
	
	IBOutlet NSTextField *topClock;
	IBOutlet NSTextField *bottomClock;
	
	IBOutlet NSTextField *topResult;
	IBOutlet NSTextField *bottomResult;
	
	IBOutlet BWGradientBox *topBox;
	IBOutlet BWGradientBox *bottomBox;
	
	//IBOutlet NSButton *revertButton;
	IBOutlet NSButton *forwardButton;
	IBOutlet NSButton *backwardButton;
	IBOutlet NSButton *backwardAllButton;
	IBOutlet NSButton *forwardAllButton;
	
	id boardDelegate;
	
	NSString *gamenumber;
	
	int wildNumber;
	
	BV_STATUS status;
	
	NSTimer *countDownTimer;
	
	NSMutableArray *whiteArray;
	NSMutableArray *blackArray;
	
	BOOL rated;
	NSString *ratingType;
	
	int initialClock;
	int increment;
	
	BOOL whiteAtBottom;
	
	BOOL whiteMove;
	long numMoves;
	
	long long whiteClock;
	long long blackClock;
	
	NSString *whitePlayer;
	NSString *blackPlayer;
	
	NSString *whiteTitle;
	NSString *blackTitle;
	
	NSString *whitePlayerAndRating;
	NSString *blackPlayerAndRating;
	
	NSMutableArray *positionsArray;
	
}

- (void)setBoardDelegate:(id)d;
- (void)setFen:(NSString *)f;

- (void)reset;


- (void)setWildNumber:(int)wn;

- (void)setNumMoves:(long)nm;
- (void)setWhiteMove:(BOOL)move;

- (void)setGameNumber:(NSString *)gn;
- (NSString *)gameNumber;

- (void)setRated:(NSString *)ratedStr type:(NSString *)ratingTypeStr;
- (void)setInitialClock:(NSString *)clockStr initialIncrement:(NSString *)incrementStr;

- (void)setBlackPlayer:(NSString*)bp withRating:(NSString *)br title:(NSString *)t;
- (void)setWhitePlayer:(NSString *)wp withRating:(NSString *)wr title:(NSString *)t;

- (NSString *)getBlackPlayer;
- (NSString *)getWhitePlayer;

- (void)algebraicMove:(NSString *)algebraic smithMove:(NSString *)smith;
- (void)takeback:(int)takebackCount;

- (void)setClock:(NSString *)clock;
- (void)setWhiteClock:(long long)wc;
- (void) setBlackClock:(long long)bc;

- (void)appendChat:(NSString *)chatStr attributes:(NSMutableDictionary *)a;

- (void)stopClockCountDown;
- (void)startClockCountDown;

- (void)gameResult:(NSString *)resultStr;

- (BV_STATUS)getStatus;
- (void)setStatus:(BV_STATUS)s;

- (void)flip;
- (void)unFlip;

- (void)kibitz:(NSString *)kibStr;

- (void)illegalMove;

- (void)numMovesToFollow:(int)num;

- (void)circle:(NSString *)coordinate;
- (void)arrowFrom:(NSString *)fromS to:(NSString *)toS;
- (void)unarrowFrom:(NSString *)fromS to:(NSString *)toS;

- (void)promoteFrom:(NSString *)fromString to:(NSString *)toString color:(BOOL)isWhite atPoint:(NSPoint)screenPoint;
- (IBAction)promoteToQueen:(id)sender;
- (IBAction)promoteToRook:(id)sender;
- (IBAction)promoteToBishop:(id)sender;
- (IBAction)promoteToKnight:(id)sender;

- (BOOL)windowShouldClose:(id)sender;
- (void)windowWillClose:(NSNotification *)aNotification;
- (void)setWindowTitle;
- (IBAction)sendFingerCommand:(id)sender;
- (IBAction)sendCommand:(id)sender;
- (void)sendCommandStr:(NSString *)str;

/*
- (NSSize)windowWillResize:(NSWindow *)sender
					toSize:(NSSize)frameSize;
*/

- (IBAction)back1:(id)sender;
- (IBAction)forward1:(id)sender;
- (IBAction)back999:(id)sender;
- (IBAction)forward999:(id)sender;
- (IBAction)revert:(id)sender;

- (int)rowsForTable:(GCTableView *)gc;
- (NSString *)stringForTable:(GCTableView *)gc forRow:(int)row column:(int)col;
- (void)clickedMoveList:(id)sender;
- (IBAction)moveForward:(id)sender;
- (IBAction)moveBack:(id)sender;
- (IBAction)moveToEnd:(id)sender;
- (IBAction)moveToStart:(id)sender;

@end
