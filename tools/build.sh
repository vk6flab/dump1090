#!/bin/bash

# Build the image
docker build -t vk6flab/plutosdr-dump1090 . || exit 1

# Extract the binary we built
container_id=$(docker create vk6flab/plutosdr-dump1090)
docker cp $container_id:/plutosdr/dump1090/dump1090 dump1090
docker rm $container_id

# Copy our binary to the pluto
scp dump1090 root@pluto.local:/root
