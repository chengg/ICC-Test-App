//
//  MainWindowController.m
//  ICC Test App
//


#import "MainWindowController.h"
#import "ConsoleViewController.h"
#import "ChannelViewController.h"
#import "ChildNode.h"
#import "ImageAndTextCell.h"
#import "SeparatorCell.h"
#import "GCOutlineView.h"

#define COLUMNID_NAME			@"NameColumn"	// the single column name in our outline view
#define INITIAL_INFODICT		@"Outline"		// name of the dictionary file to populate our outline view

#define UNTITLED_NAME			@"Untitled"		// default name for added folders and leafs


#define kNodesPBoardType		@"myNodesPBoardType"	// drag and drop pasteboard type
#define kMinOutlineViewSplit	120.0

// -------------------------------------------------------------------------------
//	TreeAdditionObj
//
//	This object is used for passing data between the main and secondary thread
//	which populates the outline view.
// -------------------------------------------------------------------------------
@interface TreeAdditionObj : NSObject
{
	NSIndexPath *indexPath;
	NSString	*nodeURL;
	NSString	*nodeName;
	BOOL		selectItsParent;
	BOOL		isChannel;
}

@property (readonly) NSIndexPath *indexPath;
@property (readonly) NSString *nodeURL;
@property (readonly) NSString *nodeName;
@property (readonly) BOOL selectItsParent;
@property (readonly) BOOL isChannel;

@end

@implementation TreeAdditionObj
@synthesize indexPath, nodeURL, nodeName, selectItsParent, isChannel;

// -------------------------------------------------------------------------------
- (id)initWithURL:(NSString *)url withName:(NSString *)name selectItsParent:(BOOL)select isChannel:(BOOL)channel
{
	self = [super init];
	
	nodeName = name;
	nodeURL = url;
	selectItsParent = select;
	isChannel = channel;
	
	return self;
}
@end

@implementation MainWindowController

@synthesize dragNodesArray;

// -------------------------------------------------------------------------------
//	initWithWindow:window:
// -------------------------------------------------------------------------------
-(id)initWithWindow:(NSWindow *)window
{
	self = [super initWithWindow:window];
	if (self)
	{
		contents = [[NSMutableArray alloc] init];
		
		addingChannel = NO;
		
		channelsArray = [[NSMutableArray alloc] init];
				
		channelsDict = [[NSMutableDictionary alloc] init];
		channelIndexPathDict = [[NSMutableDictionary alloc] init];
		
		consoleImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForImageResource:@"Terminal.icns"]];
		[consoleImage setSize:NSMakeSize(16,16)];
		
		chatImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForImageResource:@"newMessage.png"]];

	}
	
	return self;
}

// -------------------------------------------------------------------------------
//	dealloc:
// -------------------------------------------------------------------------------
- (void)dealloc
{
	//[folderImage release];
	//[urlImage release];
	
	[consoleImage release];
	[chatImage release];
	
	[consoleViewController release];
	
	[contents release];
	
	[channelsArray release];
	[channelsDict release];
	[channelIndexPathDict release];
	
	[separatorCell release];
	
	self.dragNodesArray = nil;
	
	[super dealloc];
}

// -------------------------------------------------------------------------------
//	awakeFromNib:
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{
	// load the console view controller for later use
	consoleViewController = [[ConsoleViewController alloc] initWithNibName:@"ConsoleView" bundle:nil];
	[[self window] setInitialFirstResponder:[consoleViewController consoleTextField]];
	[consoleViewController setAppDelegate:appDelegate];
	
	
	//[[self window] setAutorecalculatesContentBorderThickness:YES forEdge:NSMinYEdge];
	//[[self window] setContentBorderThickness:30 forEdge:NSMinYEdge];
	
	// apply our custom ImageAndTextCell for rendering the first column's cells
	NSTableColumn *tableColumn = [myOutlineView tableColumnWithIdentifier:COLUMNID_NAME];
	ImageAndTextCell *imageAndTextCell = [[[ImageAndTextCell alloc] init] autorelease];
	[imageAndTextCell setEditable:YES];
	[tableColumn setDataCell:imageAndTextCell];
	
	separatorCell = [[SeparatorCell alloc] init];
    [separatorCell setEditable:NO];
	
	// build our default tree on a separate thread,
	// some portions are from disk which could get expensive depending on the size of the dictionary file:
	
	[NSThread detachNewThreadSelector:	@selector(populateOutlineContents:)
							 toTarget:self		// we are the target
						   withObject:nil];
	
	
	// scroll to the top in case the outline contents is very long
	[[[myOutlineView enclosingScrollView] verticalScroller] setFloatValue:0.0];
	[[[myOutlineView enclosingScrollView] contentView] scrollToPoint:NSMakePoint(0,0)];
	
	// make our outline view appear with gradient selection, and behave like the Finder, iTunes, etc.
	[myOutlineView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];
	
	// drag and drop support
	[myOutlineView registerForDraggedTypes:[NSArray arrayWithObjects:
											kNodesPBoardType,			// our internal drag type
											nil]];
	
}

