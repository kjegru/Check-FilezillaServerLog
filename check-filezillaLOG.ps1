#requires -version 2
<#
.SYNOPSIS
  Goes through the FileZilla log file to check if file is uploaded and messages a person for each file.
.DESCRIPTION
  Run the script after you have logged in and keep it running in the background
.PARAMETER <Parameter_Name>
    <Brief description of parameter input required. Repeat this attribute if required>
.INPUTS
  None
.OUTPUTS
  E-mail/slack(in code)/print in prompt.
.NOTES
  Version:        1.0
  Author:         Kjetil Grun
  Creation Date:  27.06.2016
  Purpose/Change: Just a working script
  
.EXAMPLE
  <Example goes here. Repeat this attribute for more than one example>
#>

$fzdir = 'C:\Program Files (x86)\FileZilla Server\Logs\'
$line = 0
$lastfile = ''

while($true) {

    # Finding last changed logfile
    $fzlog = Get-ChildItem $fzdir | Where-Object { ! $_.PSIsContainer } | Sort-Object lastwriteTime | Select-Object -last 1

    if($fzdir+$fzlog -notlike $lastfile) {
        Write-Host 'New file. Reset line counter'
        $line = 0
    }
    Write-Host 'Checking logfile'
    Write-Host "Number of lines when last checked $line"  

    # Finding the line number of the file
    $currlines = Get-Content $fzdir$fzlog | Measure-Object -Line
    Write-Host 'Number of lines in file: ' $currlines.Lines
    # Checking if number of lines has changed
    if($currlines.Lines -gt $line) {
        # If number of file is more than last time check the newest lines
        (Get-Content (Get-Item $fzdir$fzlog))[$line .. $currlines.Lines]| foreach {
            $word = $_.split(' ')
            # For loop through the line as it seems different powershell versions has different ways of counting the array. It should not be less than 6 words into the sentence.
            for($i=0; $i -le 6; $i++) {
              # Finding the word STOR which is the status code for stored file in FileZilla
              if($word[$i] -like 'STOR') {
                $file = $word[$i+1]
                $ip = $word[$i-1]
                $site = $word[$i-2]
                $postSlackMessage = @{token='token-here';channel='#compile-bot';text="$file uploaded by $ip to $site";username='via API'}
                Invoke-RestMethod -Uri https://slack.com/api/chat.postMessage -Body $postSlackMessage
              }
            }
        }
    }
    # Sleeping for X seconds so not to check all the time
    Start-Sleep -s 10
    # Setting the value of the line numbers and filename for the next check.
    $line = $currlines.Lines
    $lastfile = $fzdir+$fzlog
}

