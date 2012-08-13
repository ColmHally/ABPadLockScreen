//
//  ABPadLockScreen.m
//
//  Version 1.2
//
//  Created by Aron Bury on 09/09/2011.
//  Copyright 2011 Aron Bury. All rights reserved.
//
//  Get the latest version of ABLockScreen from this location:
//  https://github.com/abury/ABPadLockScreen
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//
#import "ABPadLockScreen.h"

static const int pinModeSet = 0;
static const int pinModeUnlock = 1;

@interface ABPadLockScreen()
@property (nonatomic, retain) UIImageView *keyValueOneImageView;
@property (nonatomic, retain) UIImageView *keyValueTwoImageView;
@property (nonatomic, retain) UIImageView *keyValueThreeImageView;
@property (nonatomic, retain) UIImageView *keyValueFourImageView;
@property (nonatomic, retain) UIImageView *incorrectAttemptImageView;

@property (nonatomic, retain) UILabel *incorrectAttemptLabel;
@property (nonatomic, retain) NSArray *titleLabels;
@property (nonatomic, retain) NSArray *subTitleLabels;

@property (nonatomic) int digitsPressed;
@property (nonatomic) int attempts;
@property (nonatomic) int prevPasscode;

@property (nonatomic, retain) NSString *digitOne;
@property (nonatomic, retain) NSString *digitTwo;
@property (nonatomic, retain) NSString *digitThree;
@property (nonatomic, retain) NSString *digitFour;

- (void)animateKeyValues;
- (void)cancelButtonTapped:(id)sender;
- (void)digitButtonPressed:(id)sender;
- (void)backSpaceButtonTapped:(id)sender;
- (void)digitInputted:(int)digit;
- (void)pinEnterred;
- (void)lockPad;
- (UIButton *)getStyledButtonForNumber:(int)number;
@end

@implementation ABPadLockScreen
@synthesize delegate, dataSource;
@synthesize keyValueOneImageView, keyValueTwoImageView, keyValueThreeImageView, keyValueFourImageView, incorrectAttemptImageView;
@synthesize incorrectAttemptLabel, subTitleLabels, titleLabels;
@synthesize digitOne, digitTwo, digitThree, digitFour;
@synthesize digitsPressed, attempts, prevPasscode;
@synthesize pinMode;

+ (int)pinModeSet {
    return pinModeSet;
}

+ (int)pinModeUnlock {
    return pinModeUnlock;
}

