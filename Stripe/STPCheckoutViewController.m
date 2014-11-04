//
//  STPCheckoutViewController.m
//  StripeExample
//
//  Created by Jack Flintermann on 9/15/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import "STPCheckoutViewController.h"
#import "STPCheckoutOptions.h"
#import "STPToken.h"
#import "Stripe.h"
#import "STPColorUtils.h"

@interface STPCheckoutViewController()<UIWebViewDelegate>
@property(weak, nonatomic)UIWebView *webView;
@property(weak, nonatomic)UIActivityIndicatorView *activityIndicator;
@property(nonatomic)STPCheckoutOptions *options;
@property(nonatomic)NSURL *url;
@property(nonatomic)UIStatusBarStyle previousStyle;

@end

@implementation STPCheckoutViewController

static NSString *const checkoutUserAgent = @"Stripe";
static NSString *const checkoutURL = @"http://localhost:5394/v3/ios";
static NSString *const checkoutRPCScheme = @"stripecheckout";
static NSString *const checkoutRedirectPrefix = @"/-/";

- (instancetype)initWithOptions:(STPCheckoutOptions *)options {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _options = options;
        NSString *userAgent = [[UIWebView new] stringByEvaluatingJavaScriptFromString:@"window.navigator.userAgent"];
        if ([userAgent rangeOfString:checkoutUserAgent].location == NSNotFound) {
            userAgent = [NSString stringWithFormat:@"%@ %@/%@", userAgent, checkoutUserAgent, STPLibraryVersionNumber];
            NSDictionary *defaults = @{@"UserAgent": userAgent};
            [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
        }
            _previousStyle = [[UIApplication sharedApplication] statusBarStyle];
    }
    return self;
}

- (NSString *)optionsJavaScript {
    return [NSString stringWithFormat:@"window.StripeCheckoutOptions = %@;", [self.options stringifiedJSONRepresentation]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.url = [NSURL URLWithString:checkoutURL];
    
    UIWebView *webView = [UIWebView new];
    [self.view addSubview:webView];
    [webView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:|-0-[webView]-0-|"
                               options:NSLayoutFormatDirectionLeadingToTrailing
                               metrics:nil
                               views:NSDictionaryOfVariableBindings(webView)]];
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:|-0-[webView]-0-|"
                               options:NSLayoutFormatDirectionLeadingToTrailing
                               metrics:nil
                               views:NSDictionaryOfVariableBindings(webView)]];
    webView.keyboardDisplayRequiresUserAction = NO;
    webView.backgroundColor = [UIColor whiteColor];
    self.view.backgroundColor = [UIColor whiteColor];
    if (self.options.logoColor) {
        webView.backgroundColor = self.options.logoColor;
    }
    [webView loadRequest:[NSURLRequest requestWithURL:self.url]];
    webView.delegate = self;
    self.webView = webView;
    
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.hidesWhenStopped = YES;
    [self.view addSubview:activityIndicator];
    self.activityIndicator = activityIndicator;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
- (UIStatusBarStyle)preferredStatusBarStyle {
    return [STPColorUtils colorIsLight:self.options.logoColor] ? UIStatusBarStyleDefault : UIStatusBarStyleLightContent;
}
#endif

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.activityIndicator.center = self.view.center;
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [webView stringByEvaluatingJavaScriptFromString:[self optionsJavaScript]];
    [self.activityIndicator startAnimating];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *url = request.URL;
    if (navigationType == UIWebViewNavigationTypeLinkClicked &&
        [url.host isEqualToString:self.url.host] &&
        [url.path rangeOfString:checkoutRedirectPrefix].location == 0) {
        [[UIApplication sharedApplication] openURL:url];
        return NO;
    }
    if ([url.scheme isEqualToString:checkoutRPCScheme]) {
        NSString *event = url.host;
        NSString *path = [url.path componentsSeparatedByString:@"/"][1];
        NSDictionary *payload = nil;
        if (path != nil) {
            payload = [NSJSONSerialization JSONObjectWithData:[path dataUsingEncoding:NSUTF8StringEncoding]
                                                      options:0 error:nil];
        }
        
        if ([event isEqualToString:@"CheckoutDidOpen"]) {
            if (payload[@"logoColor"]) {
                [self setLogoColor:[STPColorUtils colorForHexCode:payload[@"logoColor"]]];
            }
        }
        else if ([event isEqualToString:@"CheckoutDidTokenize"]) {
            STPToken *token = nil;
            if (payload != nil && payload[@"token"] != nil) {
                token = [[STPToken alloc] initWithAttributeDictionary:payload[@"token"]];
            }
            [self.delegate checkoutController:self didFinishWithToken:token];
            [self resetStatusBarColor];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else if ([url.host isEqualToString:@"CheckoutDidClose"]) {
            if ([self.delegate respondsToSelector:@selector(checkoutControllerDidCancel:)]) {
                [self.delegate checkoutControllerDidCancel:self];
            }
            [self resetStatusBarColor];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else if ([event isEqualToString:@"CheckoutDidError"]) {
            if ([self.delegate respondsToSelector:@selector(checkoutController:didFailWithError:)]) {
                NSError *error = [[NSError alloc] initWithDomain:StripeDomain code:STPCheckoutError userInfo:payload];
                [self.delegate checkoutController:self didFailWithError:error];
            }
            [self resetStatusBarColor];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        return NO;
    }
    return navigationType == UIWebViewNavigationTypeOther;
}

- (void)resetStatusBarColor {
    [[UIApplication sharedApplication] setStatusBarStyle:self.previousStyle animated:YES];
}

- (void)setLogoColor:(UIColor *)color {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    self.options.logoColor = color;
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        [self setNeedsStatusBarAppearanceUpdate];
        UIStatusBarStyle style = [STPColorUtils colorIsLight:color] ? UIStatusBarStyleDefault : UIStatusBarStyleLightContent;
        [[UIApplication sharedApplication] setStatusBarStyle:style animated:YES];
    }
#endif
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [UIView animateWithDuration:0.2 animations:^{
        self.activityIndicator.alpha = 0;
    } completion:^(BOOL finished) {
        [self.activityIndicator stopAnimating];
    }];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self.activityIndicator stopAnimating];
    if ([self.delegate respondsToSelector:@selector(checkoutController:didFailWithError:)]) {
        [self.delegate checkoutController:self didFailWithError:error];
    }
    [self resetStatusBarColor];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
