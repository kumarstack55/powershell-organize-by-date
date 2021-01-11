Set-Variable -Name "ARCHIVE_DIR_NAME" -value "Archive" -Option Constant

function Wait-PressAnyKeyToContinue {
    Write-Host -NoNewLine 'Press any key to continue...';
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
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
        $parent = Split-Path $parent -Parent
        If ($leaf -eq $ARCHIVE_DIR_NAME) {
            return $parent
        }
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
        [System.DateTime][parameter(mandatory = $true)]$ItemDate,
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
    } ElseIf ($ItemDate.Year -eq $Date.Year -and $ItemDate.Month -lt $Date.Month) {
        $parts += @(Get-Date $ItemDate -Format "yyyyMM")
    }

    $ret = $parts[0]
    for ($index = 1; $index -lt $parts.Length; $index++) {
        $ret = Join-Path $ret $parts[$index]
    }

    $ret
}

function Get-ItemNamePrefixDate {
    <#
    .SYNOPSIS
    $Item.Name の先頭8文字による日付を得る
#>
    param([parameter(Mandatory)]$Item)
    If ($Item.Name -match "^(?<Year>\d{4})(?<Month>\d{2})(?<Day>\d{2})\D") {
        try {
            Get-Date -Year $Matches.Year -Month $Matches.Month -Day $Matches.Day -Hour 0 -Minute 0 -Second 0 -Millisecond 0
        } catch {
            $null
        }
    } else {
        $null
    }
}

function Test-ItemNamePrefixDate {
    <#
    .SYNOPSIS
    $Item.Name の先頭8文字が日付であるか判定する
#>
    param([parameter(Mandatory)]$Item)
    $null -ne (Get-ItemNamePrefixDate $Item)
}

function Get-ItemParent {
    param($Item)
    If ($Item -is [System.IO.FileInfo]) {
        $Item.Directory
    } ElseIf ($Item -is [System.IO.DirectoryInfo]) {
        $Item.Parent
    } else {
        throw "期待しないタイプが与えられた: $($Item.GetType())"
    }
}

function Get-ItemArchiveParentDirectory {
    param($Item)
    $parentFullName = (Get-ItemParent $Item).FullName
    Get-ArchiveParentDir -ParentFullName $parentFullName
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

        # ファイル名に日付が含まれるなら処理しない
        if (Test-ItemNamePrefixDate $item) {
            continue
        }

        # 変更内容を出力する
        [String]$prefix = Get-Date -Date $item.LastWriteTime -Format "yyyyMMdd_"
        $newFilename = $prefix + $item.Name
        $newFullname = Join-Path $item.Directory.FullName $newFilename
        Write-Information "---"
        Write-Information "src: $($item.FullName)"
        Write-Information "dst: $newFullname"

        # リネームする
        Rename-Item -NewName $newFullname -LiteralPath $item
    }
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

        # 移動先のディレクトリがなければ作る
        $archiveParentDir = Get-ItemArchiveParentDirectory $Item
        $date = Get-ItemNamePrefixDate $Item
        if ($null -eq $date) {
            throw "ファイル名の先頭8文字が整数ではなかった: $($Item.FullName)"
        }
        $archivePath = Get-ArchivePath -ItemDate $date
        $destDir = Join-Path $archiveParentDir $archivePath
        if (-not (Test-Path $destDir -PathType Container)) {
            New-Item $destDir -ItemType Container | Out-Null
        }

        # 変更内容を出力する
        Write-Information "---"
        Write-Information "src: $($Item.FullName)"
        Write-Information "dst: $($destDir)"

        # 移動する
        Move-Item $Item -Destination $destDir

        # 移動元のフォルダが $ARCHIVE_DIR_NAME 配下で、アイテム数がゼロならディレクトリを消す
        $parentFullName = (Get-ItemParent $Item).FullName
        if ((Test-DirHasArchive $parentFullName) -and ((Get-ChildItem $parentFullName | Measure-Object).Count -eq 0)) {
            Remove-Item -LiteralPath $parentFullName
        }
    }
}
