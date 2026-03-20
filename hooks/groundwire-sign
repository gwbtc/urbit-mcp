#!/usr/bin/env bash
#
# groundwire-sign — custom gpg.program for signing git commits with a
# Groundwire key via a remote signing service (an Urbit ship running %vitriol).
#
# Git calls gpg.program with:
#   gpg.program --status-fd=2 -bsau <key-id>
# and pipes the commit object (minus gpgsig) to stdin.
#
# This script:
#   1. Reads the commit content from stdin
#   2. Optionally fetches the maintainer's ecash pubkey and sats-per-pr price
#   3. Sends content (+ sats_required if applicable) to the committer's ship
#   4. Returns a structured signature block on stdout
#   5. Emits GPG-compatible status on fd 2
#
# The signature block includes the signer's @p so the CI verifier can
# look up the identity on-chain via its own ship, rather than trusting
# the committer's self-reported pubkey.
#
# Configuration (git config or env vars):
#   GROUNDWIRE_SIGN_ENDPOINT       — base URL of the committer's ship (e.g. http://localhost:8080/vitriol)
#   GROUNDWIRE_SIGN_TOKEN          — auth cookie for the ship
#   GROUNDWIRE_MAINTAINER_ENDPOINT — (optional) base URL of the maintainer's ship for ecash pubkey
#   GROUNDWIRE_MAINTAINER_TOKEN    — (optional) auth cookie for the maintainer's ship
#
# Install:
#   git config --global gpg.program /path/to/groundwire-sign
#   git config --global commit.gpgsign true
#

set -euo pipefail

# --- Configuration -----------------------------------------------------------

ENDPOINT="${GROUNDWIRE_SIGN_ENDPOINT:-$(git config --get groundwire.sign-endpoint 2>/dev/null || echo "")}"
TOKEN="${GROUNDWIRE_SIGN_TOKEN:-$(git config --get groundwire.sign-token 2>/dev/null || echo "")}"
MAINTAINER_ENDPOINT="${GROUNDWIRE_MAINTAINER_ENDPOINT:-$(git config --get groundwire.maintainer-endpoint 2>/dev/null || echo "")}"
MAINTAINER_TOKEN="${GROUNDWIRE_MAINTAINER_TOKEN:-$(git config --get groundwire.maintainer-token 2>/dev/null || echo "")}"

if [ -z "$ENDPOINT" ]; then
  echo "groundwire-sign: GROUNDWIRE_SIGN_ENDPOINT not set" >&2
  echo "  Set via: git config --global groundwire.sign-endpoint <url>" >&2
  echo "  Or env:  export GROUNDWIRE_SIGN_ENDPOINT=<url>" >&2
  exit 1
fi

# --- Parse git's gpg arguments -----------------------------------------------

STATUS_FD=""
KEY_ID=""

while [ $# -gt 0 ]; do
  case "$1" in
    --status-fd=*)
      STATUS_FD="${1#--status-fd=}"
      ;;
    --status-fd)
      shift
      STATUS_FD="$1"
      ;;
    -bsau)
      shift
      KEY_ID="$1"
      ;;
    *)
      ;;
  esac
  shift
done

# --- Read commit content from stdin -------------------------------------------

COMMIT_CONTENT=$(cat)

# --- Fetch maintainer's ecash pubkey and price (optional) --------------------

ECASH_PUBKEY=""
SATS_REQUIRED=""

if [ -n "$MAINTAINER_ENDPOINT" ]; then
  # Fetch ecash pubkey
  ECASH_RESPONSE=$(curl -s -f \
    -H "Cookie: ${MAINTAINER_TOKEN}" \
    "${MAINTAINER_ENDPOINT}/ecash-pubkey") || {
    echo "groundwire-sign: warning: could not fetch maintainer ecash pubkey" >&2
  }
  if [ -n "$ECASH_RESPONSE" ]; then
    ECASH_CONFIGURED=$(echo "$ECASH_RESPONSE" | jq -r '.configured // empty')
    if [ "$ECASH_CONFIGURED" = "true" ]; then
      ECASH_PUBKEY=$(echo "$ECASH_RESPONSE" | jq -r '.pubkey // empty')
    else
      echo "groundwire-sign: warning: maintainer ecash not configured" >&2
    fi
  fi

  # Fetch sats-per-pr price
  PRICE_RESPONSE=$(curl -s -f \
    -H "Cookie: ${MAINTAINER_TOKEN}" \
    "${MAINTAINER_ENDPOINT}/sats-per-pr") || {
    echo "groundwire-sign: warning: could not fetch maintainer price" >&2
  }
  if [ -n "$PRICE_RESPONSE" ]; then
    PRICE_CONFIGURED=$(echo "$PRICE_RESPONSE" | jq -r '.configured // empty')
    if [ "$PRICE_CONFIGURED" = "true" ]; then
      SATS_REQUIRED=$(echo "$PRICE_RESPONSE" | jq -r '.sats // empty')
    fi
  fi
