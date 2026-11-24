package com.nexa.player.nexa_player

import android.content.ContentUris
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.util.Size
import androidx.annotation.NonNull
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import kotlin.math.max

class MainActivity : AudioServiceActivity() {
    private val channelName = "com.nexa.player/media_store"
    private val ioExecutor: ExecutorService = Executors.newFixedThreadPool(4)
    private val mainHandler = Handler(Looper.getMainLooper())

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
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        ioExecutor.shutdownNow()
        super.onDestroy()
    }

    private fun queryMediaStore(): List<Map<String, Any?>> {
        val trackList = mutableListOf<Map<String, Any?>>()
        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.ALBUM_ID,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.TRACK,
            MediaStore.Audio.Media.YEAR,
            MediaStore.Audio.Media.SIZE
        )

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
                    "file_size" to size
                )
                trackList.add(item)
            }
        }
        return trackList
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
