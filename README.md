# powershell-organize-by-date

ファイルを日付ベースに整理したい人のためのツール。

## これは何？

ファイル名の先頭に、ファイルの変更日を yyyyMMdd 形式にしてリネームしたり、
ファイル名の先頭に日付がつくフォルダ名やファイル名を、
西暦や、年月のフォルダに移動させたり、
がエクスプローラの「送る」でできるようになります。

## もっと具体的には？

次のようなフォルダ構成において:

* Desktop/
    * dir1/ (変更日: yyyy-MM-dd)
    * file1/ (変更日: yyyy-MM-dd)

Rename-ItemWithModifiedDate で
dir1, file1.txt のファイル名の先頭に日付を加え:

* Desktop/
    * yyyyMMdd_dir1/
    * yyyyMMdd_file1/

Move-ItemToArchiveDirByDate で
dir1, file1.txt をアーカイブ用のフォルダに移動できる:

* Desktop/
    * Archive/
        * yyyy/
            * yyyyMM/
                * yyyyMMdd_dir1/
            * yyyyMM/
                * yyyyMMdd_file1/

## 利用方法

エクスプローラーでファイルやフォルダを選択して、
右クリックして、送る、から行いたい操作を選ぶ。

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