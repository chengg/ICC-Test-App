//
//  GCTableView.h
//  ICC Test App
//


#import <Cocoa/Cocoa.h>

@class GCTableView;
@protocol GCTableDatasource
-(int)rowsForTable:(GCTableView*)gc;
-(NSString*)stringForTable:(GCTableView*)gc forRow:(int)row column:(int)col;
@end


@interface GCTableView : NSView <GCTableDatasource> {
	
	NSMutableDictionary *attributes;
	
	NSBundle *appBundle;
	NSString *path;
	NSImage *selectImage;
	
	
	int columns;
	int rows;
	
	BOOL*   columnSelectable;
	BOOL*   columnStretchesOnResize;
	
	double* columnWidths;
	double  rowHeight;
	
	int     selectedRow;
	int     selectedCol;
	
	IBOutlet id<GCTableDatasource> datasource;
	
	id target;
	SEL action;
	
	NSRect*     rectList;
}

- (id)initWithFrame:(NSRect)frame;
- (void)drawRect:(NSRect)rect;
- (void)mouseDown:(NSEvent*)event;
- (int)selectedRow;
- (int)selectedColumn;
- (void)selectRow:(int)row column:(int)col;
- (void)reloadData;
- (void)setColumn:(int)index widthToFitString:(NSString*)foo;

- (void)setDatasource:(id<GCTableDatasource>)data;
- (void)setTarget:(id)target;
- (void)setAction:(SEL)aselector;


@end
