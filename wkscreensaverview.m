#import "wkscreensaverview.h"

@interface NSAttributedString (Hyperlink)
+(id)hyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL;
@end

@implementation NSAttributedString (Hyperlink)
+(id)hyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL
{
    NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString: inString];
    NSRange range = NSMakeRange(0, [attrString length]);
	
    [attrString beginEditing];
    [attrString addAttribute:NSLinkAttributeName value:[aURL absoluteString] range:range];
	
    // make the text appear in blue
    [attrString addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:range];
	
    // next make the text appear with an underline
    [attrString addAttribute:
	 NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSSingleUnderlineStyle] range:range];
	
	[attrString addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Helvetica" size:14] range:range];
	
    [attrString endEditing];
	
    return [attrString autorelease];
}
@end

@implementation wkscreensaverview

static NSString * const MyModuleName = @"com.yournamehere.MyScreenSaver";

typedef enum status_codes {
	ST_NOTHING_DONE_YET,
	ST_ERROR,
	ST_DATA_BEING_LOADED,
	ST_DATA_LOADED
} Status;

Status currentstatus;

- (void) tryToGetData
{
	ScreenSaverDefaults *defaults;
	defaults = [ScreenSaverDefaults defaultsForModuleWithName:MyModuleName];
	
	wk_apikey = [defaults stringForKey:@"wk_apikey"];
	
	if ([wk_apikey isEqualToString:@"nil"]) {
		currentstatus = ST_ERROR;
		errormessage = @"You need to set your apikey in the Screensaver preferences!";
		NSLog(@"%@", errormessage);
	}
	else {//parse learned kanjis
		currentstatus = ST_DATA_BEING_LOADED;
		
		NSOperationQueue *mainQueue = [[NSOperationQueue alloc] init];
		[mainQueue setMaxConcurrentOperationCount:5];
		NSLog(@"Trying to get api data with apikey: %@", wk_apikey);
		NSString *apiurl = [NSString stringWithFormat:@"https://www.wanikani.com/api/user/%@/kanji/", wk_apikey];
		NSURL *url = [NSURL URLWithString:apiurl];
		
		NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
		
		[request setHTTPMethod:@"GET"];
		[request setAllHTTPHeaderFields:@{@"Accepts-Encoding": @"gzip", @"Accept": @"application/json"}];
		
		[NSURLConnection sendAsynchronousRequest:request queue:mainQueue completionHandler:^(NSURLResponse *response, NSData *responseData, NSError *error) {
			NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *)response;
			if (!error) {
				NSLog(@"Status Code: %li %@", (long)urlResponse.statusCode, [NSHTTPURLResponse localizedStringForStatusCode:urlResponse.statusCode]);
				NSLog(@"Response Body: %@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
				
				if(responseData == nil) {
					NSLog(@"response is nil");
					errormessage = @"response is nil";
				}
				else if(NSClassFromString(@"NSJSONSerialization"))
				{
					NSError *error = nil;
					id object = [NSJSONSerialization
								 JSONObjectWithData:responseData
								 options:0
								 error:&error];
					
					if(error) { NSLog(@"json is malformed"); }
					
					if([object isKindOfClass:[NSDictionary class]])
					{
						NSDictionary *results = object;
						if(results[@"error"] != nil) {
							//{"error":{"code":"user_not_found","message":"User does not exist."}}
							NSDictionary * error_contents = results[@"error"];
							NSString * wk_returned_error = error_contents[@"message"];
							NSLog(@"error getting api data yo~ %@", wk_returned_error);
							currentstatus = ST_ERROR;
							errormessage = [wk_returned_error retain];
						} else {
							
							NSDictionary * ui = [results objectForKey:@"user_information"];
							id usrname = [ui objectForKey:@"username"];
							id title = [ui objectForKey:@"title"];
							
							username = [[NSString stringWithFormat:@"%@ of Sect %@", usrname,
										 title] retain];
							
							NSArray * kanji_entries = [results objectForKey:@"requested_information"];
							for (NSDictionary *kanji_element in kanji_entries) {
								NSString *kanji_glyph = [kanji_element objectForKey:@"character"];
								kanjis = [[NSString stringWithFormat:@"%@ %@", kanjis,
										   kanji_glyph] retain];
								NSString * user_specific = [kanji_element objectForKey:@"user_specific"];
								
								if(user_specific != (NSString *)[NSNull null]) {
									NSDictionary * kanji_user_specific = [kanji_element objectForKey:@"user_specific"];
									NSString * srslevel = [kanji_user_specific objectForKey:@"srs"];
									NSLog(@"%@ srslevel = %@", kanji_glyph, srslevel);
									kanji_status[kanji_glyph] = srslevel;
								} else {
									kanji_status[kanji_glyph] = @"null";
									NSLog(@"user_specific key is null! (for kanji %@)", kanji_glyph);
								}
							}
							currentstatus = ST_DATA_LOADED;
							if(![self isPreview]) { //only refresh if we're currently in the Sys'Pref'-pane since the user could enter new data in the preferences panel
								dispatch_async( dispatch_get_main_queue(), ^{
									[self setAnimationTimeInterval:150];
								});
							}
						}
						
					}
					else
					{
						errormessage = @"Seems like WK changed their API, send me a message yo!";
						NSLog(@"%@", errormessage);
					}
				}
				else
				{
					NSLog(@"error, class %@ not supported on this platform. :(", @"NSJSONSerialization");
					currentstatus = ST_ERROR;
					errormessage = @"NSJSONSerialization not supported on this platform.";
				}
			}
			else {
				NSLog(@"An error occured, Status Code: %li", (long)urlResponse.statusCode);
				NSLog(@"Description: %@", [error localizedDescription]);
				NSLog(@"Response Body: %@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
			}
		}];
	}
	
}

- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
	self = [super initWithFrame:frame isPreview:isPreview];
	[self setAnimationTimeInterval:0.1]; //as long as we dont have data, refresh every 100ms
	
	if (self)
	{
		ScreenSaverDefaults *defaults;
		
		defaults = [ScreenSaverDefaults defaultsForModuleWithName:MyModuleName];
		
		// Register our default values
		[defaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
									@"nil", @"wk_apikey",
									//potentially other options?
									nil]];
	}
	
	NSString* imageName = [[NSBundle bundleForClass:[self class]] pathForResource:@"wk" ofType:@"png"];
	background = [[NSImage alloc] initWithContentsOfFile:imageName];
	
	username = @"username";
	kanjis = @"かんじ";
	kanji_status = [[NSMutableDictionary alloc] init];
	currentstatus = ST_NOTHING_DONE_YET;
	
	[self tryToGetData];
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
	NSRect rect;
	NSSize size;
	
	size = [self bounds].size;
	rect.size = NSMakeSize(size.width, size.height);
	
	// Calculate random origin point
	rect.origin = NSMakePoint(0, 0);
	[background drawInRect:rect];
	
	if(currentstatus == ST_NOTHING_DONE_YET || currentstatus == ST_DATA_BEING_LOADED) //no data received, yet
	{
		NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica" size:(size.width / 33.0)], NSFontAttributeName,[NSColor whiteColor], NSForegroundColorAttributeName, nil];
		
		NSAttributedString * currentText=[[NSAttributedString alloc] initWithString:@"Loading data..." attributes: attributes];
		
		[currentText drawAtPoint:NSMakePoint(size.width * 0.01, size.height * 0.01)];
		
	} else if(currentstatus == ST_ERROR) { //there was an error...
		NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica" size:(size.width / 33.0)], NSFontAttributeName,[NSColor whiteColor], NSForegroundColorAttributeName, nil];
		
		NSAttributedString * currentText=[[NSAttributedString alloc] initWithString:errormessage attributes: attributes];
		
		[currentText drawAtPoint:NSMakePoint(size.width * 0.01, size.height * 0.01)];
		
	} else if(currentstatus == ST_DATA_LOADED){
		{//render kanjis
			rect.size.width *= 0.5;
			rect.origin.x += size.width * 0.5;
			
			rect.size.height -= size.height * 0.01;
			rect.origin.y -= size.height * 0.01;
			
			int kanji_count = kanji_status.count;
			float q = ((int)(round(sqrt(kanji_count) + 0.5)));
			
			NSFont *font = [NSFont fontWithName:@"Hiragino Maru Gothic ProN" size:(rect.size.width / (q * 1.0))];
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
			NSLog(@"q = %f, n = %i", q, kanji_count);
			int n = 0;
			for( NSString *kanji_key in [kanji_status allKeys])
			{
				n++;
				NSString *kanji_srslevel = kanji_status[kanji_key];
				
				NSMutableDictionary * kanji_attrs = [NSMutableDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
				NSColor * kanji_color;
				
				if([kanji_srslevel isEqualToString:@"apprentice"]) kanji_color = colors[0];
				else if ([kanji_srslevel isEqualToString:@"guru"]) kanji_color = colors[1];
				else if ([kanji_srslevel isEqualToString:@"master"]) kanji_color = colors[2];
				else if ([kanji_srslevel isEqualToString:@"enlightened"]) kanji_color = colors[3];
				else if ([kanji_srslevel isEqualToString:@"burned"]) kanji_color = colors[4];
				else kanji_color = colors[5];
				//[kanji_attrs insertValue:color inPropertyWithKey:NSForegroundColorAttributeName];
				kanji_attrs[NSForegroundColorAttributeName] = kanji_color;
				
				NSString * kanji = kanji_key;
				if(n >= q) {
					kanji = [NSString stringWithFormat:@"%@%@", kanji, @"\n"];
					n = 0;
				}
				
				NSAttributedString * attrstring = [[NSAttributedString alloc] initWithString:kanji attributes:kanji_attrs];
				[coloredText appendAttributedString:attrstring];
			}
			//[coloredText addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:NSMakeRange(3,1)];
			[coloredText drawInRect:rect];
		}
		{//render username + title
			NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica" size:(size.width / 33.0)], NSFontAttributeName,[NSColor whiteColor], NSForegroundColorAttributeName, nil];
			
			NSAttributedString * currentText=[[NSAttributedString alloc] initWithString:username attributes: attributes];
			
			[currentText drawAtPoint:NSMakePoint(size.width * 0.01, size.height * 0.01)];
		}
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
	[wk_apikey_textfield setStringValue:[defaults stringForKey:@"wk_apikey"]];

	// both are needed, otherwise hyperlink won't accept mousedown
    [wk_apikey_url setAllowsEditingTextAttributes: YES];
	[wk_apikey_url setEditable:NO];
    [wk_apikey_url setSelectable: YES];
	
    NSURL* url = [NSURL URLWithString:@"https://www.wanikani.com/account"];
	
    NSMutableAttributedString* string = [[NSMutableAttributedString alloc] init];
    [string appendAttributedString: [NSAttributedString hyperlinkFromString:@"Click here for your apikey!" withURL:url]];
	
	[wk_apikey_url setAttributedStringValue:string];
	return configSheet;
}

- (IBAction)cancelClick:(id)sender
{
	[self tryToGetData];
	[[NSApplication sharedApplication] endSheet:configSheet];
}

- (IBAction) okClick: (id)sender
{
	ScreenSaverDefaults *defaults;
	
	defaults = [ScreenSaverDefaults defaultsForModuleWithName:MyModuleName];
	
	// Update our defaults
	[defaults setObject:[wk_apikey_textfield stringValue] forKey:@"wk_apikey"];
	
	// Save the settings to disk
	[defaults synchronize];
	
	[self tryToGetData];
	
	[[NSApplication sharedApplication] endSheet:configSheet];
}

@end