- (void)setAppDelegate:(id)appObj
{
	appDelegate = appObj;


}

// -------------------------------------------------------------------------------
//	setContents:newContents
// -------------------------------------------------------------------------------
- (void)setContents:(NSArray*)newContents
{
	if (contents != newContents)
	{
		[contents release];
		contents = [[NSMutableArray alloc] initWithArray:newContents];
	}
}

// -------------------------------------------------------------------------------
//	contents:
// -------------------------------------------------------------------------------
- (NSMutableArray *)contents
{
	return contents;
}

// -------------------------------------------------------------------------------
//	selectParentFromSelection:
//
//	Take the currently selected node and select its parent.
// -------------------------------------------------------------------------------
- (void)selectParentFromSelection
{
	if ([[treeController selectedNodes] count] > 0)
	{
		NSTreeNode* firstSelectedNode = [[treeController selectedNodes] objectAtIndex:0];
		NSTreeNode* parentNode = [firstSelectedNode parentNode];
		if (parentNode)
		{
			// select the parent
			NSIndexPath* parentIndex = [parentNode indexPath];
			[treeController setSelectionIndexPath:parentIndex];
		}
		else
		{
			// no parent exists (we are at the top of tree), so make no selection in our outline
			NSArray* selectionIndexPaths = [treeController selectionIndexPaths];
			[treeController removeSelectionIndexPaths:selectionIndexPaths];
		}
	}
}

// -------------------------------------------------------------------------------
//	performAddFolder:treeAddition
// -------------------------------------------------------------------------------
-(void)performAddFolder:(TreeAdditionObj *)treeAddition
{
	// NSTreeController inserts objects using NSIndexPath, so we need to calculate this
	NSIndexPath *indexPath = nil;
	
	// if there is no selection, we will add a new group to the end of the contents array
	if ([[treeController selectedObjects] count] == 0)
	{
		// there's no selection so add the folder to the top-level and at the end
		indexPath = [NSIndexPath indexPathWithIndex:[contents count]];
	}
	else
	{
		// get the index of the currently selected node, then add the number its children to the path -
		// this will give us an index which will allow us to add a node to the end of the currently selected node's children array.
		//
		indexPath = [treeController selectionIndexPath];
		if ([[[treeController selectedObjects] objectAtIndex:0] isLeaf])
		{
			// user is trying to add a folder on a selected child,
			// so deselect child and select its parent for addition
			[self selectParentFromSelection];
		}
		else
		{
			indexPath = [indexPath indexPathByAddingIndex:[[[[treeController selectedObjects] objectAtIndex:0] children] count]];
		}
	}
	
	ChildNode *node = [[ChildNode alloc] init];
	[node setNodeTitle:[treeAddition nodeName]];
	
	// the user is adding a child node, tell the controller directly
	[treeController insertObject:node atArrangedObjectIndexPath:indexPath];
	
	[node release];
}

// -------------------------------------------------------------------------------
//	addFolder:folderName:
// -------------------------------------------------------------------------------
- (void)addFolder:(NSString *)folderName
{
	TreeAdditionObj *treeObjInfo = [[TreeAdditionObj alloc] initWithURL:nil withName:folderName selectItsParent:NO isChannel:NO];
	
	if (buildingOutlineView)
	{
		// add the folder to the tree controller, but on the main thread to avoid lock ups
		[self performSelectorOnMainThread:@selector(performAddFolder:) withObject:treeObjInfo waitUntilDone:YES];
	}
	else
	{
		[self performAddFolder:treeObjInfo];
	}
	
	[treeObjInfo release];
}

