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
		
		[self setAnimationTimeInterval:150]; //TODO implement async stuffs and render an animation or something until we got useful data
	}
	
	
	NSString* imageName = [[NSBundle bundleForClass:[self class]] pathForResource:@"wk" ofType:@"png"];
	background = [[NSImage alloc] initWithContentsOfFile:imageName];
	
	username = @"greenroom";
	kanjis = @"";
	kanji_status = [[NSMutableDictionary alloc] init];
	
	{//parse username aswell as title
		NSData *returnedData = [self getDataFrom:@"https://www.wanikani.com/api/user/9e890bc24fc18cb971c5bd8b8680090a/user-information"];
		
		// probably check here that returnedData isn't nil; attempting
		// NSJSONSerialization with nil data raises an exception, and who
		// knows how your third-party library intends to react?
		
		if(NSClassFromString(@"NSJSONSerialization"))
		{
			NSError *error = nil;
			id object = [NSJSONSerialization
						 JSONObjectWithData:returnedData
						 options:0
						 error:&error];
			
			if(error) { NSLog(@"json is malformed"); }
			
			// the originating poster wants to deal with dictionaries;
			// assuming you do too then something like this is the first
			// validation step:
			if([object isKindOfClass:[NSDictionary class]])
			{
				NSDictionary *results = object;
				/* proceed with results as you like; the assignment to
				 an explicit NSDictionary * is artificial step to get
				 compile-time checking from here on down (and better autocompletion
				 when editing). You could have just made object an NSDictionary *
				 in the first place but stylistically you might prefer to keep
				 the question of type open until it's confirmed */
				NSDictionary * ui = [results objectForKey:@"user_information"];
				for (id key in ui) {
					//NSLog(@"key: %@, value: %@ \n", key, [ui objectForKey:key]);
				}
				id usrname = [ui objectForKey:@"username"];
				id title = [ui objectForKey:@"title"];
				
				username = [[NSString stringWithFormat:@"%@ of Sect %@", usrname,
							 title] retain];
				
			}
			else
			{
				/* there's no guarantee that the outermost object in a JSON
				 packet will be a dictionary; if we get here then it wasn't,
				 so 'object' shouldn't be treated as an NSDictionary; probably
				 you need to report a suitable error condition */
			}
		}
		else
		{
			// the user is using iOS 4; we'll need to use a third-party solution.
			// If you don't intend to support iOS 4 then get rid of this entire
			// conditional and just jump straight to
			// NSError *error = nil;
			// [NSJSONSerialization JSONObjectWithData:...
		}
	}
	
	{//parse learned kanjis
		NSData *returnedData = [self getDataFrom:@"https://www.wanikani.com/api/user/9e890bc24fc18cb971c5bd8b8680090a/kanji/"];
		
		// probably check here that returnedData isn't nil; attempting
		// NSJSONSerialization with nil data raises an exception, and who
		// knows how your third-party library intends to react?
		
		if(NSClassFromString(@"NSJSONSerialization"))
		{
			NSError *error = nil;
			id object = [NSJSONSerialization
						 JSONObjectWithData:returnedData
						 options:0
						 error:&error];
			
			if(error) { NSLog(@"json is malformed"); }
			
			// the originating poster wants to deal with dictionaries;
			// assuming you do too then something like this is the first
			// validation step:
			if([object isKindOfClass:[NSDictionary class]])
			{
				NSDictionary *results = object;
				/* proceed with results as you like; the assignment to
				 an explicit NSDictionary * is artificial step to get
				 compile-time checking from here on down (and better autocompletion
				 when editing). You could have just made object an NSDictionary *
				 in the first place but stylistically you might prefer to keep
				 the question of type open until it's confirmed */
				NSArray * kanji_entries = [results objectForKey:@"requested_information"];
				for (NSDictionary *kanji_element in kanji_entries) {
					NSString *kanji_glyph = [kanji_element objectForKey:@"character"];
					//NSDictionary * kanji_info = [kanji_entries objectAtIndex:key];
					//NSLog(@"key: %@, value: %@ \n", kanji_element, [kanji_element objectForKey:@"character"]);
					kanjis = [[NSString stringWithFormat:@"%@ %@", kanjis,
								 kanji_glyph] retain];
					NSString * user_specific = [kanji_element objectForKey:@"user_specific"];

					if(user_specific != (NSString *)[NSNull null]) {
						NSDictionary * kanji_user_specific = [kanji_element objectForKey:@"user_specific"];
						NSString * srslevel = [kanji_user_specific objectForKey:@"srs"];
						NSLog(@"%@ srslevel = %@", kanji_glyph, srslevel);
						//[kanji_status insertValue:srslevel inPropertyWithKey:kanji_glyph];
						kanji_status[kanji_glyph] = srslevel;
					} else {
						//[kanji_status insertValue:@"null" inPropertyWithKey:kanji_glyph];
						kanji_status[kanji_glyph] = @"null";
						NSLog(@"user_specific key is null! (for kanji %@)", kanji_glyph);
					}
				}
				
			}
			else
			{
				/* there's no guarantee that the outermost object in a JSON
				 packet will be a dictionary; if we get here then it wasn't,
				 so 'object' shouldn't be treated as an NSDictionary; probably
				 you need to report a suitable error condition */
			}
		}
		else
		{
			// the user is using iOS 4; we'll need to use a third-party solution.
			// If you don't intend to support iOS 4 then get rid of this entire
			// conditional and just jump straight to
			// NSError *error = nil;
			// [NSJSONSerialization JSONObjectWithData:...
		}
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

- (NSString *) getStringFrom:(NSString *)url{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:url]];
	
    NSError *error = [[NSError alloc] init];
    NSHTTPURLResponse *responseCode = nil;
	
    NSData *oResponseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&responseCode error:&error];
	
    if([responseCode statusCode] != 200){
        NSLog(@"Error getting %@, HTTP status code %li", url, (long)[responseCode statusCode]);
        return nil;
    }
	
    return [[NSString alloc] initWithData:oResponseData encoding:NSUTF8StringEncoding];
}

