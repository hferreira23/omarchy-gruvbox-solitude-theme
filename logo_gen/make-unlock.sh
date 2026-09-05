#!/bin/bash
# Regen ../unlock.png from logo_gen/logo.png (builds the logo first if missing).
# Extra args pass through, e.g.: ./make-unlock.sh --logo-color '#d65d0e'
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/generate.sh" unlock "$@"
