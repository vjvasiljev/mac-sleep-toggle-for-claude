#!/bin/bash
# SleepToggle: menu bar switch for macOS.
#   😳 AI mode = no sleep (lid closed too), screen never dims, no password lock
#   💤 Normal mode = normal macOS behaviour (your previous lock settings restored)
# Install:   bash install.sh
# Remove:    bash install.sh --uninstall
set -euo pipefail

APP="$HOME/Applications/SleepToggle.app"
PLIST="$HOME/Library/LaunchAgents/com.local.sleeptoggle.plist"
SUPPORT="$HOME/Library/Application Support/SleepToggle"
SUDOERS="/etc/sudoers.d/sleeptoggle"
LABEL="com.local.sleeptoggle"
DOMAIN="gui/$(id -u)"
ME="$(id -un)"

stop_app() {
  launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
  pkill -x SleepToggle 2>/dev/null || true
}

if [[ "${1:-}" == "--uninstall" ]]; then
  stop_app
  if [[ -f "$SUPPORT/lock" ]]; then
    echo "Restoring your previous screen lock (asks for your Mac password):"
    sysadminctl -screenLock "$(cat "$SUPPORT/lock")" -password - || true
  fi
  rm -rf "$APP" "$SUPPORT"
  rm -f "$PLIST"
  security delete-generic-password -a "$ME" -s SleepToggle >/dev/null 2>&1 || true
  sudo rm -f "$SUDOERS"
  sudo /usr/bin/pmset -a disablesleep 0
  echo "Removed. Normal mode restored."
  exit 0
fi

if ! xcode-select -p >/dev/null 2>&1; then
  xcode-select --install || true
  echo "Install the Command Line Tools in the window that opened, then run this script again."
  exit 1
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cat > "$WORK/main.swift" <<'SWIFT'
import Cocoa
import IOKit.pwr_mgt

final class AppDelegate: NSObject, NSApplicationDelegate {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    var timer: Timer?
    var sleepDisabled = false
    var displayAssertion: IOPMAssertionID = 0
    let lockFile = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/SleepToggle/lock")

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let button = item.button {
            button.target = self
            button.action = #selector(clicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    // Runs a tool and returns its exit code with stdout+stderr combined.
    @discardableResult
    func run(_ path: String, _ args: [String]) -> (status: Int32, output: String) {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = args
        process.standardOutput = pipe
        process.standardError = pipe
        do { try process.run() } catch { return (-1, "") }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus, String(data: data, encoding: .utf8) ?? "")
    }

    // Keeps the screen from dimming while in awake mode.
    func keepDisplayAwake(_ on: Bool) {
        if on && displayAssertion == 0 {
            IOPMAssertionCreateWithName(
                kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                "SleepToggle" as CFString, &displayAssertion)
        } else if !on && displayAssertion != 0 {
            IOPMAssertionRelease(displayAssertion)
            displayAssertion = 0
        }
    }

    func password() -> String? {
        let r = run("/usr/bin/security",
                    ["find-generic-password", "-a", NSUserName(), "-s", "SleepToggle", "-w"])
        let pw = r.output.trimmingCharacters(in: .newlines)
        return r.status == 0 && !pw.isEmpty ? pw : nil
    }

    // Current lock delay as sysadminctl accepts it: "off", "immediate" or seconds.
    func currentLock() -> String {
        let out = run("/usr/sbin/sysadminctl", ["-screenLock", "status"]).output.lowercased()
        if out.contains("is off") { return "off" }
        // Output starts with a timestamp, so take only the number after "delay is".
        if let range = out.range(of: #"delay is \d+"#, options: .regularExpression) {
            return String(out[range].filter(\.isNumber))
        }
        return "immediate"
    }

    func setLock(_ value: String) {
        guard let pw = password() else { return }
        run("/usr/sbin/sysadminctl", ["-screenLock", value, "-password", pw])
    }

    func refresh() {
        let output = run("/usr/bin/pmset", ["-g"]).output
        sleepDisabled = output.split(separator: "\n").contains { line in
            let parts = line.split(whereSeparator: { $0 == " " || $0 == "\t" })
            return parts.count >= 2 && parts[0] == "SleepDisabled" && parts[1] == "1"
        }
        keepDisplayAwake(sleepDisabled)
        item.button?.title = sleepDisabled ? "😳" : "💤"
        item.button?.toolTip = sleepDisabled
            ? "AI mode: no sleep, screen stays on, no password"
            : "Normal mode"
    }

