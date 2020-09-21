Param([string] $path, [int]$keep = 50, [int]$project, [bool]$keepSourceFolder = $false)

function Log($message, $type) {
  $logFile = $path + "\compression.log"
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
  Log("Compressing $source")
 
  If (Test-path $destination) { 
    Remove-item $destination 
  }
  
  Add-Type -assembly "system.io.compression.filesystem"
  [io.compression.zipfile]::CreateFromDirectory($source, $destination)
}

function DeleteFolder($folder) {
  Log("Deleting the source folder $source")
  
  If (Test-path $folder) { 
    Remove-Item $folder -Recurse -Force 
  } 
}

function Main {
  $sw = [Diagnostics.Stopwatch]::StartNew()
  Log("Sast scans compression start on $path")
  $wildcard = If ($project) { [string]::Format('{0}_*', $project) } Else { '*' }
  $numberOfScansIgnoredByProject = @{}
  $totalCompressedFolders = 0

  $allScans = Get-ChildItem -Path $path -Filter $wildcard -Directory | Sort-Object CreationTime

  foreach ($scan in $allScans) {
    $project = $scan[0].BaseName.Split('_')[0]
    $totalIgnored = $numberOfScansIgnoredByProject[$project]

    if ($totalIgnored -lt $keep) {
      $numberOfScansIgnoredByProject[$project] ++
    }
    else {
      $source = $scan.FullName
      $destinationFile = $source + "-temp.zip"
     
      ZipFile $source $destinationFile

      if ($keepSourceFolder -ne $true) {
        DeleteFolder $source
      }

      $newDestination = $source + '/content.zip'
      Log("Moving the zipped content to $newDestination")
      New-Item -Path $source -ItemType Directory | Out-Null
      Move-Item -Path $destinationFile -Destination $newDestination

      $totalCompressedFolders ++
    }
  }
  
  $sw.Stop()
  Log("Finished compressing $totalCompressedFolders folder(s) in $($sw.Elapsed.TotalSeconds) sec")
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