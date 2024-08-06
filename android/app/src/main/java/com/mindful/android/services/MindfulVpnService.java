package com.mindful.android.services;

import static com.mindful.android.generics.ServiceBinder.ACTION_START_SERVICE;

import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.IBinder;
import android.os.ParcelFileDescriptor;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.core.app.NotificationCompat;

import com.mindful.android.R;
import com.mindful.android.generics.ServiceBinder;
import com.mindful.android.helpers.NotificationHelper;
import com.mindful.android.helpers.SharedPrefsHelper;
import com.mindful.android.utils.Utils;

import org.jetbrains.annotations.Contract;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.SocketAddress;
import java.net.SocketException;
import java.nio.channels.DatagramChannel;
import java.util.Set;
import java.util.concurrent.atomic.AtomicReference;

/**
 * A VPN service that manages internet access by blocking specified apps.
 */
public class MindfulVpnService extends android.net.VpnService {
    private static final int SERVICE_ID = 302;
    private static final String TAG = "Mindful.VpnService";

    private final AtomicReference<Thread> mAtomicVpnThread = new AtomicReference<>();
    private ParcelFileDescriptor mVpnInterface = null;
    private Set<String> mBlockedApps;
    private boolean mShouldRestartVpn = false;
    private boolean mIsStoppedForcefully = true;

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent == null) return START_NOT_STICKY;
        String action = intent.getAction();

        if (ACTION_START_SERVICE.equals(action)) {
            mBlockedApps = SharedPrefsHelper.fetchBlockedApps(this);
            connectVpn();
            return START_STICKY;
        } else {
            stopAndDisposeService();
            return START_NOT_STICKY;
        }
    }

    /**
     * Restarts the VPN service by disconnecting and then reconnecting the VPN.
     */
    private void restartVpnService() {
        disconnectVpn();
        connectVpn();
        Log.d(TAG, "restartVpnService: VPN restarted successfully");
    }

    /**
     * Establishes a VPN connection based on blocked apps.
     * If there are no blocked apps, the service will stop itself.
     */
    private void connectVpn() {
        // Check if no blocked apps then STOP service
        // Necessary if the service starts from Boot Receiver
        if (mBlockedApps.isEmpty()) {
            Log.w(TAG, "connectVpn: Tried to Connect Vpn without any blocked apps, Exiting");
            stopAndDisposeService();
            return;
        }

        final Thread newThread = new Thread(getVpnRunnable(), TAG);
        setVpnThread(newThread);
        newThread.start();

        startForeground(
                SERVICE_ID,
                new NotificationCompat.Builder(this, NotificationHelper.NOTIFICATION_OTHER_CHANNEL_ID)
                        .setSmallIcon(R.drawable.ic_notification)
                        .setContentTitle("Mindful service")
                        .setContentText("Mindful is now managing internet access to help you stay focused.")
                        .setAutoCancel(true)
                        .build()
        );
    }

    /**
     * Disconnects the VPN connection if established.
     */
    private void disconnectVpn() {
        try {
            if (mVpnInterface != null) {
                mVpnInterface.close();
            }
            setVpnThread(null);
            Log.d(TAG, "disconnectVpn: VPN connection is closed successfully");
        } catch (IOException e) {
            Log.e(TAG, "disconnectVpn: Unable to close VPN connection", e);
        }
    }

    /**
     * Stops the foreground service and disconnects the VPN.
     */
    private void stopAndDisposeService() {
        disconnectVpn();
        mIsStoppedForcefully = false;
        stopForeground(true);
        stopSelf();
    }

    /**
     * Returns a Runnable that configures and establishes the VPN connection.
     *
     * @return A Runnable that sets up the VPN connection.
     */
    @NonNull
    @Contract(" -> new")
    private Runnable getVpnRunnable() {
        return new Runnable() {
            @Override
            public void run() {
                try (DatagramChannel tunnel = DatagramChannel.open()) {

                    if (!MindfulVpnService.this.protect(tunnel.socket())) {
                        throw new IllegalStateException("Cannot protect the vpn socket tunnel");
                    }

                    final SocketAddress serverAddress = new InetSocketAddress("localhost", 0);
                    tunnel.connect(serverAddress);
                    tunnel.configureBlocking(false);

                    Builder builder = MindfulVpnService.this.new Builder();
                    builder.addAddress("192.168.0.0", 24);
                    builder.addRoute("0.0.0.0", 0);

                    // Add blocked app's packages
                    for (String packageName : mBlockedApps) {
                        try {
                            builder.addAllowedApplication(packageName);
                        } catch (PackageManager.NameNotFoundException e) {
                            Log.w(TAG, "getVpnRunnable: Cannot find app with package " + packageName);
                        }
                    }

                    synchronized (MindfulVpnService.this) {
                        mVpnInterface = builder.establish();
                        Log.d(TAG, "getVpnRunnable: VPN connected successfully");
                    }


                } catch (SocketException e) {
                    Log.e(TAG, "run: Cannot use socket for VPN", e);
                    stopAndDisposeService();
                } catch (IOException | IllegalArgumentException e) {
                    Log.e(TAG, "run: VPN connection failed, exiting", e);
                    stopAndDisposeService();
                }
            }
        };
    }

    /**
     * Sets the current VPN thread, interrupting the previous thread if necessary.
     *
     * @param thread The new thread to be set.
     */
    private void setVpnThread(final Thread thread) {
        final Thread oldThread = mAtomicVpnThread.getAndSet(thread);
        if (oldThread != null) {
            oldThread.interrupt();
        }
    }

    /**
     * Updates the list of blocked apps and restarts the VPN service if needed.
     */
    public void updateBlockedApps() {
        mBlockedApps = SharedPrefsHelper.fetchBlockedApps(this);
        if (mBlockedApps.isEmpty()) stopAndDisposeService();
        else mShouldRestartVpn = true;
    }

    /**
     * Restarts the VPN service if it should be restarted.
     */
    public void onApplicationStop() {
        if (mShouldRestartVpn) {
            restartVpnService();
            mShouldRestartVpn = false;
        }
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        disconnectVpn();

        if (mIsStoppedForcefully) {
            Log.d(TAG, "onDestroy: Vpn service destroyed forcefully. Trying to restart it");
            if (!Utils.isServiceRunning(this, MindfulVpnService.class.getName())) {
                startService(new Intent(this, MindfulVpnService.class).setAction(ACTION_START_SERVICE));
            }
            return;
        }
        Log.d(TAG, "onDestroy: VPN service is destroyed");
    }

    @Override
    public IBinder onBind(Intent intent) {
        return new ServiceBinder<>(MindfulVpnService.this);
    }
}