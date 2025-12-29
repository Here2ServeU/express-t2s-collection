#!/bin/bash
# Run API synthetic test

URL=$1

STATUS=$(curl -o /dev/null -s -w "%{http_code}\n" $URL)

if [ $STATUS -ne 200 ]; then
  echo "Synthetic Test FAILED: $STATUS"
  exit 1
fi

echo "Synthetic Test PASSED: $STATUS"