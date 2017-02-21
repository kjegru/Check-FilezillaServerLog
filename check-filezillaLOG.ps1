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
  Purpose/Change: Divided the different jobs into function and sent the new files noticed upload in one message.
  
.EXAMPLE
  <Example goes here. Repeat this attribute for more than one example>
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Log location
$fzdir = 'C:\Program Files (x86)\FileZilla Server\Logs\'
$line = 0
$lastfile = ''
$counter = 0

#-----------------------------------------------------------[Functions]------------------------------------------------------------
function reset-linecount {
	write-host "checking if the file is new"
	if($lastfile -like '' -or $fzlog -notlike $lastfile) {
			Write-Host 'New file. Reset line counter'
			$line = 0
	}	
}

function set-lastfile {
	$lastfile = $fzlog
	return $lastfile
}

function find-logfilesize {
	Write-Host 'Checking logfile'
	Write-Host "Number of lines when last checked $line"  

	# Finding the line number of the file
	$currlines = Get-Content $fzdir$fzlog | Measure-Object -Line
	Write-Host 'Number of lines in file: ' $currlines.Lines
	return $currlines
	
}

function check-lineschanged {
	# Checking if number of lines has changed
	if($currlines.Lines -gt $line) {
		# If number of lines is more than last time - check the newest lines
		(Get-Content (Get-Item $fzdir$fzlog))[$line .. $currlines.Lines]| foreach {
			$word = $_.split(' ')
			# For loop through the line as it seems different powershell versions has different ways of counting the list. It should not be less than 7 words into the sentence.
			for($i=0; $i -le 6; $i++) {
			  # Finding the word STOR which is the status code for stored file in FileZilla and adding it to an list 
			  if($word[$i] -like 'STOR') {
				#$msglist +=(,($word[$i+1]," is uploaded by ",$word[$i-1]," with IP: ",$word[$i-2]))	
				$msglist +=($word[$i+1]+" is uploaded by "+$word[$i-1]+" with IP: "+$word[$i-2]+"`n")	
			  }
			}
		}
	}
		# Setting the value of the line numbers and filename for the next check.
		return $msglist
}

function return-multiple {
	$line = $args[0]
	$msglist = $args[1]
}

function send-message {	
	if($msglist -notlike $null){
		#$postSlackMessage = @{token="notoken4ugetyerown";channel='compile-bot';as_user="false";icon_url="icon url";text=$msglist;username="jian-yang"}
		#Invoke-RestMethod -Uri https://slack.com/api/chat.postMessage -Body $postSlackMessage
		# Clearing the list
		write-host $msglist
	}
	# Sleeping for X seconds so not to check all the time
	Start-Sleep -s 5
}

while ($true) {
	# Finding last changed logfile
	$fzlog = Get-ChildItem $fzdir | Where-Object { ! $_.PSIsContainer } | Sort-Object lastwriteTime | Select-Object -last 1
	# Doing the jobs
	$line = reset-linecount
	$lastfile = set-lastfile
	$currlines = find-logfilesize
	$msglist = check-lineschanged
	# Setting the line number for the next recursion and sending the array
	$line = $currlines.Lines
	send-message
	# Clearing the array
	clear-variable -Name "msglist"
}