// -------------------------------------------------------------------------------
//	performAddChild:treeAddition
// -------------------------------------------------------------------------------
-(void)performAddChild:(TreeAdditionObj *)treeAddition
{
	if ([[treeController selectedObjects] count] > 0)
	{
		// we have a selection
		if ([[[treeController selectedObjects] objectAtIndex:0] isLeaf])
		{
			// trying to add a child to a selected leaf node, so select its parent for add
			[self selectParentFromSelection];
		}
	}
	
	// find the selection to insert our node
	NSIndexPath *indexPath;
	if ([[treeController selectedObjects] count] > 0)
	{
		// we have a selection, insert at the end of the selection
		indexPath = [treeController selectionIndexPath];
		indexPath = [indexPath indexPathByAddingIndex:[[[[treeController selectedObjects] objectAtIndex:0] children] count]];
	}
	else
	{
		// no selection, just add the child to the end of the tree
		indexPath = [NSIndexPath indexPathWithIndex:[contents count]];
	}
	
	// create a leaf node
	ChildNode *node = [[ChildNode alloc] initLeaf];
	[node setURL:[treeAddition nodeURL]];
	[node setIsChannel:[treeAddition isChannel]];
	
	if ([treeAddition nodeName])
		[node setNodeTitle:[treeAddition nodeName]];
	
	// the user is adding a child node, tell the controller directly
	[treeController insertObject:node atArrangedObjectIndexPath:indexPath];
	
	if ([[node nodeTitle] isEqualToString:@"ICC Console"])
		consoleIndexPath = indexPath;
	
	if ([node isChannel]) {
		[channelIndexPathDict setObject:indexPath forKey:[treeAddition nodeURL]];
	}
	
	[node release];
	
	// adding a child automatically becomes selected by NSOutlineView, so keep its parent selected
	if ([treeAddition selectItsParent])
		[self selectParentFromSelection];
}

// -------------------------------------------------------------------------------
//	addChild:url:withName:
// -------------------------------------------------------------------------------
- (void)addChild:(NSString *)url withName:(NSString *)nameStr selectParent:(BOOL)select isChannel:(BOOL)channel
{
	TreeAdditionObj *treeObjInfo = [[TreeAdditionObj alloc] initWithURL:url withName:nameStr selectItsParent:select isChannel:channel];
	
	if (buildingOutlineView)
	{
		// add the child node to the tree controller, but on the main thread to avoid lock ups
		[self performSelectorOnMainThread:@selector(performAddChild:) withObject:treeObjInfo waitUntilDone:YES];
	}
	else
	{
		[self performAddChild:treeObjInfo];
	}
	
	[treeObjInfo release];
}

// -------------------------------------------------------------------------------
//	addMainSection:
// -------------------------------------------------------------------------------
- (void)addMainSection
{
	// insert the "Devices" group at the top of our tree
	[self addFolder:@"MAIN"];
	
	// automatically add mounted and removable volumes to the "Devices" group	
	[self addChild:nil withName:@"ICC Console" selectParent:YES isChannel:NO];
	[self addChild:nil withName:@"Notify List" selectParent:YES isChannel:NO];
	[self addChild:nil withName:@"Seek Graph" selectParent:YES isChannel:NO];
	[self addChild:nil withName:@"Rating Graph" selectParent:YES isChannel:NO];
	
	[self selectParentFromSelection];
}

// -------------------------------------------------------------------------------
//	addChannelsSection:
// -------------------------------------------------------------------------------
- (void)addChannelsSection
{
	// insert the "Devices" group at the top of our tree
	[self addFolder:@"CHANNELS"];
	[self addChannel:@"1"];
	[self selectParentFromSelection];
}	

// -------------------------------------------------------------------------------
//	populateOutlineContents:inObject
//
//	This method is being called on a separate thread to avoid blocking the UI
//	a startup time.
// -------------------------------------------------------------------------------
- (void)populateOutlineContents:(id)inObject
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	buildingOutlineView = YES;		// indicate to ourselves we are building the default tree at startup
	
	[myOutlineView setHidden:YES];	// hide the outline view - don't show it as we are building the contents
	
	[self addMainSection];
	[self addChannelsSection];
	
	//[self addDevicesSection];		// add the "Devices" outline section
	//[self addPlacesSection];		// add the "Places" outline section
	//[self populateOutline];			// add the disk-based outline content
	
	buildingOutlineView = NO;		// we're done building our default tree
	
	// remove the current selection
	NSArray *selection = [treeController selectionIndexPaths];
	[treeController removeSelectionIndexPaths:selection];
	
	[myOutlineView setHidden:NO];	// we are done populating the outline view content, show it again
	
	[treeController setSelectionIndexPath:consoleIndexPath];
	//[[self window] makeFirstResponder:[consoleViewController consoleTextField]];

	
	[pool release];
}

