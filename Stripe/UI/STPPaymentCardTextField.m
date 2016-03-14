//
//  STPPaymentCardTextField.m
//  Stripe
//
//  Created by Jack Flintermann on 7/16/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Stripe.h"
#import "STPPaymentCardTextField.h"
#import "STPPaymentCardTextFieldViewModel.h"
#import "STPFormTextField.h"
#import "STPCardValidator.h"

#define FAUXPAS_IGNORED_IN_METHOD(...)

@interface STPPaymentCardTextField()<STPFormTextFieldDelegate>

@property(nonatomic, readwrite, strong)STPFormTextField *sizingField;

@property(nonatomic, readwrite, weak)UIImageView *brandImageView;
@property(nonatomic, readwrite, weak)UIView *fieldsView;

@property(nonatomic, readwrite, weak)STPFormTextField *numberField;

@property(nonatomic, readwrite, weak)STPFormTextField *expirationField;

@property(nonatomic, readwrite, weak)STPFormTextField *cvcField;

@property(nonatomic, readwrite, weak)STPFormTextField *zipcodeField;

@property(nonatomic, readwrite, strong)STPPaymentCardTextFieldViewModel *viewModel;

@property(nonatomic, readwrite, weak)UITextField *selectedField;

@property(nonatomic, assign)BOOL numberFieldShrunk;

@end

@implementation STPPaymentCardTextField

@synthesize font = _font;
@synthesize textColor = _textColor;
@synthesize textErrorColor = _textErrorColor;
@synthesize placeholderColor = _placeholderColor;
@dynamic enabled;

CGFloat const STPPaymentCardTextFieldDefaultPadding = 10;

#if CGFLOAT_IS_DOUBLE
#define stp_roundCGFloat(x) round(x)
#else
#define stp_roundCGFloat(x) roundf(x)
#endif

#pragma mark initializers

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {

    self.borderColor = [self.class placeholderGrayColor];
    self.cornerRadius = 5.0f;
    self.borderWidth = 1.0f;

    self.clipsToBounds = YES;

    _viewModel = [STPPaymentCardTextFieldViewModel new];
    _sizingField = [self buildTextField];

    UIImageView *brandImageView = [[UIImageView alloc] initWithImage:self.brandImage];
    brandImageView.contentMode = UIViewContentModeCenter;
    brandImageView.backgroundColor = [UIColor clearColor];
    if ([brandImageView respondsToSelector:@selector(setTintColor:)]) {
        brandImageView.tintColor = self.placeholderColor;
    }
    self.brandImageView = brandImageView;

    STPFormTextField *numberField = [self buildTextField];
    numberField.formatsCardNumbers = YES;
    numberField.tag = STPCardFieldTypeNumber;
    self.numberField = numberField;
    self.numberPlaceholder = [self.viewModel defaultPlaceholder];

    STPFormTextField *expirationField = [self buildTextField];
    expirationField.tag = STPCardFieldTypeExpiration;
    expirationField.alpha = 0;
    self.expirationField = expirationField;
    self.expirationField.font = [UIFont systemFontOfSize:13];
    self.expirationPlaceholder = @"MM/YY";

    STPFormTextField *cvcField = [self buildTextField];
    cvcField.tag = STPCardFieldTypeCVC;
    cvcField.alpha = 0;
    self.cvcField = cvcField;
    self.cvcField.font = [UIFont systemFontOfSize:13];
    self.cvcPlaceholder = @"CVC";

    STPFormTextField *zipcodeField = [self buildTextField];
    zipcodeField.tag = STPCardFieldTypeZipcode;
    zipcodeField.alpha = 0;
    zipcodeField.keyboardType = UIKeyboardTypeDefault;
    self.zipcodeField = zipcodeField;
    self.zipcodeField.font = [UIFont systemFontOfSize:13];
    self.zipcodePlaceholder = @"ZIPCODE";

//    self.numberField.backgroundColor = [UIColor yellowColor];
//    self.expirationField.backgroundColor = [UIColor redColor];
//    self.cvcField.backgroundColor = [UIColor purpleColor];
//    self.zipcodeField.backgroundColor = [UIColor blueColor];

//    self.numberField.text = @"378282246310005";
//    self.expirationField.text = @"12/18";
//    self.cvcField.text = @"4928";
//    self.zipcodeField.text = @"31291";

    UIView *fieldsView = [[UIView alloc] init];
    fieldsView.clipsToBounds = YES;
    fieldsView.backgroundColor = [UIColor clearColor];
    self.fieldsView = fieldsView;

    [self addSubview:self.fieldsView];
    [self.fieldsView addSubview:cvcField];
    [self.fieldsView addSubview:expirationField];
    [self.fieldsView addSubview:numberField];
    [self.fieldsView addSubview:zipcodeField];
    [self addSubview:brandImageView];
}

