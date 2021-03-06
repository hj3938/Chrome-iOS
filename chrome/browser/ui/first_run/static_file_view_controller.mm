// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ios/chrome/browser/ui/first_run/static_file_view_controller.h"

#import <WebKit/WebKit.h>

#include "base/logging.h"
#include "base/mac/scoped_nsobject.h"
#include "ios/chrome/browser/browser_state/chrome_browser_state.h"
#import "ios/chrome/browser/ui/material_components/utils.h"
#include "ios/chrome/browser/ui/rtl_geometry.h"
#import "ios/third_party/material_components_ios/src/components/AppBar/src/MaterialAppBar.h"
#import "ios/third_party/material_components_ios/src/components/FlexibleHeader/src/MaterialFlexibleHeader.h"
#import "ios/third_party/material_components_ios/src/components/Palettes/src/MaterialPalettes.h"
#import "ios/web/public/web_view_creation_util.h"

@interface StaticFileViewController ()<UIScrollViewDelegate> {
  ios::ChromeBrowserState* _browserState;  // weak
  base::scoped_nsobject<NSURL> _URL;
  // YES if the header has been configured for RTL.
  BOOL _headerLaidOutForRTL;
  // The web view used to display the static content.
  base::scoped_nsobject<WKWebView> _webView;
  // The header.
  base::scoped_nsobject<MDCAppBar> _appBar;
}

@end

@implementation StaticFileViewController

- (instancetype)initWithBrowserState:(ios::ChromeBrowserState*)browserState
                                 URL:(NSURL*)URL {
  DCHECK(browserState);
  DCHECK(URL);
  self = [super init];
  if (self) {
    _appBar.reset([[MDCAppBar alloc] init]);
    [self addChildViewController:[_appBar headerViewController]];
    _browserState = browserState;
    _URL.reset([URL retain]);
  }
  return self;
}

- (void)dealloc {
  [_webView scrollView].delegate = nil;
  [super dealloc];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  _webView.reset([web::BuildWKWebView(self.view.bounds, _browserState) retain]);
  [_webView setAutoresizingMask:UIViewAutoresizingFlexibleWidth |
                                UIViewAutoresizingFlexibleHeight];

  // Loads terms of service into the web view.
  [_webView loadRequest:[NSURLRequest requestWithURL:_URL]];
  [_webView setBackgroundColor:[UIColor whiteColor]];
  [self.view addSubview:_webView];

  ConfigureAppBarWithCardStyle(_appBar);
  [_appBar headerViewController].headerView.trackingScrollView =
      [_webView scrollView];
  [_webView scrollView].delegate = [_appBar headerViewController];

  // Add the app bar at the end.
  [_appBar addSubviewsToParent];
}

@end