fi

# --- Send to signing service --------------------------------------------------

PAYLOAD_ARGS=(--arg content "$COMMIT_CONTENT" --arg key_id "$KEY_ID")
PAYLOAD_EXPR='{content: $content, key_id: $key_id'

if [ -n "$SATS_REQUIRED" ] && [ "$SATS_REQUIRED" != "0" ]; then
  PAYLOAD_ARGS+=(--argjson sats "$SATS_REQUIRED")
  PAYLOAD_EXPR+=', sats_required: $sats'
fi

if [ -n "$ECASH_PUBKEY" ]; then
  PAYLOAD_ARGS+=(--arg ecash_pubkey "$ECASH_PUBKEY")
  PAYLOAD_EXPR+=', ecash_pubkey: $ecash_pubkey'
fi

PAYLOAD_EXPR+='}'
PAYLOAD=$(jq -n "${PAYLOAD_ARGS[@]}" "$PAYLOAD_EXPR")

RESPONSE=$(curl -s -f \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Cookie: ${TOKEN}" \
  "${ENDPOINT}/sign" \
  -d "$PAYLOAD") || {
  echo "groundwire-sign: signing service request failed" >&2
  exit 1
}

# Check for error in response (e.g. insufficient balance)
ERROR=$(echo "$RESPONSE" | jq -r '.error // empty')
if [ -n "$ERROR" ]; then
  echo "groundwire-sign: $ERROR" >&2
  exit 1
fi

SIGNATURE=$(echo "$RESPONSE" | jq -r '.signature // empty')
SIGNER_ID=$(echo "$RESPONSE" | jq -r '.signer_id // empty')
PASS=$(echo "$RESPONSE" | jq -r '.pass // empty')
ECASH_AMOUNT=$(echo "$RESPONSE" | jq -r '.ecash_amount // empty')
ECASH_ENCRYPTED=$(echo "$RESPONSE" | jq -r '.ecash_encrypted // empty')
ECASH_CIPHERTEXT=$(echo "$RESPONSE" | jq -r '.ecash_ciphertext // empty')
ECASH_EPH_PUBKEY=$(echo "$RESPONSE" | jq -r '.ecash_ephemeral_pubkey // empty')
ECASH_MAC=$(echo "$RESPONSE" | jq -r '.ecash_mac // empty')
ECASH_TOKENS=$(echo "$RESPONSE" | jq -r '.ecash_tokens // empty')

if [ -z "$SIGNATURE" ]; then
  echo "groundwire-sign: no signature in response" >&2
  exit 1
fi

if [ -z "$SIGNER_ID" ]; then
  echo "groundwire-sign: no signer_id in response" >&2
  exit 1
fi

# --- Output structured signature to stdout ------------------------------------
# Git captures this verbatim as the gpgsig header.
# The CI verifier parses this to extract the signer's @p and signature.

{
  echo "-----BEGIN GROUNDWIRE SIGNATURE-----"
  echo "signer:${SIGNER_ID}"
  echo "pass:${PASS}"
  echo "sig:${SIGNATURE}"
  [ -n "$ECASH_PUBKEY" ] && echo "ecash-pubkey:${ECASH_PUBKEY}"
  if [ -n "$ECASH_AMOUNT" ] && [ "$ECASH_AMOUNT" != "0" ]; then
    echo "ecash-amount:${ECASH_AMOUNT}"
    if [ "$ECASH_ENCRYPTED" = "true" ]; then
      echo "ecash-ciphertext:${ECASH_CIPHERTEXT}"
      echo "ecash-ephemeral-pubkey:${ECASH_EPH_PUBKEY}"
      echo "ecash-mac:${ECASH_MAC}"
    elif [ -n "$ECASH_TOKENS" ] && [ "$ECASH_TOKENS" != "null" ]; then
      echo "ecash-tokens:${ECASH_TOKENS}"
    fi
  fi
  echo "-----END GROUNDWIRE SIGNATURE-----"
}

# --- Emit GPG-compatible status on status-fd ----------------------------------

if [ -n "$STATUS_FD" ]; then
  {
    echo "[GNUPG:] SIG_CREATED D"
    echo "[GNUPG:] BEGIN_SIGNING"
  } >&"$STATUS_FD"
fi
