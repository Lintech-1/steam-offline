# Steam Offline Mode Manager

A Lua program for managing offline mode of Steam accounts.

**English** - [Русский](README-RU.md)

## Description

This program allows you to easily switch offline mode for various Steam accounts by editing the `loginusers.vdf` file. The program automatically finds the Steam configuration file, shows a list of all accounts, and allows you to choose which account to enable or disable offline mode for.

## Features

- 🔍 Automatic Steam account detection
- 🎨 Colored terminal interface
- ⚡ Quick offline mode switching
- 🔒 Safe VDF file editing
- 📝 Current status display for each account

## Requirements

- Lua interpreter
- Steam installed in standard directory (other paths may be added in the future)

## Installation

1. Clone the repository or download the `steam_offline_manager.lua` file
2. Make sure you have Lua installed:
   ```bash
   lua -v
   ```
3. Make the file executable:
   ```bash
   chmod +x steam_offline_manager.lua
   ```

## Usage

Run the program from terminal:

```bash
lua steam_offline_manager.lua
```

or like this:

```bash
./steam_offline_manager.lua
```

### Program Interface

1. **Account List**: The program will show all found Steam accounts with current offline mode status
2. **Account Selection**: Enter the account number to change settings
3. **Mode Switching**: Choose action to enable/disable offline mode
4. **Exit**: Enter `0` to exit the program

### Example Output

```
Select language / Выберите язык:
[1] English
[2] Русский

Select/Выберите (1-2): 1

Reading file: /home/kotoko/.local/share/Steam/config/loginusers.vdf
Checking backup...
Backup created: /home/kotoko/.local/share/Steam/config/loginusers.vdf.backup

=== Steam Accounts List ===
[1] MyAccount 1
    Offline mode: DISABLED
[2] MyAccount 2
    Offline mode: DISABLED

[0] Exit

Select account (0 to exit): 1

User: MyAccount 1
Offline mode currently: disabled

[1] enable offline mode
[0] Back

Select action: 1

✓ Offline mode for 'MyAccount 1' enabled

Press Enter to continue...

=== Steam Accounts List ===
[1] MyAccount 1
    Offline mode: ENABLED
[2] MyAccount 1
    Offline mode: DISABLED

[0] Exit

Select account (0 to exit): 0
Exiting program
```

## Security

- The program creates a backup of the original file before making changes
- Checks VDF structure integrity
- Handles file read/write errors

## File Structure

The program works with the `~/.local/share/Steam/config/loginusers.vdf` file, which has the following structure:

```vdf
"users"
{
    "USER_ID"
    {
        "AccountName"       "username"
        "PersonaName"       "Display Name"
        "RememberPassword"  "1"
        "WantsOfflineMode"  "0"  // <- This value is changed
        "SkipOfflineModeWarning" "0"
        "AllowAutoLogin"    "1"
        "MostRecent"        "1"
        "Timestamp"         "1234567890"
    }
}
```

## Support

If you encounter problems, create an issue in the repository or check:

1. Is Steam installed
2. Does the file `~/.local/share/Steam/config/loginusers.vdf` exist
3. Do you have read/write permissions for the file 