- (STPPaymentCardTextFieldViewModel *)viewModel {
    if (_viewModel == nil) {
        _viewModel = [STPPaymentCardTextFieldViewModel new];
    }
    return _viewModel;
}

#pragma mark appearance properties

+ (UIColor *)placeholderGrayColor {
    return [UIColor lightGrayColor];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:[backgroundColor copy]];
    self.numberField.backgroundColor = self.backgroundColor;
}

- (UIColor *)backgroundColor {
    return [super backgroundColor] ?: [UIColor whiteColor];
}

- (void)setFont:(UIFont *)font {
    _font = [font copy];

    for (UITextField *field in [self allFields]) {
        field.font = _font;
    }

    self.sizingField.font = _font;

    [self setNeedsLayout];
}

- (UIFont *)font {
    return _font ?: [UIFont systemFontOfSize:16];
}

- (void)setTextColor:(UIColor *)textColor {
    _textColor = [textColor copy];

    for (STPFormTextField *field in [self allFields]) {
        field.defaultColor = _textColor;
    }
}

- (void)setContentVerticalAlignment:(UIControlContentVerticalAlignment)contentVerticalAlignment {
    [super setContentVerticalAlignment:contentVerticalAlignment];
    for (UITextField *field in [self allFields]) {
        field.contentVerticalAlignment = contentVerticalAlignment;
    }
    switch (contentVerticalAlignment) {
        case UIControlContentVerticalAlignmentCenter:
            self.brandImageView.contentMode = UIViewContentModeCenter;
            break;
        case UIControlContentVerticalAlignmentBottom:
            self.brandImageView.contentMode = UIViewContentModeBottom;
            break;
        case UIControlContentVerticalAlignmentFill:
            self.brandImageView.contentMode = UIViewContentModeTop;
            break;
        case UIControlContentVerticalAlignmentTop:
            self.brandImageView.contentMode = UIViewContentModeTop;
            break;
    }
}

- (UIColor *)textColor {
    return _textColor ?: [UIColor blackColor];
}

- (void)setTextErrorColor:(UIColor *)textErrorColor {
    _textErrorColor = [textErrorColor copy];

    for (STPFormTextField *field in [self allFields]) {
        field.errorColor = _textErrorColor;
    }
}

- (UIColor *)textErrorColor {
    return _textErrorColor ?: [UIColor redColor];
}

- (void)setPlaceholderColor:(UIColor *)placeholderColor {
    _placeholderColor = [placeholderColor copy];

    if ([self.brandImageView respondsToSelector:@selector(setTintColor:)]) {
        self.brandImageView.tintColor = placeholderColor;
    }

    for (STPFormTextField *field in [self allFields]) {
        field.placeholderColor = _placeholderColor;
    }
}

- (UIColor *)placeholderColor {
    return _placeholderColor ?: [self.class placeholderGrayColor];
}

- (void)setNumberPlaceholder:(NSString * __nullable)numberPlaceholder {
    _numberPlaceholder = [numberPlaceholder copy];
    self.numberField.placeholder = _numberPlaceholder;
}

- (void)setExpirationPlaceholder:(NSString * __nullable)expirationPlaceholder {
    _expirationPlaceholder = [expirationPlaceholder copy];
    self.expirationField.placeholder = _expirationPlaceholder;
}

- (void)setCvcPlaceholder:(NSString * __nullable)cvcPlaceholder {
    _cvcPlaceholder = [cvcPlaceholder copy];
    self.cvcField.placeholder = _cvcPlaceholder;
}

- (void)setZipcodePlaceholder:(NSString * __nullable)zipcodePlaceholder {
    _zipcodePlaceholder = [zipcodePlaceholder copy];
    self.zipcodeField.placeholder = _zipcodePlaceholder;
}

- (void)setCursorColor:(UIColor *)cursorColor {
    self.tintColor = cursorColor;
}

- (UIColor *)cursorColor {
    return self.tintColor;
}

- (void)setBorderColor:(UIColor * __nullable)borderColor {
    self.layer.borderColor = [[borderColor copy] CGColor];
}

- (UIColor * __nullable)borderColor {
    return [[UIColor alloc] initWithCGColor:self.layer.borderColor];
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    self.layer.cornerRadius = cornerRadius;
}

