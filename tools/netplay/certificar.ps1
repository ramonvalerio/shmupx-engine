# Certificação de um jogo para o treino em dupla online (docs/NETPLAY.md):
#   1. SyncTest: a cada quadro volta de 1 a N quadros e refaz, comparando o estado (determinismo);
#   2. teste longo entre dois motores no mesmo PC, com entradas automáticas e rede ruim simulada.
# O jogo passa se o SyncTest der "ok" e o teste longo terminar sem nenhum desync.
#
#   pwsh tools/netplay/certificar.ps1 -Jogo truxton2 -Roms D:\ShmupXClient\roms -Motor <pasta do motor>
param(
    [Parameter(Mandatory)] [string] $Jogo,
    [Parameter(Mandatory)] [string] $Roms,
    [Parameter(Mandatory)] [string] $Motor,
    # tempo emulado do SyncTest (s) e do teste entre dois motores (min)
    [int] $SegundosSyncTest = 600,
    [int] $MinutosDupla = 30,
    [int] $Profundidade = 7,
    # rede simulada: atraso de ida (ms), variação (ms), perda (%)
    [string] $Rede = "40,10,2"
)
$ErrorActionPreference = "Stop"
$exe = Join-Path $Motor "shmupx-engine.exe"
if (-not (Test-Path $exe)) { throw "Motor não encontrado: $exe" }
$trabalho = Join-Path ([IO.Path]::GetTempPath()) "shmupx-certificar-$Jogo"
Remove-Item -Recurse -Force $trabalho -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force $trabalho | Out-Null

function Read-Eventos([string] $arquivo) {
    Get-Content $arquivo | Where-Object { $_ -like "SHMUPX_NETPLAY *" } | ForEach-Object { $_.Substring(15) | ConvertFrom-Json }
}

function Start-Motor([string] $nome, [string[]] $extra) {
    $pasta = Join-Path $trabalho $nome
    New-Item -ItemType Directory -Force $pasta | Out-Null
    $argumentos = @($Jogo, "-rompath", $Roms, "-skip_gameinfo", "-video", "none", "-sound", "none",
        "-cfg_directory", "$pasta\cfg", "-nvram_directory", "$pasta\nvram", "-snapshot_directory", "$pasta\snap") + $extra
    Start-Process -FilePath $exe -ArgumentList $argumentos -WorkingDirectory $Motor -NoNewWindow -PassThru `
        -RedirectStandardOutput "$pasta\saida.log" -RedirectStandardError "$pasta\erros.log"
}

Write-Host "== SyncTest de $Jogo ($SegundosSyncTest s emulados, volta até $Profundidade quadros)"
$st = Start-Motor "synctest" @("-shmupx_synctest", "$Profundidade", "-str", "$SegundosSyncTest")
$st.WaitForExit()
$resultado = Read-Eventos "$trabalho\synctest\saida.log" | Where-Object { $_.event -eq "synctest" } | Select-Object -Last 1
if (-not $resultado -or $resultado.result -ne "ok") {
    Write-Host "FALHOU no SyncTest:" ($resultado | ConvertTo-Json -Compress)
    exit 1
}
Write-Host "ok: $($resultado.checked) estados refeitos conferidos em $($resultado.frames) quadros (estado de $($resultado.state_bytes) bytes)"

Write-Host "== Teste entre dois motores ($MinutosDupla min, rede simulada $Rede)"
$chave = -join ((1..32) | ForEach-Object { "{0:x}" -f (Get-Random -Maximum 16) })
$comum = @("-str", "$($MinutosDupla * 60)", "-shmupx_netplay_key", $chave, "-shmupx_netplay_autoinput", "-shmupx_netplay_simulate", $Rede)
$host_ = Start-Motor "host" ($comum + @("-shmupx_netplay", "host", "-shmupx_netplay_port", "47101", "-shmupx_netplay_peer", "127.0.0.1:47102"))
Start-Sleep -Seconds 2
$guest = Start-Motor "guest" ($comum + @("-shmupx_netplay", "guest", "-shmupx_netplay_port", "47102", "-shmupx_netplay_peer", "127.0.0.1:47101"))
$host_.WaitForExit()
$guest.WaitForExit()

$falhou = $false
foreach ($lado in "host", "guest") {
    $eventos = Read-Eventos "$trabalho\$lado\saida.log"
    $resumo = $eventos | Where-Object { $_.event -eq "summary" } | Select-Object -Last 1
    $fim = $eventos | Where-Object { $_.event -eq "ended" } | Select-Object -Last 1
    Write-Host "$lado`:" ($resumo | ConvertTo-Json -Compress) "fim:" $fim.reason
    if (-not $resumo -or $resumo.desyncs -ne 0 -or $fim.reason -ne "local_exit") { $falhou = $true }
}
if ($falhou) {
    Write-Host "FALHOU no teste entre dois motores (logs em $trabalho)"
    exit 1
}
Write-Host "CERTIFICADO: $Jogo pode entrar em NETPLAY_ROMS (shmupx-client/src/data/netplay.ts)"