#pragma mark - NSOutlineView delegate

- (BOOL)gcOutlineView:(NSOutlineView*)outlineView shouldShowDisclosureTriangleForItem:(id)item
{
	item = [item representedObject];
	
	if([[item nodeTitle] isEqualToString:@"MAIN"]) {
		return NO;
	}
	else {
		return YES;
	}

}

// -------------------------------------------------------------------------------
//	isSpecialGroup:
// -------------------------------------------------------------------------------
- (BOOL)isSpecialGroup:(BaseNode *)groupNode
{ 
	return ([groupNode nodeIcon] == nil &&
			[[groupNode nodeTitle] isEqualToString:@"MAIN"] || [[groupNode nodeTitle] isEqualToString:@"CHANNELS"]);
}


// -------------------------------------------------------------------------------
//	shouldSelectItem:item
// -------------------------------------------------------------------------------
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item;
{
	// don't allow special group nodes (Devices and Places) to be selected
	BaseNode* node = [item representedObject];
	return (![self isSpecialGroup:node]);
}

// -------------------------------------------------------------------------------
//	dataCellForTableColumn:tableColumn:row
// -------------------------------------------------------------------------------
- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	NSCell* returnCell = [tableColumn dataCell];
	
	if ([[tableColumn identifier] isEqualToString:COLUMNID_NAME])
	{
		// we are being asked for the cell for the single and only column
		BaseNode* node = [item representedObject];
		if ([node nodeIcon] == nil && [[node nodeTitle] length] == 0)
			returnCell = separatorCell;
	}
	
	return returnCell;
}

// -------------------------------------------------------------------------------
//	textShouldEndEditing:
// -------------------------------------------------------------------------------
- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
	if ([[fieldEditor string] length] == 0)
	{
		// don't allow empty node names
		return NO;
	}
	else
	{
		return YES;
	}
}

// -------------------------------------------------------------------------------
//	shouldEditTableColumn:tableColumn:item
//
//	Decide to allow the edit of the given outline view "item".
// -------------------------------------------------------------------------------
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	BOOL result = YES;
	
	item = [item representedObject];
	if ([self isSpecialGroup:item])
	{
		result = NO; // don't allow special group nodes to be renamed
	}
	else
	{
		if ([[item urlString] isAbsolutePath])
			result = NO;	// don't allow file system objects to be renamed
	}
	
	return result;
}

// -------------------------------------------------------------------------------
//	outlineView:willDisplayCell
// -------------------------------------------------------------------------------
- (void)outlineView:(NSOutlineView *)olv willDisplayCell:(NSCell*)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{	 
	if ([[tableColumn identifier] isEqualToString:COLUMNID_NAME])
	{
		// we are displaying the single and only column
		if ([cell isKindOfClass:[ImageAndTextCell class]])
		{
			item = [item representedObject];
			if (item)
			{
				
				
				if ([item isLeaf])
				{
					// does it have a URL string?
					NSString *urlStr = [item urlString];
					if (urlStr)
					{
						[item setNodeIcon:chatImage];
						
						/*
						if ([item isLeaf])
						{
							NSImage *iconImage;
							if ([[item urlString] hasPrefix:@"http:"])
								iconImage = consoleImage;
							else
								iconImage = [[NSWorkspace sharedWorkspace] iconForFile:urlStr];
							[item setNodeIcon:iconImage];
						}
						else
						{
							NSImage* iconImage = [[NSWorkspace sharedWorkspace] iconForFile:urlStr];
							[item setNodeIcon:iconImage];
						}*/
					}
					else
					{
						// it's a separator, don't bother with the icon
					}
				}
				else
				{
					// check if it's a special folder (DEVICES or PLACES), we don't want it to have an icon
					if ([self isSpecialGroup:item])
					{
						[item setNodeIcon:nil];
					}
					else
					{
						// it's a folder, use the folderImage as its icon
						[item setNodeIcon:consoleImage];
					}
				}
			}
			
			if([[item nodeTitle] isEqualToString:@"ICC Console"])
				[item setNodeIcon:consoleImage];
			
			// set the cell's image
			[(ImageAndTextCell*)cell setImage:[item nodeIcon]];
		}
	}
}

