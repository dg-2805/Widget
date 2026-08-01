package com.example.our_space

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.RadialGradient
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.Typeface
import android.os.Build
import android.os.BatteryManager
import android.text.TextPaint
import android.util.TypedValue
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import java.util.Calendar
import kotlin.math.max
import kotlin.math.min

class OurSpaceWidgetProvider : AppWidgetProvider() {
    override fun onEnabled(context: Context) = scheduleNextRefresh(context)

    override fun onDisabled(context: Context) {
        alarmManager(context).cancel(refreshIntent(context))
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_REFRESH,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_BOOT_COMPLETED -> {
                updateAllWidgets(context)
                scheduleNextRefresh(context)
            }
        }
    }

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { updateWidget(context, manager, it) }
        scheduleNextRefresh(context)
    }

    private fun updateAllWidgets(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        manager.getAppWidgetIds(ComponentName(context, OurSpaceWidgetProvider::class.java))
            .forEach { updateWidget(context, manager, it) }
    }

    private fun updateWidget(context: Context, manager: AppWidgetManager, widgetId: Int) {
        val snapshot = readSnapshot(context)
        val options = manager.getAppWidgetOptions(widgetId)
        val width = dpToPx(
            context,
            options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH)
                .takeIf { it > 0 } ?: options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 180),
        )
        val height = dpToPx(
            context,
            options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT)
                .takeIf { it > 0 } ?: options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 110),
        )
        val artwork = drawWidget(context, max(width, 1), max(height, 1), snapshot)
        RemoteViews(context.packageName, R.layout.our_space_widget).also { views ->
            views.setImageViewBitmap(R.id.widget_artwork, artwork)
            views.setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
            manager.updateAppWidget(widgetId, views)
        }
    }

    private fun readSnapshot(context: Context): WidgetSnapshot {
        val prefs = HomeWidgetPlugin.getData(context)
        val now = Calendar.getInstance()
        val battery = batterySnapshot(context)
        val phase = TwilightPhase.fromHour(now.get(Calendar.HOUR_OF_DAY))
        val count = prefs.getInt("twilights_together", countTwilightsTogether(now))
        val comfort = prefs.getString("comfort_message", defaultComfortMessage(phase)).orEmpty()
        val pandaLabel = prefs.getString("panda_label", defaultPandaLabel(phase, battery.isCharging)).orEmpty()
        val batteryLevel = prefs.getInt("battery_level", battery.level)
        val isCharging = prefs.getBoolean("is_charging", battery.isCharging)
        return WidgetSnapshot(
            phase = phase,
            count = count,
            comfortMessage = comfort.ifBlank { defaultComfortMessage(phase) },
            pandaLabel = pandaLabel.ifBlank { defaultPandaLabel(phase, isCharging) },
            batteryLevel = batteryLevel,
            isCharging = isCharging,
            surpriseIndex = count % 3,
        )
    }

    private fun drawWidget(
        context: Context,
        width: Int,
        height: Int,
        snapshot: WidgetSnapshot,
    ): Bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888).also { bitmap ->
        val canvas = Canvas(bitmap)
        drawBackground(canvas, width, height, snapshot.phase)
        drawAtmosphere(canvas, width, height, snapshot.phase)
        drawCalendar(canvas, width, height, snapshot)
        drawPandaPanel(canvas, width, height, snapshot)
        drawSurprise(canvas, width, height, snapshot)
        drawComfort(canvas, width, height, snapshot)
    }

    private fun drawBackground(canvas: Canvas, width: Int, height: Int, phase: TwilightPhase) {
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = LinearGradient(
                0f,
                0f,
                0f,
                height.toFloat(),
                intArrayOf(phase.topColor, phase.bottomColor),
                null,
                Shader.TileMode.CLAMP,
            )
        }
        canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), paint)
        val vignette = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = RadialGradient(
                width / 2f,
                height / 2f,
                max(width, height) * 0.82f,
                intArrayOf(Color.TRANSPARENT, Color.argb(95, 19, 13, 28)),
                floatArrayOf(0.42f, 1f),
                Shader.TileMode.CLAMP,
            )
        }
        canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), vignette)
    }

    private fun drawAtmosphere(canvas: Canvas, width: Int, height: Int, phase: TwilightPhase) {
        val glowPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = RadialGradient(
                width * 0.76f,
                height * 0.16f,
                max(width, height) * 0.22f,
                intArrayOf(phase.glowColor, Color.TRANSPARENT),
                floatArrayOf(0.0f, 1f),
                Shader.TileMode.CLAMP,
            )
        }
        canvas.drawCircle(width * 0.76f, height * 0.16f, max(width, height) * 0.19f, glowPaint)

        val orbPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = phase.orbColor }
        canvas.drawCircle(width * 0.78f, height * 0.18f, min(width, height) * 0.09f, orbPaint)

        if (phase == TwilightPhase.NIGHT) {
            val star = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.argb(200, 235, 241, 255)
                strokeWidth = max(1f, width * 0.008f)
            }
            listOf(
                width * 0.10f to height * 0.16f,
                width * 0.86f to height * 0.22f,
                width * 0.18f to height * 0.34f,
            ).forEach { (x, y) ->
                canvas.drawLine(x - 8, y, x + 8, y, star)
                canvas.drawLine(x, y - 8, x, y + 8, star)
            }
        }
    }

    private fun drawCalendar(canvas: Canvas, width: Int, height: Int, snapshot: WidgetSnapshot) {
        val digits = max(snapshot.count, 0).toString()
        val gap = width * 0.010f
        val tile = min(height * 0.23f, (width * 0.50f - gap * (digits.length - 1)) / digits.length)
        val rowWidth = digits.length * tile + (digits.length - 1) * gap
        val left = (width - rowWidth) / 2f
        val top = height * 0.08f
        val card = RectF(width * 0.08f, top, width * 0.92f, top + tile * 1.04f)
        val cardPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = LinearGradient(
                card.left,
                card.top,
                card.left,
                card.bottom,
                intArrayOf(snapshot.phase.cardTop, snapshot.phase.cardBottom),
                null,
                Shader.TileMode.CLAMP,
            )
        }
        val shadow = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.argb(88, 26, 12, 23) }
        canvas.drawRoundRect(RectF(card).apply { offset(0f, tile * 0.04f) }, tile * 0.14f, tile * 0.14f, shadow)
        canvas.drawRoundRect(card, tile * 0.14f, tile * 0.14f, cardPaint)

        val glow = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = RadialGradient(
                card.centerX(),
                card.centerY(),
                card.width() * 0.60f,
                intArrayOf(Color.argb(140, 255, 255, 255), Color.TRANSPARENT),
                floatArrayOf(0.05f, 1f),
                Shader.TileMode.CLAMP,
            )
        }
        canvas.drawRoundRect(card, tile * 0.14f, tile * 0.14f, glow)

        val accent = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = snapshot.phase.accentColor
            strokeWidth = max(1f, tile * 0.026f)
        }
        canvas.drawLine(card.left + tile * 0.18f, card.top + tile * 0.13f, card.right - tile * 0.18f, card.top + tile * 0.13f, accent)

        val numeral = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = snapshot.phase.numeralColor
            typeface = Typeface.create("sans-serif", Typeface.BOLD)
            textAlign = Paint.Align.CENTER
            textSize = tile * 0.54f
        }
        digits.forEachIndexed { index, digit ->
            val x = left + index * (tile + gap)
            val rect = RectF(x, top, x + tile, top + tile)
            val radius = tile * 0.16f
            val tilePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = snapshot.phase.tileColor }
            val topRim = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = snapshot.phase.rimColor
                strokeWidth = max(1f, tile * 0.03f)
            }
            canvas.drawRoundRect(rect, radius, radius, tilePaint)
            canvas.drawLine(x + tile * 0.14f, top + tile * 0.08f, x + tile * 0.86f, top + tile * 0.08f, topRim)
            canvas.drawLine(x + tile * 0.14f, top + tile * 0.93f, x + tile * 0.86f, top + tile * 0.93f, topRim)
            val baseline = top + tile * 0.71f - (numeral.descent() + numeral.ascent()) / 2f
            canvas.drawText(digit.toString(), x + tile / 2f, baseline, numeral)
        }

        val caption = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = snapshot.phase.captionColor
            textAlign = Paint.Align.CENTER
            textSize = min(width * 0.06f, height * 0.11f)
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
            letterSpacing = 0.04f
        }
        canvas.drawText("Twilights Together", width / 2f, card.bottom + caption.textSize * 0.85f, caption)
    }

    private fun drawPandaPanel(canvas: Canvas, width: Int, height: Int, snapshot: WidgetSnapshot) {
        val card = RectF(width * 0.08f, height * 0.52f, width * 0.56f, height * 0.90f)
        val shadow = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.argb(80, 17, 9, 16) }
        canvas.drawRoundRect(RectF(card).apply { offset(0f, height * 0.03f) }, 28f, 28f, shadow)
        val panelPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = LinearGradient(
                card.left,
                card.top,
                card.left,
                card.bottom,
                intArrayOf(snapshot.phase.panelTop, snapshot.phase.panelBottom),
                null,
                Shader.TileMode.CLAMP,
            )
        }
        canvas.drawRoundRect(card, 28f, 28f, panelPaint)

        val pandaCenterX = card.centerX() - 6f
        val pandaCenterY = card.centerY() + 4f
        val body = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.WHITE }
        val outline = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.argb(42, 32, 23, 35) }
        canvas.drawCircle(pandaCenterX, pandaCenterY, card.width() * 0.17f, outline)
        canvas.drawCircle(pandaCenterX, pandaCenterY, card.width() * 0.165f, body)
        canvas.drawCircle(pandaCenterX - 20, pandaCenterY - 20, card.width() * 0.055f, Color.BLACK.paint())
        canvas.drawCircle(pandaCenterX + 20, pandaCenterY - 20, card.width() * 0.055f, Color.BLACK.paint())
        canvas.drawOval(
            RectF(pandaCenterX - 36, pandaCenterY - 32, pandaCenterX - 18, pandaCenterY - 4),
            Color.BLACK.paint(),
        )
        canvas.drawOval(
            RectF(pandaCenterX + 18, pandaCenterY - 32, pandaCenterX + 36, pandaCenterY - 4),
            Color.BLACK.paint(),
        )
        canvas.drawCircle(pandaCenterX - 8, pandaCenterY - 6, 4f, Color.BLACK.paint())
        canvas.drawCircle(pandaCenterX + 8, pandaCenterY - 6, 4f, Color.BLACK.paint())
        canvas.drawCircle(pandaCenterX, pandaCenterY + 6, 3.2f, Color.BLACK.paint())

        val label = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = snapshot.phase.captionColor
            textAlign = Paint.Align.CENTER
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
            textSize = max(14f, width * 0.042f)
        }
        canvas.drawText(snapshot.pandaLabel, card.centerX(), card.bottom - height * 0.07f, label)

        // Pinterest Asset Needed
        // Purpose: Panda companion illustration for the widget
        // Suggested Search: "soft watercolor panda companion"
        // Asset Path: assets/images/panda/widget_panda.png
        // Aspect Ratio: 1:1
    }

    private fun drawSurprise(canvas: Canvas, width: Int, height: Int, snapshot: WidgetSnapshot) {
        when (snapshot.surpriseIndex) {
            0 -> drawShootingStar(canvas, width, height, snapshot.phase)
            1 -> drawWave(canvas, width, height, snapshot.phase)
            else -> drawBloom(canvas, width, height, snapshot.phase)
        }
    }

    private fun drawShootingStar(canvas: Canvas, width: Int, height: Int, phase: TwilightPhase) {
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = phase.glowColor
            strokeWidth = max(2f, width * 0.008f)
        }
        canvas.drawLine(width * 0.72f, height * 0.38f, width * 0.88f, height * 0.28f, paint)
        canvas.drawCircle(width * 0.72f, height * 0.38f, max(3f, width * 0.012f), paint)
    }

    private fun drawWave(canvas: Canvas, width: Int, height: Int, phase: TwilightPhase) {
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = phase.accentColor
            style = Paint.Style.STROKE
            strokeWidth = max(2f, width * 0.009f)
        }
        val path = android.graphics.Path().apply {
            moveTo(width * 0.64f, height * 0.41f)
            cubicTo(width * 0.68f, height * 0.36f, width * 0.73f, height * 0.47f, width * 0.78f, height * 0.41f)
            cubicTo(width * 0.82f, height * 0.36f, width * 0.86f, height * 0.47f, width * 0.90f, height * 0.41f)
        }
        canvas.drawPath(path, paint)
    }

    private fun drawBloom(canvas: Canvas, width: Int, height: Int, phase: TwilightPhase) {
        val petal = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = phase.accentColor }
        val center = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = phase.glowColor }
        val x = width * 0.80f
        val y = height * 0.39f
        val r = min(width, height) * 0.028f
        repeat(5) { index ->
            val angle = Math.toRadians(index * 72.0 - 90.0)
            canvas.drawCircle(x + kotlin.math.cos(angle).toFloat() * r, y + kotlin.math.sin(angle).toFloat() * r, r * 0.74f, petal)
        }
        canvas.drawCircle(x, y, r * 0.44f, center)
    }

    private fun drawComfort(canvas: Canvas, width: Int, height: Int, snapshot: WidgetSnapshot) {
        val card = RectF(width * 0.60f, height * 0.60f, width * 0.92f, height * 0.89f)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.argb(96, 22, 12, 27) }
        canvas.drawRoundRect(card, 22f, 22f, paint)
        val message = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
            textSize = max(12f, width * 0.032f)
            textAlign = Paint.Align.CENTER
        }
        canvas.drawText(snapshot.comfortMessage, card.centerX(), card.centerY(), message)
    }

    private fun scheduleNextRefresh(context: Context) {
        val now = Calendar.getInstance()
        val next = nextBoundaryAfter(now)
        val alarm = alarmManager(context)
        val intent = refreshIntent(context)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && alarm.canScheduleExactAlarms()) {
            alarm.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next.timeInMillis, intent)
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next.timeInMillis, intent)
        } else {
            alarm.set(AlarmManager.RTC_WAKEUP, next.timeInMillis, intent)
        }
    }

    private fun nextBoundaryAfter(now: Calendar): Calendar {
        val candidates = listOf(6, 11, 17, 20).mapNotNull { hour ->
            (now.clone() as Calendar).apply {
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
                set(Calendar.HOUR_OF_DAY, hour)
                set(Calendar.MINUTE, 0)
            }.takeIf { it.after(now) }
        }.toMutableList()

        candidates += (now.clone() as Calendar).apply {
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            add(Calendar.DAY_OF_YEAR, 1)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
        }

        candidates.sortBy { it.timeInMillis }
        return candidates.first()
    }

    private fun refreshIntent(context: Context): PendingIntent = PendingIntent.getBroadcast(
        context,
        1042,
        Intent(context, OurSpaceWidgetProvider::class.java).setAction(ACTION_REFRESH),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    private fun alarmManager(context: Context) = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    private fun dpToPx(context: Context, dp: Int) =
        TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, dp.toFloat(), context.resources.displayMetrics).toInt()

    private fun countTwilightsTogether(now: Calendar): Int {
        val start = Calendar.getInstance().apply {
            set(2026, Calendar.JANUARY, 23, 0, 0, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val today = Calendar.getInstance().apply {
            set(now.get(Calendar.YEAR), now.get(Calendar.MONTH), now.get(Calendar.DAY_OF_MONTH), 0, 0, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val diff = (today.timeInMillis - start.timeInMillis) / (24L * 60L * 60L * 1000L)
        return max(1, diff.toInt() + 1)
    }

    private fun batterySnapshot(context: Context): BatterySnapshot {
        val intent = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val level = intent?.let {
            val rawLevel = it.getIntExtra(BatteryManager.EXTRA_LEVEL, 100)
            val scale = it.getIntExtra(BatteryManager.EXTRA_SCALE, 100)
            ((rawLevel.toFloat() / scale.toFloat()) * 100f).toInt()
        } ?: 100
        val status = intent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING || status == BatteryManager.BATTERY_STATUS_FULL
        return BatterySnapshot(level = level, isCharging = isCharging)
    }

    private fun defaultPandaLabel(phase: TwilightPhase, isCharging: Boolean): String = when {
        isCharging -> "Holding a glowing star"
        phase == TwilightPhase.MORNING -> "Stretching"
        phase == TwilightPhase.DAY -> "Reading"
        phase == TwilightPhase.TWILIGHT -> "Watching the sunset"
        else -> "Sleeping"
    }

    private fun defaultComfortMessage(phase: TwilightPhase): String = when (phase) {
        TwilightPhase.MORNING -> "I'm here."
        TwilightPhase.DAY -> "We'll get through today."
        TwilightPhase.TWILIGHT -> "You don't have to carry everything alone."
        TwilightPhase.NIGHT -> "Another twilight together."
    }

    private enum class TwilightPhase(
        val topColor: Int,
        val bottomColor: Int,
        val orbColor: Int,
        val glowColor: Int,
        val accentColor: Int,
        val numeralColor: Int,
        val tileColor: Int,
        val rimColor: Int,
        val cardTop: Int,
        val cardBottom: Int,
        val panelTop: Int,
        val panelBottom: Int,
        val captionColor: Int,
    ) {
        MORNING(0xFFFFE8C8.toInt(), 0xFFF9CBA7.toInt(), 0xFFFFC46A.toInt(), 0xFFFFD98F.toInt(), 0xFFF3A264.toInt(), 0xFF33251E.toInt(), 0xFFFFF5E9.toInt(), 0xFFFFD0A4.toInt(), 0xFFFFF7E9.toInt(), 0xFFF7E0C1.toInt(), 0xFFFFF3EA.toInt(), 0xFFF6D4B5.toInt(), 0xFF3B2B21.toInt()),
        DAY(0xFFF6F0E3.toInt(), 0xFFEADFD0.toInt(), 0xFFFFE2A7.toInt(), 0xFFFFEEC2.toInt(), 0xFFCB8A5F.toInt(), 0xFF2A201D.toInt(), 0xFFFFFBF3.toInt(), 0xFFFFE2C0.toInt(), 0xFFFFF8EF.toInt(), 0xFFF4E2C9.toInt(), 0xFFFFF8F0.toInt(), 0xFFF2E0C7.toInt(), 0xFF3A2B21.toInt()),
        TWILIGHT(0xFFFFB38A.toInt(), 0xFF7A4F7A.toInt(), 0xFFFFC490.toInt(), 0xFFFFD39D.toInt(), 0xFFF2A17C.toInt(), 0xFF2E1E28.toInt(), 0xFFFFF1E8.toInt(), 0xFFFFD2B2.toInt(), 0xFFFFEFE4.toInt(), 0xFFF4D0BE.toInt(), 0xFFFFF0E8.toInt(), 0xFFF0C7B1.toInt(), 0xFF432936.toInt()),
        NIGHT(0xFF201B3A.toInt(), 0xFF0F1023.toInt(), 0xFF9BC9FF.toInt(), 0xFF93C2FF.toInt(), 0xFFA8D3FF.toInt(), 0xFFF6F1FB.toInt(), 0xFF2F2944.toInt(), 0xFF516592.toInt(), 0xFF2F2947.toInt(), 0xFF211E36.toInt(), 0xFF2A2540.toInt(), 0xFF1F1B31.toInt(), 0xFFF3F0FF.toInt());

        companion object {
            fun fromHour(hour: Int): TwilightPhase = when (hour) {
                in 6..10 -> MORNING
                in 11..16 -> DAY
                in 17..19 -> TWILIGHT
                else -> NIGHT
            }
        }
    }

    // Pinterest Asset Needed
    // Purpose: Morning background
    // Suggested Search: "soft watercolor sunrise panda"
    // Asset Path: assets/images/backgrounds/morning.png
    // Aspect Ratio: 9:16

    // Pinterest Asset Needed
    // Purpose: Day background
    // Suggested Search: "soft watercolor daytime panda"
    // Asset Path: assets/images/backgrounds/day.png
    // Aspect Ratio: 9:16

    // Pinterest Asset Needed
    // Purpose: Twilight background
    // Suggested Search: "soft watercolor sunset panda"
    // Asset Path: assets/images/backgrounds/twilight.png
    // Aspect Ratio: 9:16

    // Pinterest Asset Needed
    // Purpose: Night background
    // Suggested Search: "soft watercolor night panda"
    // Asset Path: assets/images/backgrounds/night.png
    // Aspect Ratio: 9:16

    private data class WidgetSnapshot(
        val phase: TwilightPhase,
        val count: Int,
        val comfortMessage: String,
        val pandaLabel: String,
        val batteryLevel: Int,
        val isCharging: Boolean,
        val surpriseIndex: Int,
    )

    private data class BatterySnapshot(
        val level: Int,
        val isCharging: Boolean,
    )

    private fun Int.paint(): Paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = this@paint }

    private companion object {
        const val ACTION_REFRESH = "com.example.our_space.ACTION_WIDGET_REFRESH"
    }
}
