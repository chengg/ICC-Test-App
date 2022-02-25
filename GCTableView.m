//
//  GCTableView.m
//  ICC Test App
//


#import "GCTableView.h"


@implementation GCTableView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		
		appBundle = [NSBundle mainBundle];
				
		path = [appBundle pathForImageResource:@"select"];
		selectImage = [[NSImage alloc] initWithContentsOfFile:path];
		
		
		attributes = [[NSMutableDictionary alloc] init];
		[attributes setObject:[NSFont fontWithName:@"Lucida Grande"  size:10.0] forKey:NSFontAttributeName];
		[attributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
		
		columns   = 3;
		rows      = 0;
		columnSelectable = (BOOL*)malloc(sizeof(BOOL) * columns);
		columnWidths     = (double*)malloc(sizeof(double) * columns);
		
		selectedRow = -1;
		selectedCol = -1;
		
		columnSelectable[0] = NO; columnSelectable[1] = YES; columnSelectable[2] = YES;
		
		[self setColumn:0 widthToFitString:@"999."];
		[self setColumn:1 widthToFitString:@"axh8=Q#"];
		[self setColumn:2 widthToFitString:@"axh8=Q#"];
		
		datasource = self;
		
		[self reloadData];
		
	}
    return self;
}

-(void)setDatasource:(id<GCTableDatasource>)gc {
	datasource = gc;
}

-(void)setTarget:(id)targ { target = targ; }
-(void)setAction:(SEL)act { action = act; }

-(void)dealloc {
	free(columnSelectable);
	free(columnWidths);
	free(rectList);
	[super dealloc];
}

-(int)selectedRow { return selectedRow; }
-(int)selectedColumn { return selectedCol; }

-(void)reloadData {
	/* Get the new number of rows for the table.  Future versions might also have changable columns,
	 * but since I only need this for a specific purpose, there is no point. */
	rows = [datasource rowsForTable:self];
	
	/* Allocate enough space for our rectangles. */
	if ( rectList ) free(rectList);
	rectList = (NSRect*) malloc(sizeof(NSRect) * rows * columns);
	
	int i, j;
	
	/* We draw the grid starting at an 2,2 inset */
	double xinset = 2.0;
	double yinset = 2.0;
	
	/* Column width so far */
	double wc = 0.0;
	NSRect frame = [self frame];
	
	frame.size.width = 0.0;
	frame.size.height = rowHeight * rows;
	
	for ( i = 0; i < columns; ++i ) {
		frame.size.width += columnWidths[i];
		for ( j = 0; j < rows; ++j ) {
			int index = j * columns + i;
			NSPoint p;
			p.x = wc + xinset; p.y = yinset + rowHeight * j;
			
		rectList[index] = NSMakeRect(p.x, p.y, columnWidths[i], rowHeight);		}
		wc += columnWidths[i];
	}
	
	frame.size.width += 4.0;
	frame.size.height += 4.0;
	/* We set our frame to have the same origin and use the expanded bounds as calculated above. */
	[self setFrame:frame];
	[self setNeedsDisplay:YES];
	
}

