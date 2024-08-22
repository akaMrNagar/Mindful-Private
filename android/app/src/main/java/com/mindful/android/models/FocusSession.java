package com.mindful.android.models;

import android.util.Log;

import androidx.annotation.NonNull;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashSet;

public class FocusSession {

    /**
     * Flag indicating whether to start DND mode.
     */
    public boolean toggleDnd = false;


    /**
     * Total duration for this focus session.
     */
    public long durationSecs = 0L;


    /**
     * Set of app package names identified as distracting apps.
     */
    public HashSet<String> distractingApps = new HashSet<>(0);


    /**
     * Constructs a FocusSession instance from a JSON string.
     *
     * @param jsonMapString JSON representation of FocusSession.
     */
    public FocusSession(@NonNull String jsonMapString) {
        if (jsonMapString.isEmpty()) {
            Log.d("Mindful.FocusSession", "JSON string passed to the constructor is empty");
        } else {
            try {
                JSONObject jsonObject = new JSONObject(jsonMapString);

                // Deserialize fields
                toggleDnd = jsonObject.getBoolean("toggleDnd");
                durationSecs = jsonObject.getLong("durationSeconds");

                // Deserialize distracting apps
                JSONArray appsJsonArray = jsonObject.getJSONArray("distractingApps");
                for (int i = 0; i < appsJsonArray.length(); i++) {
                    distractingApps.add(appsJsonArray.getString(i));
                }

            } catch (JSONException e) {
                Log.e("Mindful.FocusSession", "Error deserializing JSON to FocusSession model", e);
            }
        }

    }

}