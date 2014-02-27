//
//  MyScreenSaverView.h
//  Cocoa Dev Central: Write a Screen Saver: Part 1
//

#import <ScreenSaver/ScreenSaver.h>

@interface MyScreenSaverView : ScreenSaverView 
{
	IBOutlet id configSheet;
	IBOutlet id drawFilledShapesOption;
	IBOutlet id drawOutlinedShapesOption;
	IBOutlet id drawBothOption;
}

@end