- (CGFloat)cornerRadius {
    return self.layer.cornerRadius;
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    self.layer.borderWidth = borderWidth;
}

- (CGFloat)borderWidth {
    return self.layer.borderWidth;
}

- (void)setKeyboardAppearance:(UIKeyboardAppearance)keyboardAppearance {
    _keyboardAppearance = keyboardAppearance;
    for (STPFormTextField *field in [self allFields]) {
        field.keyboardAppearance = keyboardAppearance;
    }
}

- (void)setInputAccessoryView:(UIView *)inputAccessoryView {
    _inputAccessoryView = inputAccessoryView;

    for (STPFormTextField *field in [self allFields]) {
        field.inputAccessoryView = inputAccessoryView;
    }
}

#pragma mark UIControl

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    for (STPFormTextField *textField in [self allFields]) {
        textField.enabled = enabled;
    };
}

#pragma mark UIResponder & related methods

- (BOOL)isFirstResponder {
    return [self.selectedField isFirstResponder];
}

- (BOOL)canBecomeFirstResponder {
    return [[self firstResponderField] canBecomeFirstResponder];
}

- (BOOL)becomeFirstResponder {
    return [[self firstResponderField] becomeFirstResponder];
}

- (STPFormTextField *)firstResponderField {

    if ([self.viewModel validationStateForField:STPCardFieldTypeNumber] != STPCardValidationStateValid) {
        return self.numberField;
    } else if ([self.viewModel validationStateForField:STPCardFieldTypeExpiration] != STPCardValidationStateValid) {
        return self.expirationField;
    } else if ([self.viewModel validationStateForField:STPCardFieldTypeCVC] != STPCardValidationStateValid) {
        return self.cvcField;
    } else {
        return self.zipcodeField;
    }
}

- (BOOL)canResignFirstResponder {
    return [self.selectedField canResignFirstResponder];
}

- (BOOL)resignFirstResponder {
    [super resignFirstResponder];
    BOOL success = [self.selectedField resignFirstResponder];
    [self setNumberFieldShrunk:[self shouldShrinkNumberField] animated:YES completion:nil];
    return success;
}

- (BOOL)selectNextField {
    return [[self nextField] becomeFirstResponder];
}

- (BOOL)selectPreviousField {
    return [[self previousField] becomeFirstResponder];
}

- (STPFormTextField *)nextField {
    if (self.selectedField == self.numberField) {
        return self.expirationField;
    } else if (self.selectedField == self.expirationField) {
        return self.cvcField;
    } else if (self.selectedField == self.cvcField) {
        return self.zipcodeField;
    }
    return nil;
}

- (STPFormTextField *)previousField {
    if (self.selectedField == self.zipcodeField) {
        return self.cvcField;
    } else if (self.selectedField == self.cvcField) {
        return self.expirationField;
    } else if (self.selectedField == self.expirationField) {
        return self.numberField;
    }
    return nil;
}

#pragma mark public convenience methods

- (void)clear {
    for (STPFormTextField *field in [self allFields]) {
        field.text = @"";
    }
    self.viewModel = [STPPaymentCardTextFieldViewModel new];
    [self onChange];
    [self updateImageForFieldType:STPCardFieldTypeNumber];
    __weak id weakself = self;
    [self setNumberFieldShrunk:NO animated:YES completion:^(__unused BOOL completed){
        __strong id strongself = weakself;
        if ([strongself isFirstResponder]) {
            [[strongself numberField] becomeFirstResponder];
        }
    }];
}

- (BOOL)isValid {
    return [self.viewModel isValid];
}

#pragma mark readonly variables

- (NSString *)cardNumber {
    return self.viewModel.cardNumber;
}

- (NSUInteger)expirationMonth {
    return [self.viewModel.expirationMonth integerValue];
}

- (NSUInteger)expirationYear {
    return [self.viewModel.expirationYear integerValue];
}

- (NSString *)cvc {
    return self.viewModel.cvc;
}

- (NSString *)zipcode {
    return self.viewModel.zipcode;
}

- (STPCardParams *)card {
    if (!self.isValid) { return nil; }

    STPCardParams *c = [[STPCardParams alloc] init];
    c.number = self.cardNumber;
    c.expMonth = self.expirationMonth;
    c.expYear = self.expirationYear;
    c.cvc = self.cvc;
    c.addressZip = self.zipcode;
    return c;
}