- (void)drawRect:(NSRect)rect {
	
	NSShadow *shadow = [[NSShadow alloc] init];
	[shadow setShadowOffset:NSMakeSize(1.0,-1.0)];
	[shadow setShadowBlurRadius:2.0];
	[shadow setShadowColor:[NSColor shadowColor]];
	
	NSDictionary *highlightedAttr = [NSDictionary dictionaryWithObjectsAndKeys:
									 shadow, NSShadowAttributeName,
									 [NSColor selectedMenuItemTextColor], NSForegroundColorAttributeName,
									 [NSFont fontWithName:@"Lucida Grande Bold" size:10.0], NSFontAttributeName, nil];
	
	
	//NSRect b = [self bounds];
	//[[NSColor whiteColor] set];
	
	NSString *inColorString = @"D2D6E1";
	
	// set background color from the inColorString hex string
	//
	//
	unsigned int colorCode = 0;
	unsigned char redByte, greenByte, blueByte;
	
	if (nil != inColorString)
	{
		NSScanner *scanner = [NSScanner scannerWithString:inColorString];
		(void) [scanner scanHexInt:&colorCode];	// ignore error
	}
	redByte		= (unsigned char) (colorCode >> 16);
	greenByte	= (unsigned char) (colorCode >> 8);
	blueByte	= (unsigned char) (colorCode);	// masks off high bits
	/*
	[[NSColor
			  colorWithCalibratedRed:		(float)redByte	/ 0xff
			  green:	(float)greenByte/ 0xff
			  blue:	(float)blueByte	/ 0xff
			  alpha:1.0] set];
	
	*/
	
	[[NSColor clearColor] set];
	NSBezierPath *bpath = [NSBezierPath bezierPath];
	
	[bpath fill];
	
	int i,j;
	
	/*
	for ( i = 1; i <= rows; ++i ) {
		NSBezierPath* bp = [NSBezierPath bezierPath];
		
		NSPoint p;
		p.y = rectList[i*columns].origin.y;
		p.x = 0;
		[bp moveToPoint:p];
		p.x = b.size.width;
		[bp lineToPoint:p];
		
		[bp setLineWidth:0.5];
		[[NSColor grayColor] set];
		[bp stroke];
	}*/
	
	for ( i = 0; i < columns; ++i ) {
		for ( j = 0; j < rows; ++j ) {
			int index = j * columns + i;
			
			/* If the rectangle we were asked to draw interesects with the rectangle of this
			 * particluar cell.... */
			
			if ( NSIntersectsRect(rect, rectList[index]) ) {
				NSString* value = [datasource stringForTable:self forRow:j column:i];
				
				/* This is where we draw the string. */
				NSRect temp = rectList[index];
				temp.origin.x += 2.0;
				//temp.origin.y -= 2.0;
				temp.size.width -= 4.0;
				temp.size.height -= 4.0;
				
				/* Just a pointer to which attributes we will use. */
				
				/* If we are drawing our selected cell, highlight it and set the
				 * attribute pointer */
				if ( i == selectedCol && j == selectedRow ) {
					//[[NSColor alternateSelectedControlColor] set];
					//NSRectFill(rectList[index]);
					
					[selectImage drawInRect:rectList[index] fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
					
					[value drawAtPoint:temp.origin withAttributes:highlightedAttr];
				} 
				else {
				
					/* drawAtPoint could also be used if you don't mind your text ignoring boundries. */
					[value drawAtPoint:temp.origin withAttributes:attributes];
				}
			}
		}
	}
	
	
	
}

- (void)selectRow:(int)row column:(int)col 
{
	/* The area we will need to redraw */
	NSRect drawRect;
	
	if ( selectedRow == -1 ) 
		drawRect = NSZeroRect;
	else 
		drawRect = rectList[selectedRow * columns + selectedCol];
	
	/* See if the passed in coordinates are valid */
	if ( row < rows && row >= 0 && col < columns && col >= 0 ) {
		/* We ignore the selectableColumn flags for this */
		selectedRow = row;
		selectedCol = col;
		
		int index = selectedRow * columns + selectedCol;
		
		drawRect = NSUnionRect( drawRect, rectList[index] );
		
		/* Are we in a scroll view */
		if ( [[self superview] isKindOfClass:[NSClipView class]] ) {
			NSClipView* clipv = (NSClipView*) [self superview];
			
			/* See if the midpoint of the new selected rectangle is vislble */
			NSPoint mid;
			
			if ( index % columns != 0 ) 
				index -= index&columns;
			
			mid.x = rectList[index].origin.x; // + rectList[index].size.width/2.0;
			mid.y = rectList[index].origin.y; // + rectList[index].size.height/2.0;
			
			
			
			[clipv scrollToPoint:[clipv constrainScrollPoint:mid]];
			
			//[[self enclosingScrollView] scrollPoint:mid];

			
		}
		
	} else {
		/* Invalid, just unselect the previous selection */
		selectedRow = -1;
		selectedCol = -1;
	}
	
	[self setNeedsDisplay:YES];
}

-(void)mouseDown:(NSEvent*)theEvent {
	/* drawRect is used to keep track of which parts we have to redraw if the selection changes. */
	NSRect drawRect;
	
	if ( selectedRow == -1 ) drawRect = NSZeroRect;
	else drawRect = rectList[selectedRow*columns + selectedCol];
	
	/* Figure out which rectangle we clicked in. */
	NSPoint p = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
	int i, j;
	
	/* Subtract out the insets from the point */
	p.x -= 8.0;
	p.y -= 8.0;
	
	/* Loop through all of our rows-- we could actually use division to do this */
	for ( i = 0; i < rows; ++i ) {
		if ( p.y < (rowHeight * (i+1)) ) break;
	}
	
	/* But not for this-- since the column widths are variable, we have to loop through 
	 all of them to find.  "cw" keeps track of the total column widths so far */
	double cw = columnWidths[0];
	for ( j = 0; j < columns; ++j ) {
		if ( p.x < cw ) break;
		if ( j < (columns-1) ) cw += columnWidths[j+1];
	}
	
	/* If we looped through all of them and still haven't found anything, then obviously the selection
	 is invalid.  We mark them as -1 since they are impossible cooridinates (see the drawRect: method)
	 */
	
	if ( i == rows )    i = -1;
	if ( j == columns ) j = -1;
	
	/* If we have a valid column and if the column is selectable and we have a valid row... */
	if ( j > -1 && columnSelectable[j] && i != -1 ) {
		selectedRow = i;
		selectedCol = j;
		[target performSelector:action withObject:self];
		
		/* Update our refresh rectangle */
		drawRect = NSUnionRect(drawRect, rectList[selectedRow*columns + selectedCol]);
	} else {
		/* Otherwise, no selection was made and we simply clear it. */
		selectedRow = -1;
		selectedCol = -1;
	}
	[self setNeedsDisplayInRect:drawRect];
}

-(BOOL)isFlipped { return YES; }

/* Just a handy utility function to set our column widths */
-(void)setColumn:(int)index widthToFitString:(NSString*)foo {
	NSAttributedString* bar = [[[NSAttributedString alloc] initWithString:foo attributes:attributes] autorelease];
	
	if ( bar >= 0 && index < columns ) {
		columnWidths[index] = [bar size].width + 8.0;
		rowHeight = [bar size].height + 4.0;
	}
}

/* Sample datasource */

-(int)rowsForTable:(GCTableView*)gc { return 300; }

-(NSString*)stringForTable:(GCTableView*)tb forRow:(int)row column:(int)col {	
	if ( col == 0 ) return [NSString stringWithFormat:@"%d. ", (row+1)];
	else return @"axb8=Q#";
}

@end