- (NSData *) getDataFrom:(NSString *)url{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:url]];
	
    NSError *error = [[NSError alloc] init];
    NSHTTPURLResponse *responseCode = nil;
	
    NSData *oResponseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&responseCode error:&error];
	
    if([responseCode statusCode] != 200){
        NSLog(@"Error getting %@, HTTP status code %li", url, (long)[responseCode statusCode]);
        return nil;
    }
	
    return oResponseData;
}

- (void)animateOneFrame
{
	NSRect rect;
	NSSize size;
	NSColor *color;
	float red, green, blue, alpha;
	ScreenSaverDefaults *defaults;

	size = [self bounds].size;
	rect.size = NSMakeSize(size.width, size.height);
	
	// Calculate random origin point
	rect.origin = SSRandomPointForSizeWithinRect( rect.size, [self bounds] );
	[background drawInRect:rect];
	
	{//render kanjis
	 //note we are using the convenience method, so we don't need to autorelease the object
	 //NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Hiragino Maru Gothic ProN" size:56], NSFontAttributeName,[NSColor whiteColor], NSForegroundColorAttributeName, nil];
		
		//NSAttributedString * currentText=[[NSAttributedString alloc] initWithString:kanjis attributes: attributes];
		
		rect.size.width *= 0.5;
		rect.origin.x += size.width * 0.5;
		
		rect.size.height -= size.height * 0.01;
		rect.origin.y -= size.height * 0.01;
		//[currentText drawAtPoint:NSMakePoint(20, 20)];
		//[currentText drawInRect:rect];
		
		
		NSFont *font = [NSFont fontWithName:@"Hiragino Maru Gothic ProN" size:56.0];
		NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:font
																	forKey:NSFontAttributeName];
		NSMutableAttributedString *coloredText = [[NSMutableAttributedString alloc] initWithString:@"" attributes:attrsDictionary];

		NSArray * colors = @[
							 [NSColor colorWithSRGBRed:0.9 green:0.1 blue:0.6 alpha:1.0], //apprentice
							 [NSColor colorWithSRGBRed:0.57 green:0.21 blue:0.66 alpha:1.0], //guru
							 [NSColor colorWithSRGBRed:0.22 green:0.36 blue:0.85 alpha:1.0], //master
							 [NSColor colorWithSRGBRed:0.1 green:0.6 blue:0.89 alpha:1.0], //enlightened
							 [NSColor colorWithSRGBRed:0.0 green:0.0 blue:0.0 alpha:1.0], //burned
							 [NSColor colorWithSRGBRed:1.0 green:1.0 blue:1.0 alpha:1.0] //not yet learned
							 ];
		for( NSString *kanji_key in [kanji_status allKeys])
		{
			NSString *kanji_srslevel = kanji_status[kanji_key];
			
			NSMutableDictionary * kanji_attrs = [NSMutableDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
			CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
			CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
			CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
			NSColor *color = [NSColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
			NSColor * kanji_color;
			
			if([kanji_srslevel isEqualToString:@"apprentice"]) kanji_color = colors[0];
			else if ([kanji_srslevel isEqualToString:@"guru"]) kanji_color = colors[1];
			else if ([kanji_srslevel isEqualToString:@"master"]) kanji_color = colors[2];
			else if ([kanji_srslevel isEqualToString:@"enlightened"]) kanji_color = colors[3];
			else if ([kanji_srslevel isEqualToString:@"burned"]) kanji_color = colors[4];
			else kanji_color = colors[5];
			//[kanji_attrs insertValue:color inPropertyWithKey:NSForegroundColorAttributeName];
			kanji_attrs[NSForegroundColorAttributeName] = kanji_color;
			
			NSAttributedString * attrstring = [[NSAttributedString alloc] initWithString:kanji_key attributes:kanji_attrs];
			[coloredText appendAttributedString:attrstring];
			NSLog(@"appended %@\n", kanji_key);
		}
		//[coloredText addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:NSMakeRange(3,1)];
		[coloredText drawInRect:rect];
		
	}
	{//render username + title
	 //note we are using the convenience method, so we don't need to autorelease the object
		NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica" size:42], NSFontAttributeName,[NSColor whiteColor], NSForegroundColorAttributeName, nil];
		
		NSAttributedString * currentText=[[NSAttributedString alloc] initWithString:username attributes: attributes];
		
		[currentText drawAtPoint:NSMakePoint(66, 66)];
	}
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
