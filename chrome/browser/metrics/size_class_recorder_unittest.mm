// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/metrics/size_class_recorder.h"
#import "ios/chrome/browser/metrics/size_class_recorder_private.h"

#include <memory>

#import "base/mac/scoped_nsobject.h"
#include "base/test/histogram_tester.h"
#import "ios/chrome/browser/ui/ui_util.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "testing/platform_test.h"

using ios_internal::SizeClassForReporting;
using ios_internal::SizeClassForReportingForUIUserInterfaceSizeClass;

namespace {

const char kSizeClassUsedHistogramName[] = "Tab.HorizontalSizeClassUsed";

const char kPageLoadSizeClassHistogramName[] =
    "Tab.PageLoadInHorizontalSizeClass";

class SizeClassRecorderTest : public PlatformTest {
 protected:
  void SetUp() override {
    PlatformTest::SetUp();
    histogram_tester_.reset(new base::HistogramTester());
  }

  base::scoped_nsobject<SizeClassRecorder> recorder_;
  std::unique_ptr<base::HistogramTester> histogram_tester_;
};

TEST_F(SizeClassRecorderTest, Initialization_SizeClassUnspecified) {
  // SizeClassRecoder is only available on iPad devices.
  if (!IsIPadIdiom())
    return;

  recorder_.reset([[SizeClassRecorder alloc]
      initWithHorizontalSizeClass:UIUserInterfaceSizeClassUnspecified]);
  recorder_.reset();

  histogram_tester_->ExpectTotalCount(kSizeClassUsedHistogramName, 0);
  histogram_tester_->ExpectTotalCount(kPageLoadSizeClassHistogramName, 0);
}

TEST_F(SizeClassRecorderTest, Initialization_SizeClassCompact) {
  // SizeClassRecoder is only available on iPad devices.
  if (!IsIPadIdiom())
    return;

  recorder_.reset([[SizeClassRecorder alloc]
      initWithHorizontalSizeClass:UIUserInterfaceSizeClassCompact]);
  recorder_.reset();

  histogram_tester_->ExpectTotalCount(kSizeClassUsedHistogramName, 0);
  histogram_tester_->ExpectTotalCount(kPageLoadSizeClassHistogramName, 0);
}

TEST_F(SizeClassRecorderTest, Initialization_SizeClassRegular) {
  // SizeClassRecoder is only available on iPad devices.
  if (!IsIPadIdiom())
    return;

  recorder_.reset([[SizeClassRecorder alloc]
      initWithHorizontalSizeClass:UIUserInterfaceSizeClassRegular]);
  recorder_.reset();

  histogram_tester_->ExpectTotalCount(kSizeClassUsedHistogramName, 0);
  histogram_tester_->ExpectTotalCount(kPageLoadSizeClassHistogramName, 0);
}

TEST_F(SizeClassRecorderTest, RecordInitialSizeClassOnAppBecomeActive) {
  // SizeClassRecoder is only available on iPad devices.
  if (!IsIPadIdiom())
    return;

  recorder_.reset([[SizeClassRecorder alloc]
      initWithHorizontalSizeClass:UIUserInterfaceSizeClassCompact]);
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationDidBecomeActiveNotification
                    object:nil];

  histogram_tester_->ExpectUniqueSample(kSizeClassUsedHistogramName,
                                        SizeClassForReporting::COMPACT, 1);
  histogram_tester_->ExpectTotalCount(kPageLoadSizeClassHistogramName, 0);
}

TEST_F(SizeClassRecorderTest,
       DontRecordInitialSizeClassSubsequentAppBecomeActive) {
  // SizeClassRecoder is only available on iPad devices.
  if (!IsIPadIdiom())
    return;

  recorder_.reset([[SizeClassRecorder alloc]
      initWithHorizontalSizeClass:UIUserInterfaceSizeClassCompact]);
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationDidBecomeActiveNotification
                    object:nil];
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationDidBecomeActiveNotification
                    object:nil];

  histogram_tester_->ExpectUniqueSample(kSizeClassUsedHistogramName,
                                        SizeClassForReporting::COMPACT, 1);
  histogram_tester_->ExpectTotalCount(kPageLoadSizeClassHistogramName, 0);
}