// -------------------------------------------------------------------------------
//	removeSubview:
// -------------------------------------------------------------------------------
- (void)removeSubview
{
	// empty selection
	NSArray *subViews = [placeHolderView subviews];
	if ([subViews count] > 0)
	{
		[[subViews objectAtIndex:0] removeFromSuperview];
	}
	
	[placeHolderView displayIfNeeded];	// we want the removed views to disappear right away
}

// -------------------------------------------------------------------------------
//	changeItemView:
// ------------------------------------------------------------------------------
- (void)changeItemView
{
	NSArray		*selection = [treeController selectedObjects];	
	BaseNode	*node = [selection objectAtIndex:0];
	NSString	*urlStr = [node urlString];
	
	
	if ([node isChannel]) {
				
		ChannelViewController *c = [channelsDict objectForKey:urlStr];
		if (c) {
			[self removeSubview];
			currentView = nil;
			[placeHolderView addSubview:[c view]];
			currentView = [c view];	
			
			[[self window] makeFirstResponder:[c channelTextField]];
			
			NSRect newBounds;
			newBounds.origin.x = 0;
			newBounds.origin.y = 0;
			newBounds.size.width = [[currentView superview] frame].size.width;
			newBounds.size.height = [[currentView superview] frame].size.height;
			[currentView setFrame:[[currentView superview] frame]];
			
			// make sure our added subview is placed and resizes correctly
			[currentView setFrameOrigin:NSMakePoint(0,0)];
			[currentView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
		}
	}
	else {
	
		[self removeSubview];
		currentView = nil;
		
		[placeHolderView addSubview:[consoleViewController view]];
		currentView = [consoleViewController view];	
		
		[[self window] makeFirstResponder:[consoleViewController consoleTextField]];
		
		NSRect newBounds;
		newBounds.origin.x = 0;
		newBounds.origin.y = 0;
		newBounds.size.width = [[currentView superview] frame].size.width;
		newBounds.size.height = [[currentView superview] frame].size.height;
		[currentView setFrame:[[currentView superview] frame]];
		
		// make sure our added subview is placed and resizes correctly
		[currentView setFrameOrigin:NSMakePoint(0,0)];
		[currentView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
	}
}

// -------------------------------------------------------------------------------
//	outlineViewSelectionDidChange:notification
// -------------------------------------------------------------------------------
- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	if (buildingOutlineView || addingChannel)	// we are currently building the outline view, don't change any view selections
		return;
	
	// ask the tree controller for the current selection
	NSArray *selection = [treeController selectedObjects];
	if ([selection count] > 1)
	{
		// multiple selection - clear the right side view
		[self removeSubview];
		currentView = nil;
	}
	else
	{
		if ([selection count] == 1)
		{
			// single selection
			[self changeItemView];
		}
		else
		{
			// there is no current selection - no view to display
			[self removeSubview];
			currentView = nil;
		}
	}
	
}

// ----------------------------------------------------------------------------------------
// outlineView:isGroupItem:item
// ----------------------------------------------------------------------------------------
-(BOOL)outlineView:(NSOutlineView*)outlineView isGroupItem:(id)item
{
	if ([self isSpecialGroup:[item representedObject]])
	{
		return YES;
	}
	else
	{
		return NO;
	}
}


#pragma mark - NSOutlineView drag and drop

// ----------------------------------------------------------------------------------------
// draggingSourceOperationMaskForLocal <NSDraggingSource override>
// ----------------------------------------------------------------------------------------
- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
	return NSDragOperationMove;
}

// ----------------------------------------------------------------------------------------
// outlineView:writeItems:toPasteboard
// ----------------------------------------------------------------------------------------
- (BOOL)outlineView:(NSOutlineView *)ov writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard
{
	[pboard declareTypes:[NSArray arrayWithObjects:kNodesPBoardType, nil] owner:self];
	
	// keep track of this nodes for drag feedback in "validateDrop"
	self.dragNodesArray = items;
	
	return YES;
}

