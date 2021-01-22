#remove all stacks
docker stack ls |awk '{print $1}' |xargs docker stack rm
#Alternatively, remove one at a time
docker stack rm crypto
docker stack rm detgen
docker stack rm kafka
docker stack rm traefik
#remove all images
docker rmi $(docker images |grep detector |awk '{print $3}')
docker rmi $(docker images |grep generator |awk '{print $3}')
docker rmi confluentinc/cp-zookeeper:latest
docker rmi confluentinc/cp-kafka:latest
docker rmi obsidiandynamics/kafdrop
docker rmi traefik:v2.3
#remove network, leave swarm
docker network rm traefik_default
docker swarm leave --force

sudo nano /etc/hosts, remove .localhost subdomains

