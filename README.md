# SleepToggle: keep your Mac awake for Claude

A tiny macOS menu bar switch. One click and your MacBook keeps working with the lid closed, so long Claude Code sessions, agents, downloads and servers don't stop.

| Icon | Mode | What happens |
| --- | --- | --- |
| 😳 | AI mode | No sleep (lid closed too), screen never dims, no password lock |
| 💤 | Normal | Regular macOS behaviour; your previous lock settings are restored |

- **Left click:** switch mode.
- **Right click:** menu with status and "Quit".
- Starts at login and checks the state every 5 seconds, so changes made with `pmset` in Terminal show up too.

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/vjvasiljev/mac-sleep-toggle-for-claude/main/install.sh)
```

The installer compiles the app locally with Swift. If Xcode Command Line Tools are missing, it offers to install them; run the command again afterwards. It asks for your Mac password twice:

1. **For `sudo`:** adds a sudoers rule that allows only `pmset -a disablesleep 0/1` without a password.
2. **For the Keychain:** stored under the name `SleepToggle`. macOS changes the screen lock only with the user's password (`sysadminctl -screenLock`).

## Remove

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/vjvasiljev/mac-sleep-toggle-for-claude/main/install.sh) --uninstall
```

Uninstalling restores normal sleep and your previous screen lock delay, then deletes the app, the sudoers rule and the Keychain item.

## Check it works

```bash
pmset -g | grep SleepDisabled
pmset -g assertions | grep SleepToggle
sysadminctl -screenLock status
```

In AI mode 😳 you should see `SleepDisabled 1`, a `PreventUserIdleDisplaySleep named: "SleepToggle"` line, and `screenLock is off`.

## Things to know

- **No password in AI mode:** anyone who opens the lid gets in without a password.
- **Heat in a bag:** the Mac doesn't sleep there either, so it can overheat and drain the battery. Switch to 💤 before packing it.
- **Changed your Mac password?** Run the installer again so the Keychain item matches.
- **Password visibility:** each switch passes the password to `sysadminctl` as an argument, so it is briefly visible in the process list.
- **Hidden icon:** on MacBooks with a notch, the icon can be hidden behind it when the menu bar is full.

## По-русски

Значок в строке меню macOS. В режиме AI mode 😳 Mac работает и с закрытой крышкой: не засыпает, экран не гаснет, пароль не просит. Обычный режим 💤 возвращает обычное поведение macOS и прежние настройки блокировки. Установка и удаление делаются командами выше, интерфейс виджета на русском.

## License

MIT
