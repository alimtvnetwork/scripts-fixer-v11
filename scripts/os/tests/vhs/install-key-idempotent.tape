# vhs tape — Windows install-key idempotency demo
# render: vhs scripts/os/tests/vhs/install-key-idempotent.tape

Output install-key-idempotent.gif

Set Shell "pwsh"
Set FontSize 14
Set Width 1100
Set Height 600
Set Theme "Catppuccin Mocha"
Set TypingSpeed 35ms

Type "# first run — appends the key"
Enter
Type "pwsh scripts/os/run.ps1 install-key --user demo --key-file C:\\demo\\alice.pub --dry-run"
Enter
Sleep 1500ms
Type "# second run — body match, skipped"
Enter
Type "pwsh scripts/os/run.ps1 install-key --user demo --key-file C:\\demo\\alice.pub --dry-run"
Enter
Sleep 2s