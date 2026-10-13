#!/usr/bin/env bash
# Run Flutter with a full supported JDK, scoped to this command.
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ -n "${VI_NHO_JAVA_HOME:-}" ]]; then
  export JAVA_HOME="$VI_NHO_JAVA_HOME"
elif [[ -x .tools/jdk21/bin/javac ]]; then
  export JAVA_HOME="$PWD/.tools/jdk21"
elif [[ -x /usr/lib/jvm/java-21-openjdk-amd64/bin/javac ]]; then
  export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
fi
if [[ -n "${JAVA_HOME:-}" ]]; then
  export PATH="$JAVA_HOME/bin:$PATH"
fi
if ! command -v javac >/dev/null; then
  echo 'Cần JDK đầy đủ, không chỉ JRE. Linux x64: python3 tool/setup_jdk21.py'
  exit 1
fi
VI_NHO_JAVA_MAJOR="$(java -version 2>&1 | sed -n '1s/.*version "\([0-9]*\).*/\1/p')"
if [[ -z "$VI_NHO_JAVA_MAJOR" || "$VI_NHO_JAVA_MAJOR" -lt 17 || "$VI_NHO_JAVA_MAJOR" -gt 24 ]]; then
  echo 'Gradle 8.14.3 cần JDK 17-24; ưu tiên JDK 21. Linux x64: python3 tool/setup_jdk21.py'
  exit 1
fi
exec flutter "$@"
