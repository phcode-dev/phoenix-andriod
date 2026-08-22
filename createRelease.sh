#!/usr/bin/env bash
#
# Builds a signed Play Store bundle for the Phoenix Code TWA.
#
# Put the upload keystore at the path below (it is gitignored), run this, type the password when
# asked, and upload the .aab it prints. The password is only ever held in this shell's memory: it is
# never written to disk, never passed as a command line argument where `ps` could read it, and never
# echoed back to the terminal.
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

KEYSTORE="${PHCODE_KEYSTORE_FILE:-$REPO_DIR/android.keystore}"
KEY_ALIAS="${PHCODE_KEY_ALIAS:-android}"
BUNDLE="$REPO_DIR/app/build/outputs/bundle/release/app-release.aab"

fail() { printf '\nERROR: %s\n' "$1" >&2; exit 1; }

# --- Java -------------------------------------------------------------------------------------
# Android Studio's bundled JBR is Java 25, which this Gradle/AGP pair does not support. Pick a JDK
# they do: 17 through 21.
if [[ -z "${JAVA_HOME:-}" ]] || ! "$JAVA_HOME/bin/java" -version 2>&1 | grep -qE '"(17|21)\.'; then
    for candidate in /usr/lib/jvm/java-21-openjdk-amd64 /usr/lib/jvm/java-17-openjdk-amd64; do
        if [[ -x "$candidate/bin/java" ]]; then
            export JAVA_HOME="$candidate"
            break
        fi
    done
fi
[[ -x "${JAVA_HOME:-}/bin/java" ]] || fail "No JDK 17 or 21 found. Install one, or set JAVA_HOME."
echo "Using JDK: $("$JAVA_HOME/bin/java" -version 2>&1 | head -1)"

# --- Keystore ---------------------------------------------------------------------------------
[[ -f "$KEYSTORE" ]] || fail "Keystore not found at $KEYSTORE
Copy your Play upload keystore there (it is gitignored), or set PHCODE_KEYSTORE_FILE."

echo "Keystore:    $KEYSTORE"
echo "Key alias:   $KEY_ALIAS"
echo "Version:     versionCode $(grep -oP 'versionCode \K[0-9]+' app/build.gradle) / targetSdk $(grep -oP 'targetSdkVersion \K[0-9]+' app/build.gradle)"
echo

# -s keeps it off the screen, -r stops backslashes being eaten.
read -rsp "Keystore password: " PHCODE_KEYSTORE_PASSWORD; echo
[[ -n "$PHCODE_KEYSTORE_PASSWORD" ]] || fail "No password entered."
read -rsp "Key password (blank if same as keystore): " PHCODE_KEY_PASSWORD; echo
PHCODE_KEY_PASSWORD="${PHCODE_KEY_PASSWORD:-$PHCODE_KEYSTORE_PASSWORD}"

# Make sure the password is right before spending a couple of minutes on a build that would then
# fail at the very last step.
if ! "$JAVA_HOME/bin/keytool" -list -keystore "$KEYSTORE" -alias "$KEY_ALIAS" \
        -storepass "$PHCODE_KEYSTORE_PASSWORD" >/dev/null 2>&1; then
    fail "Could not open '$KEY_ALIAS' in the keystore. Wrong password, or wrong alias."
fi
echo "Keystore unlocked, alias '$KEY_ALIAS' found."

export PHCODE_KEYSTORE_FILE="$KEYSTORE"
export PHCODE_KEY_ALIAS="$KEY_ALIAS"
export PHCODE_KEYSTORE_PASSWORD PHCODE_KEY_PASSWORD
# Clear the secrets from the environment however this script exits.
trap 'unset PHCODE_KEYSTORE_PASSWORD PHCODE_KEY_PASSWORD' EXIT

# --- Build ------------------------------------------------------------------------------------
echo
echo "Building release bundle..."
rm -f "$BUNDLE"
./gradlew clean bundleRelease

[[ -f "$BUNDLE" ]] || fail "Build finished but no bundle at $BUNDLE"

# --- Verify -----------------------------------------------------------------------------------
# The Gradle config falls back to producing an UNSIGNED bundle rather than failing, so confirm the
# artifact really is signed instead of trusting that it is.
if ! "$JAVA_HOME/bin/jarsigner" -verify "$BUNDLE" >/dev/null 2>&1; then
    fail "The bundle was produced but is NOT signed. Do not upload it."
fi

echo
echo "Signed bundle ready:"
echo "  $BUNDLE"
echo "  $(du -h "$BUNDLE" | cut -f1)"
echo
echo "Upload it at https://play.google.com/console -> Production -> Create new release."
