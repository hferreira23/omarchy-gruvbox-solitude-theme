#!/bin/bash
# Regen ../preview-unlock.png via `omarchy plymouth preview`
# (opens the result in imv for review).
# Extra args pass through, e.g.: ./make-preview.sh -b '#1d2021' -t '#ebdbb2'
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/generate.sh" preview "$@"
