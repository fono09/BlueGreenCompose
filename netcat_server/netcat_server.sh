#!/bin/sh

while true; do
  (echo "HTTP/1.0 200 Ok"; echo; echo "Hello World") | nc -l 8080;
  if [ $? -ne 0 ]; then
    break
  fi
done
