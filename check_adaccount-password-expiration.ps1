<#
.SYNOPSIS
    Script for checking Active Directory user password expiration.

.DESCRIPTION
    This script checks the expiration status of passwords for Active Directory users.

.AUTHOR
    asysadminstory.fr

.VERSION
    1.0 - Initial version: Check AD user password expiration.

.PARAMETER searchbase
    Specifies the Organizational Unit (OU) to check for user password expiration.

.PARAMETER account
    Specifies one or more user accounts to check for password expiration.

.PARAMETER warning
    Sets the warning threshold for password expiration in days.

.PARAMETER critical
    Sets the critical threshold for password expiration in days.

.PARAMETER help
    Displays the script usage help.

.EXAMPLE
    .\check_password_expiration.ps1 -searchbase "ou=Users,dc=example,dc=com" -warning 10 -critical 5

    Checks password expiration for all users in the specified Organizational Unit.

.EXAMPLE
    .\check_password_expiration.ps1 -account "user1,user2,user3" -warning 7 -critical 3

    Checks password expiration for the specified user accounts.
#>

param (
    [string]$searchbase,
    [string]$account,
    [int]$warning = 10,
    [int]$critical = 5,
    [switch]$help
)

function Show-Help {
    Write-Host "Usage: Check-ADPasswordExpiration.ps1 -searchbase <OU> -account <account1,account2> [-warning <days>] [-critical <days>] [-help]"
}

function Get-PasswordExpiration {
    param (
        [string]$samAccountName
    )

    $user = Get-AdUser -Filter {SamAccountName -eq $samAccountName} -Properties "SamAccountName", "msDS-UserPasswordExpiryTimeComputed", "PasswordNeverExpires"

    if ($user) {
        # Vérifier si le mot de passe n'expire jamais
        if ($user.PasswordNeverExpires) {
            Write-Host "CRITICAL:", $($user.SamAccountName), "has password set to never expire."
            return 2
        }

        $expirationDate = [datetime]::FromFileTime($user."msDS-UserPasswordExpiryTimeComputed")
        $daysRemaining = ($expirationDate - (Get-Date)).Days

        if ($daysRemaining -lt 0) {
            Write-Host "CRITICAL:",$($user.SamAccountName), "is expired for", $($daysRemaining * -1), "days."
            return 2
        } elseif ($daysRemaining -lt $critical) {
            Write-Host "CRITICAL:",$($user.SamAccountName), "will expire in", $daysRemaining, "days."
            return 2
        } elseif ($daysRemaining -lt $warning) {
            Write-Host "WARNING:",$($user.SamAccountName), "will expire in", $daysRemaining, "days."
            return 1
        } else {
            Write-Host "OK:",$($user.SamAccountName), "will expire in", $daysRemaining, "days."
            return 0
        }
    } else {
        Write-Host "UNKNOWN: Account ",$samAccountName, "not found."
        return 3
    }
}

if ($help) {
    Show-Help
    exit 3
}

if (($searchbase -and $account) -or (-not $searchbase -and -not $account)) {
    Write-Host "ERROR: Either --searchbase or --account is required, but not both."
    exit 3
}

if ($account) {
    $accounts = $account -split ","
    $globalStatus = $null

    foreach ($acc in $accounts) {
        $status = Get-PasswordExpiration -samAccountName $acc.Trim()

        # Mettre à jour le statut global en cas de sortie critique ou inconnue
        if ($status -eq 2 -or $status -eq 3) {
            $globalStatus = $status
        }
    }

    # Sortie du statut global après avoir vérifié tous les comptes.
    if ($globalStatus -eq $null) {
        Write-Host "OK: All specified accounts are within expiration thresholds."
        exit 0
    } else {
        exit $globalStatus
    }
} elseif ($searchbase) {
    $users = Get-AdUser -Filter * -SearchBase $searchbase -Properties "SamAccountName", "msDS-UserPasswordExpiryTimeComputed", "PasswordNeverExpires"
    $globalStatus = $null

    foreach ($user in $users) {
        $status = Get-PasswordExpiration -samAccountName $user.SamAccountName

        # Mettre à jour le statut global en cas de sortie critique ou inconnue
        if ($status -eq 2 -or $status -eq 3) {
            $globalStatus = $status
        }
    }

    # Sortie du statut global après avoir vérifié tous les comptes.
    if ($globalStatus -eq $null) {
        Write-Host "OK: All accounts in the specified search base are within expiration thresholds."
        exit 0
    } else {
        exit $globalStatus
    }
} else {
    Write-Host "ERROR: Either --searchbase or --account is required."
    exit 3
}
