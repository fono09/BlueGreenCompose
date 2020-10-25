while true; do
  curl -v -H "Host: hello.world.local" nginx:80 &
  sleep 1
done
