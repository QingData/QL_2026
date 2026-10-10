param(
    [Parameter(Mandatory = $true)]
    [string]$RootPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputTsv
)

$root = (Resolve-Path -LiteralPath $RootPath -ErrorAction Stop).Path
$outputPath = [System.IO.Path]::GetFullPath($OutputTsv)
$start = [datetime]::new(2025, 9, 1)
$endExclusive = [datetime]::new(2026, 10, 9)

$folders = @(
    Get-ChildItem -LiteralPath $root -File -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object {
            $_.FullName -ne $outputPath -and
            $_.LastWriteTime -ge $start -and
            $_.LastWriteTime -lt $endExclusive
        } |
        Group-Object DirectoryName |
        Where-Object { $_.Count -ge 5 } |
        Sort-Object @{ Expression = 'Count'; Descending = $true },
                    @{ Expression = 'Name'; Descending = $false } |
        ForEach-Object {
            [pscustomobject]@{
                FolderPath       = $_.Name
                ChangedFileCount = $_.Count
            }
        }
)

if ($folders.Count -eq 0) {
    Write-Host "No folders have at least 5 matching files."
    exit
}

$folders |
    Export-Csv -LiteralPath $outputPath -Delimiter "`t" -NoTypeInformation -Encoding UTF8

$folders | Format-Table -AutoSize
Write-Host "Saved $($folders.Count) folders to $outputPath"
