package com.mindful.android.services;

import static com.mindful.android.generics.ServiceBinder.ACTION_START_SERVICE;
import static com.mindful.android.receivers.alarm.MidnightResetReceiver.ACTION_MIDNIGHT_SERVICE_RESET;
import static com.mindful.android.utils.AppConstants.INTENT_EXTRA_IS_THIS_BEDTIME;
import static com.mindful.android.utils.AppConstants.INTENT_EXTRA_PACKAGE_NAME;

import android.annotation.SuppressLint;
import android.app.Service;
import android.app.usage.UsageStatsManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.IBinder;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.core.app.NotificationCompat;

import com.mindful.android.R;
import com.mindful.android.generics.ServiceBinder;
import com.mindful.android.helpers.NotificationHelper;
import com.mindful.android.helpers.ScreenUsageHelper;
import com.mindful.android.helpers.SharedPrefsHelper;
import com.mindful.android.receivers.DeviceLockUnlockReceiver;
import com.mindful.android.utils.Utils;

import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Timer;
import java.util.TimerTask;

/**
 * A service that tracks app usage, manages timers for app usage limits, and handles bedtime lockdowns.
 */
public class MindfulTrackerService extends Service {

    private static final int SERVICE_ID = 301;
    private final String TAG = "Mindful.MindfulTrackerService";
    public static final String ACTION_NEW_APP_LAUNCHED = "com.mindful.android.ACTION_NEW_APP_LAUNCHED";
    public static final String ACTION_START_SERVICE_BEDTIME_MODE = "com.mindful.android.MindfulTrackerService.START_SERVICE_BEDTIME";
    public static final String ACTION_STOP_SERVICE_BEDTIME_MODE = "com.mindful.android.MindfulTrackerService.STOP_SERVICE_BEDTIME";

    private boolean mIsServiceRunning = false;
    private boolean mIsStoppedForcefully = true;

    private UsageStatsManager mUsageStatsManager;

    private DeviceLockUnlockReceiver mLockUnlockReceiver;
    private AppLaunchReceiver mAppLaunchReceiver;

    private HashMap<String, Long> mAppTimers = new HashMap<>();
    private final HashSet<String> mPurgedApps = new HashSet<>();
    private HashSet<String> mDistractingApps = new HashSet<>();


    @Override
    public void onCreate() {
        super.onCreate();
        mUsageStatsManager = (UsageStatsManager) getSystemService(Context.USAGE_STATS_SERVICE);
    }

    @Override
    public int onStartCommand(@NonNull Intent intent, int flags, int startId) {
        String action = intent.getAction();
        if (action == null) return START_NOT_STICKY;

        switch (action) {
            // Only start service
            case ACTION_START_SERVICE: {
                startTrackingService();
                return START_STICKY;
            }
            // Start service if already not running along with bedtime routine
            case ACTION_START_SERVICE_BEDTIME_MODE: {
                if (!mIsServiceRunning) startTrackingService();
                startStopBedtimeRoutine(true);
                return START_STICKY;
            }
            // Stop bedtime routine
            case ACTION_STOP_SERVICE_BEDTIME_MODE:
                startStopBedtimeRoutine(false);
                break;

            // Time to reset purged app's list
            case ACTION_MIDNIGHT_SERVICE_RESET:
                mPurgedApps.clear();
                NotificationHelper.pushAlertNotification(this, 757, "Tracking service is resetting data at midnight");
                Log.d(TAG, "onStartCommand: Midnight reset completed");
                break;

            default:
                stopIfNoUsage();
                break;
        }

        return START_NOT_STICKY;
    }

    // REVIEW: Suppressing api warnings
    @SuppressLint("NewApi")
    private void startTrackingService() {
        mAppTimers = SharedPrefsHelper.fetchAppTimers(this);

        // Register lock/unlock receiver
        IntentFilter lockUnlockFilter = new IntentFilter();
        lockUnlockFilter.addAction(Intent.ACTION_USER_PRESENT);
        lockUnlockFilter.addAction(Intent.ACTION_SCREEN_OFF);
        mLockUnlockReceiver = new DeviceLockUnlockReceiver(this);
        registerReceiver(mLockUnlockReceiver, lockUnlockFilter);

        // Register app launch receiver
        mAppLaunchReceiver = new AppLaunchReceiver();
        registerReceiver(mAppLaunchReceiver, new IntentFilter(ACTION_NEW_APP_LAUNCHED), Context.RECEIVER_NOT_EXPORTED);

        // Create notification
        startForeground(
                SERVICE_ID,
                new NotificationCompat.Builder(this, NotificationHelper.NOTIFICATION_OTHER_CHANNEL_ID)
                        .setSmallIcon(R.drawable.ic_notification)
                        .setContentTitle("Mindful service")
                        .setContentText("Mindful is now tracking app usage to help you stay focused and manage your digital habits.")
                        .setAutoCancel(true)
                        .build()
        );

        Log.d(TAG, "startTrackingService: Foreground service started");
        mIsServiceRunning = true;
    }

    /**
     * Updates app timers from shared preferences and stops the service if no timers are active.
     */
    public void updateAppTimers() {
        mAppTimers = SharedPrefsHelper.fetchAppTimers(this);
        mPurgedApps.clear();
        Log.d(TAG, "updateAppTimers: App timers updated successfully");
        stopIfNoUsage();
    }

    /**
     * Stops the service if no timers are active and no distracting apps.
     */
    private void stopIfNoUsage() {
        if (mDistractingApps.isEmpty() && mAppTimers.isEmpty()) {
            mIsStoppedForcefully = false;
            Log.d(TAG, "stopIfNoUsage: The service is not required any more therefore, stopping it");
            stopForeground(true);
            stopSelf();
        }
    }

