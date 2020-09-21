param ([string] $path, [int]$keep, [int]$project)

function Log($message, $type) {
  $logFile = $path + "\compression.log"
  $timeStamp = "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date) 
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

function ZipFile ($source, $destination) {
  Log("Compressing $source")
  If (Test-path $destination) { Remove-item $destination }
  Add-Type -assembly "system.io.compression.filesystem"
  [io.compression.zipfile]::CreateFromDirectory($source, $destination)
}

function DeleteFolder {
  param ($folder)
  Log("Deleting the source folder $source")
  Remove-Item $folder -Recurse -Force
}

function Main {
  Log('Sast scans compression start on $path')
  $wildcard = If ($project) { [string]::Format('{0}_*', $project) } Else { '*' }
  $numberOfScansIgnoredByProject = @{}
  $totalCompressedFolders = 0
  $allScans = Get-ChildItem -Path $path -Filter $wildcard -Directory | Sort-Object CreationTime -Descending

  foreach ($scan in $allScans) {
    $project = $scan[0].BaseName.Split('_')[0]
    $totalIgnored = $numberOfScansIgnoredByProject[$project]

    if ($totalIgnored -lt $keep) {
      $numberOfScansIgnoredByProject[$project] ++
    }
    else {
      $source = $scan.FullName
      $destinationFile = $scan.FullName + ".zip"
     
      ZipFile $source $destinationFile
     
      DeleteFolder $source
      $totalCompressedFolders ++
    }
  }

  Log("Finished compressing $totalCompressedFolders folder(s)")
}

try {
  Main
}
catch {
  Write-Error "$($_.Exception.Message)"
}