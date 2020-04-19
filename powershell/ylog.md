### As admin

```
Set-ExecutionPolicy AllSigned
```

```
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
```

```
choco install ConEmu
```

```
Install-Module -Name PowerShellGet -Force -SkipPublisherCheck
```

```
Install-Module posh-git -Scope CurrentUser
Install-Module oh-my-posh -Scope CurrentUser
Set-Prompt
Set-Theme Robbyrussell
```

Install Cascadia fonts
https://github.com/microsoft/cascadia-code


Editing the $PROFILE doc with the content of `profile.ps1`.
```
code $PROFILE
```

Restarting terminals.

Problems while openning new session, this code fixes it.
```
Set-ExecutionPolicy RemoteSigned
``` 


(this, in powershell admin, no windows-terminal)
```
powershell -noprofile -command "Install-Module PSReadLine -Force -SkipPublisherCheck -AllowPrerelease"
```


