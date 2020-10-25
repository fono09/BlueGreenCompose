#!/bin/sh -x

DOCKER_COMPOSE_PATH=$(cat autodeploy.json | jq -r .docker_compose_path)
STARTUP_TIMEOUT=$(cat autodeploy.json | jq -r .startup.timeout)
SHUTDOWN_TIMEOUT=$(cat autodeploy.json | jq -r .shutdown.timeout)
WORKING_SAMPLES=$(cat autodeploy.json | jq -r .working.samples)
WORKING_THRESHOLD=$(cat autodeploy.json | jq -r .working.threshold)
WORKING_TIMEOUT=$(cat autodeploy.json | jq -r .working.timeout)
BLUE_NAME=$(cat autodeploy.json | jq -r .environments.blue.name)
GREEN_NAME=$(cat autodeploy.json | jq -r .environments.green.name)
BLUE=$(docker-compose -f $DOCKER_COMPOSE_PATH ps -q $BLUE_NAME | wc -l)
GREEN=$(docker-compose -f $DOCKER_COMPOSE_PATH ps -q $GREEN_NAME | wc -l)

if [ $BLUE -gt 0 -a $GREEN -gt 0 ]; then
  echo "[ERROR] Blue and green, both environments are running."
  exit 1
elif [ $BLUE -eq 0 -a $GREEN -eq 0 ]; then
  echo "[ERROR] Blue and green, both environments are *not* running."
  exit 1
elif [ $BLUE -gt 0 ]; then
  SHUTDOWN=$BLUE_NAME
  STARTUP=$GREEN_NAME
elif [ $GREEN -gt 0 ]; then
  SHUTDOWN=$GREEN_NAME
  STARTUP=$BLUE_NAME
fi

echo "[INFO] $SHUTDOWN is running."
echo "[INFO] $STARTUP will soon start up."
eval "docker-compose -f $DOCKER_COMPOSE_PATH up -d --build $STARTUP"

WATCH_COUNT=0
HEALTHY_COUNT=0
while [ $HEALTHY_COUNT -le 0 ]; do
  WATCH_COUNT=$((WATCH_COUNT+1))
  if [ $WATCH_COUNT -gt $STARTUP_TIMEOUT ]; then
    echo "[ERROR] $STARTUP did not become healthy."
    exit 1
  fi
  HEALTHY_COUNT=$(docker-compose -f $DOCKER_COMPOSE_PATH ps $STARTUP | grep -v unhealthy | grep -v healthy | wc -l)
  sleep 1
done

WATCH_COUNT=0
WORKING_COUNT=0
while [ $WORKING_COUNT -lt $WORKING_THRESHOLD ]; do
  WATCH_COUNT=$((WATCH_COUNT+1))
  if [ $WATCH_COUNT -gt $WORKING_TIMEOUT ]; then
    echo "[ERROR] $STARTUP did not working."
    exit 1
  fi
  WORKING_COUNT=$(docker-compose -f $DOCKER_COMPOSE_PATH logs --tail $WORKING_SAMPLES $STARTUP | grep -e GET -e POST | wc -l)
done


echo "[INFO] $SHUTDOWN will soon shut down."
docker-compose stop -t $SHUTDOWN_TIMEOUT $SHUTDOWN
if [ $? -ne 0 ]; then
  echo "[ERROR] $SHUTDOWN did not stopped."
  exit 1
fi
docker-compose rm -f $SHUTDOWN
if [ $? -ne 0 ]; then
  echo "[ERROR] $SHUTDOWN did not removed."
  exit 1
fi

echo "[INFO] Deployment completed successfully."