- (CGSize)intrinsicContentSize {

    CGSize imageSize = self.brandImage.size;

    self.sizingField.text = self.viewModel.defaultPlaceholder;
    CGFloat textHeight = [self.sizingField measureTextSize].height;
    CGFloat imageHeight = imageSize.height + (STPPaymentCardTextFieldDefaultPadding * 2);
    CGFloat height = stp_roundCGFloat((MAX(MAX(imageHeight, textHeight), 44)));

    CGFloat width = stp_roundCGFloat([self widthForCardNumber:self.viewModel.defaultPlaceholder] + imageSize.width + (STPPaymentCardTextFieldDefaultPadding * 3));

    return CGSizeMake(width, height);
}

- (CGRect)brandImageRectForBounds:(CGRect)bounds {
    return CGRectMake(STPPaymentCardTextFieldDefaultPadding, 2, self.brandImageView.image.size.width, bounds.size.height - 2);
}

- (CGRect)fieldsRectForBounds:(CGRect)bounds {
    CGRect brandImageRect = [self brandImageRectForBounds:bounds];
    return CGRectMake(CGRectGetMaxX(brandImageRect), 0, CGRectGetWidth(bounds) - CGRectGetMaxX(brandImageRect), CGRectGetHeight(bounds));
}

- (CGRect)numberFieldRectForBounds:(CGRect)bounds {
    CGFloat placeholderWidth = [self widthForCardNumber:self.numberField.placeholder] - 4;
    CGFloat numberWidth = [self widthForCardNumber:self.viewModel.defaultPlaceholder] - 4;
    CGFloat numberFieldWidth = MAX(placeholderWidth, numberWidth);

    CGFloat nonFragmentWidth = [self widthForCardNumber:[self.viewModel numberWithoutLastDigits]] - 8;
    if (self.viewModel.brand == STPCardBrandAmex) {
        // AMEX cards have 1 less whitespace, so can have less length
        numberFieldWidth -= 16;
    }

    CGFloat numberFieldX = self.numberFieldShrunk ? STPPaymentCardTextFieldDefaultPadding - nonFragmentWidth : 8;
    return CGRectMake(numberFieldX, 0, numberFieldWidth, CGRectGetHeight(bounds));
}

- (CGRect)zipcodeFieldRectForBounds:(CGRect)bounds {
    CGRect fieldsRect = [self fieldsRectForBounds:bounds];

    CGFloat zipcodeWidth = MAX([self widthForText:self.zipcodeField.placeholder], [self widthForText:@"A1B-2C3"]);
    CGFloat zipcodeX = self.numberFieldShrunk ?
            CGRectGetWidth(fieldsRect) - zipcodeWidth - STPPaymentCardTextFieldDefaultPadding / 2  :
            CGRectGetWidth(fieldsRect);
    return CGRectMake(zipcodeX + STPPaymentCardTextFieldDefaultPadding, 0, zipcodeWidth, CGRectGetHeight(bounds));
}

- (CGFloat)paddingForExpirationAndCVC: (CGRect)bounds {
    CGRect numberFieldRect = [self numberFieldRectForBounds:bounds];
    CGRect zipcodeFieldRect = [self zipcodeFieldRectForBounds:bounds];
    CGFloat totalLength = CGRectGetMinX(zipcodeFieldRect) - CGRectGetMaxX(numberFieldRect);
    return MAX(0, (totalLength - [self expirationWidth] - [self cvcWidth]) / 3.0);
}

- (CGFloat)cvcWidth {
    return MAX([self widthForText:self.cvcField.placeholder], [self widthForText:@"8888"]);
}

- (CGFloat)expirationWidth {
    return MAX([self widthForText:self.expirationField.placeholder], [self widthForText:@"88/88"]) - 6;
}

- (CGRect)cvcFieldRectForBounds:(CGRect)bounds {
    CGRect expirationFieldRect = [self expirationFieldRectForBounds:bounds];
    CGFloat cvcX = CGRectGetMaxX(expirationFieldRect) + [self paddingForExpirationAndCVC:bounds];
    return CGRectMake(cvcX, 0, [self cvcWidth], CGRectGetHeight(bounds));
}

