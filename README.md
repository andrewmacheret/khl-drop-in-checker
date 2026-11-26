# check-khl-seasons

Daily GitHub Actions job that watches the Kraken Hockey League (DaySmart) season list and sends an
[ntfy](https://ntfy.sh) push when seasons are added or removed.

- `check.sh` fetches the season names, diffs them against `seasons_cache.txt`, and notifies on changes.
- The workflow commits the updated `seasons_cache.txt` back to the repo.
- Secret `NTFY_TOPIC`: the ntfy topic to publish to.
- Secret `NTFY_EMAIL` (optional): ntfy.sh also emails each notification here.
- Run manually: Actions → Check KHL seasons → Run workflow.
