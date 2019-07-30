################################################################################
## This script requires an encrypted password be setup. To configure
## the encrypted password, run the following command under the same
## user account as the scheduled script will run under:
##          Read-Host -Prompt Password -AsSecureString | ConvertFrom-SecureString | Out-File $env:userprofile\o365securestring.txt 
    $adminAccount = "whatever@fqdn.tld"
    $smtpServer = "mail.fqdn.tld"
    $emailNotify = "ralphhogaboom@fqdn.tld"
    $mailboxServer = "mb01.fqdn.tld"
#
$scriptName = ($MyInvocation.MyCommand.Name).Replace(".ps1","")
$scriptVersion = "12"
$logFileName = $PSScriptRoot + "\" + $scriptName + ".log"
remove-item $logFileName -ErrorAction SilentlyContinue
Start-Transcript $logFileName

$Pass = cat $env:userprofile\o365securestring.txt | convertto-securestring
$UserCredential = New-Object System.Management.Automation.PSCredential -ArgumentList $adminAccount, $Pass
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$mailboxServer/PowerShell/ -Authentication Kerberos -Credential $UserCredential
Import-PSSession $Session

$domains = Get-AcceptedDomain
$mailboxes = Get-Mailbox -ResultSize Unlimited

$emailBody = $null

foreach ($mailbox in $mailboxes) {

    $forwardingRules = $null
    Write-Host "Checking rules for $($mailbox.displayname) - $($mailbox.primarysmtpaddress)" -foregroundColor Green
    $rules = get-inboxrule -Mailbox $mailbox.primarysmtpaddress
    
    $forwardingRules = $rules | Where-Object {$_.forwardto -or $_.forwardasattachmentto}

    foreach ($rule in $forwardingRules) {
        $recipients = @()
        $recipients = $rule.ForwardTo | Where-Object {$_ -match "SMTP"}
        $recipients += $rule.ForwardAsAttachmentTo | Where-Object {$_ -match "SMTP"}
    
        $externalRecipients = @()

        foreach ($recipient in $recipients) {
            $email = ($recipient -split "SMTP:")[1].Trim("]")
            $domain = ($email -split "@")[1]

            if ($domains.DomainName -notcontains $domain) {
                $externalRecipients += $email
            }    
        }

        if ($externalRecipients) {
            if ($($rule.name) -eq 'My name is in the To or Cc box' -and $($mailbox.displayname) -eq "Ralph Hogaboom") {
                # do nothing, etc. Add more with ElseIf to filter out known forwarders. Obv this only works in smaller institutions.
            } else {
                # finally, new stuff
                $extRecString = $externalRecipients -join ", "
                Write-Host "$($rule.Name) forwards to $extRecString" -ForegroundColor Yellow
                $emailBody += "$($rule.Name) forwards to $extRecString for mailbox $($mailbox.displayname) - $($mailbox.primarysmtpaddress) `r`n"
    
                $ruleHash = $null
                $ruleHash = [ordered]@{
                    PrimarySmtpAddress = $mailbox.PrimarySmtpAddress
                    DisplayName        = $mailbox.DisplayName
                    RuleId             = $rule.Identity
                    RuleName           = $rule.Name
                    RuleDescription    = $rule.Description
                    ExternalRecipients = $extRecString
                }
                $ruleObject = New-Object PSObject -Property $ruleHash
                $ruleObject | Export-Csv c:\users\ralph.hogaboom\externalrules.csv -NoTypeInformation -Append
            }
        }
    }
}

if ($emailBody.length -gt 0) {
    send-mailmessage -from $emailNotify -to $emailNotify -subject "Suspicious rules found in mailbox in On Prem exchange server" -body $emailBody -SmtpServer $smtpServer
}

Stop-Transcript
