
========================================
#install virtualbox
https://www.virtualbox.org/wiki/Downloads

#Start 3 vms
docker-machine create vm1

docker-machine create vm2
docker-machine create vm3

#setup vm1 as master
docker-machine ssh vm1
docker swarm init --advertise-addr 192.168.99.100
#Activate the Manager so worker nodes can join
eval $(docker-machine env vm1)
docker-machine active

#setup vm2,vm3 as workers
docker-machine ssh vm2
docker swarm join --token SWMTKN-1-5ft6k0wizhroo68aao6wgopkub6q2ugfsitzi7pwo0qqoo0kfm-41znbc1eiu6ht0qv6s7vro3bh 192.168.65.3:2377

docker-machine ssh vm3
docker swarm join --token SWMTKN-1-5ft6k0wizhroo68aao6wgopkub6q2ugfsitzi7pwo0qqoo0kfm-41znbc1eiu6ht0qv6s7vro3bh 192.168.65.3:2377

#pull test image on vm1
docker pull traefik/whoami

docker service create --name whoami --replicas 3 --publish published=8080,target=80 traefik/whoami

#open vm1 ports you want to expose on localhost in virtualbox
virtualbox==>settings==>networks==>advanced==>port forwarding

========================================


# Init Swarm master
docker swarm init

# Get join token:
SWARM_TOKEN=$(docker swarm join-token -q worker)
echo $SWARM_TOKEN

# Get Swarm master IP (Docker for Mac xhyve VM IP)
SWARM_MASTER_IP=$(docker info | grep -w 'Node Address' | awk '{print $3}')
echo $SWARM_MASTER_IP

# Docker version
DOCKER_VERSION=17.09.1-ce-dind

# Number of workers
NUM_WORKERS=3

# Run NUM_WORKERS workers with SWARM_TOKEN
for i in $(seq "${NUM_WORKERS}"); do
	docker run -d --privileged --name worker-${i} --hostname=worker-${i} -p ${i}2375:2375 docker:${DOCKER_VERSION}
	docker --host=localhost:${i}2375 swarm join --token ${SWARM_TOKEN} ${SWARM_MASTER_IP}:2377
done

docker pull dockersamples/visualizer

# Setup the visualizer
docker service create \
  --detach=true \
  --name=viz \
  --publish=8000:8080/tcp \
  --constraint=node.role==manager \
  --mount=type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
  dockersamples/visualizer
  
docker node ls

docker pull magnuslarsson/quotes:go-22
docker service create --name quotes-service --detach=false -p 8080:8080 magnuslarsson/quotes:go-22
docker service create --name whoami-service --detach=false -p 8080:80 --network some-network traefik/whoami

docker swarm join --token SWMTKN-1-3xxhb0gv7j4ttswl76gpc5jm3arg5i27x438438lv1youo5ubr-4e6slud7lz0x5vz5gzpb6c0r5 192.168.65.3:2377


curl localhost:8080/api/quote -s -w "\n" | jq .

while true; do curl localhost:8080/api/quote -s -w "\n" | jq -r .ipAddress; sleep 1; done

docker service scale quotes-service=11 --detach=true

docker rm -f $(docker ps --filter name=quotes-service -q)

docker rm -f worker-2

i=2
docker node rm worker-${i}
docker run -d --privileged --name worker-${i} --hostname=worker-${i} -p ${i}2375:2375 docker:${DOCKER_VERSION}
docker --host=localhost:${i}2375 swarm join --token ${SWARM_TOKEN} ${SWARM_MASTER_IP}:2377

docker service scale quotes-service=8 --detach=false
docker service scale quotes-service=11 --detach=false

# Remove services
docker service rm quotes-service viz

# Unregister worker nodes
for i in $(seq "${NUM_WORKERS}"); do
	docker --host=localhost:${i}2375 swarm leave
done

# Remove worker nodes
docker rm -f $(docker ps -a -q --filter ancestor=docker:${DOCKER_VERSION} --format="")		

# Leave Swarm mode
docker swarm leave --force

# remove all containers with dind
docker ps -a |grep dind |awk '{print $1 " -f"}' |xargs docker rm