- (CGRect)expirationFieldRectForBounds:(CGRect)bounds {
    CGRect numberFieldRect = [self numberFieldRectForBounds:bounds];
    CGFloat expirationX = CGRectGetMaxX(numberFieldRect) + [self paddingForExpirationAndCVC:bounds];
    return CGRectMake(expirationX + STPPaymentCardTextFieldDefaultPadding, 0, [self expirationWidth], CGRectGetHeight(bounds));
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGRect bounds = self.bounds;

    self.brandImageView.frame = [self brandImageRectForBounds:bounds];
    self.fieldsView.frame = [self fieldsRectForBounds:bounds];
    self.numberField.frame = [self numberFieldRectForBounds:bounds];
    self.cvcField.frame = [self cvcFieldRectForBounds:bounds];
    self.expirationField.frame = [self expirationFieldRectForBounds:bounds];
    self.zipcodeField.frame = [self zipcodeFieldRectForBounds:bounds];
}

#pragma mark - private helper methods

- (STPFormTextField *)buildTextField {
    STPFormTextField *textField = [[STPFormTextField alloc] initWithFrame:CGRectZero];
    textField.backgroundColor = [UIColor clearColor];
    textField.keyboardType = UIKeyboardTypeNumberPad;
    textField.font = self.font;
    textField.defaultColor = self.textColor;
    textField.errorColor = self.textErrorColor;
    textField.placeholderColor = self.placeholderColor;
    textField.formDelegate = self;
    return textField;
}

- (NSArray *)allFields {
    return @[self.numberField, self.expirationField, self.cvcField, self.zipcodeField];
}

typedef void (^STPNumberShrunkCompletionBlock)(BOOL completed);
- (void)setNumberFieldShrunk:(BOOL)shrunk animated:(BOOL)animated
                  completion:(STPNumberShrunkCompletionBlock)completion {

    if (_numberFieldShrunk == shrunk) {
        if (completion) {
            completion(YES);
        }
        return;
    }

    _numberFieldShrunk = shrunk;
    void (^animations)() = ^void() {
        for (UIView *view in @[self.expirationField, self.cvcField, self.zipcodeField]) {
            view.alpha = 1.0f * shrunk;
        }
        [self layoutSubviews];
    };

    FAUXPAS_IGNORED_IN_METHOD(APIAvailability);
    NSTimeInterval duration = animated * 0.3;
    if ([UIView respondsToSelector:@selector(animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:)]) {
        [UIView animateWithDuration:duration
                              delay:0
             usingSpringWithDamping:0.85f
              initialSpringVelocity:0
                            options:0
                         animations:animations
                         completion:completion];
    } else {
        [UIView animateWithDuration:duration
                         animations:animations
                         completion:completion];
    }
}

- (BOOL)shouldShrinkNumberField {
    return [self.viewModel validationStateForField:STPCardFieldTypeNumber] == STPCardValidationStateValid;
}

- (CGFloat)widthForText:(NSString *)text {
    self.sizingField.formatsCardNumbers = NO;
    [self.sizingField setText:text];
    return [self.sizingField measureTextSize].width + 8;
}

- (CGFloat)widthForTextWithLength:(NSUInteger)length {
    NSString *text = [@"" stringByPaddingToLength:length withString:@"M" startingAtIndex:0];
    return [self widthForText:text];
}

- (CGFloat)widthForCardNumber:(NSString *)cardNumber {
    self.sizingField.formatsCardNumbers = YES;
    [self.sizingField setText:cardNumber];
    return [self.sizingField measureTextSize].width + 15;
}

#pragma mark STPPaymentTextFieldDelegate

- (void)formTextFieldDidBackspaceOnEmpty:(__unused STPFormTextField *)formTextField {
    STPFormTextField *previous = [self previousField];
    [previous becomeFirstResponder];
    [previous deleteBackward];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.selectedField = (STPFormTextField *)textField;
    switch ((STPCardFieldType)textField.tag) {
        case STPCardFieldTypeNumber:
            [self setNumberFieldShrunk:NO animated:YES completion:nil];
            if ([self.delegate respondsToSelector:@selector(paymentCardTextFieldDidBeginEditingNumber:)]) {
                [self.delegate paymentCardTextFieldDidBeginEditingNumber:self];
            }
            break;
        case STPCardFieldTypeCVC:
            [self setNumberFieldShrunk:YES animated:YES completion:nil];
            if ([self.delegate respondsToSelector:@selector(paymentCardTextFieldDidBeginEditingCVC:)]) {
                [self.delegate paymentCardTextFieldDidBeginEditingCVC:self];
            }
            break;
        case STPCardFieldTypeExpiration:
            [self setNumberFieldShrunk:YES animated:YES completion:nil];
            if ([self.delegate respondsToSelector:@selector(paymentCardTextFieldDidBeginEditingExpiration:)]) {
                [self.delegate paymentCardTextFieldDidBeginEditingExpiration:self];
            }
            break;
        case STPCardFieldTypeZipcode:
            [self setNumberFieldShrunk:YES animated:YES completion:nil];
            if ([self.delegate respondsToSelector:@selector(paymentCardTextFieldDidBeginEditingZipcode:)]) {
                [self.delegate paymentCardTextFieldDidBeginEditingZipcode:self];
            }
    }
    [self updateImageForFieldType:textField.tag];
}

