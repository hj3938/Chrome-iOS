// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <XCTest/XCTest.h>

#include "base/mac/foundation_util.h"
#include "base/metrics/field_trial.h"
#include "base/strings/sys_string_conversions.h"
#include "components/strings/grit/components_strings.h"
#include "components/version_info/version_info.h"
#include "ios/chrome/browser/chrome_url_constants.h"
#include "ios/chrome/browser/experimental_flags.h"
#import "ios/chrome/browser/ui/omnibox/omnibox_text_field_ios.h"
#include "ios/chrome/test/app/navigation_test_util.h"
#include "ios/chrome/test/app/web_view_interaction_test_util.h"
#import "ios/chrome/test/earl_grey/chrome_earl_grey.h"
#import "ios/chrome/test/earl_grey/chrome_matchers.h"
#import "ios/chrome/test/earl_grey/chrome_test_case.h"
#import "ios/testing/wait_util.h"
#import "ios/web/public/web_client.h"
#include "ui/base/device_form_factor.h"
#include "ui/base/l10n/l10n_util.h"
#include "url/scheme_host_port.h"

using chrome_test_util::BackButton;
using chrome_test_util::ForwardButton;
using chrome_test_util::StaticHtmlViewContainingText;
using chrome_test_util::TapWebViewElementWithId;
using chrome_test_util::WebViewContainingText;

namespace {

// Loads WebUI page with given |host|.
void LoadWebUIUrl(const std::string& host) {
  GURL web_ui_url(url::SchemeHostPort(kChromeUIScheme, host, 0).Serialize());
  [ChromeEarlGrey loadURL:web_ui_url];
}

// Adds wait for omnibox text matcher so that omnibox text can be updated.
// TODO(crbug.com/642207): This method has to be unified with the omniboxText
// matcher or resides in the same location with the omniboxText matcher.
id<GREYMatcher> WaitForOmniboxText(std::string text) {
  MatchesBlock matches = ^BOOL(UIView* view) {
    if (![view isKindOfClass:[OmniboxTextFieldIOS class]]) {
      return NO;
    }
    OmniboxTextFieldIOS* omnibox =
        base::mac::ObjCCast<OmniboxTextFieldIOS>(view);
    GREYAssert(testing::WaitUntilConditionOrTimeout(
                   testing::kWaitForUIElementTimeout,
                   ^{
                     return base::SysNSStringToUTF8(omnibox.text) == text;
                   }),
               @"Omnibox did not contain %@", base::SysUTF8ToNSString(text));
    return YES;
  };

  DescribeToBlock describe = ^(id<GREYDescription> description) {
    [description appendText:@"omnibox text "];
    [description appendText:base::SysUTF8ToNSString(text)];
  };

  return grey_allOf(chrome_test_util::Omnibox(),
                    [[[GREYElementMatcherBlock alloc]
                        initWithMatchesBlock:matches
                            descriptionBlock:describe] autorelease],
                    nil);
}

}  // namespace

// Test case for chrome://* WebUI pages.
@interface WebUITestCase : ChromeTestCase
@end

@implementation WebUITestCase

// Tests that chrome://version renders and contains correct version number and
// user agent string.
- (void)testVersion {
  LoadWebUIUrl(kChromeUIVersionHost);

  // Verify that app version is present on the page.
  const std::string version = version_info::GetVersionNumber();
  [[EarlGrey selectElementWithMatcher:WebViewContainingText(version)]
      assertWithMatcher:grey_notNil()];

  // Verify that mobile User Agent string is present on the page.
  const bool isDesktopUA = false;
  const std::string userAgent = web::GetWebClient()->GetUserAgent(isDesktopUA);
  [[EarlGrey selectElementWithMatcher:WebViewContainingText(userAgent)]
      assertWithMatcher:grey_notNil()];
}

// Tests that chrome://physical-web renders and the page title is present.
- (void)testPhysicalWeb {
  // Enable the Physical Web via Chrome variation.
  base::FieldTrialList::CreateFieldTrial("PhysicalWebEnabled", "Enabled");

  LoadWebUIUrl(kChromeUIPhysicalWebHost);

  // Verify that the title string is present on the page.
  std::string pageTitle = l10n_util::GetStringUTF8(IDS_PHYSICAL_WEB_UI_TITLE);
  [[EarlGrey selectElementWithMatcher:WebViewContainingText(pageTitle)]
      assertWithMatcher:grey_notNil()];
}

// Tests that clicking on a link for a native page from chrome://chrome-urls
// navigates to that page.
- (void)testChromeURLNavigateToNativePage {
  LoadWebUIUrl(kChromeUIChromeURLsHost);

  // Tap on chrome://terms link on the page.
  chrome_test_util::TapWebViewElementWithId(kChromeUITermsHost);

  // Verify that the resulting page is chrome://terms.
  [[EarlGrey selectElementWithMatcher:WaitForOmniboxText("chrome://terms")]
      assertWithMatcher:grey_sufficientlyVisible()];
  NSString* kTermsText = @"Google Chrome Terms of Service";
  [[EarlGrey selectElementWithMatcher:StaticHtmlViewContainingText(kTermsText)]
      assertWithMatcher:grey_notNil()];
}

