[CmdletBinding(SupportsShouldProcess)]
Param(
    [object[]][parameter(Mandatory,ValueFromRemainingArguments)]$ItemList
)
<#
    .SYNOPSIS
    ファイル名先頭8文字をyyyyMMdd日付と認識し、Archiveフォルダ内で整理します
#>

. "$PSScriptRoot/Utility.ps1"

if ($MyInvocation.InvocationName -ne '.') {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = "Stop"
    $ret = 0
    try {
        Move-ItemToArchiveDirByDate $ItemList
    } catch {
        $_
        $ret = 1
    }
    Wait-PressAnyKeyToContinue
    exit $ret
}
