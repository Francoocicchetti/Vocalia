Set-Location $PSScriptRoot
$ErrorActionPreference = 'Stop'
$compiler = "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe"
if (!(Test-Path $compiler)) { throw 'Inno Setup compiler missing from runner' }
@'
[Setup]
AppId=Vocalia.Windows
AppName=Vocalia
AppVersion=0.0.6
AppVerName=Vocalia 0.0.6
AppPublisher=Francoocicchetti
AppPublisherURL=https://github.com/Francoocicchetti/Vocalia
AppSupportURL=https://github.com/Francoocicchetti/Vocalia/issues
DefaultDirName={localappdata}\Programs\Vocalia
DefaultGroupName=Vocalia
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64os
ArchitecturesInstallIn64BitMode=x64os
MinVersion=10.0.22000
UninstallDisplayIcon={app}\Vocalia.exe
SetupIconFile=Vocalia.ico
OutputDir=release
OutputBaseFilename=Vocalia-0.0.6-Windows-x64-Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes
RestartApplications=no
[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
[Files]
Source: "dist\Vocalia\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
[Icons]
Name: "{userprograms}\Vocalia"; Filename: "{app}\Vocalia.exe"; WorkingDir: "{app}"
Name: "{userdesktop}\Vocalia"; Filename: "{app}\Vocalia.exe"; WorkingDir: "{app}"; Tasks: desktopicon
[Run]
Filename: "{app}\Vocalia.exe"; Description: "{cm:LaunchProgram,Vocalia}"; Flags: nowait postinstall skipifsilent
'@ | Set-Content installer.iss -Encoding utf8
& $compiler installer.iss
if ($LASTEXITCODE) { throw 'Installer build failed' }
$ErrorActionPreference = 'Stop'
$setup = (Resolve-Path release/Vocalia-0.0.6-Windows-x64-Setup.exe).Path
$target = Join-Path $env:LOCALAPPDATA 'Programs\Vocalia'
$data = Join-Path $env:LOCALAPPDATA 'Vocalia'
New-Item -ItemType Directory -Path $data -Force | Out-Null
$marker = Join-Path $data 'installer-preservation-test.txt'
'preserve history and models' | Set-Content $marker
function Install-App {
  $process = Start-Process $setup -ArgumentList '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /TASKS=desktopicon /LOG=install.log' -Wait -PassThru
  if ($process.ExitCode -ne 0) { throw "Installation failed: $($process.ExitCode)" }
}
# Verify the upgrade over the previously distributed build.
$previous = Join-Path $env:TEMP 'Vocalia-previous-0.0.5.exe'
Invoke-WebRequest 'https://github.com/Francoocicchetti/Vocalia/releases/download/v0.0.5/Vocalia-0.0.5-Windows-x64-Setup.exe' -OutFile $previous
$old = Start-Process $previous -ArgumentList '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-' -Wait -PassThru
if ($old.ExitCode -ne 0) { throw 'Previous-version installation failed' }
Install-App
if ((Get-Item (Join-Path $target 'Vocalia.exe')).VersionInfo.ProductVersion -ne '0.0.6') { throw 'Upgrade did not replace the old executable' }
if ((Get-Item (Join-Path $target 'Vocalia.exe')).VersionInfo.FileVersion -ne '0.0.6.0') { throw 'Installer revision did not replace original 0.0.6 executable' }
$source = (Resolve-Path dist/Vocalia).Path
$files = Get-ChildItem $source -Recurse -File
foreach ($file in $files) {
  $relative = [IO.Path]::GetRelativePath($source, $file.FullName)
  $installed = Join-Path $target $relative
  if (!(Test-Path $installed)) { throw "Missing installed file: $relative" }
  if ((Get-FileHash $file.FullName).Hash -ne (Get-FileHash $installed).Hash) { throw "Installed file mismatch: $relative" }
}
$shell = New-Object -ComObject WScript.Shell
foreach ($folder in @([Environment]::GetFolderPath('Programs'), [Environment]::GetFolderPath('Desktop'))) {
  $shortcut = Join-Path $folder 'Vocalia.lnk'
  if (!(Test-Path $shortcut)) { throw "Missing shortcut: $shortcut" }
  if ($shell.CreateShortcut($shortcut).TargetPath -ne (Join-Path $target 'Vocalia.exe')) { throw 'Incorrect shortcut target' }
}
$env:QT_QPA_PLATFORM = 'offscreen'
$env:VOCALIA_SMOKE_RESULT = Join-Path $env:TEMP 'installed-gui-result.txt'
$gui = Start-Process (Join-Path $target 'Vocalia.exe') -ArgumentList '--smoke-test' -PassThru
if (!$gui.WaitForExit(180000)) { $gui.Kill(); throw 'Installed app test timed out' }
if ($gui.ExitCode -ne 0 -or !(Test-Path $env:VOCALIA_SMOKE_RESULT)) { throw 'Installed app failed to start or pass GUI tests' }
if ((Get-Content $env:VOCALIA_SMOKE_RESULT -Raw).Trim() -ne 'PASS') { throw 'Installed GUI tests failed' }
Install-App
if ((Get-Content $marker -Raw).Trim() -ne 'preserve history and models') { throw 'Reinstall changed user data' }
$uninstall = Start-Process (Join-Path $target 'unins000.exe') -ArgumentList '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART' -Wait -PassThru
if ($uninstall.ExitCode -ne 0) { throw 'Uninstall failed' }
if (Test-Path (Join-Path $target 'Vocalia.exe')) { throw 'Uninstall left application executable' }
if (!(Test-Path $marker)) { throw 'Uninstall removed user data' }
if (Test-Path (Join-Path ([Environment]::GetFolderPath('Programs')) 'Vocalia.lnk')) { throw 'Uninstall left Start menu shortcut' }
"PASS: $($files.Count) installed files match the published ZIP; installed GUI, shortcuts, upgrade from 0.0.5 to 0.0.6, reinstall and data-preserving uninstall." | Set-Content release/Windows-Installer-Validation.txt
(Get-FileHash $setup -Algorithm SHA256).Hash.ToLower() + '  Vocalia-0.0.6-Windows-x64-Setup.exe' | Set-Content release/SHA256SUMS-Installer.txt
