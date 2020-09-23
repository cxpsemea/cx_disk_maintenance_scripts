Param([string]$path, [int]$keep = 50, [int]$project, [bool]$keepSourceFolder = $false)
Add-Type -assembly "system.io.compression.filesystem"
function Log($message, $type) {
  $logFile = "$path\compression.log"
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

function ZipFile($source, $destination) {
  If (Test-path $destination) { 
    Remove-item $destination 
  }

  Log("Compressing $source")
  $zipSw = [Diagnostics.Stopwatch]::StartNew()
  [io.compression.zipfile]::CreateFromDirectory($source, $destination)
  $zipSw.Stop()

  Log("Compressed in $($zipSw.Elapsed.TotalSeconds) sec")
}

function Main {
  $mainSw = [Diagnostics.Stopwatch]::StartNew()
  Log("Sast scans compression start on $path")
  $wildcard = If ($project) { [string]::Format('{0}_*', $project) } Else { '*' }
  $numberOfScansIgnoredByProject = @{}
  $totalCompressedFolders = 0

  $allScans = Get-ChildItem -Path $path -Filter $wildcard -Directory | Sort-Object CreationTime -Descending

  foreach ($scan in $allScans) {
    $project = $scan[0].BaseName.Split('_')[0]
    $totalIgnored = $numberOfScansIgnoredByProject[$project]
    $sourceFolder = $scan.FullName
    $zipFileDestination = "$sourceFolder\$($scan.Name).zip"

    If ($totalIgnored -lt $keep) {
      $numberOfScansIgnoredByProject[$project] ++
    }
    ElseIf (!(Test-path  $zipFileDestination)) {
      $tempZipLocation = "$($scan.Name)-temp.zip"
      ZipFile $sourceFolder $tempZipLocation

      if ($keepSourceFolder -ne $true) {
        Log("Deleting the source folder content")
        Remove-Item "$sourceFolder\*" -Recurse -Force
      }

      Log("Moving the zipped content to the source folder")
      Move-Item -Path $tempZipLocation -Destination $zipFileDestination

      $totalCompressedFolders ++
    }
  }
  
  $mainSw.Stop()

  If (  $totalCompressedFolders -eq 0) {
    Log("There isn't any new scan to compress")
  }
  Else {
    Log("Finished compressing $totalCompressedFolders folder(s) in $($mainSw.Elapsed.TotalSeconds) sec")
  }
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