//
//  GCOutlineView.m
//  ICC Test App
//


#import "GCOutlineView.h"


@implementation GCOutlineView

- (NSRect)frameOfOutlineCellAtRow:(NSInteger)row
{
	// Default to show triangle
	BOOL showTriangle = YES;
	
	// Ask the delegate if we should show the triangle
	if ([[self delegate] respondsToSelector:@selector(gcOutlineView:shouldShowDisclosureTriangleForItem:)])
		showTriangle = [[self delegate] gcOutlineView:self shouldShowDisclosureTriangleForItem:[self itemAtRow:row]];
	
	if (showTriangle)
		// Return default value
		return [super frameOfOutlineCellAtRow:row];
	else
		// Not showing the triangle, return empty rect
		return NSZeroRect;
}


@end
