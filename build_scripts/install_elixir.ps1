$WebClient = New-Object System.Net.WebClient

Write-Output "Downloading Erlang"
$erlang_url = "https://github.com/erlang/otp/releases/download/OTP-23.2.7/otp_win64_23.2.7.exe"
$WebClient.DownloadFile($erlang_url, "$env:TEMP\erlang.exe")

Write-Output "Installing Erlang"
Invoke-Expression "$env:TEMP\erlang.exe /S /D=c:\erlang"

while (!(Test-Path "c:\erlang\bin\erl.exe")) { Start-Sleep 5 }

Write-Output "Downloading Elixir"
$WebClient.DownloadFile("https://github.com/elixir-lang/elixir/releases/download/v1.11.3/Precompiled.zip", "$env:TEMP\elixir.zip")

Write-Output "Extracting Elixir"
Expand-Archive -DestinationPath c:\elixir $env:TEMP\elixir.zip -Force

Write-Output "Finished"