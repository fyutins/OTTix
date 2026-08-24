; Installateur Windows (Inno Setup 6).
;
; Compilation :
;   iscc /DAppVersion=0.1.0 /DSourceDir=<dossier issu de "cmake --install"> ^
;        /DOutputDir=<dossier de sortie> packaging\windows\OTTix.iss
;
; SourceDir doit contenir appOTTix.exe, les DLL Qt deployees par
; windeployqt, libmpv-2.dll et le dossier qml/ (c'est exactement ce que
; produit "cmake --install <build> --prefix dist").

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
; Ne jamais changer cet AppId : il identifie l'application pour les mises a
; jour et la desinstallation.
AppId={{7BBA9DA9-70DE-4A00-BE43-ABDC91B14B63}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
VersionInfoVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppUrl}
AppSupportURL={#AppUrl}/issues
AppUpdatesURL={#AppUrl}/releases

; Installation par utilisateur par defaut (aucune elevation) ; l'utilisateur
; peut demander une installation pour toute la machine dans l'assistant.
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
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

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

; La base de donnees et les reglages vivent dans %LOCALAPPDATA%\OTTix :
; la desinstallation les conserve volontairement (playlists, favoris).
