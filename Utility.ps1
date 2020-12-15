Set-Variable -Name "ARCHIVE_DIR_NAME" -value "Archive" -Option Constant

function Wait-PressAnyKeyToContinue {
    Write-Host -NoNewLine 'Press any key to continue...';
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
}

function Rename-ItemWithModifiedDate {
    param([parameter(Mandatory)][object[]]$ItemList)
<#
    .SYNOPSIS
    ファイル名先頭8文字に日付がなければファイル名の先頭に日付を加える。
#>

    foreach ($item in $ItemList) {
        if ($item -is [String]) {
            $item = Get-Item $item
        }

        # ファイル名に日付が含まれるか確認する
        if ($item.Name -match "^(?<Year>\d{4})(?<Month>\d{2})(?<Day>\d{2})") {
            continue
        }

        # ファイルの先頭の日付を得る
        $prefix = Get-Date -Date $item.LastWriteTime -Format "yyyyMMdd_"

        # リネームする
        $newFilename = $prefix + $item.Name
        $newFullname = Join-Path $item.Directory.FullName $newFilename
        Write-Information "---"
        Write-Information "src: $newFullname"
        Write-Information "dest: $($item.FullName)"
        Rename-Item -NewName $newFullname -LiteralPath $item
    }
}

function Get-ArchiveParentDir {
    [OutputType([String])]
    Param([String]$ParentFullName)
<#
    .SYNOPSIS
    指定ファイルまたはディレクトリに対するアーカイブディレクトリを得る

    .DESCRIPTION
    指定ファイルまたはディレクトリが ARCHIVE_DIR_NAME の下にあれば、 ARCHIVE_DIR_NAME を返す。
    それ以外の場合は、そのファイルまたはディレクトリの親ディレクトリを返す。
#>

    [String]$parent = $ParentFullName
    Do {
        $leaf = (Split-Path $parent -Leaf)
        If ($leaf -eq $ARCHIVE_DIR_NAME) {
            return $parent
        }
        $parent = Split-Path $parent -Parent
    } While ($parent -ne "")

    $ParentFullName
}

function Test-DirHasArchive {
    [OutputType([String])]
    Param([String]$FullName)
<#
    .SYNOPSIS
    ARCHIVE_DIR_NAME が含まれるか確認する
#>

    [String]$parent = $FullName
    Do {
        $leaf = (Split-Path $parent -Leaf)
        If ($leaf -ceq $ARCHIVE_DIR_NAME) {
            return $True
        }
        $parent = Split-Path $parent -Parent
    } While ($parent -ne "")

    $False
}

function Get-ArchivePath {
    [OutputType([String])]
    Param(
        [System.DateTime][parameter(mandatory=$true)]$ItemDate,
        [System.DateTime]$Date = (Get-Date))
<#
    .SYNOPSIS
    ARCHIVE_DIR_NAME の親ディレクトリから、ファイルが格納されるべきディレクトリまでのパスを返す。

    .DESCRIPTION
    年が過去なら ARCHIVE_DIR_NAME と yyyy/yyyyMM を結合した文字列を返す
    それ以外で年月が過去なら ARCHIVE_DIR_NAME と yyyyMM を結合した文字列を返す
    それ以外なら ARCHIVE_DIR_NAME を返す
#>

    $parts = @($ARCHIVE_DIR_NAME)
    If ($ItemDate.Year -lt $Date.Year) {
        $parts += @(Get-Date $ItemDate -Format "yyyy")
        $parts += @(Get-Date $ItemDate -Format "yyyyMM")
    }
    ElseIf ($ItemDate.Year -eq $Date.Year -and $ItemDate.Month -lt $Date.Month) {
        $parts += @(Get-Date $ItemDate -Format "yyyyMM")
    }

    $ret = $parts[0]
    for ($index = 1; $index -lt $parts.Length; $index++) {
        $ret = Join-Path $ret $parts[$index]
    }

    $ret
}

function Move-ItemToArchiveDirByDate {
    param([parameter(Mandatory)][object[]]$ItemList)
<#
    .SYNOPSIS
    ARCHIVE_DIR_NAME の親ディレクトリから、ファイルが格納されるべきディレクトリまでのパスを返す。

    .DESCRIPTION
    西暦に相違があれば、 ARCHIVE_DIR_NAME と "yyyy/yyyyMM" を結合した文字列を返す。
    それ以外で月に相違があれば、 ARCHIVE_DIR_NAME と "yyyyMM" を結合した文字列を返す。
    それ以外であれば、 ARCHIVE_DIR_NAME を返す。
#>

    foreach ($Item in $ItemList) {
        If ($Item -is [String]) {
            $Item = Get-Item $Item
        }

        # ファイル名に日付が含まれるか確認する
        If (-not ($Item.Name -match "^(?<Year>\d{4})(?<Month>\d{2})(?<Day>\d{2})")) {
            throw "ファイル名の先頭8文字が整数ではなかった: $($Item.FullName)"
        }
        [System.DateTime]$date = Get-Date -Year $Matches.Year -Month $Matches.Month -Day $Matches.Day

        # アーカイブフォルダの親ディレクトリを得る
        If ($Item -is [System.IO.FileInfo]) {
            $parentFullName = $Item.Directory.FullName
        }
        ElseIf ($Item -is [System.IO.DirectoryInfo]) {
            $parentFullName = $Item.Parent.FullName
        }
        $archiveParentDir = Get-ArchiveParentDir -ParentFullName $parentFullName

        # 移動先のディレクトリがなければ作る
        [String]$archivePath = Get-ArchivePath -ItemDate $date
        [String]$destDir = Join-Path $archiveParentDir $archivePath
        if (-not (Test-Path $destDir -PathType Container)) {
            New-Item $destDir -ItemType Container | Out-Null
        }

        # 移動する
        Write-Information "---"
        Write-Information "src: $($Item.FullName)"
        Write-Information "dest: $($destDir)"
        Move-Item $Item -Destination $destDir

        # 移動元のフォルダが $ARCHIVE_DIR_NAME 配下で、アイテム数がゼロならディレクトリを消す
        if (Test-DirHasArchive $parentFullName) {
            $m = Get-ChildItem $parentFullName | Measure-Object
            if ($m.Count -eq 0) {
                Remove-Item -LiteralPath $parentFullName
            }
        }
    }
}
