#!/usr/bin/env bash
set -e

# --- CONFIGURATION ---
DIR="$(dirname "$0")"
CONFIG_FILE="$DIR/config.env"
CACHE_FILE="$DIR/seasons_cache.txt"
API_URL='https://api.daysmartrecreation.com/v1/seasons?cache\[save\]=false&include=leagues&fields\[season\]=name%2Cid&page\[size\]=100&filter\[signup_end__gte\]=2026-08-02&filter\[online_registration_enabled\]=true&filter\[or.leagues.program_id\]=6&company=kraken'

# NTFY_TOPIC (required) and EMAIL_TO (optional) come from config.env
if [ -f "$CONFIG_FILE" ]; then
    # shellcheck source=/dev/null
    . "$CONFIG_FILE"
fi
TOPIC="${NTFY_TOPIC:?NTFY_TOPIC must be set in $CONFIG_FILE}"

# 1. Fetch current API output and sort it for clean line-by-line comparison
CURRENT_DATA=$(curl -s "$API_URL" | jq -r '.data[] | .attributes.name' | sort)

# Check if curl/jq returned empty output (e.g., network error or API down)
if [ -z "$CURRENT_DATA" ]; then
    echo "$(date): Warning: API returned no data. Skipping check."
    exit 1
fi

# 2. If no cache file exists, create it on first run and exit
if [ ! -f "$CACHE_FILE" ]; then
    echo "$CURRENT_DATA" > "$CACHE_FILE"
    echo "$(date): Initial cache created."
    exit 0
fi

# 3. Compare current data with cached data using diff
# -u provides unified diff format; tail skips the file header lines
DIFF_OUTPUT=$(diff -u "$CACHE_FILE" <(echo "$CURRENT_DATA") | tail -n +3)

# 4. If diff is non-empty, parse changes and send notification
if [ -n "$DIFF_OUTPUT" ]; then
    echo "$(date): Change detected!"

    # Format output: extract only added (+) and removed (-) lines
    # Ignore lines that start with '+++' or '---'
    FORMATTED_CHANGES=$(echo "$DIFF_OUTPUT" | grep -E '^[+-]' | grep -vE '^(---|\+\+\+)')

    # Send push notification via ntfy
    curl -s \
        -H "Title: KHL Seasons Changed" \
        -H "Tags: hockey,memo" \
        -d "$FORMATTED_CHANGES" \
        "https://ntfy.sh/$TOPIC"
    echo

    # Send an email copy via msmtp
    if [ -n "${EMAIL_TO:-}" ]; then
        if printf 'To: %s\nSubject: KHL Seasons Changed\n\n%s\n' "$EMAIL_TO" "$FORMATTED_CHANGES" | msmtp -t; then
            echo "$(date): Email sent to $EMAIL_TO."
        else
            echo "$(date): Warning: email to $EMAIL_TO failed."
        fi
    fi

    # Update cache file with new data
    echo "$CURRENT_DATA" > "$CACHE_FILE"
else
    echo "$(date): No changes detected."
fi
