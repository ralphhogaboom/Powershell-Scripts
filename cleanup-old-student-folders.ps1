$scriptName = $MyInvocation.MyCommand.Name
remove-item .\$scriptName.log
start-transcript ".\$scriptName.log"
$tempCSV = ".\$scriptName.csv" 

$targetDir = "D:\StudentFiles"
$backupDir = "D:\StudentFiles.old" # This CANNOT be inside the $targetDir

Import-Module ActiveDirectory

# get first directory
"==============================================================="
"++ Beginning folder read on " + $targetDir + " ..."
Get-ChildItem $targetDir | select name | Export-Csv $tempCSV -NoTypeInformation
"++ .... output to CSV completed."
"==============================================================="

# now import it again
$folders = Import-Csv $tempCSV

ForEach ($studentFolder in $folders) {
	# check if it matches a current student
	if ($studentFolder -ne "Name") {
		# "Now checking " + $studentFolder.name + " for a matching AD account ..."
		Try {
			if (Get-ADUser $studentFolder.name) {
			"  [INFO] " + $studentFolder.name + " exists in AD."
			}
		}
		Catch {
			"  [INFO] " + $studentFolder.name + " was not found in AD."
			# Copy this folder to another location.
			"    [INFO] Attemping to move directory ..."
			If (Move-Item ($targetDir + "\" + $studentFolder.name) $backupDir -ErrorAction SilentlyContinue) {
				"    [SUCCESS] ... directory moved OK."
			} Else {
				"    [WARN] Failed moving. Now trying to change permissions ..."
				
				takeown /F ($targetDir + "\" + $studentFolder.name) /R /D Y
				"    [SUCCESS] ... Permissions changed. Now moving the folder for realsies. Manually check to see if this folder was moved."
				Move-Item ($targetDir + "\" + $studentFolder.name) $backupDir -ErrorAction SilentlyContinue)
			}
		}
	}
}

stop-transcript

# 7989 before in folder.
# now only 4241 as of 9 NOV 2016.