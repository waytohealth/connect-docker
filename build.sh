#!/bin/sh -e
. $(dirname $0)/../.config

readonly TAGDATE="${TAGDATE:-$(date +%Y%m%d.%H%M%S)}"

${docker} build -t mirth:latest .
${docker} tag mirth:latest "mirth:${TAGDATE}"