TEST_F(SizeClassRecorderTest, RecordSizeClassChangeInForeground) {
  // SizeClassRecoder is only available on iPad devices.
  if (!IsIPadIdiom())
    return;

  recorder_.reset([[SizeClassRecorder alloc]
      initWithHorizontalSizeClass:UIUserInterfaceSizeClassUnspecified]);
  [recorder_ horizontalSizeClassDidChange:UIUserInterfaceSizeClassRegular];

  histogram_tester_->ExpectUniqueSample(kSizeClassUsedHistogramName,
                                        SizeClassForReporting::REGULAR, 1);
  histogram_tester_->ExpectTotalCount(kPageLoadSizeClassHistogramName, 0);
}

TEST_F(SizeClassRecorderTest, DontRecordSizeClassChangeInBackground) {
  // SizeClassRecoder is only available on iPad devices.
  if (!IsIPadIdiom())
    return;

  recorder_.reset([[SizeClassRecorder alloc]
      initWithHorizontalSizeClass:UIUserInterfaceSizeClassUnspecified]);
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationDidEnterBackgroundNotification
                    object:nil];
  [recorder_ horizontalSizeClassDidChange:UIUserInterfaceSizeClassRegular];

  histogram_tester_->ExpectTotalCount(kSizeClassUsedHistogramName, 0);
  histogram_tester_->ExpectTotalCount(kPageLoadSizeClassHistogramName, 0);
}

TEST_F(SizeClassRecorderTest,
       RecordSizeClassChangeInForegroundAfterBackground) {
  // SizeClassRecoder is only available on iPad devices.
  if (!IsIPadIdiom())
    return;

  recorder_.reset([[SizeClassRecorder alloc]
      initWithHorizontalSizeClass:UIUserInterfaceSizeClassUnspecified]);
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationDidEnterBackgroundNotification
                    object:nil];
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationWillEnterForegroundNotification
                    object:nil];
  [recorder_ horizontalSizeClassDidChange:UIUserInterfaceSizeClassCompact];

  histogram_tester_->ExpectUniqueSample(kSizeClassUsedHistogramName,
                                        SizeClassForReporting::COMPACT, 1);
  histogram_tester_->ExpectTotalCount(kPageLoadSizeClassHistogramName, 0);
}

TEST_F(SizeClassRecorderTest, RecordSizeClassOnPageLoaded_Unspecified) {
  // SizeClassRecoder is only available on iPad devices.
  if (!IsIPadIdiom())
    return;

  recorder_.reset([[SizeClassRecorder alloc]
      initWithHorizontalSizeClass:UIUserInterfaceSizeClassUnspecified]);
  [recorder_
      pageLoadedWithHorizontalSizeClass:UIUserInterfaceSizeClassUnspecified];

  histogram_tester_->ExpectTotalCount(kSizeClassUsedHistogramName, 0);
  histogram_tester_->ExpectUniqueSample(kPageLoadSizeClassHistogramName,
                                        SizeClassForReporting::UNSPECIFIED, 1);
}

TEST_F(SizeClassRecorderTest, RecordSizeClassOnPageLoaded_Compact) {
  // SizeClassRecoder is only available on iPad devices.
  if (!IsIPadIdiom())
    return;

  recorder_.reset([[SizeClassRecorder alloc]
      initWithHorizontalSizeClass:UIUserInterfaceSizeClassUnspecified]);
  [recorder_ pageLoadedWithHorizontalSizeClass:UIUserInterfaceSizeClassCompact];

  histogram_tester_->ExpectTotalCount(kSizeClassUsedHistogramName, 0);
  histogram_tester_->ExpectUniqueSample(kPageLoadSizeClassHistogramName,
                                        SizeClassForReporting::COMPACT, 1);
}

TEST_F(SizeClassRecorderTest, RecordSizeClassOnPageLoaded_Regular) {
  // SizeClassRecoder is only available on iPad devices.
  if (!IsIPadIdiom())
    return;

  recorder_.reset([[SizeClassRecorder alloc]
      initWithHorizontalSizeClass:UIUserInterfaceSizeClassUnspecified]);
  [recorder_ pageLoadedWithHorizontalSizeClass:UIUserInterfaceSizeClassRegular];

  histogram_tester_->ExpectTotalCount(kSizeClassUsedHistogramName, 0);
  histogram_tester_->ExpectUniqueSample(kPageLoadSizeClassHistogramName,
                                        SizeClassForReporting::REGULAR, 1);
}

}  // namespace
