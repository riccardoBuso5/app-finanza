; Script Inno Setup per Spendimeno
; Generato da Copilot

#define MyAppName "Spendimeno"
#define MyAppVersion "1.0"
#define MyAppExeName "Spendimeno.exe"

[Setup]
AppName={#MyAppName}
AppVersion={#MyAppVersion}
DefaultDirName={pf64}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputBaseFilename=SpendimenoSetup
OutputDir=Output
Compression=lzma
SolidCompression=yes

[Files]
; Copia tutto il contenuto della cartella Release
Source: ".\*"; DestDir: "{app}"; Excludes: "Output\*"; Flags: ignoreversion recursesubdirs createallsubdirs
; Rinomina l'eseguibile principale
Source: ".\flutter_application_1.exe"; DestDir: "{app}"; DestName: "{#MyAppExeName}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Crea un'icona sul desktop"; GroupDescription: "Icone aggiuntive:"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Avvia {#MyAppName}"; Flags: nowait postinstall skipifsilent
