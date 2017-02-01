// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef IOS_CHROME_BROWSER_UI_BROWSER_CONTAINER_VIEW_H_
#define IOS_CHROME_BROWSER_UI_BROWSER_CONTAINER_VIEW_H_

#import <UIKit/UIKit.h>

// UIView which allows displaing and removing a content view.
@interface BrowserContainerView : UIView

// Adds the given |contentView| as a subview and removes the previously added
// |contentView| if any. If |contentView| is nil then only old content view is
// removed.
- (void)displayContentView:(UIView*)contentView;

@end

#endif  // IOS_CHROME_BROWSER_UI_BROWSER_CONTAINER_VIEW_H_
