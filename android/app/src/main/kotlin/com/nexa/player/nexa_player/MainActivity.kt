package com.nexa.player.nexa_player

import android.Manifest
import android.app.Activity
import android.content.ContentUris
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.AudioFormat
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import android.media.audiofx.Visualizer
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.util.Size
import androidx.annotation.NonNull
import androidx.core.content.ContextCompat
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

class MainActivity : AudioServiceActivity() {
    private val channelName = "com.nexa.player/media_store"
    private val fftEventChannelName = "com.nexa.player/fft_stream"
    private val fftControlChannelName = "com.nexa.player/fft_control"
    private val ioExecutor: ExecutorService = Executors.newFixedThreadPool(4)
    private val fftExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var pendingImagePickResult: MethodChannel.Result? = null

    private var fftEventSink: EventChannel.EventSink? = null
    private var audioVisualizer: Visualizer? = null
    private var activeSessionId: Int = 0
    private var activeFpsCap: Int = 60
    private var captureRequested: Boolean = false
    private var capturePausedInBackground: Boolean = false

    companion object {
        private const val REQUEST_CODE_PICK_COVER = 41029
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSdkInt" -> result.success(Build.VERSION.SDK_INT)
                    "queryMediaStoreAudio" -> {
                        ioExecutor.execute {
                            try {
                                val tracks = queryMediaStore()
                                mainHandler.post { result.success(tracks) }
                            } catch (e: Exception) {
                                mainHandler.post {
                                    result.error("MEDIASTORE_ERROR", e.message, null)
                                }
                            }
                        }
                    }
                    "extractEmbeddedArtwork" -> {
                        val filePath = call.argument<String>("filePath")
                        val outputPath = call.argument<String>("outputPath")
                        val albumId = call.argument<Number>("albumId")?.toLong()
                        val maxSize = call.argument<Int>("maxSize") ?: 512
                        val preferEmbedded = call.argument<Boolean>("preferEmbedded") ?: true
                        if (outputPath.isNullOrBlank()) {
                            result.success(null)
                            return@setMethodCallHandler
                        }
                        ioExecutor.execute {
                            val resolved = extractAndCacheArtwork(
                                filePath = filePath,
                                outputPath = outputPath,
                                albumId = albumId,
                                maxSize = maxSize,
                                preferEmbedded = preferEmbedded
                            )
                            mainHandler.post { result.success(resolved) }
                        }
                    }
                    "extractAudioTelemetry" -> {
                        val filePath = call.argument<String>("filePath")
                        val fileSize = call.argument<Number>("fileSize")?.toLong() ?: 0L
                        val durationMs = call.argument<Number>("durationMs")?.toLong() ?: 0L
                        if (filePath.isNullOrBlank()) {
                            result.success(null)
                            return@setMethodCallHandler
                        }
                        ioExecutor.execute {
                            val telemetry = extractAudioTelemetry(filePath, fileSize, durationMs)
                            mainHandler.post { result.success(telemetry) }
                        }
                    }
                    "pickCoverImageBytes" -> {
                        if (pendingImagePickResult != null) {
                            result.error("PICKER_ACTIVE", "Image picker already open", null)
                            return@setMethodCallHandler
                        }
                        pendingImagePickResult = result
                        val pickIntent = Intent(Intent.ACTION_GET_CONTENT).apply {
                            type = "image/*"
                            addCategory(Intent.CATEGORY_OPENABLE)
                        }
                        try {
                            startActivityForResult(
                                Intent.createChooser(pickIntent, "Select Cover Art"),
                                REQUEST_CODE_PICK_COVER
                            )
                        } catch (e: Exception) {
                            pendingImagePickResult = null
                            result.error("PICKER_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, fftEventChannelName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    fftEventSink = events
                    val args = arguments as? Map<*, *>
                    val sessionId = (args?.get("audioSessionId") as? Number)?.toInt() ?: activeSessionId
                    val fpsCap = (args?.get("fpsCap") as? Number)?.toInt() ?: activeFpsCap
                    captureRequested = true
                    capturePausedInBackground = false
                    if (sessionId > 0) {
                        rebindVisualizer(sessionId, fpsCap, enabled = true)
                    }
                }

                override fun onCancel(arguments: Any?) {
                    captureRequested = false
                    capturePausedInBackground = false
                    fftEventSink = null
                    releaseVisualizerAsync()
                }
            })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, fftControlChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasRecordAudioPermission" -> {
                        val granted = ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.RECORD_AUDIO
                        ) == PackageManager.PERMISSION_GRANTED
                        result.success(granted)
                    }
                    "updateSession" -> {
                        val sessionId = call.argument<Number>("audioSessionId")?.toInt() ?: 0
                        val fpsCap = call.argument<Number>("fpsCap")?.toInt() ?: activeFpsCap
                        val enabled = call.argument<Boolean>("enabled") ?: true
                        captureRequested = enabled
                        if (sessionId > 0) {
                            rebindVisualizer(sessionId, fpsCap, enabled = enabled)
                        } else {
                            setVisualizerEnabledAsync(false)
                        }
                        result.success(true)
                    }
                    "setEnabled" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        captureRequested = enabled
                        setVisualizerEnabledAsync(enabled)
                        result.success(true)
                    }
                    "stopCapture" -> {
                        captureRequested = false
                        capturePausedInBackground = false
                        releaseVisualizerAsync()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onStart() {
        super.onStart()
        if (capturePausedInBackground && captureRequested && activeSessionId > 0 && fftEventSink != null) {
            capturePausedInBackground = false
            setVisualizerEnabledAsync(true)
        }
    }

    override fun onStop() {
        if (captureRequested) {
            capturePausedInBackground = true
            setVisualizerEnabledAsync(false)
        }
        super.onStop()
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == REQUEST_CODE_PICK_COVER) {
            val callback = pendingImagePickResult
            pendingImagePickResult = null
            if (callback == null) {
                super.onActivityResult(requestCode, resultCode, data)
                return
            }
            val uri = data?.data
            if (resultCode != Activity.RESULT_OK || uri == null) {
                callback.success(null)
                return
            }
            ioExecutor.execute {
                try {
                    val rawBytes = contentResolver.openInputStream(uri)?.use { stream ->
                        stream.readBytes()
                    }
                    if (rawBytes == null || rawBytes.isEmpty()) {
                        mainHandler.post { callback.success(null) }
                        return@execute
                    }
                    val bitmap = decodeSampledBitmapFromBytes(rawBytes, 1024)
                    if (bitmap == null) {
                        mainHandler.post { callback.success(rawBytes) }
                        return@execute
                    }
                    val out = ByteArrayOutputStream()
                    bitmap.compress(Bitmap.CompressFormat.JPEG, 90, out)
                    bitmap.recycle()
                    val encoded = out.toByteArray()
                    mainHandler.post { callback.success(encoded) }
                } catch (_: Exception) {
                    mainHandler.post { callback.success(null) }
                }
            }
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onDestroy() {
        captureRequested = false
        releaseVisualizerSync()
        fftExecutor.shutdownNow()
        ioExecutor.shutdownNow()
        super.onDestroy()
    }

    private fun rebindVisualizer(sessionId: Int, fpsCap: Int, enabled: Boolean) {
        activeSessionId = sessionId
        activeFpsCap = fpsCap.coerceIn(15, 120)
        fftExecutor.execute {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO)
                != PackageManager.PERMISSION_GRANTED
            ) {
                mainHandler.post {
                    fftEventSink?.error(
                        "PERMISSION_DENIED",
                        "RECORD_AUDIO permission required for live FFT capture",
                        null
                    )
                }
                return@execute
            }
            try {
                releaseVisualizerSync()
                val range = Visualizer.getCaptureSizeRange()
                val desiredSize = 1024.coerceIn(range[0], range[1])
                val maxRate = max(1000, Visualizer.getMaxCaptureRate())
                val desiredRate = min(maxRate, max(1000, activeFpsCap * 1000))

                val vis = Visualizer(sessionId).apply {
                    captureSize = desiredSize
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN) {
                        scalingMode = Visualizer.SCALING_MODE_NORMALIZED
                    }
                    setDataCaptureListener(
                        object : Visualizer.OnDataCaptureListener {
                            override fun onWaveFormDataCapture(
                                visualizer: Visualizer?,
                                waveform: ByteArray?,
                                samplingRate: Int
                            ) {}

                            override fun onFftDataCapture(
                                visualizer: Visualizer?,
                                fft: ByteArray?,
                                samplingRate: Int
                            ) {
                                if (fft == null || fft.isEmpty()) return
                                val copy = fft.copyOf()
                                val payload = mapOf<String, Any>(
                                    "bytes" to copy,
                                    "samplingRate" to (samplingRate / 1000).coerceAtLeast(8000),
                                    "captureSize" to desiredSize
                                )
                                mainHandler.post {
                                    fftEventSink?.success(payload)
                                }
                            }
                        },
                        desiredRate,
                        false,
                        true
                    )
                    this.enabled = enabled
                }
                audioVisualizer = vis
            } catch (_: Exception) {
                releaseVisualizerSync()
            }
        }
    }

    private fun setVisualizerEnabledAsync(enabled: Boolean) {
        fftExecutor.execute {
            try {
                audioVisualizer?.enabled = enabled
            } catch (_: Exception) {}
        }
    }

    private fun releaseVisualizerAsync() {
        fftExecutor.execute {
            releaseVisualizerSync()
        }
    }

    private fun releaseVisualizerSync() {
        try {
            audioVisualizer?.enabled = false
        } catch (_: Exception) {}
        try {
            audioVisualizer?.release()
        } catch (_: Exception) {}
        audioVisualizer = null
    }

    private fun queryMediaStore(): List<Map<String, Any?>> {
        val trackList = mutableListOf<Map<String, Any?>>()
        val projectionList = mutableListOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.ALBUM_ID,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.TRACK,
            MediaStore.Audio.Media.YEAR,
            MediaStore.Audio.Media.SIZE,
            MediaStore.Audio.Media.DATE_ADDED,
            MediaStore.Audio.Media.MIME_TYPE
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            projectionList.add(MediaStore.Audio.Media.BITRATE)
        }
        val projection = projectionList.toTypedArray()

        val selection =
            "${MediaStore.Audio.Media.IS_MUSIC} != 0 OR ${MediaStore.Audio.Media.DURATION} > 15000"
        val sortOrder = "${MediaStore.Audio.Media.TITLE} ASC"

        val uri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        val cursor = contentResolver.query(uri, projection, selection, null, sortOrder)

        cursor?.use {
            val idCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val titleCol = it.getColumnIndex(MediaStore.Audio.Media.TITLE)
            val artistCol = it.getColumnIndex(MediaStore.Audio.Media.ARTIST)
            val albumCol = it.getColumnIndex(MediaStore.Audio.Media.ALBUM)
            val albumIdCol = it.getColumnIndex(MediaStore.Audio.Media.ALBUM_ID)
            val durationCol = it.getColumnIndex(MediaStore.Audio.Media.DURATION)
            val dataCol = it.getColumnIndex(MediaStore.Audio.Media.DATA)
            val trackCol = it.getColumnIndex(MediaStore.Audio.Media.TRACK)
            val yearCol = it.getColumnIndex(MediaStore.Audio.Media.YEAR)
            val sizeCol = it.getColumnIndex(MediaStore.Audio.Media.SIZE)
            val dateAddedCol = it.getColumnIndex(MediaStore.Audio.Media.DATE_ADDED)
            val mimeCol = it.getColumnIndex(MediaStore.Audio.Media.MIME_TYPE)
            val bitrateCol = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                it.getColumnIndex(MediaStore.Audio.Media.BITRATE)
            } else {
                -1
            }

            while (it.moveToNext()) {
                val filePath = if (dataCol >= 0) it.getString(dataCol) else null
                if (filePath != null && !File(filePath).exists()) {
                    continue
                }

                val id = it.getLong(idCol)
                val rawTitle = if (titleCol >= 0) it.getString(titleCol) else null
                val rawArtist = if (artistCol >= 0) it.getString(artistCol) else null
                val rawAlbum = if (albumCol >= 0) it.getString(albumCol) else null
                val albumId = if (albumIdCol >= 0) it.getLong(albumIdCol) else null
                val duration = if (durationCol >= 0) it.getLong(durationCol) else 0L
                val trackNumber = if (trackCol >= 0) it.getInt(trackCol) else 0
                val year = if (yearCol >= 0) it.getInt(yearCol) else 0
                val size = if (sizeCol >= 0) it.getLong(sizeCol) else 0L
                val dateAddedSec = if (dateAddedCol >= 0) it.getLong(dateAddedCol) else 0L
                val dateAddedMs = if (dateAddedSec > 0L) dateAddedSec * 1000L else System.currentTimeMillis()
                val mime = if (mimeCol >= 0) it.getString(mimeCol) else null
                val rawBitrate = if (bitrateCol >= 0) it.getInt(bitrateCol) else 0

                val kbps = normalizeKbps(rawBitrate, size, duration)
                val codec = normalizeCodec(mime, filePath)

                val title = if (!rawTitle.isNullOrBlank()) {
                    rawTitle
                } else {
                    filePath?.substringAfterLast('/')?.substringBeforeLast('.') ?: "Track $id"
                }
                val artist = if (!rawArtist.isNullOrBlank() && rawArtist != "<unknown>") {
                    rawArtist
                } else {
                    "Unknown Artist"
                }
                val album = if (!rawAlbum.isNullOrBlank() && rawAlbum != "<unknown>") {
                    rawAlbum
                } else {
                    "Unknown Album"
                }

                val item = mapOf<String, Any?>(
                    "id" to id.toString(),
                    "title" to title,
                    "artist" to artist,
                    "album" to album,
                    "album_id" to albumId,
                    "duration_ms" to duration,
                    "file_path" to (filePath ?: ""),
                    "track_number" to trackNumber,
                    "year" to year,
                    "file_size" to size,
                    "date_added_ms" to dateAddedMs,
                    "bitrate" to kbps,
                    "codec" to codec
                )
                trackList.add(item)
            }
        }
        return trackList
    }

    private fun extractAudioTelemetry(
        filePath: String,
        knownFileSize: Long,
        knownDurationMs: Long
    ): Map<String, Any?>? {
        val file = File(filePath)
        if (!file.exists()) return null

        val fileSize = if (knownFileSize > 0L) knownFileSize else file.length()
        var durationMs = knownDurationMs
        var bitrateBps = 0
        var sampleRate = 0
        var channels = 0
        var bitDepth = 0
        var mimeType: String? = null

        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(filePath)
            val brStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_BITRATE)
            bitrateBps = brStr?.toIntOrNull() ?: 0
            mimeType = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_MIMETYPE)
            if (durationMs <= 0L) {
                durationMs = retriever
                    .extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
                    ?.toLongOrNull() ?: 0L
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                sampleRate = retriever
                    .extractMetadata(MediaMetadataRetriever.METADATA_KEY_SAMPLERATE)
                    ?.toIntOrNull() ?: 0
                bitDepth = retriever
                    .extractMetadata(MediaMetadataRetriever.METADATA_KEY_BITS_PER_SAMPLE)
                    ?.toIntOrNull() ?: 0
            }
        } catch (_: Exception) {
        } finally {
            try {
                retriever.release()
            } catch (_: Exception) {
            }
        }

        val extractor = MediaExtractor()
        try {
            extractor.setDataSource(filePath)
            for (i in 0 until extractor.trackCount) {
                val format = extractor.getTrackFormat(i)
                val trackMime = format.getString(MediaFormat.KEY_MIME) ?: continue
                if (trackMime.startsWith("audio/")) {
                    mimeType = mimeType ?: trackMime
                    if (bitrateBps <= 0 && format.containsKey(MediaFormat.KEY_BIT_RATE)) {
                        bitrateBps = format.getInteger(MediaFormat.KEY_BIT_RATE)
                    }
                    if (sampleRate <= 0 && format.containsKey(MediaFormat.KEY_SAMPLE_RATE)) {
                        sampleRate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                    }
                    if (channels <= 0 && format.containsKey(MediaFormat.KEY_CHANNEL_COUNT)) {
                        channels = format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                    }
                    if (bitDepth <= 0 &&
                        Build.VERSION.SDK_INT >= Build.VERSION_CODES.N &&
                        format.containsKey(MediaFormat.KEY_PCM_ENCODING)
                    ) {
                        bitDepth = when (format.getInteger(MediaFormat.KEY_PCM_ENCODING)) {
                            AudioFormat.ENCODING_PCM_8BIT -> 8
                            AudioFormat.ENCODING_PCM_16BIT -> 16
                            AudioFormat.ENCODING_PCM_FLOAT -> 32
                            AudioFormat.ENCODING_PCM_24BIT_PACKED -> 24
                            AudioFormat.ENCODING_PCM_32BIT -> 32
                            else -> 0
                        }
                    }
                    if (durationMs <= 0L && format.containsKey(MediaFormat.KEY_DURATION)) {
                        durationMs = format.getLong(MediaFormat.KEY_DURATION) / 1000L
                    }
                    break
                }
            }
        } catch (_: Exception) {
        } finally {
            try {
                extractor.release()
            } catch (_: Exception) {
            }
        }

        val kbps = normalizeKbps(bitrateBps, fileSize, durationMs)
        val codec = normalizeCodec(mimeType, filePath)
        if (bitDepth <= 0 && (codec == "MP3" || codec == "AAC" || codec == "OPUS" || codec == "OGG" || codec == "FLAC" || codec == "WAV")) {
            bitDepth = 16
        }

        return mapOf(
            "bitrate" to kbps,
            "sample_rate" to (if (sampleRate > 0) sampleRate else null),
            "bit_depth" to (if (bitDepth > 0) bitDepth else null),
            "channels" to (if (channels > 0) channels else null),
            "codec" to codec
        )
    }

    private fun normalizeKbps(rawBitrate: Int, fileSizeBytes: Long, durationMs: Long): Int? {
        if (rawBitrate > 0) {
            val kbps = if (rawBitrate > 10000) (rawBitrate / 1000.0).roundToInt() else rawBitrate
            if (kbps > 0) return kbps
        }
        if (fileSizeBytes > 0L && durationMs > 0L) {
            val computed = ((fileSizeBytes * 8.0) / (durationMs / 1000.0) / 1000.0).roundToInt()
            if (computed > 0) return computed
        }
        return null
    }

    private fun normalizeCodec(mimeType: String?, filePath: String?): String? {
        val lowerMime = mimeType?.lowercase() ?: ""
        if (lowerMime.contains("flac")) return "FLAC"
        if (lowerMime.contains("mpeg") || lowerMime.contains("mp3")) return "MP3"
        if (lowerMime.contains("mp4a") || lowerMime.contains("aac")) return "AAC"
        if (lowerMime.contains("opus")) return "OPUS"
        if (lowerMime.contains("vorbis") || lowerMime.contains("ogg")) return "OGG"
        if (lowerMime.contains("raw") || lowerMime.contains("wav") || lowerMime.contains("x-wav")) return "WAV"
        if (lowerMime.contains("alac")) return "ALAC"

        val ext = filePath?.substringAfterLast('.', "")?.lowercase() ?: ""
        return when (ext) {
            "mp3" -> "MP3"
            "flac" -> "FLAC"
            "m4a", "aac", "mp4" -> "AAC"
            "opus" -> "OPUS"
            "ogg" -> "OGG"
            "wav" -> "WAV"
            "alac" -> "ALAC"
            else -> if (ext.isNotEmpty()) ext.uppercase() else null
        }
    }

    private fun extractAndCacheArtwork(
        filePath: String?,
        outputPath: String,
        albumId: Long?,
        maxSize: Int,
        preferEmbedded: Boolean
    ): String? {
        val targetFile = File(outputPath)
        if (targetFile.exists() && targetFile.length() > 64) {
            return targetFile.absolutePath
        }

        val bitmap: Bitmap? = if (preferEmbedded) {
            decodeEmbeddedBitmap(filePath, maxSize) ?: decodeMediaStoreBitmap(albumId, maxSize)
        } else {
            decodeMediaStoreBitmap(albumId, maxSize) ?: decodeEmbeddedBitmap(filePath, maxSize)
        }

        if (bitmap == null) return null

        return try {
            targetFile.parentFile?.mkdirs()
            val tmpFile = File("${targetFile.absolutePath}.tmp")
            FileOutputStream(tmpFile).use { out ->
                bitmap.compress(Bitmap.CompressFormat.JPEG, 88, out)
            }
            bitmap.recycle()
            if (tmpFile.renameTo(targetFile)) {
                targetFile.absolutePath
            } else {
                tmpFile.copyTo(targetFile, overwrite = true)
                tmpFile.delete()
                targetFile.absolutePath
            }
        } catch (_: Exception) {
            bitmap.recycle()
            null
        }
    }

    private fun decodeEmbeddedBitmap(filePath: String?, maxSize: Int): Bitmap? {
        if (filePath.isNullOrBlank()) return null
        val audioFile = File(filePath)
        if (!audioFile.exists()) return null

        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(filePath)
            val embedded = retriever.embeddedPicture ?: return null
            decodeSampledBitmapFromBytes(embedded, maxSize)
        } catch (_: Exception) {
            null
        } finally {
            try {
                retriever.release()
            } catch (_: Exception) {
            }
        }
    }

    private fun decodeMediaStoreBitmap(albumId: Long?, maxSize: Int): Bitmap? {
        if (albumId == null || albumId <= 0L) return null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                val albumUri = ContentUris.withAppendedId(
                    MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI,
                    albumId
                )
                return contentResolver.loadThumbnail(albumUri, Size(maxSize, maxSize), null)
            } catch (_: Exception) {
                // Fall through to legacy albumart URI lookup
            }
        }
        return try {
            val legacyUri = ContentUris.withAppendedId(
                Uri.parse("content://media/external/audio/albumart"),
                albumId
            )
            contentResolver.openInputStream(legacyUri)?.use { stream ->
                val buffer = ByteArrayOutputStream()
                val chunk = ByteArray(8192)
                var read: Int
                while (stream.read(chunk).also { read = it } != -1) {
                    buffer.write(chunk, 0, read)
                }
                decodeSampledBitmapFromBytes(buffer.toByteArray(), maxSize)
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun decodeSampledBitmapFromBytes(data: ByteArray, maxSize: Int): Bitmap? {
        if (data.isEmpty()) return null
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(data, 0, data.size, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null

        var inSampleSize = 1
        val largest = max(bounds.outWidth, bounds.outHeight)
        while ((largest / inSampleSize) > maxSize * 2) {
            inSampleSize *= 2
        }

        val decodeOpts = BitmapFactory.Options().apply {
            this.inSampleSize = inSampleSize
            inPreferredConfig = Bitmap.Config.ARGB_8888
        }
        val decoded = BitmapFactory.decodeByteArray(data, 0, data.size, decodeOpts) ?: return null
        val maxDim = max(decoded.width, decoded.height)
        if (maxDim <= maxSize) return decoded

        val scale = maxSize.toFloat() / maxDim.toFloat()
        val targetW = max(1, (decoded.width * scale).toInt())
        val targetH = max(1, (decoded.height * scale).toInt())
        val scaled = Bitmap.createScaledBitmap(decoded, targetW, targetH, true)
        if (scaled != decoded) {
            decoded.recycle()
        }
        return scaled
    }
}
