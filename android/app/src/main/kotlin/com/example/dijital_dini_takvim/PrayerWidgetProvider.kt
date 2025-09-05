package com.example.dijital_dini_takvim

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Prayer Times Widget Provider
 */
class PrayerWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val widgetData = HomeWidgetPlugin.getData(context)
        val views = RemoteViews(context.packageName, R.layout.prayer_widget)

        val title = widgetData.getString("prayer_title", "Bugünün Namaz Vakitleri")
        val imsak = widgetData.getString("prayer_imsak", "--:--")
        val gunes = widgetData.getString("prayer_gunes", "--:--")
        val ogle = widgetData.getString("prayer_ogle", "--:--")
        val ikindi = widgetData.getString("prayer_ikindi", "--:--")
        val aksam = widgetData.getString("prayer_aksam", "--:--")
        val yatsi = widgetData.getString("prayer_yatsi", "--:--")
        val nextPrayerName = widgetData.getString("prayer_next_name", "")
        val nextPrayerTime = widgetData.getString("prayer_next_time", "")
        val location = widgetData.getString("prayer_location", "Konum")

        views.setTextViewText(R.id.prayer_title, title)
        views.setTextViewText(R.id.prayer_imsak, imsak)
        views.setTextViewText(R.id.prayer_gunes, gunes)
        views.setTextViewText(R.id.prayer_ogle, ogle)
        views.setTextViewText(R.id.prayer_ikindi, ikindi)
        views.setTextViewText(R.id.prayer_aksam, aksam)
        views.setTextViewText(R.id.prayer_yatsi, yatsi)
        views.setTextViewText(R.id.prayer_next, "$nextPrayerName - $nextPrayerTime")
        views.setTextViewText(R.id.prayer_location, location)

        // Widget tıklandığında uygulamayı açmak için PendingIntent
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context, 
            0, 
            intent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.prayer_widget_container, pendingIntent)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
