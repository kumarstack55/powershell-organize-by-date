$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

function Get-TestDate {
    param($Year, $Month, $Day)
    Get-Date -Year $Year -Month $Month -Day $Day -Hour 0 -Minute 0 -Second 0 -Millisecond 0
}

Describe "Utility" {
    Context "Get-ArchiveParentDir" {
        It "ARCHIVE_DIR_NAME の下にあれば、親ディレクトリを返す" {
            $dir = Get-ArchiveParentDir -ParentFullName "TestDrive:\part1\part2\$ARCHIVE_DIR_NAME\part3\part4"
            $dir | Should Be "TestDrive:\part1\part2\Archive"
        }
        It "ARCHIVE_DIR_NAME の下になければ、そのファイルの親ディレクトリを返す" {
            $dir = Get-ArchiveParentDir -ParentFullName "TestDrive:\part1\part2"
            $dir | Should Be "TestDrive:\part1\part2"
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
