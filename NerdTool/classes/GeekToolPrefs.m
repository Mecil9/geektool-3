//
//  GeekToolPrefPref.m
//  GeekToolPref
//
//  Created by Yann Bizeul on Thu Nov 21 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Carbon/Carbon.h>

#import "GeekToolPrefs.h"
#import "NTGroup.h"
#import "LogWindow.h"
#import "NTExposeBorder.h"

#import "defines.h"
#import "CGSPrivate.h"

@implementation GeekToolPrefs

@synthesize groups;

- (id)init
{
    if (self = [super init])
    {
        groups = [[NSMutableArray alloc]init];
        exposeBorderWindowArray = [[NSMutableArray alloc]init];
        windowControllerArray = [[NSMutableArray alloc]init];
    }
    return self;
}

- (void)awakeFromNib
{
    [self loadDataFromDisk];
    [self loadPreferences];
    
    [[NSColorPanel sharedColorPanel]setShowsAlpha:YES];
}

- (void)applicationWillTerminate:(NSNotification *)note
{
    [self saveDataToDisk];
}  

- (void)dealloc
{
    [groups release];
    [exposeBorderWindowArray release];
    [windowControllerArray release];
    [super dealloc];
}

#pragma mark -
#pragma mark UI management
- (IBAction)revertDefaultSelectionColor:(id)sender
{
    NSData *selectionColorData = [NSArchiver archivedDataWithRootObject:[[NSColor alternateSelectedControlColor]colorWithAlphaComponent:0.3]];
    [[NSUserDefaults standardUserDefaults]setObject:selectionColorData forKey:@"selectionColor"];    
}

- (IBAction)showExpose:(id)sender
{
    if ([[NSUserDefaults standardUserDefaults]boolForKey:@"expose"]) [self exposeBorder];
    else 
    {
        [exposeBorderWindowArray removeAllObjects];
        [windowControllerArray removeAllObjects];
    }
}

- (void)exposeBorder
{
    if ([exposeBorderWindowArray count]) [exposeBorderWindowArray removeAllObjects];
    if ([windowControllerArray count]) [windowControllerArray removeAllObjects];
    
    NSMutableArray *screens = [NSMutableArray arrayWithArray:[NSScreen screens]];
    
    for (int i = 0; i < [screens count]; i++)
    {
        NSRect visibleFrame = [[screens objectAtIndex:i]frame];
        
        if (i == 0) visibleFrame.size.height -= [NSMenuView menuBarHeight];
        
        NSWindow *exposeBorderWindow = [[NSWindow alloc]initWithContentRect:visibleFrame styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO screen:[screens objectAtIndex:0]];
        [exposeBorderWindow setDelegate:self];
        [exposeBorderWindow setOpaque:NO];
        [exposeBorderWindow setLevel:kCGDesktopWindowLevel];
        [exposeBorderWindow setBackgroundColor:[NSColor clearColor]];
        
        CGSWindow wid = [exposeBorderWindow windowNumber];
        CGSConnection cid = _CGSDefaultConnection();
        int tags[2] = {0,0};   
        
        if(!CGSGetWindowTags(cid,wid,tags,32))
        {
            tags[0] = tags[0] | 0x00000800;
            CGSSetWindowTags(cid,wid,tags,32);
        }    
        
        NTExposeBorder *view = [[NTExposeBorder alloc]initWithFrame:visibleFrame];
        [exposeBorderWindow setContentView:view];
        [view setNeedsDisplay:YES];
        [view release];
        
        NSWindowController *windowController = [[NSWindowController alloc]initWithWindow:exposeBorderWindow];
        [windowController setWindow:exposeBorderWindow];
        [windowController showWindow:self];
        
        [exposeBorderWindowArray addObject:exposeBorderWindow];
        [windowControllerArray addObject:windowController];
        
        [exposeBorderWindow release];
        [windowController release];
    }    
}
#pragma mark Log Import
- (IBAction)logImport:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanChooseFiles:YES];
    
    [openPanel beginSheetForDirectory:@"/Users/Kevin/Library/Preferences/" file:@"org.tynsoe.geektool.plist" types:nil modalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    [NSApp endSheet:sheet];
    if (returnCode == NSOKButton)
    {
        if (![[sheet filenames]count]) return;
        NSString *fileToOpen = [[sheet filenames]objectAtIndex:0];
        
        NTGroup *importedGroup = [[NTGroup alloc]init];
        [[importedGroup properties]setObject:@"Imported Logs" forKey:@"name"];
        
        NSArray *oldPreferences = [[NSMutableDictionary dictionaryWithContentsOfFile:fileToOpen]objectForKey:@"logs"];
        
        for (NSMutableDictionary *importDict in oldPreferences)
        {
            NSMutableDictionary *convertedProps = [NSMutableDictionary dictionary];
            
            [convertedProps setObject:[importDict objectForKey:@"command"] forKey:@"command"];
            [convertedProps setObject:[NSArchiver archivedDataWithRootObject:[NSColor colorWithDeviceRed:[[[importDict objectForKey:@"backgroundColor"]objectForKey:@"red"]floatValue] green:[[[importDict objectForKey:@"backgroundColor"]objectForKey:@"green"]floatValue] blue:[[[importDict objectForKey:@"backgroundColor"]objectForKey:@"blue"]floatValue] alpha:[[[importDict objectForKey:@"backgroundColor"]objectForKey:@"alpha"]floatValue]]] forKey:@"backgroundColor"];
            [convertedProps setObject:[NSArchiver archivedDataWithRootObject:[NSColor colorWithDeviceRed:[[[importDict objectForKey:@"textColor"]objectForKey:@"red"]floatValue] green:[[[importDict objectForKey:@"textColor"]objectForKey:@"green"]floatValue] blue:[[[importDict objectForKey:@"textColor"]objectForKey:@"blue"]floatValue] alpha:[[[importDict objectForKey:@"textColor"]objectForKey:@"alpha"]floatValue]]] forKey:@"textColor"];
            [convertedProps setObject:[[importDict objectForKey:@"rect"]objectForKey:@"x"] forKey:@"x"];
            [convertedProps setObject:[[importDict objectForKey:@"rect"]objectForKey:@"y"] forKey:@"y"];
            [convertedProps setObject:[[importDict objectForKey:@"rect"]objectForKey:@"w"] forKey:@"w"];
            [convertedProps setObject:[[importDict objectForKey:@"rect"]objectForKey:@"h"] forKey:@"h"];
            [convertedProps setObject:[importDict objectForKey:@"enabled"] forKey:@"enabled"];
            [convertedProps setObject:[importDict objectForKey:@"file"] forKey:@"file"];
            [convertedProps setObject:[importDict objectForKey:@"fontName"] forKey:@"fontName"];
            [convertedProps setObject:[importDict objectForKey:@"fontSize"] forKey:@"fontSize"];
            [convertedProps setObject:[importDict objectForKey:@"imageURL"] forKey:@"imageURL"];
            [convertedProps setObject:[importDict objectForKey:@"name"] forKey:@"name"];
            [convertedProps setObject:[importDict objectForKey:@"refresh"] forKey:@"refresh"];
            [convertedProps setObject:[importDict objectForKey:@"shadowText"] forKey:@"shadowText"];
            [convertedProps setObject:[importDict objectForKey:@"shadowWindow"] forKey:@"shadowWindow"];
            //[convertedProps setObject:[importDict objectForKey:@"type"] forKey:@"type"];
            
            //[[importedGroup logs]addObject:[[id<NTLogProtocol> alloc]initWithProperties:convertedProps]];
        }
        [groupController addObject:importedGroup];
    }
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
    if (returnCode == NSAlertDefaultReturn) [sheet close];
}

