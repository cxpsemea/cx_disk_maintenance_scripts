Param([string]$path)

function Main {
  $allScans = Get-ChildItem -Path $path
  
  foreach ($scan in $allScans) {
    $scanSourceFolder = $scan.FullName
    $zipFilePath = "$scanSourceFolder\$($scan.Name).zip"
   
    If (Test-path $zipFilePath) {
      Expand-Archive -LiteralPath $zipFilePath -DestinationPath $scanSourceFolder
      Remove-Item $zipFilePath
      Write-Host "Unziped the file $zipFilePath"
    } 
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