[CmdletBinding(SupportsShouldProcess)]
Param([parameter(Mandatory,ValueFromRemainingArguments)][object[]]$ItemList)
<#
    .SYNOPSIS
    ファイル名先頭8文字に日付がなければファイル名の先頭に日付を加える。
#>

. "$PSScriptRoot/Utility.ps1"

if ($MyInvocation.InvocationName -ne '.') {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = "Stop"
    Rename-ItemWithModifiedDate $ItemList
    Wait-PressAnyKeyToContinue
}