    /**
     * Starts or stops bedtime lockdown based on the passed flag.
     *
     * @param shouldStart True to start, false to stop.
     */
    public void startStopBedtimeRoutine(boolean shouldStart) {
        if (shouldStart) {
            mDistractingApps = SharedPrefsHelper.fetchBedtimeSettings(this).distractingApps;
            mPurgedApps.clear();

            Log.d(TAG, "startStopBedtimeRoutine: Bedtime routine STARTED successfully");
            // Broadcast launch event for last active app it may be restricted in bedtime mode
            if (mLockUnlockReceiver != null) mLockUnlockReceiver.broadcastLastAppLaunchEvent();

        } else {
            mDistractingApps.clear();
            Log.d(TAG, "startStopBedtimeRoutine: Bedtime routine STOPPED successfully");
            stopIfNoUsage();
        }
    }

    /**
     * Pauses or resumes tracking based on the given flag.
     *
     * @param shouldPause True to pause, false to resume.
     */
    public void pauseResumeTracking(boolean shouldPause) {
        if (mLockUnlockReceiver != null) mLockUnlockReceiver.pauseResumeTracking(shouldPause);
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        // Dispose and Unregister receiver
        if (mLockUnlockReceiver != null) {
            mLockUnlockReceiver.dispose();
            unregisterReceiver(mLockUnlockReceiver);
        }

        if (mAppLaunchReceiver != null) {
            mAppLaunchReceiver.cancelTimers();
            unregisterReceiver(mAppLaunchReceiver);
        }

        if (mIsStoppedForcefully) {
            Log.d(TAG, "onDestroy: Tracking service destroyed forcefully. Trying to restart it");
            if (!Utils.isServiceRunning(this, MindfulTrackerService.class.getName())) {
                startService(new Intent(this, MindfulTrackerService.class).setAction(ACTION_START_SERVICE));
            }
            return;
        }

        Log.d(TAG, "onDestroy: Tracking service destroyed");
    }

    @Override
    public IBinder onBind(Intent intent) {
        return new ServiceBinder<>(MindfulTrackerService.this);
    }

    /**
     * BroadcastReceiver that listens for app launch events and manages app timers.
     */
    private class AppLaunchReceiver extends BroadcastReceiver {
        private final String TAG = "Mindful.AppLaunchReceiver";
        private Timer mAppUsageRecheckTimer;

        @Override
        public void onReceive(Context context, @NonNull Intent intent) {
            String action = intent.getAction();
            if (ACTION_NEW_APP_LAUNCHED.equals(action)) {

                // Get the package name of the launched app
                String packageName = intent.getStringExtra(INTENT_EXTRA_PACKAGE_NAME);
                if (packageName == null || packageName.isEmpty()) return;
                Log.d(TAG, "onReceive: App launch event received with package ** " + packageName + " **");

                // Cancel running task
                cancelTimers();

                if (mDistractingApps.contains(packageName)) {
                    // If bedtime mode is ON
                    showOverlayDialog(packageName);
                } else if (mAppTimers.containsKey(packageName)) {
                    // Else if app has timer
                    onTimerAppLaunched(packageName);
                }
            }
        }

        /**
         * Handles the case where an app with a timer is launched.
         *
         * @param packageName The package name of the launched app.
         */
        private void onTimerAppLaunched(String packageName) {
            if (mPurgedApps.contains(packageName)) {
                showOverlayDialog(packageName);
                return;
            }

            // Fetch usage and check if timer ran out then start overlay dialog service
            long screenTimeSec = ScreenUsageHelper.fetchAppUsageTodayTillNow(mUsageStatsManager, packageName);
            long appTimerSec = mAppTimers.getOrDefault(packageName, 0L);

            if (screenTimeSec > 0 && screenTimeSec >= appTimerSec) {
                mPurgedApps.add(packageName);
                showOverlayDialog(packageName);
                return;
            }

            // Schedule timer for rechecking the app if it is still running
            long delayMs = (appTimerSec - screenTimeSec) * 1000;

            mAppUsageRecheckTimer = new Timer();
            mAppUsageRecheckTimer.schedule(new TimerTask() {
                @Override
                public void run() {
                    mPurgedApps.add(packageName);
                    showOverlayDialog(packageName);
                    Log.d(TAG, "handleTimerAppLaunch: Executed timer task for package : " + packageName);
                }
            }, delayMs);

            Log.d(TAG, "handleTimerAppLaunch: Timer task scheduled for " + packageName + " :  " + new Date(delayMs + System.currentTimeMillis()));
        }

        /**
         * Shows an overlay dialog for the given app package.
         *
         * @param packageName The package name of the app.
         */
        private void showOverlayDialog(String packageName) {
            if (!Utils.isServiceRunning(MindfulTrackerService.this, OverlayDialogService.class.getName())) {
                Intent intent = new Intent(MindfulTrackerService.this, OverlayDialogService.class);
                intent.putExtra(INTENT_EXTRA_PACKAGE_NAME, packageName);
                intent.putExtra(INTENT_EXTRA_IS_THIS_BEDTIME, mDistractingApps.contains(packageName));
                startService(intent);
                Log.d(TAG, "showOverlayDialog: Starting overlay dialog service for package : " + packageName);
            }
        }

        /**
         * Cancels any scheduled timers for app usage rechecking.
         */
        protected void cancelTimers() {
            if (mAppUsageRecheckTimer != null) {
                mAppUsageRecheckTimer.purge();
                mAppUsageRecheckTimer.cancel();
                mAppUsageRecheckTimer = null;
                Log.d(TAG, "cancelTimers: Usage recheck timer cancelled");
            }
        }
    }
}