// Tests that back navigation functions properly after navigation via anchor
// click.
- (void)testChromeURLBackNavigationFromAnchorClick {
  LoadWebUIUrl(kChromeUIChromeURLsHost);

  // Tap on chrome://version link on the page.
  chrome_test_util::TapWebViewElementWithId(kChromeUIVersionHost);

  // Verify that the resulting page is chrome://version.
  [[EarlGrey selectElementWithMatcher:WaitForOmniboxText("chrome://version")]
      assertWithMatcher:grey_sufficientlyVisible()];
  const std::string kAuthorsText = "The Chromium Authors";
  [[EarlGrey selectElementWithMatcher:WebViewContainingText(kAuthorsText)]
      assertWithMatcher:grey_notNil()];

  // Tap the back button in the toolbar and verify that the resulting page is
  // the previously visited page chrome://chrome-urls.
  [[EarlGrey selectElementWithMatcher:BackButton()] performAction:grey_tap()];
  [[EarlGrey
      selectElementWithMatcher:WaitForOmniboxText("chrome://chrome-urls")]
      assertWithMatcher:grey_sufficientlyVisible()];
  const std::string kChromeURLsText = "List of Chrome URLs";
  [[EarlGrey selectElementWithMatcher:WebViewContainingText(kChromeURLsText)]
      assertWithMatcher:grey_notNil()];
}

// Tests that back and forward navigation between chrome URLs functions
// properly.
- (void)testChromeURLBackAndForwardNavigation {
  // Navigate to the first URL chrome://version.
  LoadWebUIUrl(kChromeUIVersionHost);

  // Navigate to the second URL chrome://flags.
  LoadWebUIUrl(kChromeUIFlagsHost);

  // Tap the back button in the toolbar and verify that the resulting page's URL
  // corresponds to the first URL chrome://version that was loaded.
  [[EarlGrey selectElementWithMatcher:BackButton()] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:WaitForOmniboxText("chrome://version")]
      assertWithMatcher:grey_sufficientlyVisible()];

  // Tap the forward button in the toolbar and verify that the resulting page's
  // URL corresponds the second URL chrome://flags that was loaded.
  [[EarlGrey selectElementWithMatcher:ForwardButton()]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:WaitForOmniboxText("chrome://flags")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

// Tests that all URLs on chrome://chrome-urls page load without error.
- (void)testChromeURLsLoadWithoutError {
  // Load WebUI pages and verify they load without any error.
  for (size_t i = 0; i < kNumberOfChromeHostURLs; ++i) {
    const char* host = kChromeHostURLs[i];
    // Exclude non-WebUI pages, as they do not go through a "loading" phase as
    // expected in LoadWebUIUrl.
    if (host == kChromeUIBookmarksHost || host == kChromeUINewTabHost ||
        host == kChromeUITermsHost) {
      continue;
    }
    if (host == kChromeUIPhysicalWebHost &&
        !experimental_flags::IsPhysicalWebEnabled()) {
      continue;
    }
    LoadWebUIUrl(host);
    const std::string chrome_url_path =
        url::SchemeHostPort(kChromeUIScheme, kChromeHostURLs[i], 0).Serialize();
    [[EarlGrey selectElementWithMatcher:WaitForOmniboxText(chrome_url_path)]
        assertWithMatcher:grey_sufficientlyVisible()];
  }
  // Load chrome://terms differently since it is a Native page and is never in
  // the "loading" phase.
  chrome_test_util::LoadUrl(GURL(kChromeUITermsURL));
  [[EarlGrey selectElementWithMatcher:WaitForOmniboxText("chrome://terms")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

// Tests that loading an invalid Chrome URL results in an error page.
- (void)testChromeURLInvalid {
  // Navigate to the native error page chrome://invalidchromeurl.
  const std::string kChromeInvalidURL = "chrome://invalidchromeurl";
  chrome_test_util::LoadUrl(GURL(kChromeInvalidURL));

  // Verify that the resulting page is an error page.
  [[EarlGrey selectElementWithMatcher:WaitForOmniboxText(kChromeInvalidURL)]
      assertWithMatcher:grey_sufficientlyVisible()];
  NSString* kError =
      l10n_util::GetNSString(IDS_ERRORPAGES_HEADING_NOT_AVAILABLE);
  id<GREYMatcher> messageMatcher = [GREYMatchers matcherForText:kError];
  [[EarlGrey selectElementWithMatcher:messageMatcher]
      assertWithMatcher:grey_notNil()];
}

@end
