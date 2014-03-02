#import <ScreenSaver/ScreenSaver.h>

@interface wkscreensaverview : ScreenSaverView
{
	IBOutlet id configSheet;
	IBOutlet NSTextField* wk_apikey_textfield;
	IBOutlet NSTextField * wk_apikey_url;
	
	NSString * wk_apikey;
	NSString * username;
	NSString * kanjis;
	NSString * errormessage;
	NSMutableDictionary * kanji_status;
	NSImage * background;

};

@end
