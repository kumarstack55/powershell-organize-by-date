# powershell-organize-by-date

## インストール方法

```ps1
# clone する
cd $HOME
git clone https://github.com/kumarstack55/powershell-organize-by-date.git

cd powershell-organize-by-date

$sendToDir = Join-Path $env:APPDATA Microsoft\Windows\SendTo

function New-Shortcut {
    param(
        [parameter(Mandatory)][String]$Name,
        [parameter(Mandatory)][System.IO.FileSystemInfo]$Item
    )
    $shortcutFilename = Join-Path $Item.Directory.FullName $Name
    $targetPath = "powershell"
    $arguments = "-File `"$($Item.FullName)`" -InformationAction Continue"

    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutFilename)
    $shortcut.TargetPath = $targetPath
    $shortcut.Arguments = $arguments
    $shortcut.Save()
}
```

### Rename-ItemWithModifiedDate.ps1

```ps1
# ショートカットを作る
$item = Get-Item Rename-ItemWithModifiedDate.ps1
$shortcutFilename = "0100_ファイル名に変更日を付与する.lnk"
New-Shortcut $shortcutFilename $item

# ショートカットをエクスプローラーの「送る」で利用する
Move-Item $shortcutFilename $sendToDir -Force
```

### Move-ItemToArchiveDirByDate.ps1

```ps1
# ショートカットを作る
$item = Get-Item Move-ItemToArchiveDirByDate.ps1
$shortcutFilename = "0110_アーカイブする.lnk"
New-Shortcut $shortcutFilename $item

# ショートカットをエクスプローラーの「送る」で利用する
Move-Item $shortcutFilename $sendToDir -Force
```