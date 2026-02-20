package com.example.abodytv

import android.content.Context
import android.net.Uri
import android.view.View
import androidx.media3.common.MediaItem
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.PlayerView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

import android.util.Base64
import java.util.UUID

class NativeVideoPlayerView(context: Context, messenger: BinaryMessenger, id: Int, params: Map<String, Any>?) : PlatformView, MethodChannel.MethodCallHandler {
    private val playerView: PlayerView = PlayerView(context)
    private var exoPlayer: ExoPlayer
    private val methodChannel: MethodChannel = MethodChannel(messenger, "native_video_player_$id")
    private val context = context
    
    private var currentUserAgent: String? = null
    private var currentReferer: String? = null
    
    private fun createHttpDataSourceFactory(userAgent: String?, referer: String?): androidx.media3.datasource.DefaultHttpDataSource.Factory {
        val factory = androidx.media3.datasource.DefaultHttpDataSource.Factory()
            .setUserAgent(userAgent ?: "IPTVSmartersPro")
            .setAllowCrossProtocolRedirects(true)
            .setConnectTimeoutMs(15000)
            .setReadTimeoutMs(15000)
        
        val headers = mutableMapOf(
            "Connection" to "keep-alive",
            "Accept" to "*/*",
            "Accept-Language" to "ar-SA,ar;q=0.9,en-US;q=0.8,en;q=0.7",
            "Icy-MetaData" to "1"
        )
        if (!referer.isNullOrEmpty()) {
            headers["Referer"] = referer
        }
        factory.setDefaultRequestProperties(headers)
        
        return factory
    }
    
    private var httpDataSourceFactory = createHttpDataSourceFactory(null, null)
    private var dataSourceFactory = androidx.media3.datasource.DefaultDataSource.Factory(context, httpDataSourceFactory)

    init {
        // تخصيص LoadControl لزيادة الـ Buffer وضمان استمرار البث
        // ذاكرة مؤقتة رشيقة للبث المباشر لمنع السيرفر من فصل الاتصال
        val loadControl = androidx.media3.exoplayer.DefaultLoadControl.Builder()
            .setBufferDurationsMs(
                15000,  // Min Buffer 15s (أفضل للبث المباشر)
                30000,  // Max Buffer 30s
                1000,   // Start playback after 1s
                1500    // Re-buffer threshold 1.5s
            )
            .setBackBuffer(5000, true) // الاحتفاظ بـ 5 ثواني من البث السابق للرجوع السريع
            .build()

        exoPlayer = ExoPlayer.Builder(context)
            .setLoadControl(loadControl)
            .setWakeMode(androidx.media3.common.C.WAKE_MODE_NETWORK)
            .build()
            
        playerView.player = exoPlayer
        playerView.useController = true
        playerView.keepScreenOn = true
        playerView.resizeMode = androidx.media3.ui.AspectRatioFrameLayout.RESIZE_MODE_FIT
        
        val audioAttributes = androidx.media3.common.AudioAttributes.Builder()
            .setUsage(androidx.media3.common.C.USAGE_MEDIA)
            .setContentType(androidx.media3.common.C.AUDIO_CONTENT_TYPE_MOVIE)
            .build()
        exoPlayer.setAudioAttributes(audioAttributes, true)

        playerView.post {
            val settingsId = context.resources.getIdentifier("exo_settings", "id", context.packageName)
            if (settingsId != 0) {
                playerView.findViewById<View>(settingsId)?.visibility = View.GONE
            }
        }

        methodChannel.setMethodCallHandler(this)
        
        exoPlayer.addListener(object : androidx.media3.common.Player.Listener {
            override fun onTracksChanged(tracks: androidx.media3.common.Tracks) {
                val qualities = mutableSetOf<Int>()
                for (group in tracks.groups) {
                    if (group.type == androidx.media3.common.C.TRACK_TYPE_VIDEO) {
                        for (i in 0 until group.length) {
                            val format = group.getTrackFormat(i)
                            if (format.height > 0) {
                                qualities.add(format.height)
                            }
                        }
                    }
                }
                val sortedQualities = qualities.toList().sortedDescending()
                methodChannel.invokeMethod("onTracksChanged", mapOf("qualities" to sortedQualities))
            }

            override fun onPlaybackStateChanged(state: Int) {
                methodChannel.invokeMethod("onPlaybackState", mapOf("state" to state))
            }

            override fun onPlayerError(error: androidx.media3.common.PlaybackException) {
                println("ExoPlayer Error: ${error.message} (Code: ${error.errorCode})")
                
                // إذا كان الخطأ بسبب انتهاء الوقت أو مشاكل الشبكة، نقوم بالتحضير مجدداً
                if (error.errorCode == androidx.media3.common.PlaybackException.ERROR_CODE_BEHIND_LIVE_WINDOW ||
                    error.errorCode == androidx.media3.common.PlaybackException.ERROR_CODE_IO_NETWORK_CONNECTION_TIMEOUT ||
                    error.errorCode == androidx.media3.common.PlaybackException.ERROR_CODE_IO_READ_POSITION_OUT_OF_RANGE) {
                    println("NativePlayer: Recoverable error, retrying...")
                    exoPlayer.seekToDefaultPosition()
                    exoPlayer.prepare()
                } else {
                    methodChannel.invokeMethod("onError", mapOf("message" to error.message, "code" to error.errorCode))
                }
            }
        })
        
        val url = params?.get("url") as? String
        val drmData = params?.get("drmData") as? Map<String, String>
        val userAgent = params?.get("userAgent") as? String
        val referer = params?.get("referer") as? String
        
        playerView.setControllerVisibilityListener(PlayerView.ControllerVisibilityListener { visibility ->
            val isVisible = visibility == View.VISIBLE
            methodChannel.invokeMethod("onControlsVisibilityChange", mapOf("isVisible" to isVisible))
        })

        if (url != null) {
            play(url, drmData, null, userAgent, referer)
        }
    }