- (id)initWithMode:(int)mode withDelegate:(id<ABPadLockScreenDelegate>)aDelegate withDataSource:(id<ABPadLockScreenDataSource>)aDataSource
{
    self = [super init];
    if (self)
    {
        [self setDelegate:aDelegate];
        [self setDataSource:aDataSource];
        [self setPinMode:mode];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setFrame:CGRectMake(0.0f, 0.0f, 332.0f, 465.0f)];//size of unlock pad
    [self.view setBackgroundColor:[UIColor clearColor]];
    
    //Set the background view
    UIImageView *backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background"]] autorelease];
    [self.view addSubview:backgroundView];
    
    // when we're setting a passcode, you may want two (sub)titles: 1 for initial entry, and 1 to denote 2nd entry for verification
    int numTitles = (self.pinMode == pinModeUnlock) ? 1 : 2;
    NSMutableArray *titles = [[NSMutableArray alloc] initWithCapacity:numTitles];
    NSMutableArray *subTitles = [[NSMutableArray alloc] initWithCapacity:numTitles];
    
    for (int i=0; i < numTitles; i++) {
        
        // set the title
        UILabel *_titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20.0f, 10.0f, self.view.frame.size.width - 40.0f, 20.0f)];
        [_titleLabel setTextAlignment:UITextAlignmentCenter];
        [_titleLabel setBackgroundColor:[UIColor clearColor]];
        [_titleLabel setTextColor:[UIColor whiteColor]];
        [_titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:18.0f]];
        
        // requests title text for both initial and verification entry (if needed)
        [_titleLabel setText:[dataSource padLockScreenTitleText:self.pinMode attemptNumber:(i+1)]];
        
        // set the subtitle label
        UILabel *_subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20.0f, 70.0f, self.view.frame.size.width - 40.0f, 20.0f)];
        [_subtitleLabel setTextAlignment:UITextAlignmentCenter];
        [_subtitleLabel setFont:[UIFont fontWithName:@"Helvetica" size:14.0f]];
        [_subtitleLabel setBackgroundColor:[UIColor clearColor]];
        [_subtitleLabel setTextColor:[UIColor blackColor]];
        
        // requests subtitle text for both initial and verification entry (if needed)
        [_subtitleLabel setText:[dataSource padLockScreenSubtitleText:self.pinMode attemptNumber:(i+1)]];
        
        // set up word wrap
        [_subtitleLabel setLineBreakMode:UILineBreakModeWordWrap];
        [_subtitleLabel setNumberOfLines:0];
        
        
        if (i == 1) { // hide the second (sub)title labels, until they're needed
            _titleLabel.hidden = YES;
            _subtitleLabel.hidden = YES;
        }
        
        [self.view addSubview:_titleLabel];
        [self.view addSubview:_subtitleLabel];
        
        [titles addObject:_titleLabel];
        [subTitles addObject:_subtitleLabel];
    }
    
    [self setTitleLabels:titles];
    [self setSubTitleLabels:subTitles];
    
    // set the cancel button
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelButton setBackgroundColor:[UIColor clearColor]];
    [cancelButton setFrame:CGRectMake(self.view.frame.size.width - 60.0f, 7.0f, 50.0f, 29.0f)];
    [cancelButton setBackgroundImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancelButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cancelButton];
    
    // set the (currently empty) key value images (dots that appear when the user presses a button)
    UIImageView *_keyValueImageOne = [[[UIImageView alloc] initWithFrame:CGRectMake(52.0f, 133.0f, 16.0f, 16.0f)] autorelease];
    [self setKeyValueOneImageView:_keyValueImageOne];
    [self.view addSubview:keyValueOneImageView];
    
    UIImageView *_keyValueImageTwo = [[[UIImageView alloc] initWithFrame:CGRectMake(123.0f,
                                                                                    keyValueOneImageView.frame.origin.y,
                                                                                    16.0f,
                                                                                    16.0f)] autorelease];
    [self setKeyValueTwoImageView:_keyValueImageTwo];
    [self.view addSubview:keyValueTwoImageView];
    
    UIImageView *_keyValueImageThree = [[[UIImageView alloc] initWithFrame:CGRectMake(194.0f,
                                                                                      keyValueOneImageView.frame.origin.y,
                                                                                      16.0f,
                                                                                      16.0f)] autorelease];
    [self setKeyValueThreeImageView:_keyValueImageThree];
    [self.view addSubview:keyValueThreeImageView];
    
    UIImageView *_keyValueImageFour = [[[UIImageView alloc] initWithFrame:CGRectMake(265.0f,
                                                                                     keyValueOneImageView.frame.origin.y,
                                                                                     16.0f,
                                                                                     16.0f)] autorelease];
    [self setKeyValueFourImageView:_keyValueImageFour];
    [self.view addSubview:keyValueFourImageView];
    
    //Set the incorrect attempt error background image and label
    UIImageView *_incorrectAttemptImageView = [[UIImageView alloc] initWithFrame:CGRectMake(60.0f, 190.0f, 216.0f, 20.0f)];
    [self setIncorrectAttemptImageView:_incorrectAttemptImageView];
    [self.view addSubview:incorrectAttemptImageView];
    [_incorrectAttemptImageView release];
    
    UILabel *_incorrectAttemptLabel = [[[UILabel alloc] initWithFrame:CGRectMake(incorrectAttemptImageView.frame.origin.x + 10.0f,
                                                                                 incorrectAttemptImageView.frame.origin.y + 1.0f,
                                                                                 incorrectAttemptImageView.frame.size.width - 20.0f,
                                                                                 incorrectAttemptImageView.frame.size.height - 2.0f)] autorelease];
    [_incorrectAttemptLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:12.0f]];
    [_incorrectAttemptLabel setTextAlignment:UITextAlignmentCenter];
    [_incorrectAttemptLabel setTextColor:[UIColor whiteColor]];
    [_incorrectAttemptLabel setBackgroundColor:[UIColor clearColor]];
    [self setIncorrectAttemptLabel:_incorrectAttemptLabel];
    [self.view addSubview:incorrectAttemptLabel];
    
    //Add buttons
    float buttonTop = 242.0f;
    float buttonHeight = 55.0f;
    float leftButtonWidth = 106.0f;
    float middleButtonWidth = 109.0f;
    float rightButtonWidth = 105.0f;
    
    UIButton *oneButton = [self getStyledButtonForNumber:1];
    [oneButton setFrame:CGRectMake(6.0f, buttonTop, leftButtonWidth, buttonHeight)];
    [self.view addSubview:oneButton];
    
    UIButton *twoButton = [self getStyledButtonForNumber:2];
    [twoButton setFrame:CGRectMake(oneButton.frame.origin.x + oneButton.frame.size.width,
                                   oneButton.frame.origin.y,
                                   middleButtonWidth,
                                   buttonHeight)];
    [self.view addSubview:twoButton];
    
    UIButton *threeButton = [self getStyledButtonForNumber:3];
    [threeButton setFrame:CGRectMake(twoButton.frame.origin.x + twoButton.frame.size.width,
                                     twoButton.frame.origin.y,
                                     rightButtonWidth,
                                     buttonHeight)];
    [self.view addSubview:threeButton];
    
    UIButton *fourButton = [self getStyledButtonForNumber:4];
    [fourButton setFrame:CGRectMake(oneButton.frame.origin.x,
                                    oneButton.frame.origin.y + oneButton.frame.size.height - 1,
                                    leftButtonWidth,
                                    buttonHeight)];
    [self.view addSubview:fourButton];
    
    UIButton *fiveButton = [self getStyledButtonForNumber:5];
    [fiveButton setFrame:CGRectMake(twoButton.frame.origin.x,
                                    fourButton.frame.origin.y,
                                    middleButtonWidth,
                                    buttonHeight)];
    [self.view addSubview:fiveButton];
    
    UIButton *sixButton = [self getStyledButtonForNumber:6];
    [sixButton setFrame:CGRectMake(threeButton.frame.origin.x,
                                   fiveButton.frame.origin.y,
                                   rightButtonWidth,
                                   buttonHeight)];
    [self.view addSubview:sixButton];
    
    UIButton *sevenButton = [self getStyledButtonForNumber:7];
    [sevenButton setFrame:CGRectMake(oneButton.frame.origin.x,
                                     fourButton.frame.origin.y + fourButton.frame.size.height - 1,
                                     leftButtonWidth,
                                     buttonHeight)];
    [self.view addSubview:sevenButton];
    
    UIButton *eightButton = [self getStyledButtonForNumber:8];
    [eightButton setFrame:CGRectMake(twoButton.frame.origin.x,
                                     sevenButton.frame.origin.y,
                                     middleButtonWidth,
                                     buttonHeight)];
    [self.view addSubview:eightButton];
    
    UIButton *nineButton = [self getStyledButtonForNumber:9];
    [nineButton setFrame:CGRectMake(threeButton.frame.origin.x,
                                    sevenButton.frame.origin.y,
                                    rightButtonWidth,
                                    buttonHeight)];
    [self.view addSubview:nineButton];
    
    UIButton *blankButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [blankButton setBackgroundImage:[UIImage imageNamed:@"blank"] forState:UIControlStateNormal];
    [blankButton setBackgroundImage:[UIImage imageNamed:@"blank"] forState:UIControlStateHighlighted];
    [blankButton setFrame:CGRectMake(sevenButton.frame.origin.x,
                                     sevenButton.frame.origin.y + sevenButton.frame.size.height - 1,
                                     leftButtonWidth,
                                     buttonHeight)];
    [self.view addSubview:blankButton];
    
    UIButton *zeroButton = [self getStyledButtonForNumber:0];
    [zeroButton setFrame:CGRectMake(twoButton.frame.origin.x,
                                    blankButton.frame.origin.y,
                                    middleButtonWidth,
                                    buttonHeight)];
    [self.view addSubview:zeroButton];
    
    UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [clearButton setBackgroundImage:[UIImage imageNamed:@"clear"] forState:UIControlStateNormal];
    [clearButton setBackgroundImage:[UIImage imageNamed:@"clear-selected"] forState:UIControlStateHighlighted];
    [clearButton addTarget:self action:@selector(backSpaceButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [clearButton setFrame:CGRectMake(threeButton.frame.origin.x,
                                     zeroButton.frame.origin.y,
                                     rightButtonWidth,
                                     buttonHeight)];
    [self.view addSubview:clearButton];
    
    [titles release];
    [subTitles release];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.incorrectAttemptLabel = nil;
    self.subTitleLabels = nil;
    self.titleLabels = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (void)animateKeyValues { // perform the transition from initial entry to verification
    NSArray *keys = [NSArray arrayWithObjects:keyValueOneImageView,keyValueTwoImageView, keyValueThreeImageView, keyValueFourImageView, nil];
    
    [UIView animateWithDuration:0.5 animations:^ {
        for (UIImageView *key in keys)
            key.alpha = 0.0; // fade out each key
        
        UILabel *titleCurrent = [self.titleLabels objectAtIndex:0];
        UILabel *titleReplace = [self.titleLabels objectAtIndex:1];
        
        UILabel *subtitleCurrent = [self.subTitleLabels objectAtIndex:0];
        UILabel *subtitleReplace = [self.subTitleLabels objectAtIndex:1];
        
        [UIView transitionWithView:self.view
                          duration:0.5
                           options:UIViewAnimationOptionCurveEaseIn
                        animations:^{
                            titleCurrent.hidden = YES;
                            titleReplace.hidden = NO;
                            
                            subtitleCurrent.hidden = YES;
                            subtitleReplace.hidden = NO;
                        } completion:nil
         ];
        
    } completion:^ (BOOL finished){
        [self resetLockScreen];
        for (UIImageView *key in keys)
            key.alpha = 1.0; // ensure the digits will be visible for next entry
    }];
}

#pragma mark - pubilic methods
- (void)resetLockScreen
{
    [self setDigitsPressed:0];
    
    [keyValueOneImageView setImage:nil];
    [keyValueTwoImageView setImage:nil];
    [keyValueThreeImageView setImage:nil];
    [keyValueFourImageView setImage:nil];
    
    [self setDigitOne:nil];
    [self setDigitTwo:nil];
    [self setDigitThree:nil];
    [self setDigitFour:nil];
}

- (void)resetAttempts
{
    [self setAttempts:0];
}

#pragma mark - button methods
- (void)cancelButtonTapped:(id)sender
{
    [delegate pinEntryWasCancelled];
    [self resetLockScreen];
    [incorrectAttemptImageView setImage:nil];
    [incorrectAttemptLabel setText:nil];
    
}

- (void)backSpaceButtonTapped:(id)sender
{
    switch (digitsPressed)
    {
        case 0:
            break;
            
        case 1:
            digitsPressed = 0;
            [keyValueOneImageView setImage:nil];
            [self setDigitOne:nil];
            break;
            
        case 2:
            digitsPressed = 1;
            [keyValueTwoImageView setImage:nil];
            [self setDigitTwo:nil];
            break;
            
        case 3:
            digitsPressed = 2;
            [keyValueThreeImageView setImage:nil];
            [self setDigitThree:nil];
            break;
            
        default:
            break;
    }
    
}

- (void)digitButtonPressed:(id)sender
{
    UIButton *button = (UIButton *)sender;
    
    [self digitInputted:button.tag];
}

- (void)digitInputted:(int)digit
{
    switch (digitsPressed)
    {
        case 0:
            digitsPressed = 1;
            [keyValueOneImageView setImage:[UIImage imageNamed:@"input"]];
            [self setDigitOne:[NSString stringWithFormat:@"%i", digit]];
            break;
            
        case 1:
            digitsPressed = 2;
            [keyValueTwoImageView setImage:[UIImage imageNamed:@"input"]];
            [self setDigitTwo:[NSString stringWithFormat:@"%i", digit]];
            break;
            
        case 2:
            digitsPressed = 3;
            [keyValueThreeImageView setImage:[UIImage imageNamed:@"input"]];
            [self setDigitThree:[NSString stringWithFormat:@"%i", digit]];
            break;
            
        case 3:
            digitsPressed = 4;
            [keyValueFourImageView setImage:[UIImage imageNamed:@"input"]];
            [self setDigitFour:[NSString stringWithFormat:@"%i", digit]];
            [self performSelector:@selector(pinEnterred) withObject:self afterDelay:0.3];
            
            break;
            
        default:
            break;
    }
}

- (void)pinEnterred
{
    int stringPasscode = [[NSString stringWithFormat:@"%@%@%@%@", digitOne, digitTwo, digitThree, digitFour] intValue];
    
    if (self.pinMode == pinModeSet) {
        if (attempts == 0) { // store passcode entered and transition to next entry
            prevPasscode = stringPasscode;
            [self animateKeyValues];
            attempts++;
            
        } else {
            if (prevPasscode == stringPasscode) [delegate pinEntryWasSuccessful:stringPasscode]; // alert delegate of successful pin set
            else
                [delegate pinSetWasUnsuccessful:prevPasscode pinTwo:stringPasscode]; // alert delegate of unsuccessful pin set
        }
        return;
    }
    
    if ([dataSource checkPin:stringPasscode]) // ask datasource to validate entered pin
    {
        [delegate pinEntryWasSuccessful:stringPasscode]; // alert delegate of successful pin unlock
        [self resetLockScreen];
        [incorrectAttemptImageView setImage:nil];
        [incorrectAttemptLabel setText:nil];
    }
    else // pin entry was unsuccessful, so determine whether to lock up or go for another attempt
    {
        attempts += 1;
        [delegate pinEntryWasUnsuccessful:stringPasscode afterAttemptNumber:attempts]; // alert delegate of unsuccessful attempt
        
        [incorrectAttemptImageView setImage:[UIImage imageNamed:@"error-box"]];
        
        if ([dataSource hasAttemptLimit])
        {
            
            int remainingAttempts = [dataSource attemptLimit] - attempts;
            
            if (remainingAttempts != 0)
                [incorrectAttemptLabel setText:[NSString stringWithFormat:@"Incorrect pin. %i attempts left", remainingAttempts]];
            
            else
            {
                [incorrectAttemptLabel setText:@"No remaining attempts"];
                
                [self lockPad]; // no more attempts allowed
                [delegate attemptsExpired];
                
                return;
            }
        }
        else
            [incorrectAttemptLabel setText:[NSString stringWithFormat:@"Incorrect pin"]];
        
        [self resetLockScreen];
    }
    
}

- (void)lockPad
{
    UIView *lockView = [[[UIView alloc] initWithFrame:CGRectMake(0.0f, 238.0f, self.view.frame.size.width, self.view.frame.size.height - 238.0f)] autorelease];
    [[subTitleLabels objectAtIndex:0] setText:nil];
    [lockView setBackgroundColor:[UIColor blackColor]];
    [lockView setAlpha:0.5];
    [self.view addSubview:lockView];
}

#pragma mark - private methods
- (UIButton *)getStyledButtonForNumber:(int)number
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    NSString *imageName = [NSString stringWithFormat:@"%i", number];
    NSString *altImageName = [NSString stringWithFormat:@"%@-selected", imageName];
    [button setBackgroundImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    [button setBackgroundImage:[UIImage imageNamed:altImageName] forState:UIControlStateHighlighted];
    [button setTag:number];
    [button addTarget:self action:@selector(digitButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    return button;
    
}

@end
