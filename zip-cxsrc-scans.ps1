Param(
  [string]$path, 
  [int]$keep = 50, 
  [int]$project, 
  [string]$endHour = "15:00"
)

Add-Type -assembly "system.io.compression.filesystem"

$startHour = Get-Date
$numberOfScansIgnoredByProject = @{}

function Log($message, $type) {
  $logFileTimestamp = $startHour.ToString("yyyyMMdd_HHmmsstt")
  $logFile = "$path\logs\$logFileTimestamp - compression.log"

  If (!(test-path "$path\logs")) {
    New-Item -ItemType Directory -Force -Path "$path\logs"  | Out-Null
  }


  $timeStamp = "[{0:MM/dd/yy} {0:HH:mm:ss:ms}]" -f (Get-Date)
  Write-Output "$($timeStamp) $message" | Out-file $logFile -append 
  
  if ($type -eq "warning") {
    Write-Warning $message
  }
  elseif ($type -eq "error") {
    Write-Error $message
  }
  else {
    Write-Host $message
  }
}

function CompressFile($source, $destination) {
  If (Test-path $destination) { 
    Remove-item $destination 
  }

  Log("Compressing $source")
  $compressSw = [Diagnostics.Stopwatch]::StartNew()
  [io.compression.zipfile]::CreateFromDirectory($source, $destination)
  $compressSw.Stop()

  Log("Compressed in $($compressSw.Elapsed.TotalSeconds) sec")
}

function DeleteFolderContent($sourceFolder) {
  Log("Deleting the source folder content")
  $deleteFolderSw = [Diagnostics.Stopwatch]::StartNew()

  Remove-Item "$sourceFolder\*" -Recurse -Force

  $deleteFolderSw.Stop()
  Log("Deleted folder content in $($deleteFolderSw.Elapsed.TotalSeconds) sec")
}

filter shouldBeZipped {
  $project = $_.Name.Split('_')[0]
  $totalIgnored = $numberOfScansIgnoredByProject[$project]
    
  If (($totalIgnored -lt $keep) -and $keep -ne 0) {
    $numberOfScansIgnoredByProject[$project] ++
  }
  
  ElseIf (!(Test-path "$($_.FullName)\$($_.Name).zip")) {
    return $_
  }
}

function Main {
  $mainSw = [Diagnostics.Stopwatch]::StartNew()
  $disk = (Get-Item $path).PSDrive.Name
  $initialSize = Get-PSDrive $disk
  $totalDriveSize = $initialSize.free + $initialSize.used
  $isOutOfTime = (Get-Date) -ge $endHour

  Log("Start Sast scans zipping on $path")
  $selectedScanIndex = 0
  $wildcard = If ($project) { [string]::Format('{0}_*', $project) } Else { '*' }
  $allScans = Get-ChildItem -Path $path -Filter $wildcard -Directory
  | Where-Object { $_.Name -match "^[\d,_]+" }
  | Sort-Object CreationTime -Descending  
  | shouldBeZipped

  while (!$isOutOfTime -and !($selectedScanIndex -ge $allScans.Length)) {
    $scan = $allScans[$selectedScanIndex]
    Log("Zipping $($selectedScanIndex + 1) of $($allScans.Length) scan(s)")
      
    $sourceFolder = $scan.FullName
    $tempZipLocation = "$path\$($scan.Name)-temp.zip"
    $compressFileDestination = "$($scan.FullName)\$($scan.Name).zip"
    
    CompressFile $sourceFolder $tempZipLocation
    DeleteFolderContent($sourceFolder)
  
    Log("Moving the zipped content to the source folder")
    Move-Item -Path $tempZipLocation -Destination $compressFileDestination

    $selectedScanIndex ++
    $isOutOfTime = (Get-Date) -ge $endHour
  }
  
  $mainSw.Stop()
 
  If (($selectedScanIndex -eq 0) -and !$isOutOfTime) {
    Log("There isn't any new scan to compress")
  }
  Else {
    if ($isOutOfTime) {
      Log("Stopped because the hour >= $endHour")
    }

    Log("Finished compressing $selectedScanIndex folder(s) in $($mainSw.Elapsed.TotalSeconds) sec")
  }

  $afterScriptFreeSize = (Get-PSDrive $disk).Free
  if ($initialSize.free -ne $afterScriptFreeSize) {
    Log("Saved $($initialSize.free - $afterScriptFreeSize) bytes")
  }
  Log("Drive $disk size before: $($initialSize.free) free bytes of $totalDriveSize bytes")
  Log("Drive $disk size after:  $afterScriptFreeSize free bytes of $totalDriveSize bytes")
}

try {
  If (!(Test-path $path)) {
    throw "The specified path $path doesn't exist."
  }

  Main
}
catch {
  Write-Error "$($_.Exception.Message)"
}