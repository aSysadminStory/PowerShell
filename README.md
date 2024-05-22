# PowerShell
PowerShell Active Directory Account Password Expiration usage with Centreon

Check by account :

```
.\check_password_expiration.ps1 -account "user1,user2,user3" -warning 7 -critical 3
```

Check by OU :

```
.\check_password_expiration.ps1 -searchbase "ou=Users,dc=example,dc=com" -warning 10 -critical 5
```

Example :

```
.\check_password_expiration.ps1 -account "xxxx,centreon,xxxxx,xxxxx,xxxxx,sysprep,xxxxx,xxxxx,test1"
CRITICAL: xxxxx has password set to never expire.
OK: centreon will expire in 180 days.
OK: xxxxx will expire in 175 days.
OK: xxxxx will expire in 179 days.
CRITICAL: xxxxx will expire in 2 days.
OK: sysprep will expire in 179 days.
CRITICAL: xxxxx has password set to never expire.
CRITICAL: xxxxx has password set to never expire.
CRITICAL: xxxxx has password set to never expire.
UNKNOWN: Account  test1 not found.
```

Monitoring with Centreon and NSClient:  [asysadminstory.fr](https://asysadminstory.fr/powershell-superviser-lexpiration-des-mots-de-passe-centreon)
