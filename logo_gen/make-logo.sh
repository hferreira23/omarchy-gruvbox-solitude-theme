#!/bin/bash
# Regen logo_gen/logo.png (transparent wordmark). Extra args pass through, e.g.:
#   ./make-logo.sh --logo-color '#d65d0e'
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/generate.sh" logo "$@"
