$gw2_gfx_settings_path = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::ApplicationData)) -ChildPath "Guild Wars 2" | Join-Path -ChildPath "GFXSettings.Gw2-64.exe.xml"

if(Test-Path $gw2_gfx_settings_path -PathType Leaf) {
  $install_path = (Select-Xml -Path $gw2_gfx_settings_path -XPath '/GSA_SDK/APPLICATION/INSTALLPATH').Node.Attributes[0].Value
  $executable_file_name = (Select-Xml -Path $gw2_gfx_settings_path -XPath '/GSA_SDK/APPLICATION/EXECUTABLE').Node.Attributes[0].Value
  $executable_file_path = Join-Path $install_path -ChildPath $executable_file_name
  $module_file_path = Join-Path $install_path -ChildPath "d3d11.dll"

  function IsUpdateAvailable() {
    # check if module exists
    if(Test-Path $module_file_path -PathType Leaf) {
      # get md5 hash of current module
      $md5_current = (Get-FileHash $module_file_path -Algorithm MD5).Hash
      # get md5 hash of latest module
      $md5_latest = (Invoke-RestMethod "https://www.deltaconnected.com/arcdps/x64/d3d11.dll.md5sum").Split(' ')[0].ToUpper()
      return !($md5_latest -eq $md5_current)
    }
    return $true
  }
  if(!(IsUpdateAvailable)) {
    Write-Host "Everything is up-to-date!" -ForegroundColor Green
  }
  else {
    Write-Host "Update available!"
    function Update {
      function PrepareUpdate {
        # check if file exists
        if(Test-Path $module_file_path -PathType Leaf) {
          # remove file
          Remove-Item $module_file_path
          # check if file has been removed
          if(Test-Path $module_file_path -PathType Leaf) {
            # file has not been removed
            return $false
          }
        }
        # file has been successfully removed or didn't exist in the first place
        return $true
      }
      if(PrepareUpdate) {
        Write-Host "Updating ..."
        # download latest version
        $web_request = Invoke-WebRequest "https://www.deltaconnected.com/arcdps/x64/d3d11.dll" -OutFile $module_file_path -PassThru
        # check if webrequest returned the disired status code
        if(!($web_request.StatusCode -eq 200)) {
          Write-Error "Failed to download latest module version."
          return
        }
        # check if update succeeded
        if(!(IsUpdateAvailable)) {
          Write-Host "Update completed!" -ForegroundColor Green
        }
        else {
          Write-Error "Update failed."
        }
      }
      else {
        Write-Error "Failed to prepare file system."
      }
    }
    $process = Get-Process $executable_file_name.Split(".")[0] -ErrorAction SilentlyContinue
    # check if process exists
    if($process) {
      Write-Host "Please close the game before continuing."
    }
    else {
      Update
    }
  }
}
else {
  Write-Error "Guild Wars 2 settings file does not exist."
}
Start-Sleep 3
