; Inno Setup Script for NEXA Player (Windows x64 Installer)
; Generated for Phase 11 — Export & Distribution

#define MyAppName "NEXA Player"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "NEXA Audio Technologies"
#define MyAppURL "https://github.com/AlirezaAbd-dev/NEXA-Player"
#define MyAppExeName "nexa_player.exe"
#define MyAppId "{{C1A0A3D2-4E5B-4C21-9B5A-6A389F4381C9}"

[Setup]
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=..\..\dist\windows
OutputBaseFilename=nexa-player-{#MyAppVersion}-windows-setup
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest
ChangesAssociations=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "associateaudio"; Description: "Associate NEXA Player with supported audio files (.mp3, .flac, .wav, .m4a, .ogg, .opus)"; GroupDescription: "File Associations:"

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\..\assets\branding\app_icon.png"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Registry]
; MP3 association
Root: HKA; Subkey: "Software\Classes\.mp3\OpenWithProgids"; ValueType: string; ValueName: "NEXAPlayer.Audio"; ValueData: ""; Flags: uninsdeletevalue; Tasks: associateaudio
; FLAC association
Root: HKA; Subkey: "Software\Classes\.flac\OpenWithProgids"; ValueType: string; ValueName: "NEXAPlayer.Audio"; ValueData: ""; Flags: uninsdeletevalue; Tasks: associateaudio
; WAV association
Root: HKA; Subkey: "Software\Classes\.wav\OpenWithProgids"; ValueType: string; ValueName: "NEXAPlayer.Audio"; ValueData: ""; Flags: uninsdeletevalue; Tasks: associateaudio
; M4A association
Root: HKA; Subkey: "Software\Classes\.m4a\OpenWithProgids"; ValueType: string; ValueName: "NEXAPlayer.Audio"; ValueData: ""; Flags: uninsdeletevalue; Tasks: associateaudio
; OGG association
Root: HKA; Subkey: "Software\Classes\.ogg\OpenWithProgids"; ValueType: string; ValueName: "NEXAPlayer.Audio"; ValueData: ""; Flags: uninsdeletevalue; Tasks: associateaudio
; OPUS association
Root: HKA; Subkey: "Software\Classes\.opus\OpenWithProgids"; ValueType: string; ValueName: "NEXAPlayer.Audio"; ValueData: ""; Flags: uninsdeletevalue; Tasks: associateaudio

; ProgID definition
Root: HKA; Subkey: "Software\Classes\NEXAPlayer.Audio"; ValueType: string; ValueName: ""; ValueData: "Audio File"; Flags: uninsdeletekey; Tasks: associateaudio
Root: HKA; Subkey: "Software\Classes\NEXAPlayer.Audio\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\{#MyAppExeName},0"; Tasks: associateaudio
Root: HKA; Subkey: "Software\Classes\NEXAPlayer.Audio\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"" ""%1"""; Tasks: associateaudio
