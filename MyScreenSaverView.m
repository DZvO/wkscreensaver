//
//  MyScreenSaverView.m 
//  Cocoa Dev Central: Write a Screen Saver: Part 1
//

#import "MyScreenSaverView.h"

@implementation MyScreenSaverView

static NSString * const MyModuleName = @"com.yournamehere.MyScreenSaver";

- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
	self = [super initWithFrame:frame isPreview:isPreview];

	if (self) 
	{
		ScreenSaverDefaults *defaults;

		defaults = [ScreenSaverDefaults defaultsForModuleWithName:MyModuleName];

	    // Register our default values
	    [defaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:@"NO", @"DrawFilledShapes", @"NO", @"DrawOutlinedShapes", @"YES", @"DrawBoth", nil]];
	
		[self setAnimationTimeInterval:1/30.0];
	}
	
	return self;
}

- (void)startAnimation
{
    [super startAnimation];
}

- (void)stopAnimation
{
    [super stopAnimation];
}

- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];
}

- (void)animateOneFrame
{
	NSBezierPath *path;
	NSRect rect;
	NSSize size;
	NSColor *color;
	float red, green, blue, alpha;
	int shapeType;
	ScreenSaverDefaults *defaults;
	NSImage *img;
	
	//NSString* imageName = [[NSBundle bundleForClass:[self class]] pathForResource:@"wk" ofType:@"png"];
	//img = [[NSImage alloc] initWithContentsOfFile:imageName];
	
	NSString* imageName = [[NSBundle bundleForClass:[self class]] pathForResource:@"wk" ofType:@"png"];
	img = [[NSImage alloc] initWithContentsOfFile:imageName];
	/*NSURL* rl;
	rl = [[NSURL alloc] initWithString:@"http://i.imgur.com/aRyoP4I.jpg"];
	img = [[NSImage alloc] initWithContentsOfURL:rl];
	*/
	size = [self bounds].size;
	//
	// Calculate random width and height
	//rect.size = NSMakeSize( SSRandomFloatBetween( size.width / 100.0, size.width / 10.0 ), SSRandomFloatBetween( size.height / 100.0, size.height / 10.0 ));
	rect.size = NSMakeSize(size.width, size.height);
	
	// Calculate random origin point
	rect.origin = SSRandomPointForSizeWithinRect( rect.size, [self bounds] );
	[img drawInRect:rect];
	
	//note we are using the convenience method, so we don't need to autorelease the object
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica" size:26], NSFontAttributeName,[NSColor blackColor], NSForegroundColorAttributeName, nil];
	
	NSAttributedString * currentText=[[NSAttributedString alloc] initWithString:@"Hello WORLD!" attributes: attributes];
	
	NSSize attrSize = [currentText size];

	[currentText drawAtPoint:NSMakePoint(20, 20)];
	
	// And finally draw it
	defaults = [ScreenSaverDefaults defaultsForModuleWithName:MyModuleName];
	
	/*if ([defaults boolForKey:@"DrawBoth"])
	{
		if (SSRandomIntBetween( 0, 1 ) == 0)
			[path fill];
		else
			[path stroke];
	}
	else if ([defaults boolForKey:@"DrawFilledShapes"])
		[path fill];
	else
		[path stroke];*/
	//[path fill];
}

- (BOOL)hasConfigureSheet
{
	return YES;
}

- (NSWindow *)configureSheet
{ 
	ScreenSaverDefaults *defaults;

	defaults = [ScreenSaverDefaults defaultsForModuleWithName:MyModuleName];

	if (!configSheet)
	{
		if (![NSBundle loadNibNamed:@"ConfigureSheet" owner:self]) 
		{
			NSLog( @"Failed to load configure sheet." );
			NSBeep();
		}
	}
	
	[drawFilledShapesOption setState:[defaults boolForKey:@"DrawFilledShapes"]];
	[drawOutlinedShapesOption setState:[defaults boolForKey:@"DrawOutlinedShapes"]];
	[drawBothOption setState:[defaults boolForKey:@"DrawBoth"]];
	
	return configSheet;
}

- (IBAction)cancelClick:(id)sender
{
	[[NSApplication sharedApplication] endSheet:configSheet];
}

- (IBAction)okClick:(id)sender
{
	ScreenSaverDefaults *defaults;

	defaults = [ScreenSaverDefaults defaultsForModuleWithName:MyModuleName];
                        
	// Update our defaults
	[defaults setBool:[drawFilledShapesOption state] forKey:@"DrawFilledShapes"];
	[defaults setBool:[drawOutlinedShapesOption state] forKey:@"DrawOutlinedShapes"];
	[defaults setBool:[drawBothOption state] forKey:@"DrawBoth"];
	 
	// Save the settings to disk
	[defaults synchronize];
	 
	// Close the sheet
	[[NSApplication sharedApplication] endSheet:configSheet];
}

@end