    override fun getView(): View {
        return playerView
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "play" -> {
                val url = call.argument<String>("url")
                val drmData = call.argument<Map<String, String>>("drmData")
                val quality = call.argument<String>("quality")
                val userAgent = call.argument<String>("userAgent")
                val referer = call.argument<String>("referer")
                if (url != null) {
                    play(url, drmData, quality, userAgent, referer)
                    result.success(null)
                } else {
                    result.error("URL_NULL", "URL is null", null)
                }
            }
            "pause" -> { exoPlayer.pause(); result.success(null) }
            "resume" -> { exoPlayer.play(); result.success(null) }
            "setResizeMode" -> {
                val mode = call.argument<Int>("mode") ?: 0
                // 0 = Fit, 3 = Zoom (Fill/Crop), 4 = Fill (Stretch)
                playerView.resizeMode = when(mode) {
                    1 -> androidx.media3.ui.AspectRatioFrameLayout.RESIZE_MODE_FILL
                    2 -> androidx.media3.ui.AspectRatioFrameLayout.RESIZE_MODE_FIXED_WIDTH
                    3 -> androidx.media3.ui.AspectRatioFrameLayout.RESIZE_MODE_ZOOM
                    else -> androidx.media3.ui.AspectRatioFrameLayout.RESIZE_MODE_FIT
                }
                result.success(null)
            }
            "dispose" -> { dispose(); result.success(null) }
            else -> result.notImplemented()
        }
    }

    private var currentUrl: String? = null
    private var currentDrmData: Map<String, String>? = null

    private fun play(url: String, drmData: Map<String, String>? = null, preferredQuality: String? = null, userAgent: String? = null, referer: String? = null) {
        // If it's just a quality change for the SAME URL, check if we need to reload
        if (url == currentUrl && drmData == currentDrmData && userAgent == currentUserAgent && referer == currentReferer) {
            val state = exoPlayer.playbackState
            // If the player is NOT Idle and NOT Ended, we treat it as a quality update/no-op
            if (state != androidx.media3.common.Player.STATE_IDLE && state != androidx.media3.common.Player.STATE_ENDED) {
                println("NativePlayer: Just changing quality to $preferredQuality")
                applyQuality(preferredQuality)
                return
            }
            println("NativePlayer: Same URL but state is IDLE/ENDED ($state), reloading...")
        }

        currentUrl = url
        currentDrmData = drmData
        currentUserAgent = userAgent
        currentReferer = referer
        
        // تحديث مصنع مصدر البيانات بالهيدرات الجديدة
        httpDataSourceFactory = createHttpDataSourceFactory(userAgent, referer)
        dataSourceFactory = androidx.media3.datasource.DefaultDataSource.Factory(context, httpDataSourceFactory)
        
        println("NativePlayer: Playing $url with DRM $drmData, Quality: $preferredQuality, UserAgent: $userAgent, Referer: $referer")
        
        val mediaItemBuilder = MediaItem.Builder()
            .setUri(Uri.parse(url))
            // إجبار المشغل على وضع "البث المباشر" وتحديد زمن تأخير 5 ثواني لضمان الاستقرار
            .setLiveConfiguration(
                MediaItem.LiveConfiguration.Builder()
                    .setTargetOffsetMs(5000)
                    .setMaxPlaybackSpeed(1.02f)
                    .setMinPlaybackSpeed(0.98f)
                    .build()
            )

        val lowerUrl = url.lowercase()
        if (lowerUrl.contains(".m3u8") || lowerUrl.contains("extension=m3u8")) {
            mediaItemBuilder.setMimeType(androidx.media3.common.MimeTypes.APPLICATION_M3U8)
        } else if (lowerUrl.contains(".mpd") || lowerUrl.contains("format=mpd")) {
            mediaItemBuilder.setMimeType(androidx.media3.common.MimeTypes.APPLICATION_MPD)
        } else if (lowerUrl.contains("/live/") || lowerUrl.contains("/stream/")) {
            // Xtream often serves TS streams on these paths
            mediaItemBuilder.setMimeType(androidx.media3.common.MimeTypes.VIDEO_MP2T)
        }

        var drmSessionManager: androidx.media3.exoplayer.drm.DrmSessionManager? = null

        if (drmData != null) {
            val keyData = drmData["key"] ?: ""
            if (keyData.isNotEmpty()) {
                if (keyData.startsWith("http")) {
                    // Use URL license
                    val drmConfig = MediaItem.DrmConfiguration.Builder(androidx.media3.common.C.CLEARKEY_UUID)
                        .setLicenseUri(Uri.parse(keyData))
                        .setMultiSession(true)
                        .setForceDefaultLicenseUri(true)
                        .build()
                    mediaItemBuilder.setDrmConfiguration(drmConfig)
                } else {
                    // Use Static Key via LocalMediaDrmCallback (Fixed Black Screen Issue)
                    try {
                        val kid: String
                        val k: String
                        if (keyData.contains(":")) {
                            val parts = keyData.split(":")
                            kid = parts[0].trim()
                            k = parts[1].trim()
                        } else {
                            kid = ""
                            k = keyData.trim()
                        }

                        val kidB64 = toBase64Url(kid)
                        val keyB64 = toBase64Url(k)
                        val clearKeyJson = """{"keys":[{"kty":"oct","k":"$keyB64","kid":"$kidB64"}],"type":"temporary"}"""
                        
                        drmSessionManager = androidx.media3.exoplayer.drm.DefaultDrmSessionManager.Builder()
                            .setUuidAndExoMediaDrmProvider(androidx.media3.common.C.CLEARKEY_UUID, androidx.media3.exoplayer.drm.FrameworkMediaDrm.DEFAULT_PROVIDER)
                            .setMultiSession(true)
                            .build(androidx.media3.exoplayer.drm.LocalMediaDrmCallback(clearKeyJson.toByteArray()))
                    } catch (e: Exception) {
                        println("DRM Setup Failed: ${e.message}")
                    }
                }
            }
        }

        applyQuality(preferredQuality)

        val mediaSourceFactory = androidx.media3.exoplayer.source.DefaultMediaSourceFactory(dataSourceFactory)
        if (drmSessionManager != null) {
            mediaSourceFactory.setDrmSessionManagerProvider { drmSessionManager }
        }

        val mediaSource = mediaSourceFactory.createMediaSource(mediaItemBuilder.build())
        exoPlayer.setMediaSource(mediaSource)
        exoPlayer.prepare()
        exoPlayer.playWhenReady = true
    }

    private fun applyQuality(preferredQuality: String?) {
        // track selection for quality
        if (preferredQuality != null && preferredQuality != "Auto") {
            try {
                val height = preferredQuality.replace("p", "").toIntOrNull()
                if (height != null) {
                    exoPlayer.trackSelectionParameters = exoPlayer.trackSelectionParameters
                        .buildUpon()
                        .setMaxVideoSize(1920, height)
                        .setMinVideoSize(0, height)
                        .build()
                }
            } catch (e: Exception) {
                println("NativePlayer: Error setting preferred quality: ${e.message}")
            }
        } else {
            // Reset to Auto
            exoPlayer.trackSelectionParameters = exoPlayer.trackSelectionParameters
                .buildUpon()
                .clearVideoSizeConstraints()
                .build()
        }
    }

    private fun toBase64Url(hexOrString: String): String {
        if (hexOrString.isEmpty()) return ""
        val clean = hexOrString.replace(" ", "").replace("-", "")
        val bytes = if (clean.matches(Regex("^[0-9a-fA-F]+$"))) {
            clean.chunked(2).map { it.toInt(16).toByte() }.toByteArray()
        } else {
            clean.toByteArray()
        }
        return Base64.encodeToString(bytes, Base64.URL_SAFE or Base64.NO_WRAP or Base64.NO_PADDING)
    }

    override fun dispose() {
        exoPlayer.release()
        methodChannel.setMethodCallHandler(null)
    }
}
