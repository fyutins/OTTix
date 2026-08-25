; Windows installer (Inno Setup 6).
;
; Compilation:
;   iscc /DAppVersion=0.1.0 /DSourceDir=<folder produced by "cmake --install"> ^
;        /DOutputDir=<output folder> packaging\windows\OTTix.iss
;
; SourceDir must contain appOTTix.exe, the Qt DLLs deployed by windeployqt,
; libmpv-2.dll and the qml/ folder (which is exactly what
; "cmake --install <build> --prefix dist" produces).

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\..\dist"
#endif
#ifndef OutputDir
  #define OutputDir "..\..\dist-installer"
#endif

#define AppName "OTTix"
#define AppExeName "appOTTix.exe"
#define AppPublisher "Fyutins"
#define AppUrl "https://github.com/fyutins/OTTix"

[Setup]
; Never change this AppId: it identifies the application for updates and
; uninstallation.
AppId={{7BBA9DA9-70DE-4A00-BE43-ABDC91B14B63}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
VersionInfoVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppUrl}
AppSupportURL={#AppUrl}/issues
AppUpdatesURL={#AppUrl}/releases

; Per-user installation by default (no elevation); the user can request a
; machine-wide installation from the wizard.
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
AllowNoIcons=yes

ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0

OutputDir={#OutputDir}
OutputBaseFilename=OTTix-{#AppVersion}-Setup
SetupIconFile={#SourcePath}app.ico
UninstallDisplayIcon={app}\{#AppExeName}
UninstallDisplayName={#AppName}
WizardStyle=modern
Compression=lzma2/max
SolidCompression=yes
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent

; The database and the settings live in %LOCALAPPDATA%\OTTix: uninstallation
; deliberately keeps them (playlists, favorites).
