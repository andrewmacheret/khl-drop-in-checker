# khl-drop-in-checker

[![License](https://img.shields.io/badge/license-MIT-lightgray.svg)](https://github.com/andrewmacheret/khl-drop-in-checker/blob/main/LICENSE.md)

Get a phone notification (and optionally an email) when the Kraken Hockey League (KHL) season list changes, so you
can sign up as soon as a new season opens.

Once a day, `check.sh` asks the [DaySmart Recreation](https://www.daysmartrecreation.com/) API for the Kraken's KHL
seasons with online registration enabled, compares their names with the previous run, and if any were added or removed
sends the difference to an [ntfy](https://ntfy.sh) topic:

```
+Fall 2027 Season
-Drop-in Sept/Oct 2026
```

## Prereqs

* bash, [curl](https://curl.se), [jq](https://jqlang.org) and diff
* cron, to run it daily
* The [ntfy app](https://ntfy.sh/#subscribe-phone) (or the [web app](https://ntfy.sh/app)), for push notifications
* Optional: [msmtp](https://marlam.de/msmtp/) set up to send mail (e.g. through Gmail with an app password), for emails

On Debian/Ubuntu: `sudo apt install curl jq msmtp`

## Setup

1. Clone the repo:

   ```
   git clone https://github.com/andrewmacheret/khl-drop-in-checker.git ~/khl-drop-in-checker
   cd ~/khl-drop-in-checker
   ```

2. Create `config.env` from the example and edit it:

   ```
   cp config.env.example config.env
   ```

   * `NTFY_TOPIC`: pick a long, random topic name. ntfy topics are public, so anyone who knows the name can read it.
   * `EMAIL_TO`: optional address to email each change to, sent with `msmtp -t`. Leave blank for push only.

3. Subscribe to your `NTFY_TOPIC` in the ntfy app.

4. Run it once to record the current seasons in `seasons_cache.txt`:

   ```
   ./check.sh
   ```

5. Add a daily cron job (`crontab -e`), e.g. every day at 9 AM:

   ```
   0 9 * * * /usr/bin/bash /home/YOU/khl-drop-in-checker/check.sh >> /home/YOU/khl-drop-in-checker/check.log 2>&1
   ```

## Test a notification

Add a fake season to the cache and run the check. It reports the fake season as removed, sends the notification,
and rewrites the cache with the real list:

```
echo "Mock season" >> seasons_cache.txt
./check.sh
```

## Files

* `check.sh`: the check
* `config.env`: your topic and email (git-ignored)
* `seasons_cache.txt`: season names from the last run (git-ignored)
* `check.log`: output from cron, if you use the line above (git-ignored)

## Notes

* The API query only includes seasons whose sign-up ends on or after 2026-08-02 (`filter[signup_end__gte]` in
  `API_URL`). Seasons whose sign-up ended before then are ignored.
* If the API returns nothing (network error or outage), the check logs a warning, exits non-zero and leaves the cache
  alone.
