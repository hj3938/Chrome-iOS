// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_PASSWORDS_PASSWORD_GENERATION_PROMPT_VIEW_H_
#define IOS_CHROME_BROWSER_PASSWORDS_PASSWORD_GENERATION_PROMPT_VIEW_H_

#import <UIKit/UIKit.h>

@protocol PasswordGenerationPromptDelegate;

// TODO(crbug.com/636874): move this to MDC if they support alerts with subview.
// Returns an UIView that prompts the user with a |password| generated by Chrome
// and explains what that means. The user can accept the password, cancel
// password generation, or click a link to view all their saved passwords.
@interface PasswordGenerationPromptDialog : UIView

// Init the view. If the user accepts the password, the |delegate| will be
// notified. Clicking a button will dismiss all UIViewController presented by
// |viewController|.
- (instancetype)initWithDelegate:(id<PasswordGenerationPromptDelegate>)delegate
                  viewController:(UIViewController*)viewController
    NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

- (instancetype)initWithCoder:(NSCoder*)aDecoder NS_UNAVAILABLE;

// Configures the dialog containing the content with the |password| and the
// buttons.
- (void)configureGlobalViewWithPassword:(NSString*)password;
@end

#endif  // IOS_CHROME_BROWSER_PASSWORDS_PASSWORD_GENERATION_PROMPT_VIEW_H_
