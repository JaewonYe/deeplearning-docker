param(
  [string]$Image = "deeplearning-legacy:cu113",
  [string]$Output = "deeplearning-legacy-cu113.tar"
)

$ErrorActionPreference = "Stop"
docker image inspect $Image *> $null
if ($LASTEXITCODE -ne 0) { throw "Docker image not found: $Image. Run docker compose build first." }

docker save --output $Output $Image
if ($LASTEXITCODE -ne 0) { throw "docker save failed" }

$hash = Get-FileHash -Algorithm SHA256 $Output
# Write LF line endings so sha256sum on Linux reads the checksum correctly.
$checksumLine = "$($hash.Hash.ToLower())  $(Split-Path $Output -Leaf)`n"
[System.IO.File]::WriteAllText((Join-Path (Get-Location).Path "$Output.sha256"), $checksumLine, [System.Text.Encoding]::ASCII)
Write-Host "Created $Output and $Output.sha256"
Write-Host "Copy both files to the offline Ubuntu machine."
