#!/bin/sh
echo "Starting traffic generator..."
while true; do
  curl -s http://express-service:8080/checkout
  echo ""
  sleep 1
done