// -------------------------------------------------------------------------------
//	outlineView:validateDrop:proposedItem:proposedChildrenIndex:
//
//	This method is used by NSOutlineView to determine a valid drop target.
// -------------------------------------------------------------------------------
- (NSDragOperation)outlineView:(NSOutlineView *)ov
				  validateDrop:(id <NSDraggingInfo>)info
				  proposedItem:(id)item
			proposedChildIndex:(NSInteger)index
{
	NSDragOperation result = NSDragOperationNone;
	
	if (!item)
	{
		// no item to drop on
		result = NSDragOperationGeneric;
	}
	else
	{
		if ([self isSpecialGroup:[item representedObject]])
		{
			// don't allow dragging into special grouped sections (i.e. Devices and Places)
			result = NSDragOperationNone;
		}
		else
		{	
			if (index == -1)
			{
				// don't allow dropping on a child
				result = NSDragOperationNone;
			}
			else
			{
				// drop location is a container
				result = NSDragOperationMove;
			}
		}
	}
	
	return result;
}


// -------------------------------------------------------------------------------
//	handleInternalDrops:pboard:withIndexPath:
//
//	The user is doing an intra-app drag within the outline view.
// -------------------------------------------------------------------------------
- (void)handleInternalDrops:(NSPasteboard*)pboard withIndexPath:(NSIndexPath*)indexPath
{
	// user is doing an intra app drag within the outline view:
	//
	NSArray* newNodes = self.dragNodesArray;
	
	// move the items to their new place (we do this backwards, otherwise they will end up in reverse order)
	NSInteger i;
	for (i = ([newNodes count] - 1); i >=0; i--)
	{
		[treeController moveNode:[newNodes objectAtIndex:i] toIndexPath:indexPath];
	}
	
	// keep the moved nodes selected
	NSMutableArray* indexPathList = [NSMutableArray array];
	for (i = 0; i < [newNodes count]; i++)
	{
		[indexPathList addObject:[[newNodes objectAtIndex:i] indexPath]];
	}
	[treeController setSelectionIndexPaths: indexPathList];
}


// -------------------------------------------------------------------------------
//	outlineView:acceptDrop:item:childIndex
//
//	This method is called when the mouse is released over an outline view that previously decided to allow a drop
//	via the validateDrop method. The data source should incorporate the data from the dragging pasteboard at this time.
//	'index' is the location to insert the data as a child of 'item', and are the values previously set in the validateDrop: method.
//
// -------------------------------------------------------------------------------
- (BOOL)outlineView:(NSOutlineView*)ov acceptDrop:(id <NSDraggingInfo>)info item:(id)targetItem childIndex:(NSInteger)index
{
	// note that "targetItem" is a NSTreeNode proxy
	//
	BOOL result = NO;
	
	// find the index path to insert our dropped object(s)
	NSIndexPath *indexPath;
	if (targetItem)
	{
		// drop down inside the tree node:
		// feth the index path to insert our dropped node
		indexPath = [[targetItem indexPath] indexPathByAddingIndex:index];
	}
	else
	{
		// drop at the top root level
		if (index == -1)	// drop area might be ambibuous (not at a particular location)
			indexPath = [NSIndexPath indexPathWithIndex:[contents count]];		// drop at the end of the top level
		else
			indexPath = [NSIndexPath indexPathWithIndex:index]; // drop at a particular place at the top level
	}
	
	NSPasteboard *pboard = [info draggingPasteboard];	// get the pasteboard
	
	// check the dragging type -
	if ([pboard availableTypeFromArray:[NSArray arrayWithObject:kNodesPBoardType]])
	{
		// user is doing an intra-app drag within the outline view
		[self handleInternalDrops:pboard withIndexPath:indexPath];
		result = YES;
	}
	else if ([pboard availableTypeFromArray:[NSArray arrayWithObject:@"WebURLsWithTitlesPboardType"]])
	{
		// the user is dragging URLs from Safari
		[self handleWebURLDrops:pboard withIndexPath:indexPath];		
		result = YES;
	}
	else if ([pboard availableTypeFromArray:[NSArray arrayWithObject:NSFilenamesPboardType]])
	{
		// the user is dragging file-system based objects (probably from Finder)
		[self handleFileBasedDrops:pboard withIndexPath:indexPath];
		result = YES;
	}

	
	return result;
}


