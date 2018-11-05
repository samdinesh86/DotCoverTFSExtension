[CmdletBinding()]
param()
Trace-VstsEnteringInvocation $MyInvocation
try {
    [string] $TestAssembliesDirectory = Get-VstsInput -Name TestAssembliesDirectory		
    [string] $TestResultsDirectory = Get-VsTsInput -Name TestResultDirectory
    [string] $CustomVstestPath = Get-VstsInput -Name VSTestPath
    [string] $CustomDotCoverPath = Get-VstsInput -Name DotCoverPath
    [string] $CustomexcludedAssemblies = Get-VstsInput -Name ExcludedAssemblies 
    [string] $InlcudeAssemblies = Get-VstsInput -Name TestAssemblies
    [string] $ReportType = Get-VstsInput -Name ReportType
    
    $DotCoverPath = "C:\BuildTools\dotCover.2018.1"
    $VSTestPath = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\Common7\IDE\CommonExtensions\Microsoft\TestWindow\vstest.console.exe"
    $excludedAssemblies ="+:module=*;class=*;function=*;-:module=*Test*;-:module=*Utility*;"
    Write-Host "Validating Dotcover and VSTest Path"	

    if (-not ([string]::IsNullOrEmpty($CustomDotCoverPath)) -and (Test-Path $($CustomDotCoverPath + "\dotcover.exe"))) {
        Write-Host "DotCover Commandline Exists"
        $DotCoverPath = $CustomDotCoverPath
    }
    elseif ( Test-Path $($DotCoverPath + "\dotcover.exe")) {
        Write-Host "Default DotCover Commandline Exists"
    }
    else {
        Write-Error "DotCover doesn't exist"  
    }

    if (-not ([string]::IsNullOrEmpty($CustomVstestPath)) -and (Test-Path $CustomVstestPath)) {
        Write-Host "VSTest path is valid"
        $VSTestPath = $CustomVstestPath
    }
    elseif ( Test-Path $VSTestPath) {
        Write-Host "Default VSTest path is valid"
    }
    else {
        Write-Error "VSTest doesn't exist"
    }

    if(-not ([string]::IsNullOrEmpty($CustomexcludedAssemblies))){
        $excludedAssemblies = $CustomexcludedAssemblies
    }

    try {
        Write-Host "Validating Test Assemblies"
        if($InlcudeAssemblies.contains('*')){
            $testDlls = Get-ChildItem $TestAssembliesDirectory -File -include "*.dll" -Recurse| Where-Object { $_.Name -like $InlcudeAssemblies } | Select-Object
	
            foreach ($testDll in $testDlls) { 				
            
                $dotCoverTargetArguments += @($testDll.FullName)	
            }    
        }else{
            $assemblies += $InlcudeAssemblies -split ','
            foreach ($assembly in $assemblies) { 	
                $testDll = Get-ChildItem $TestAssembliesDirectory -File -include "*.dll" -Recurse| Where-Object { $_.Name -eq $assembly } | Select-Object
                $dotCoverTargetArguments += @($testDll.FullName)	
            }    
        }
        if($ReportType -eq "XML"){
           $OutputFormat = "DetailedXML"
        }else{
            $OutputFormat = "HTML"
        }
        Write-Host "Coverage with dotCover Started"
        Write-Host $dotCoverTargetArguments
        cd $DotCoverPath
	 	.\dotcover.exe cover /TargetExecutable="$VstestPath" /Filters="$excludedAssemblies" /TargetWorkingDir="$TestAssembliesDirectory" /TargetArguments="$dotCoverTargetArguments" /Output="$TestResultsDirectory\CoverageReport.dcvr" /LogFile="$TestResultsDirectory\DotCoverlog.txt" 
        .\dotcover.exe report /Source="$TestResultsDirectory\CoverageReport.dcvr" /Output="$TestResultsDirectory\CoverageReport."$($ReportType.ToLower()) /ReportType=$OutputFormat
        Write-Host "Finished running dotCover"
        exit 0
    }
    catch {
        Write-Error $_
        exit 1
    }
}	
catch {
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    Write-Error "$FailedItem - $ErrorMessage"
}
finally {
    Trace-VstsLeavingInvocation $MyInvocation
}