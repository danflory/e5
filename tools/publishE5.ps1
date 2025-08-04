param()

Write-Host "=== PublishE5 Script Starting ==="

# 1. Commit and push changes to current branch
git add -A

# Generate commit message from changed files
$gitStatus = git status --porcelain | ForEach-Object { $_.Trim() }
if ($gitStatus.Count -eq 0) {
    Write-Host "No changes to commit."
} else {
    $summary = "Commit: " + ($gitStatus -join ", ")
    git commit -m "$summary"
    $branch = git rev-parse --abbrev-ref HEAD
    git push origin $branch
    Write-Host "Committed and pushed changes to $branch."
}

# 2. Zip the updated solution folder to .Solutions, overwriting old
$solutionBase = "C:\d\e5\solutions"
$zipOutDir = "C:\d\e5\.Solutions"
New-Item -Type Directory -Force -Path $zipOutDir | Out-Null

# Find all solution folders (each subfolder in $solutionBase)
$solutionFolders = Get-ChildItem -Path $solutionBase -Directory
foreach ($folder in $solutionFolders) {
    $solName = $folder.Name
    $zipPath = Join-Path $zipOutDir "$solName.zip"
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
    Compress-Archive -Path $folder.FullName\* -DestinationPath $zipPath
    Write-Host "Zipped $solName to $zipPath"

    # 3. Import to tenant (overwrite)
    try {
        pac solution import --path $zipPath --overwrite true
        Write-Host "Imported $solName to tenant."
    } catch {
        Write-Host ("Import failed for ${solName}: " + $_.Exception.Message)
    }
}

Write-Host "=== PublishE5 Script Complete ==="
