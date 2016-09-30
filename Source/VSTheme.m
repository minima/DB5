//
//  VSTheme.m
//  Q Branch LLC
//
//  Created by Brent Simmons on 6/26/13.
//  Copyright (c) 2012 Q Branch LLC. All rights reserved.
//

#import "VSTheme.h"

static BOOL stringIsEmpty(NSString *s);
static COLORCLASS *colorWithHexString(NSString *hexString);


@interface VSTheme ()

@property (nonatomic, strong) NSDictionary *themeDictionary;
@property (nonatomic, strong) NSCache *colorCache;
@property (nonatomic, strong) NSCache *fontCache;

@end


@implementation VSTheme


#pragma mark Init

- (id)initWithDictionary:(NSDictionary *)themeDictionary {
	
	self = [super init];
	if (self == nil)
		return nil;
	
	_themeDictionary = themeDictionary;

	_colorCache = [NSCache new];
	_fontCache = [NSCache new];

	return self;
}


- (id)objectForKey:(NSString *)key {

	id obj = [self.themeDictionary valueForKeyPath:key];
	if (obj == nil && self.parentTheme != nil)
		obj = [self.parentTheme objectForKey:key];
	return obj;
}


- (BOOL)boolForKey:(NSString *)key {

	id obj = [self objectForKey:key];
	if (obj == nil)
		return NO;
	return [obj boolValue];
}


- (NSString *)stringForKey:(NSString *)key {
	
	id obj = [self objectForKey:key];
	if (obj == nil)
		return nil;
	if ([obj isKindOfClass:[NSString class]])
		return obj;
	if ([obj isKindOfClass:[NSNumber class]])
		return [obj stringValue];
	return nil;
}


- (NSInteger)integerForKey:(NSString *)key {

	id obj = [self objectForKey:key];
	if (obj == nil)
		return 0;
	return [obj integerValue];
}


- (CGFloat)floatForKey:(NSString *)key {
	
	id obj = [self objectForKey:key];
	if (obj == nil)
		return  0.0f;
	return [obj floatValue];
}


- (NSTimeInterval)timeIntervalForKey:(NSString *)key {

	id obj = [self objectForKey:key];
	if (obj == nil)
		return 0.0;
	return [obj doubleValue];
}


- (IMAGECLASS *)imageForKey:(NSString *)key {
	
	NSString *imageName = [self stringForKey:key];
	if (stringIsEmpty(imageName))
		return nil;
	
	return [IMAGECLASS imageNamed:imageName];
}


- (COLORCLASS *)colorForKey:(NSString *)key {

	COLORCLASS *cachedColor = [self.colorCache objectForKey:key];
	if (cachedColor != nil)
		return cachedColor;
    
	NSString *colorString = [self stringForKey:key];
	COLORCLASS *color = colorWithHexString(colorString);
	if (color == nil)
		color = [COLORCLASS blackColor];

	[self.colorCache setObject:color forKey:key];

	return color;
}


- (EDGEINSETS)edgeInsetsForKey:(NSString *)key {

	CGFloat left = [self floatForKey:[key stringByAppendingString:@"Left"]];
	CGFloat top = [self floatForKey:[key stringByAppendingString:@"Top"]];
	CGFloat right = [self floatForKey:[key stringByAppendingString:@"Right"]];
	CGFloat bottom = [self floatForKey:[key stringByAppendingString:@"Bottom"]];
	
	EDGEINSETS edgeInsets = EDGEINSETSMAKE(top, left, bottom, right);
	return edgeInsets;
}


- (FONTCLASS *)fontForKey:(NSString *)key {

	FONTCLASS *cachedFont = [self.fontCache objectForKey:key];
	if (cachedFont != nil)
		return cachedFont;
    
	NSString *fontName = [self stringForKey:key];
	CGFloat fontSize = [self floatForKey:[key stringByAppendingString:@"Size"]];

	if (fontSize < 1.0f)
		fontSize = 15.0f;

	FONTCLASS *font = nil;
    
    if (stringIsEmpty(fontName)) {
        font = [FONTCLASS systemFontOfSize:fontSize];
    } else {
        // Translate HelveticaNeue fonts into system font
        NSArray* components = [fontName componentsSeparatedByString:@"-"];
        if (components.count > 0 && [components[0] isEqualToString:@"HelveticaNeue"]) {
            if (components.count > 1) {
                NSString* weightString = components[1];
                if ([weightString isEqualToString:@"UltraLight"]) {
                    font = [FONTCLASS systemFontOfSize:fontSize weight:UIFontWeightUltraLight];
                } else if ([weightString isEqualToString:@"Thin"]) {
                    font = [FONTCLASS systemFontOfSize:fontSize weight:UIFontWeightThin];
                } else if ([weightString isEqualToString:@"Light"]) {
                    font = [FONTCLASS systemFontOfSize:fontSize weight:UIFontWeightLight];
                } else if ([weightString isEqualToString:@"Medium"]) {
                    font = [FONTCLASS systemFontOfSize:fontSize weight:UIFontWeightMedium];
                } else if ([weightString isEqualToString:@"Bold"]) {
                    font = [FONTCLASS systemFontOfSize:fontSize weight:UIFontWeightBold];
                } else {
                    // Unknown
                    font = [FONTCLASS fontWithName:fontName size:fontSize];
                }
            } else {
                font = [FONTCLASS systemFontOfSize:fontSize];
            }
        } else {
            font = [FONTCLASS fontWithName:fontName size:fontSize];
        }
    }

	if (font == nil)
		font = [FONTCLASS systemFontOfSize:fontSize];
    
	[self.fontCache setObject:font forKey:key];

	return font;
}


