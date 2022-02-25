//
//  Board.h
//  ICC Test App
//
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "AJHBezierUtils.h"

@interface Board : NSObject {
	int circleArray[64];
	BOOL flipped;

	NSMutableArray *fromArrowArray;
	NSMutableArray *toArrowArray;

	int fromSquare;
	int toSquare;
	
	NSBundle *appBundle;
	NSString *path;
	NSImage *darkwood;
	NSImage *lightwood;
}

- (id)init;
- (void)setFlipped:(BOOL)f;
- (void)deleteAllCircles;
- (void)addOrDeleteCircle:(int)squareNumber;
- (void)deleteAllArrows;
- (void)addArrowFrom:(int)fromS to:(int)toS;
- (void)deleteArrowFrom:(int)fromS to:(int)toS;
- (void)fromSquare:(int)f toSquare:(int)t;



@end
