import 'package:flutter/material.dart';

/// Central semantic widget keys for NEXA Player Phase 2 library & scanner views.
abstract final class Phase2Keys {
  // Navigation & Shell
  static const Key tabSongs = ValueKey('tab_songs');
  static const Key tabAlbums = ValueKey('tab_albums');
  static const Key tabArtists = ValueKey('tab_artists');
  static const Key tabPlaylists = ValueKey('tab_playlists');
  static const Key tabFolders = ValueKey('tab_folders');
  static const Key tabSettings = ValueKey('tab_settings');

  // All Songs Screen
  static const Key searchField = ValueKey('songs_search_field');
  static const Key sortButton = ValueKey('songs_sort_button');
  static const Key sortMenuTitle = ValueKey('sort_menu_title');
  static const Key sortMenuArtist = ValueKey('sort_menu_artist');
  static const Key sortMenuDuration = ValueKey('sort_menu_duration');
  static const Key sortMenuDateAdded = ValueKey('sort_menu_date_added');
  static const Key allSongsList = ValueKey('all_songs_list');
  static const Key songCountHeader = ValueKey('song_count_header');
  static Key trackTile(String trackId) => ValueKey('track_tile_$trackId');
  static Key trackFavoriteToggle(String trackId) =>
      ValueKey('track_fav_$trackId');

  // Albums Screen & Detail
  static const Key albumsGrid = ValueKey('albums_grid');
  static Key albumCard(String albumId) => ValueKey('album_card_$albumId');
  static const Key albumDetailScreen = ValueKey('album_detail_screen');
  static const Key albumDetailBackButton = ValueKey('album_detail_back');
  static const Key albumDetailTrackList = ValueKey('album_detail_track_list');

  // Artists Screen & Detail
  static const Key artistsList = ValueKey('artists_list');
  static Key artistCard(String artistId) => ValueKey('artist_card_$artistId');
  static const Key artistDetailScreen = ValueKey('artist_detail_screen');
  static const Key artistDetailBackButton = ValueKey('artist_detail_back');
  static const Key artistDetailTrackList = ValueKey('artist_detail_track_list');

  // Playlists Screen & Dialogs
  static const Key playlistsList = ValueKey('playlists_list');
  static const Key createPlaylistFab = ValueKey('create_playlist_fab');
  static const Key createPlaylistDialog = ValueKey('create_playlist_dialog');
  static const Key playlistNameInput = ValueKey('playlist_name_input');
  static const Key playlistConfirmCreate = ValueKey('playlist_confirm_create');
  static Key playlistItem(String playlistId) =>
      ValueKey('playlist_item_$playlistId');
  static Key playlistDeleteButton(String playlistId) =>
      ValueKey('playlist_delete_$playlistId');
  static const Key confirmDeletePlaylistButton =
      ValueKey('confirm_delete_playlist');

  // Folders Screen
  static const Key foldersTreeView = ValueKey('folders_tree_view');
  static Key folderNode(String folderPath) =>
      ValueKey('folder_node_$folderPath');
  static Key fileNode(String filePath) => ValueKey('file_node_$filePath');

  // Scanner Settings Screen
  static const Key scannerSettingsScreen = ValueKey('scanner_settings_screen');
  static const Key scannerFolderList = ValueKey('scanner_folder_list');
  static const Key addFolderButton = ValueKey('add_folder_button');
  static const Key addFolderPathInput = ValueKey('add_folder_path_input');
  static const Key addFolderConfirmButton = ValueKey('add_folder_confirm');
  static Key removeFolderButton(String path) =>
      ValueKey('remove_folder_$path');
  static const Key rescanButton = ValueKey('rescan_button');
  static const Key scannerProgressBar = ValueKey('scanner_progress_bar');
  static const Key scannerStatusText = ValueKey('scanner_status_text');
  static const Key skipShortFilesSwitch = ValueKey('skip_short_files_switch');
  static const Key minDurationSlider = ValueKey('min_duration_slider');
}
