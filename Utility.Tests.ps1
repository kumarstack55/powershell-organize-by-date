$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

function Get-TestDate {
    param($Year, $Month, $Day)
    Get-Date -Year $Year -Month $Month -Day $Day -Hour 0 -Minute 0 -Second 0 -Millisecond 0
}

Describe "Utility" {
    Context "Get-ItemNamePrefixDate" {
        It "先頭にyyyyMMddがあれば日付を返す" {
            $expected = Get-TestDate -Year 2021 -Month 1 -Day 1
            $item = New-Item -Path "TestDrive:" -Name "20210101_testfile1.txt" -ItemType "file"
            Get-ItemNamePrefixDate $item | Should Be $expected
        }
        It "先頭にyyyyMMddがなければnullを返す" {
            $expected = Get-TestDate -Year 2021 -Month 1 -Day 1
            $item = New-Item -Path "TestDrive:" -Name "testfile1.txt" -ItemType "file"
            Get-ItemNamePrefixDate $item | Should Be $null
        }
        It "日付として不正ならnullを返す" {
            $item = New-Item -Path "TestDrive:" -Name "20210132_testfile1.txt" -ItemType "file"
            Get-ItemNamePrefixDate $item | Should Be $expected
        }
        It "先頭のyyyyMMddに続く数字あればnullを返す" {
            $item = New-Item -Path "TestDrive:" -Name "202101019_testfile1.txt" -ItemType "file"
            Get-ItemNamePrefixDate $item | Should Be $null
        }
    }
    Context "Test-ItemNamePrefixDate" {
        It "先頭にyyyyMMddがあればtrueを返す" {
            $item = New-Item -Path "TestDrive:" -Name "20210101_testfile1.txt" -ItemType "file"
            Test-ItemNamePrefixDate $item | Should Be $true
        }
        It "先頭にyyyyMMddがなければfalseを返す" {
            $item = New-Item -Path "TestDrive:" -Name "testfile1.txt" -ItemType "file"
            Test-ItemNamePrefixDate $item | Should Be $false
        }
        It "日付として不正ならfalseを返す" {
            $item = New-Item -Path "TestDrive:" -Name "20210132_testfile1.txt" -ItemType "file"
            Test-ItemNamePrefixDate $item | Should Be $false
        }
        It "先頭のyyyyMMddに続く数字あればfalseを返す" {
            $item = New-Item -Path "TestDrive:" -Name "202101019_testfile1.txt" -ItemType "file"
            Test-ItemNamePrefixDate $item | Should Be $false
        }
    }
    Context "Get-ArchiveParentDir" {
        It "ARCHIVE_DIR_NAME の下にあれば、親ディレクトリを返す" {
            $dir = Get-ArchiveParentDir -ParentFullName "TestDrive:\part1\part2\$ARCHIVE_DIR_NAME\part3\part4"
            $dir | Should Be "TestDrive:\part1\part2"
        }
        It "ARCHIVE_DIR_NAME の下になければ、そのファイルの親ディレクトリを返す" {
            $dir = Get-ArchiveParentDir -ParentFullName "TestDrive:\part1\part2"
            $dir | Should Be "TestDrive:\part1\part2"
        }
    }
    Context "Get-ItemArchiveParentDirectory" {
        It "未アーカイブファイルの親ディレクトリを返す" {
            $now = Get-TestDate -Year 2021 -Month 2 -Day 1

            New-Item -Path "TestDrive:\part1\part2" -ItemType Directory
            $item = New-Item -Path "TestDrive:\part1\part2" -Name "20210201_testfile1.txt" -ItemType "file"

            $expected = Join-Path (Get-PSDrive TestDrive).Root "part1\part2"

            Get-ItemArchiveParentDirectory -Item $item -Date $now | Should Be $expected
        }
        It "未アーカイブディレクトリの親ディレクトリを返す" {
            $now = Get-TestDate -Year 2021 -Month 2 -Day 1

            $item = New-Item -Path "TestDrive:\part1\part2\20210201_dir1" -ItemType Directory

            $expected = Join-Path (Get-PSDrive TestDrive).Root "part1\part2"

            Get-ItemArchiveParentDirectory -Item $item -Date $now | Should Be $expected
        }
        It "アーカイブ済ファイルの親ディレクトリを返す" {
            $now = Get-TestDate -Year 2021 -Month 2 -Day 1

            New-Item -Path "TestDrive:\part1\part2\$ARCHIVE_DIR_NAME" -ItemType Directory
            $item = New-Item -Path "TestDrive:\part1\part2\$ARCHIVE_DIR_NAME" -Name "20210201_testfile1.txt" -ItemType "file" -Force

            $expected = Join-Path (Get-PSDrive TestDrive).Root "part1\part2"

            Get-ItemArchiveParentDirectory -Item $item -Date $now | Should Be $expected
        }
    }
    Context "Get-ArchivePath" {
        It "年が過去なら ARCHIVE_DIR_NAME と yyyy/yyyyMM を結合した文字列を返す" {
            $now = Get-TestDate -Year 2021 -Month 2 -Day 1
            $itemDate = Get-TestDate -Year 2020 -Month 1 -Day 1
            Get-ArchivePath -ItemDate $itemDate -Date $now | Should Be "$ARCHIVE_DIR_NAME\2020\202001"
        }
        It "それ以外で年月が過去なら ARCHIVE_DIR_NAME と yyyyMM を結合した文字列を返す" {
            $now = Get-TestDate -Year 2021 -Month 2 -Day 1
            $itemDate = Get-TestDate -Year 2021 -Month 1 -Day 1
            Get-ArchivePath -ItemDate $itemDate -Date $now | Should Be "$ARCHIVE_DIR_NAME\202101"
        }
        It "それ以外なら ARCHIVE_DIR_NAME を返す" {
            $now = Get-TestDate -Year 2021 -Month 2 -Day 1
            $itemDate = Get-TestDate -Year 2021 -Month 3 -Day 1
            Get-ArchivePath -ItemDate $itemDate -Date $now | Should Be "$ARCHIVE_DIR_NAME"
        }
    }
}