#pragma mark - Split View Delegate

// -------------------------------------------------------------------------------
//	splitView:constrainMinCoordinate:
//
//	What you really have to do to set the minimum size of both subviews to kMinOutlineViewSplit points.
// -------------------------------------------------------------------------------
- (float)splitView:(NSSplitView *)splitView constrainMinCoordinate:(float)proposedCoordinate ofSubviewAt:(int)index
{
	return proposedCoordinate + kMinOutlineViewSplit;
}

// -------------------------------------------------------------------------------
//	splitView:constrainMaxCoordinate:
// -------------------------------------------------------------------------------
- (float)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(float)proposedCoordinate ofSubviewAt:(int)index
{
	return proposedCoordinate - kMinOutlineViewSplit;
}

// -------------------------------------------------------------------------------
//	splitView:resizeSubviewsWithOldSize:
//
//	Keep the left split pane from resizing as the user moves the divider line.
// -------------------------------------------------------------------------------
- (void)splitView:(NSSplitView*)sender resizeSubviewsWithOldSize:(NSSize)oldSize
{
	NSRect newFrame = [sender frame]; // get the new size of the whole splitView
	NSView *left = [[sender subviews] objectAtIndex:0];
	NSRect leftFrame = [left frame];
	NSView *right = [[sender subviews] objectAtIndex:1];
	NSRect rightFrame = [right frame];
	
	CGFloat dividerThickness = [sender dividerThickness];
	
	leftFrame.size.height = newFrame.size.height;
	
	rightFrame.size.width = newFrame.size.width - leftFrame.size.width - dividerThickness;
	rightFrame.size.height = newFrame.size.height;
	rightFrame.origin.x = leftFrame.size.width + dividerThickness;
	
	[left setFrame:leftFrame];
	[right setFrame:rightFrame];
}


#pragma mark - Methods to send data to ConsoleViewController

- (void)appendData:(NSData *)d attributes:(NSMutableDictionary *)a
{
	[consoleViewController appendData:d attributes:a];
}

- (void)appendString:(NSString *)s attributes:(NSMutableDictionary *)a
{
	[consoleViewController appendString:s attributes:a];
}

#pragma mark - Methods for channels

- (void)appendToChannel:(NSString *)channelStr string:(NSAttributedString *)s
{
	[s retain];
	
	ChannelViewController *c = [channelsDict objectForKey:channelStr];
	if (c != nil) {
		[c appendString:s];
		//[c appendString:s attributes:a];
		NSLog(@"channel found");
	}
	else {
		NSLog(@"channel not found");
	}
	[s release];
}


- (void)addChannel:(NSString *)channelStr
{	
	BOOL duplicate = NO;
	
	/*
	for (NSString *cs in channelsArray) {
		if ([cs isEqualToString:channelStr]) {
			duplicate = YES;
			break;
		}
	}*/

	
	
	if ([channelsDict objectForKey:channelStr] != nil) {
		duplicate = YES;
	}
	
	
	if (duplicate == NO) {
		addingChannel = YES;
		[channelsArray addObject:[channelStr retain]];
		ChannelViewController *c = [[ChannelViewController alloc] initWithNibName:@"ChannelView" bundle:nil];
		[NSBundle loadNibNamed:@"ChannelView" owner:c];
		if (c) {
			[c setAppDelegate:appDelegate];
			[c setChannel:[channelStr intValue]];
			[channelsDict setObject:c forKey:channelStr];
			[treeController setSelectionIndexPath:[NSIndexPath indexPathWithIndex:1]];
			[self addChild:channelStr 
				  withName:[NSString stringWithFormat:@"Channel %@", channelStr] 
			  selectParent:YES 
				 isChannel:YES];
			[treeController setSelectionIndexPath:consoleIndexPath];
		}
	}

	addingChannel = NO;
}

- (void)removeChannel:(NSString *)channelStr
{
	[treeController removeObjectAtArrangedObjectIndexPath:[channelIndexPathDict objectForKey:channelStr]];
	[channelsDict removeObjectForKey:channelStr];
	[channelsArray removeObjectForKey:channelStr];
	[channelIndexPathDict removeObjectForKey:channelStr];
}


@end