- (void)textFieldDidEndEditing:(__unused UITextField *)textField {
    self.selectedField = nil;
}

- (BOOL)textField:(STPFormTextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {

    BOOL deletingLastCharacter = (range.location == textField.text.length - 1 && range.length == 1 && [string isEqualToString:@""]);
    if (deletingLastCharacter && [textField.text hasSuffix:@"/"] && range.location > 0) {
        range.location -= 1;
        range.length += 1;
    }

    NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    STPCardFieldType fieldType = textField.tag;
    switch (fieldType) {
        case STPCardFieldTypeNumber:
            self.viewModel.cardNumber = newText;
            textField.text = self.viewModel.cardNumber;
            break;
        case STPCardFieldTypeExpiration: {
            self.viewModel.rawExpiration = newText;
            textField.text = self.viewModel.rawExpiration;
            break;
        }
        case STPCardFieldTypeCVC:
            self.viewModel.cvc = newText;
            textField.text = self.viewModel.cvc;
            break;
        case STPCardFieldTypeZipcode:
            self.viewModel.zipcode = newText;
            textField.text = self.viewModel.zipcode;
            break;
    }
    [self updateImageForFieldType:fieldType];

    STPCardValidationState state = [self.viewModel validationStateForField:fieldType];
    textField.validText = YES;
    switch (state) {
        case STPCardValidationStateInvalid:
            textField.validText = NO;
            break;
        case STPCardValidationStateIncomplete:
            break;
        case STPCardValidationStateValid: {
            [self selectNextField];
            break;
        }
    }
    [self onChange];

    return NO;
}

- (UIImage *)brandImage {
    if (self.selectedField) {
        return [self brandImageForFieldType:self.selectedField.tag];
    } else {
        return [self brandImageForFieldType:STPCardFieldTypeNumber];
    }
}

+ (UIImage *)cvcImageForCardBrand:(STPCardBrand)cardBrand {
    return [STPPaymentCardTextFieldViewModel cvcImageForCardBrand:cardBrand];
}

+ (UIImage *)brandImageForCardBrand:(STPCardBrand)cardBrand {
    return [STPPaymentCardTextFieldViewModel brandImageForCardBrand:cardBrand];
}

- (UIImage *)brandImageForFieldType:(STPCardFieldType)fieldType {
    if (fieldType == STPCardFieldTypeCVC) {
        return [self.class cvcImageForCardBrand:self.viewModel.brand];
    }

    return [self.class brandImageForCardBrand:self.viewModel.brand];
}

- (void)updateImageForFieldType:(STPCardFieldType)fieldType {
    UIImage *image = [self brandImageForFieldType:fieldType];
    if (image != self.brandImageView.image) {
        self.brandImageView.image = image;

        CATransition *transition = [CATransition animation];
        transition.duration = 0.2f;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        transition.type = kCATransitionFade;

        [self.brandImageView.layer addAnimation:transition forKey:nil];

        [self setNeedsLayout];
    }
}

- (void)onChange {
    if ([self.delegate respondsToSelector:@selector(paymentCardTextFieldDidChange:)]) {
        [self.delegate paymentCardTextFieldDidChange:self];
    }
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

@implementation PTKCard
@end

@interface PTKView()
@property(nonatomic, weak)id<PTKViewDelegate>internalDelegate;
@end

@implementation PTKView

@dynamic delegate;

- (void)setDelegate:(id<PTKViewDelegate> __nullable)delegate {
    self.internalDelegate = delegate;
}

- (id<PTKViewDelegate> __nullable)delegate {
    return self.internalDelegate;
}

- (void)onChange {
    [super onChange];
    [self.internalDelegate paymentView:self withCard:[self card] isValid:self.isValid];
}

- (PTKCard * __nonnull)card {
    PTKCard *card = [[PTKCard alloc] init];
    card.number = self.cardNumber;
    card.expMonth = self.expirationMonth;
    card.expYear = self.expirationYear;
    card.cvc = self.cvc;
    return card;
}

@end

#pragma clang diagnostic pop
