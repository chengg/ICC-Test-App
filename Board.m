//
//  Board.m
//  ICC Test App
//


#import "Board.h"


@implementation Board

- (id) init
{
    self = [super init];
    if (self != nil) {
		
		appBundle = [NSBundle mainBundle];
		path = [appBundle pathForImageResource:@"darkwood"];
		darkwood = [[NSImage alloc] initWithContentsOfFile:path];
		path = [appBundle pathForImageResource:@"whitewood"];
		lightwood = [[NSImage alloc] initWithContentsOfFile:path];
		
		flipped = NO;
		
		for (int i = 0; i < 64; i++) {
			circleArray[i] = 0;
		}
		
		fromArrowArray = [[NSMutableArray alloc] init];
		toArrowArray = [[NSMutableArray alloc] init];
		
		fromSquare = -1;
		toSquare = -1;
    }
    return self;
}

- (void)setFlipped:(BOOL)f
{
	flipped = f;
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

- (void)fromSquare:(int)f toSquare:(int)t
{
	fromSquare = f;
	toSquare = t;
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
	NSLog(@"board drawLayer:");
	CGRect cgb = [layer bounds];
	
	
	NSGraphicsContext *nsGraphicsContext;
	nsGraphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:ctx
																   flipped:NO];
	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext:nsGraphicsContext];
	
	// ...Draw content using NS APIs...
	NSRect bounds = NSMakeRect(cgb.origin.x, cgb.origin.y, cgb.size.width, cgb.size.height);
	
	//[[NSColor whiteColor] set];
	//[NSBezierPath fillRect:bounds];
	
	[[NSColor darkGrayColor] set];
	
	float yPoint, xPoint;
	int k = 0;
	
	float squareHeight = bounds.size.height/8;
	float squareWidth = bounds.size.width/8;
	
	//NSSize squareSize = NSMakeSize(squareWidth, squareHeight);
	
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
				//[[NSColor alternateSelectedControlColor] set];
				[NSBezierPath fillRect:NSMakeRect(xPoint, yPoint, paintWidth, paintHeight)];
				//[lightwood drawInRect:NSMakeRect(xPoint, yPoint, paintWidth, paintHeight) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
				whiteColor = YES;
			} else {
				//[[NSColor lightGrayColor] set];
				//[[NSColor whiteColor] set];
				[[NSColor clearColor] set];
				[NSBezierPath fillRect:NSMakeRect(xPoint, yPoint, paintWidth, paintHeight)];
				//[darkwood drawInRect:NSMakeRect(xPoint, yPoint, paintWidth, paintHeight) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
				whiteColor = NO;
			}
		}
		
		k++;
		if (k%2 == 0)
			whiteColor = NO;
		else
			whiteColor = YES;
	}
	
	
	// draw circles
	[[NSColor keyboardFocusIndicatorColor] set];
	
	NSBezierPath *oPath;
	for (int i = 0; i < 64; i++) {
		if (circleArray[i] == 1) {
			NSLog(@"circling: %i", i);
			if (! flipped)
				oPath = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect((i % 8) * squareWidth + 3.0, 
																			(i / 8) * squareHeight + 3.0, 
																			squareWidth - 6.0, 
																			squareHeight - 6.0) 
														xRadius:10.0 
														yRadius:10.0];
			else
				oPath = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(((63 - i) % 8) * squareWidth + 3.0, 
																		  ((63 - i) / 8) * squareHeight + 3.0, 
																		  squareWidth - 6.0, 
																		  squareHeight - 6.0) 
														xRadius:10.0
														yRadius:10.0];
			[oPath setLineWidth:5.0];
			[oPath stroke];
		}
	}
	
	// highlight from square and to square
	
	[[NSColor keyboardFocusIndicatorColor] set];
	//[[NSColor redColor] set];
	NSBezierPath *bPath = [NSBezierPath bezierPath];
	[bPath setLineWidth:5.0];
	if (flipped == NO && fromSquare != -1 && toSquare != -1) {
		[bPath appendBezierPathWithRect:NSMakeRect((bounds.origin.x) + 3.0 + (squareWidth * (fromSquare%8)), 
														  (bounds.origin.y) + 3.0 + (squareHeight * (fromSquare/8)), 
														  squareWidth - 6.0, squareHeight - 6.0)];
		/*
		[bPath appendBezierPathWithRect:NSMakeRect((bounds.origin.x) + 4.0 + (squareWidth * (fromSquare%8)), 
												  (bounds.origin.y) + 4.0 + (squareHeight * (fromSquare/8)), 
												  squareWidth - 8.0, squareHeight - 8.0)];
		 */
		[bPath stroke];
		//[bPath fill];
		[bPath removeAllPoints];
		
		[bPath appendBezierPathWithRect:NSMakeRect((bounds.origin.x) + 3.0 + (squareWidth * (toSquare%8)), 
														  (bounds.origin.y) + 3.0 + (squareHeight * (toSquare/8)), 
														  squareWidth - 6.0, squareHeight - 6.0)];
		/*
		[bPath appendBezierPathWithRect:NSMakeRect((bounds.origin.x) + 4.0 + (squareWidth * (toSquare%8)), 
												  (bounds.origin.y) + 4.0 + (squareHeight * (toSquare/8)), 
												  squareWidth - 8.0, squareHeight - 8.0)];
		*/
		
		[bPath stroke];
		//[bPath fill];
		[bPath removeAllPoints];
	}
	else if (flipped == YES && fromSquare != -1 && toSquare != -1) {
		[bPath appendBezierPathWithRect:NSMakeRect((bounds.origin.x) + 3.0  + (((63-fromSquare)%8) * squareWidth),
														  (bounds.origin.y) + 3.0 + (((63-fromSquare)/8) * squareHeight), 
														  squareWidth - 6.0, squareHeight - 6.0)];
		/*
		[bPath appendBezierPathWithRect:NSMakeRect((bounds.origin.x)  + (((63-fromSquare)%8) * squareWidth),
												  (bounds.origin.y) + (((63-fromSquare)/8) * squareHeight), 
												  squareWidth, squareHeight)];
		 */
		[bPath stroke];
		[bPath removeAllPoints];
		[bPath appendBezierPathWithRect:NSMakeRect((bounds.origin.x) + 3.0 + (((63-toSquare)%8) * squareWidth),
														  (bounds.origin.y) + 3.0 + (((63-toSquare)/8) * squareHeight), 
														  squareWidth - 6.0, squareHeight - 6.0)];
		/*
		[bPath appendBezierPathWithRect:NSMakeRect((bounds.origin.x) + (((63-toSquare)%8) * squareWidth),
												  (bounds.origin.y) + (((63-toSquare)/8) * squareHeight), 
												  squareWidth, squareHeight)];
		 */
		[bPath stroke];
		[bPath removeAllPoints];
	}
	
	NSBezierPath *arrow;
	// arrows
	
	[[NSColor keyboardFocusIndicatorColor] set];
	NSBezierPath *aPath = [NSBezierPath bezierPath];
	
	[aPath setLineWidth:5.0];
	
	for (int i = 0; i < [fromArrowArray count]; i++) {
		if (!flipped) {
			[aPath moveToPoint:NSMakePoint((bounds.origin.x) + (([[fromArrowArray objectAtIndex:i] intValue] % 8) * squareWidth) + squareWidth/2, 
										   (bounds.origin.y) + (([[fromArrowArray objectAtIndex:i] intValue] / 8) * squareHeight) + squareHeight/2)];
			[aPath lineToPoint:NSMakePoint((bounds.origin.x) + (([[toArrowArray objectAtIndex:i] intValue] % 8) * squareWidth) + squareWidth/2, 
									   (bounds.origin.y) + (([[toArrowArray objectAtIndex:i] intValue] / 8) * squareHeight) + squareHeight/2)];
			[aPath stroke];
		}
		else {
			[aPath moveToPoint:NSMakePoint((bounds.origin.x) + (((63 - [[fromArrowArray objectAtIndex:i] intValue]) % 8) * squareWidth) + squareWidth/2, 
										   (bounds.origin.y) + (((63 - [[fromArrowArray objectAtIndex:i] intValue]) / 8) * squareHeight) + squareHeight/2)];
			[aPath lineToPoint:NSMakePoint((bounds.origin.x) + (((63 - [[toArrowArray objectAtIndex:i] intValue]) % 8) * squareWidth) + squareWidth/2, 
										   (bounds.origin.y) + (((63 - [[toArrowArray objectAtIndex:i] intValue]) / 8) * squareHeight) + squareHeight/2)];
			[aPath stroke];
		}
		
		arrow = [aPath bezierPathWithArrowHeadForEndOfLength:15 angle:20];
		[arrow closePath];
		[arrow fill];
		[arrow stroke];
		[aPath removeAllPoints];
	}
		
	[NSGraphicsContext restoreGraphicsState];
	
}




@end
