package com.nexa.player.nexa_player

import android.os.Build
import android.provider.MediaStore
import androidx.annotation.NonNull
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: AudioServiceActivity() {
    private val CHANNEL = "com.nexa.player/media_store"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSdkInt" -> {
                    result.success(Build.VERSION.SDK_INT)
                }
                "queryMediaStoreAudio" -> {
                    try {
                        val tracks = queryMediaStore()
                        result.success(tracks)
                    } catch (e: Exception) {
                        result.error("MEDIASTORE_ERROR", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun queryMediaStore(): List<Map<String, Any?>> {
        val trackList = mutableListOf<Map<String, Any?>>()
        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.TRACK,
            MediaStore.Audio.Media.YEAR,
            MediaStore.Audio.Media.SIZE
        )

        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0 OR ${MediaStore.Audio.Media.DURATION} > 15000"
        val sortOrder = "${MediaStore.Audio.Media.TITLE} ASC"

        val uri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        val cursor = contentResolver.query(uri, projection, selection, null, sortOrder)

        cursor?.use {
            val idCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val titleCol = it.getColumnIndex(MediaStore.Audio.Media.TITLE)
            val artistCol = it.getColumnIndex(MediaStore.Audio.Media.ARTIST)
            val albumCol = it.getColumnIndex(MediaStore.Audio.Media.ALBUM)
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
                val duration = if (durationCol >= 0) it.getLong(durationCol) else 0L
                val trackNumber = if (trackCol >= 0) it.getInt(trackCol) else 0
                val year = if (yearCol >= 0) it.getInt(yearCol) else 0
                val size = if (sizeCol >= 0) it.getLong(sizeCol) else 0L

                val title = if (!rawTitle.isNullOrBlank()) rawTitle else (filePath?.substringAfterLast('/')?.substringBeforeLast('.') ?: "Track $id")
                val artist = if (!rawArtist.isNullOrBlank() && rawArtist != "<unknown>") rawArtist else "Unknown Artist"
                val album = if (!rawAlbum.isNullOrBlank() && rawAlbum != "<unknown>") rawAlbum else "Unknown Album"

                val item = mapOf<String, Any?>(
                    "id" to id.toString(),
                    "title" to title,
                    "artist" to artist,
                    "album" to album,
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
}
