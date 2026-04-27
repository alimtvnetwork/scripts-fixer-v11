# vhs tape — interactive add-user with --ask prompts
# render: vhs scripts-linux/68-user-mgmt/tests/vhs/add-user-ask.tape

Output add-user-ask.gif

Set FontSize 14
Set Width 1100
Set Height 540
Set Theme "Catppuccin Mocha"
Set TypingSpeed 40ms

Type "bash scripts-linux/68-user-mgmt/add-user.sh --ask --dry-run"
Enter
Sleep 600ms
Type "demo-user"
Enter
Sleep 400ms
Type "demo passphrase"
Enter
Sleep 400ms
Type "Demo Account (vhs)"
Enter
Sleep 400ms
Type "y"
Enter
Sleep 2s