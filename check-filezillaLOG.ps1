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
  Version:        2.0
  Author:         Kjetil Grun
  Creation Date:  27.06.2016
  Purpose/Change: Just a working script
  
.EXAMPLE
  <Example goes here. Repeat this attribute for more than one example>
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Log location
$fzdir = 'C:\Program Files (x86)\FileZilla Server\Logs\'
$line = 0
$global:lastfile = $null
$global:line = $null
#-----------------------------------------------------------[Functions]------------------------------------------------------------

function run-forever {
	while($true) {
		check-ifnewfile
		}
}

function check-ifnewfile {
	# Finding last changed logfile
	$fzlog = Get-ChildItem $fzdir | Where-Object { ! $_.PSIsContainer } | Sort-Object lastwriteTime | Select-Object -last 1
	write-host "checking if the file is new"
	if($lastfile -like $null -or $fzdir+$fzlog -notlike $lastfile) {
			Write-Host 'New file. Reset line counter'
			$line = 0
	}
		find-logfilesize
}

function find-logfilesize {
	Write-Host 'Checking logfile'
	Write-Host "Number of lines when last checked $line"  

	# Finding the line number of the file
	$currlines = Get-Content $fzdir$fzlog | Measure-Object -Line
	Write-Host 'Number of lines in file: ' $currlines.Lines
	check-lineschanged
}

function check-lineschanged {
	# Checking if number of lines has changed
	if($currlines.Lines -gt $line) {
		# If number of file is more than last time check the newest lines
		(Get-Content (Get-Item $fzdir$fzlog))[$line .. $currlines.Lines]| foreach {
			$word = $_.split(' ')
			# For loop through the line as it seems different powershell versions has different ways of counting the array. It should not be less than 7 words into the sentence.
			for($i=0; $i -le 6; $i++) {
			  # Finding the word STOR which is the status code for stored file in FileZilla and adding it to an array 
			  if($word[$i] -like 'STOR') {
				$msgarray +=(,($word[$i+1],$word[$i-1],$word[$i-2]))	
			  }
			}
		}
	}
		# Setting the value of the line numbers and filename for the next check.
		set-globallines $currlines.lines [REF]$global:line
		write-host $line "er antall linjer"
		#Set-Variable -Name $line -Value $currlines.Lines
		Set-variable -Name $lastfile -Value $fzdir+$fzlog
		send-message
}

function set-globallines ($a, [REF]$b) {
	$b.value = $currlines.Lines
}


function send-message {

	#$postSlackMessage = @{token='toke-here';channel='#compile-bot';text="$file uploaded by $ip to $site";username='via API'}
	#Invoke-RestMethod -Uri https://slack.com/api/chat.postMessage -Body $postSlackMessage
	for($j=0; $j -le $msgarray.GetUpperBound(0); $j++) {
		write-host $msgarray[$j][0] "is uploaded by" $msgarray[$j][1] "with IP:" $msgarray[$j][2]
	}
	$msgarray.Clear()
	# Sleeping for X seconds so not to check all the time
	Start-Sleep -s 10

}

run-forever