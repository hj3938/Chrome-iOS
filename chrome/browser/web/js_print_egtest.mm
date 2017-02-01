// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <EarlGrey/EarlGrey.h>
#import <XCTest/XCTest.h>
#include <map>

#import "ios/chrome/test/earl_grey/chrome_earl_grey.h"
#import "ios/chrome/test/earl_grey/chrome_matchers.h"
#import "ios/chrome/test/earl_grey/chrome_test_case.h"
#import "ios/web/public/test/http_server.h"
#import "ios/web/public/test/http_server_util.h"

// Test case for bringing up the print dialog when a web site's JavaScript runs
// "window.print".
@interface JSPrintTestCase : ChromeTestCase
@end

@implementation JSPrintTestCase

// Tests that tapping a button with onclick='window.print' brings up the
// print dialog.
- (void)testWebPrintButton {
  // Create map of canned responses and set up the test HTML server.
  std::map<GURL, std::string> responses;
  const GURL testURL = web::test::HttpServer::MakeUrl("http://printpage");

  // Page containing button with onclick attribute calling window.print.
  responses[testURL] =
      "<input onclick='window.print();' type='button' id=\"printButton\" "
      "value='Print Page' />";

  web::test::SetUpSimpleHttpServer(responses);
  [ChromeEarlGrey loadURL:testURL];

  // Tap print button.
  [ChromeEarlGrey tapWebViewElementWithID:@"printButton"];

  // Test if print dialog appeared.
  id<GREYMatcher> printerOption = grey_allOf(
      grey_accessibilityLabel(@"Printer Options"),
      grey_not(grey_accessibilityTrait(UIAccessibilityTraitHeader)), nil);
  [[EarlGrey selectElementWithMatcher:printerOption]
      assertWithMatcher:grey_sufficientlyVisible()];

  // Clean up and close print dialog.
  id<GREYMatcher> cancelButton =
      grey_allOf(grey_accessibilityLabel(@"Cancel"),
                 grey_accessibilityTrait(UIAccessibilityTraitButton), nil);
  [[EarlGrey selectElementWithMatcher:cancelButton] performAction:grey_tap()];
}

@end