- (CGPoint)pointForKey:(NSString *)key {

	CGFloat pointX = [self floatForKey:[key stringByAppendingString:@"X"]];
	CGFloat pointY = [self floatForKey:[key stringByAppendingString:@"Y"]];

	CGPoint point = CGPointMake(pointX, pointY);
	return point;
}


- (CGSize)sizeForKey:(NSString *)key {

	CGFloat width = [self floatForKey:[key stringByAppendingString:@"Width"]];
	CGFloat height = [self floatForKey:[key stringByAppendingString:@"Height"]];

	CGSize size = CGSizeMake(width, height);
	return size;
}

#ifndef TargetAppKit
- (UIViewAnimationOptions)curveForKey:(NSString *)key {
    
	NSString *curveString = [self stringForKey:key];
	if (stringIsEmpty(curveString))
		return UIViewAnimationOptionCurveEaseInOut;

	curveString = [curveString lowercaseString];
	if ([curveString isEqualToString:@"easeinout"])
		return UIViewAnimationOptionCurveEaseInOut;
	else if ([curveString isEqualToString:@"easeout"])
		return UIViewAnimationOptionCurveEaseOut;
	else if ([curveString isEqualToString:@"easein"])
		return UIViewAnimationOptionCurveEaseIn;
	else if ([curveString isEqualToString:@"linear"])
		return UIViewAnimationOptionCurveLinear;
    
	return UIViewAnimationOptionCurveEaseInOut;
}


- (VSAnimationSpecifier *)animationSpecifierForKey:(NSString *)key {

	VSAnimationSpecifier *animationSpecifier = [VSAnimationSpecifier new];

	animationSpecifier.duration = [self timeIntervalForKey:[key stringByAppendingString:@"Duration"]];
	animationSpecifier.delay = [self timeIntervalForKey:[key stringByAppendingString:@"Delay"]];
	animationSpecifier.curve = [self curveForKey:[key stringByAppendingString:@"Curve"]];

	return animationSpecifier;
}
#endif

- (VSTextCaseTransform)textCaseTransformForKey:(NSString *)key {

	NSString *s = [self stringForKey:key];
	if (s == nil)
		return VSTextCaseTransformNone;

	if ([s caseInsensitiveCompare:@"lowercase"] == NSOrderedSame)
		return VSTextCaseTransformLower;
	else if ([s caseInsensitiveCompare:@"uppercase"] == NSOrderedSame)
		return VSTextCaseTransformUpper;

	return VSTextCaseTransformNone;
}

@end

#ifndef TargetAppKit
@implementation VSTheme (Animations)


- (void)animateWithAnimationSpecifierKey:(NSString *)animationSpecifierKey animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion {

    VSAnimationSpecifier *animationSpecifier = [self animationSpecifierForKey:animationSpecifierKey];

    [UIView animateWithDuration:animationSpecifier.duration delay:animationSpecifier.delay options:animationSpecifier.curve animations:animations completion:completion];
}

@end


#pragma mark -

@implementation VSAnimationSpecifier

@end
#endif

static BOOL stringIsEmpty(NSString *s) {
	return s == nil || [s length] == 0;
}


static COLORCLASS *colorWithHexString(NSString *hexString) {

	/*Picky. Crashes by design.*/
	
	if (stringIsEmpty(hexString))
		return [COLORCLASS blackColor];

	NSMutableString *s = [hexString mutableCopy];
	[s replaceOccurrencesOfString:@"#" withString:@"" options:0 range:NSMakeRange(0, [hexString length])];
	CFStringTrimWhitespace((__bridge CFMutableStringRef)s);

	NSString *redString = [s substringToIndex:2];
	NSString *greenString = [s substringWithRange:NSMakeRange(2, 2)];
	NSString *blueString = [s substringWithRange:NSMakeRange(4, 2)];

	unsigned int red = 0, green = 0, blue = 0;
	[[NSScanner scannerWithString:redString] scanHexInt:&red];
	[[NSScanner scannerWithString:greenString] scanHexInt:&green];
	[[NSScanner scannerWithString:blueString] scanHexInt:&blue];

#ifdef TargetAppKit
	return [NSColor colorWithSRGBRed:(CGFloat)red/255.0f green:(CGFloat)green/255.0f blue:(CGFloat)blue/255.0f alpha:1.0f];
#else
	return [UIColor colorWithRed:(CGFloat)red/255.0f green:(CGFloat)green/255.0f blue:(CGFloat)blue/255.0f alpha:1.0f];
#endif
}