#pragma mark Saving
- (NSString *)pathForDataFile
{
    NSString *appSupportDir = [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,NSUserDomainMask,YES) objectAtIndex:0]stringByAppendingPathComponent:[[NSProcessInfo processInfo]processName]];
    
    if ([[NSFileManager defaultManager]fileExistsAtPath:appSupportDir] == NO)
        [[NSFileManager defaultManager]createDirectoryAtPath:appSupportDir attributes:nil];
    
    return [appSupportDir stringByAppendingPathComponent:@"LogData.ntdata"];    
}

- (void)saveDataToDisk
{
    NSString *path = [self pathForDataFile];
    
    NSMutableDictionary *rootObject = [NSMutableDictionary dictionary];
    
    [rootObject setValue:[self groups] forKey:@"groups"];
    [NSKeyedArchiver archiveRootObject:rootObject toFile:path];
}

- (void)loadDataFromDisk
{
    NSString *path = [self pathForDataFile];
    NSDictionary *rootObject = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    NSMutableArray *groupArray = [NSMutableArray arrayWithArray:[rootObject valueForKey:@"groups"]];
     
    NTGroup *groupToSelect = nil;
    
    if (![groupArray count])
    {
        NTGroup *defaultGroup = [[NTGroup alloc]init];
        [groupArray addObject:defaultGroup];
        groupToSelect = defaultGroup;
    }
    
    for (NTGroup *tmp in groupArray)
        if ([[[tmp properties]objectForKey:@"active"]boolValue])
        {
            groupToSelect = tmp;
            break;
        }
    
    [self setGroups:[NSMutableArray arrayWithArray:groupArray]];
    [groupController setSelectedObjects:[NSArray arrayWithObject:groupToSelect]];
}

- (void)loadPreferences
{
    NSData *selectionColorData = [[NSUserDefaults standardUserDefaults]objectForKey:@"selectionColor"];
    if (!selectionColorData) selectionColorData = [NSArchiver archivedDataWithRootObject:[[NSColor alternateSelectedControlColor]colorWithAlphaComponent:0.3]];
    [[NSUserDefaults standardUserDefaults]setObject:selectionColorData forKey:@"selectionColor"];
    
    [self showExpose:nil];
}

#pragma mark -
#pragma mark Misc
- (NSRect)screenRect:(NSRect)oldRect
{
    NSRect screenSize = [[NSScreen mainScreen]frame];
    int screenY = screenSize.size.height - oldRect.origin.y - oldRect.size.height;
    return NSMakeRect(oldRect.origin.x,screenY,oldRect.size.width,oldRect.size.height);
}

@end
