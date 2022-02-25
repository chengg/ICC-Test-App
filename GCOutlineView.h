//
//  GCOutlineView.h
//  ICC Test App
//


#import <Cocoa/Cocoa.h>


@interface NSObject (DisclosureTriangleAdditions)

- (BOOL)gcOutlineView:(NSOutlineView*)outlineView shouldShowDisclosureTriangleForItem:(id)item;

@end

@interface GCOutlineView : NSOutlineView
{
}

@end
