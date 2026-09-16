#!/usr/bin/env bash
# Rebuilds fail-after-delay.jar. The jar is committed so the cloud compiler never needs a
# JBang/Maven toolchain; run this only when FailAfterDelay.java changes.
set -euo pipefail

cd "$(dirname "$0")"

FLINK_VERSION=${FLINK_VERSION:-2.2.0}
CP=$(find ~/.m2/repository/org/apache/flink -name "flink-table-common-${FLINK_VERSION}.jar" \
  -o -name "flink-core-api-${FLINK_VERSION}.jar" \
  -o -name "flink-annotations-${FLINK_VERSION}.jar" | tr '\n' ':')

rm -rf target
mkdir -p target/classes/META-INF/services

javac --release 17 -cp "$CP" -d target/classes ./*.java
for f in ./*.java; do
  echo "com.datasqrl.testjobs.$(basename "$f" .java)"
done > target/classes/META-INF/services/org.apache.flink.table.functions.ScalarFunction

jar --create --file fail-after-delay.jar -C target/classes .
rm -rf target
echo "built fail-after-delay.jar"
