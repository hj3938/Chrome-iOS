// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ios/chrome/browser/ui/settings/utils/pref_backed_boolean.h"

#import "base/mac/scoped_nsobject.h"
#include "base/values.h"
#include "components/prefs/pref_registry_simple.h"
#include "components/prefs/testing_pref_service.h"
#import "ios/chrome/browser/ui/settings/utils/fake_observable_boolean.h"
#include "ios/web/public/test/test_web_thread_bundle.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "testing/platform_test.h"

namespace {

const char kTestSwitchPref[] = "test-pref";

class PrefBackedBooleanTest : public PlatformTest {
 public:
  void SetUp() override {
    pref_service_.registry()->RegisterBooleanPref(kTestSwitchPref, false);
    observable_boolean_.reset([[PrefBackedBoolean alloc]
        initWithPrefService:&pref_service_
                   prefName:kTestSwitchPref]);
  }

 protected:
  bool GetPref() { return pref_service_.GetBoolean(kTestSwitchPref); }

  void SetPref(bool value) {
    base::Value* booleanValue = new base::FundamentalValue(value);
    pref_service_.SetUserPref(kTestSwitchPref, booleanValue);
  }

  PrefBackedBoolean* GetObservableBoolean() {
    return observable_boolean_.get();
  }

  web::TestWebThreadBundle thread_bundle_;
  TestingPrefServiceSimple pref_service_;
  base::scoped_nsobject<PrefBackedBoolean> observable_boolean_;
};

TEST_F(PrefBackedBooleanTest, ReadFromPrefs) {
  SetPref(false);
  EXPECT_FALSE(GetObservableBoolean().value);

  SetPref(true);
  EXPECT_TRUE(GetObservableBoolean().value);
}

TEST_F(PrefBackedBooleanTest, WriteToPrefs) {
  GetObservableBoolean().value = true;
  EXPECT_TRUE(GetPref());

  GetObservableBoolean().value = false;
  EXPECT_FALSE(GetPref());
}

TEST_F(PrefBackedBooleanTest, ObserverUpdates) {
  SetPref(false);
  base::scoped_nsobject<TestBooleanObserver> observer(
      [[TestBooleanObserver alloc] init]);
  GetObservableBoolean().observer = observer;
  EXPECT_EQ(0, observer.get().updateCount);

  SetPref(true);
  EXPECT_EQ(1, observer.get().updateCount)
      << "Changing value should update observer";

  SetPref(true);
  EXPECT_EQ(1, observer.get().updateCount)
      << "Setting the same value should not update observer";
}

}  // namespace
