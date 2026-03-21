; Script Inno Setup per Spendimeno
; Generato da Copilot

[Setup]
AppName=Spendimeno
AppVersion=1.0
DefaultDirName={pf64}\Spendimeno
DefaultGroupName=Spendimeno
OutputBaseFilename=SpendimenoSetup
Compression=lzma
SolidCompression=yes

[Files]
; Copia tutto il contenuto della cartella Release
Source: "c:\Users\rikka\OneDrive\Documenti\PERSONALE\app-finanza\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; Rinomina l'eseguibile principale
Source: "c:\Users\rikka\OneDrive\Documenti\PERSONALE\app-finanza\Release\flutter_application_1.exe"; DestDir: "{app}"; DestName: "Spendimeno.exe"; Flags: ignoreversion

[Icons]
Name: "{group}\Spendimeno"; Filename: "{app}\Spendimeno.exe"
Name: "{commondesktop}\Spendimeno"; Filename: "{app}\Spendimeno.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Crea un'icona sul desktop"; GroupDescription: "Icone aggiuntive:"

[Run]
Filename: "{app}\Spendimeno.exe"; Description: "Avvia Spendimeno"; Flags: nowait postinstall skipifsilent