    @objc func toggle() {
        let enable = !sleepDisabled
        let value = enable ? "1" : "0"
        let result = run("/usr/bin/sudo", ["-n", "/usr/bin/pmset", "-a", "disablesleep", value])
        if result.status != 0 {
            let source = "do shell script \"/usr/bin/pmset -a disablesleep \(value)\" with administrator privileges"
            NSAppleScript(source: source)?.executeAndReturnError(nil)
        }
        if enable {
            let lock = currentLock()
            if lock != "off" {
                try? FileManager.default.createDirectory(
                    at: lockFile.deletingLastPathComponent(), withIntermediateDirectories: true)
                try? lock.write(to: lockFile, atomically: true, encoding: .utf8)
            }
            setLock("off")
        } else {
            let saved = (try? String(contentsOf: lockFile, encoding: .utf8))?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            setLock(saved?.isEmpty == false ? saved! : "immediate")
        }
        refresh()
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }

    @objc func clicked() {
        guard NSApp.currentEvent?.type == .rightMouseUp else {
            toggle()
            return
        }
        let menu = NSMenu()
        menu.autoenablesItems = false
        let status = NSMenuItem(
            title: sleepDisabled ? "😳 AI mode: no sleep, screen stays on, no password" : "💤 Normal mode",
            action: nil, keyEquivalent: "")
        status.isEnabled = false
        menu.addItem(status)
        menu.addItem(.separator())
        let change = NSMenuItem(
            title: sleepDisabled ? "Switch to Normal mode" : "Switch to AI mode",
            action: #selector(toggle), keyEquivalent: "")
        change.target = self
        menu.addItem(change)
        let exit = NSMenuItem(title: "Quit SleepToggle", action: #selector(quit), keyEquivalent: "")
        exit.target = self
        menu.addItem(exit)
        item.menu = menu
        item.button?.performClick(nil)
        item.menu = nil
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
SWIFT

echo "Compiling..."
stop_app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$HOME/Library/LaunchAgents" "$SUPPORT"
swiftc -O "$WORK/main.swift" -o "$APP/Contents/MacOS/SleepToggle" -framework Cocoa -framework IOKit

cat > "$APP/Contents/Info.plist" <<'PLISTEOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>SleepToggle</string>
  <key>CFBundleIdentifier</key><string>com.local.sleeptoggle</string>
  <key>CFBundleExecutable</key><string>SleepToggle</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>2.4</string>
  <key>LSUIElement</key><true/>
</dict>
</plist>
PLISTEOF
codesign --force --sign - "$APP" >/dev/null 2>&1 || true

# Allows only these two exact pmset commands without a password.
echo "Your Mac password for sudo, once, so switching modes never asks again."
RULE="$WORK/sudoers"
echo "$ME ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1" > "$RULE"
/usr/sbin/visudo -cf "$RULE" >/dev/null
sudo /usr/bin/install -m 440 -o root -g wheel "$RULE" "$SUDOERS"

# macOS changes the screen lock only with the user's password, so keep it in Keychain.
echo
read -r -s -p "Your Mac password again (saved in Keychain; macOS needs it to turn the screen lock off): " PW
echo
if ! dscl . -authonly "$ME" "$PW" >/dev/null 2>&1; then
  echo "Wrong password. Run the installer again."
  exit 1
fi
security add-generic-password -U -a "$ME" -s SleepToggle -w "$PW"
unset PW

cat > "$PLIST" <<PLISTEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array><string>$APP/Contents/MacOS/SleepToggle</string></array>
  <key>RunAtLoad</key><true/>
  <!-- Restart after a crash; "Quit" from the menu exits 0 and stays closed. -->
  <key>KeepAlive</key><dict><key>SuccessfulExit</key><false/></dict>
</dict>
</plist>
PLISTEOF
launchctl bootstrap "$DOMAIN" "$PLIST"

echo "Done. 😳 = AI mode (no sleep, screen stays on, no password). 💤 = Normal mode."
echo "If the icon already shows 😳, click it twice (to 💤 and back) to turn the screen lock off."
