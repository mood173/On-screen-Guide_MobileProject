package com.example.screen_guide_test

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

// Only result text and time are persisted. Image paths and bytes never enter this store.
class HistoryStore(context: Context) {
    private val preferences = context.getSharedPreferences("analysis_history", Context.MODE_PRIVATE)

    @Synchronized
    fun list(): List<Map<String, Any>> {
        val array = JSONArray(preferences.getString("items", "[]"))
        return (0 until array.length()).map { index ->
            val item = array.getJSONObject(index)
            mapOf(
                "id" to item.getString("id"),
                "createdAt" to item.getLong("createdAt"),
                "text" to item.getString("text"),
            )
        }.reversed()
    }

    @Synchronized
    fun save(text: String): String {
        val id = UUID.randomUUID().toString()
        val array = JSONArray(preferences.getString("items", "[]"))
        array.put(JSONObject().put("id", id).put("createdAt", System.currentTimeMillis()).put("text", text))
        check(preferences.edit().putString("items", array.toString()).commit())
        return id
    }

    @Synchronized
    fun delete(id: String): Boolean {
        val current = JSONArray(preferences.getString("items", "[]"))
        val remaining = JSONArray()
        for (index in 0 until current.length()) {
            val item = current.getJSONObject(index)
            if (item.getString("id") != id) remaining.put(item)
        }
        if (remaining.length() == current.length()) return false
        check(preferences.edit().putString("items", remaining.toString()).commit())
        return true
    }
}
