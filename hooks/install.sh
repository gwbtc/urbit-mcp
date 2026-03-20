#!/usr/bin/env bash
#
# Install Groundwire commit signing.
#
# Usage:
#   ./install.sh <ship-url> [auth-cookie] [--maintainer <url> [cookie]]
#
# This configures git globally to sign all commits with your Groundwire key.
# Your ship must be running the %vitriol agent with a signing key configured.
#
# When --maintainer is provided, the signing hook will fetch the maintainer's
# ecash pubkey and sats-per-PR price. If a price is set, ecash tokens from
# the committer's wallet are automatically included in the signature.
#
# Example:
#   ./install.sh http://localhost:8080/vitriol "urbauth-~zod=0v5.abc..."
#   ./install.sh http://localhost:8080/vitriol "urbauth-~zod=0v5.abc..." \
#     --maintainer http://maintainer:8080/vitriol "urbauth-~nec=0v5.xyz..."
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SIGN_PROGRAM="${SCRIPT_DIR}/groundwire-sign"

if [ $# -lt 1 ]; then
  echo "Usage: $0 <ship-url> [auth-cookie]"
  echo ""
  echo "  ship-url     Base URL of your ship's vitriol endpoint (e.g. http://localhost:8080/vitriol)"
  echo "  auth-cookie  Auth cookie for your ship (e.g. urbauth-~zod=0v5.abc...)"
  exit 1
fi

ENDPOINT="$1"
TOKEN="${2:-}"

# Parse optional --maintainer flag
MAINTAINER_ENDPOINT=""
MAINTAINER_TOKEN=""
shift; shift 2>/dev/null || true
while [ $# -gt 0 ]; do
  case "$1" in
    --maintainer)
      shift
      MAINTAINER_ENDPOINT="${1:-}"
      shift 2>/dev/null || true
      # Next arg is maintainer token if it doesn't start with --
      if [ $# -gt 0 ] && [[ "$1" != --* ]]; then
        MAINTAINER_TOKEN="$1"
        shift
      fi
      ;;
    *)
      shift
      ;;
  esac
done

chmod +x "$SIGN_PROGRAM"

git config --global gpg.program "$SIGN_PROGRAM"
git config --global commit.gpgsign true
git config --global groundwire.sign-endpoint "$ENDPOINT"

if [ -n "$TOKEN" ]; then
  git config --global groundwire.sign-token "$TOKEN"
fi

if [ -n "$MAINTAINER_ENDPOINT" ]; then
  git config --global groundwire.maintainer-endpoint "$MAINTAINER_ENDPOINT"
  echo "  groundwire.maintainer-endpoint: $MAINTAINER_ENDPOINT"
  if [ -n "$MAINTAINER_TOKEN" ]; then
    git config --global groundwire.maintainer-token "$MAINTAINER_TOKEN"
  fi
fi

echo "Groundwire commit signing configured."
echo "  gpg.program:              $SIGN_PROGRAM"
echo "  groundwire.sign-endpoint: $ENDPOINT"
echo "  commit.gpgsign:           true"
if [ -n "$MAINTAINER_ENDPOINT" ]; then
  echo "  groundwire.maintainer-endpoint: $MAINTAINER_ENDPOINT"
fi
echo ""
echo "All future commits will be signed with your Groundwire key."
