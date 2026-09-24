$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
python -m pip install -r requirements.txt
if ($LASTEXITCODE) { throw 'Dependency installation failed' }
python -m unittest discover -v
if ($LASTEXITCODE) { throw 'Core tests failed' }
python -m PyInstaller --noconfirm --clean --onedir --windowed --name Vocalia --version-file version_info.txt --icon Vocalia.ico --add-data "logo.png;." --add-data "ui-translations.json;." --collect-all sherpa_onnx --collect-all sherpa_onnx_core --collect-all faster_whisper --collect-all ctranslate2 --collect-all tokenizers --collect-all av --collect-all onnxruntime --collect-all huggingface_hub --copy-metadata faster-whisper --copy-metadata huggingface-hub --copy-metadata tokenizers --copy-metadata ctranslate2 app.py
if ($LASTEXITCODE) { throw 'Packaging failed' }
Copy-Item README.md dist/Vocalia/README.md
Copy-Item README.es.md dist/Vocalia/README.es.md
Copy-Item THIRD-PARTY-NOTICES.txt dist/Vocalia/THIRD-PARTY-NOTICES.txt
python collect_licenses.py dist/Vocalia/licenses
if ($LASTEXITCODE) { throw 'License collection failed' }
Copy-Item -Recurse -Force model-licenses dist/Vocalia/licenses/model-licenses
$env:QT_QPA_PLATFORM = 'offscreen'
$env:VOCALIA_SMOKE_RESULT = Join-Path $PSScriptRoot 'gui-result.txt'
Remove-Item $env:VOCALIA_SMOKE_RESULT -ErrorAction SilentlyContinue
$env:VOCALIA_E2E_FIXTURE = Join-Path $PSScriptRoot 'test-speech.opus'
$gui = Start-Process -FilePath dist/Vocalia/Vocalia.exe -ArgumentList '--smoke-test' -Wait -PassThru
if ($gui.ExitCode -ne 0 -or !(Test-Path $env:VOCALIA_SMOKE_RESULT)) { throw 'Packaged GUI regression test failed' }
python smoke_engine.py (Join-Path $PSScriptRoot 'dist/Vocalia/Vocalia.exe')
if ($LASTEXITCODE) { throw 'Packaged transcription test failed' }
python smoke_advanced.py (Join-Path $PSScriptRoot 'dist/Vocalia/Vocalia.exe')
if ($LASTEXITCODE) { throw 'Packaged comparison/speaker test failed' }
Compress-Archive -Path dist/Vocalia -DestinationPath Vocalia-0.0.6-Windows-x64.zip -Force
(Get-FileHash Vocalia-0.0.6-Windows-x64.zip -Algorithm SHA256).Hash + '  Vocalia-0.0.6-Windows-x64.zip' | Set-Content SHA256SUMS-Windows.txt
