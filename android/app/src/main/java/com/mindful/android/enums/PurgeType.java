/*
 *
 *  *
 *  *  * Copyright (c) 2024 Mindful (https://github.com/akaMrNagar/Mindful)
 *  *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *  *
 *  *  * This source code is licensed under the GPL-2.0 license license found in the
 *  *  * LICENSE file in the root directory of this source tree.
 *  *
 *
 */

package com.mindful.android.enums;

public enum PurgeType {
    FocusSession,
    BedtimeRoutine,
    AppTimerOut,
    AppLaunchLimitOut,
    GroupTimerOut;


    public static PurgeType fromInteger(int x) {
        switch (x) {
            case 0:
                return PurgeType.FocusSession;
            case 1:
                return PurgeType.BedtimeRoutine;
            case 2:
                return PurgeType.AppTimerOut;
            case 3:
                return PurgeType.AppLaunchLimitOut;
            case 4:
                return PurgeType.GroupTimerOut;
        }
        return PurgeType.AppTimerOut;
    }

    public int toInteger() {
        switch (this) {
            case FocusSession:
                return 0;
            case BedtimeRoutine:
                return 1;
            case AppTimerOut:
                return 2;
            case AppLaunchLimitOut:
                return 3;
            case GroupTimerOut:
                return 4;
        }
        return 2;
    }
}