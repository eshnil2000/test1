env $(cat .env | grep ^[A-Z] | xargs) docker stack deploy -c docker-compose.traefik.kafka.yml kafka
env $(cat .env | grep ^[A-Z] | xargs) docker stack deploy -c docker-compose.yml crypto
docker stack deploy -c docker-compose.kafka.detgen.yml detgen
docker service rm detgen_generator

docker stack rm crypto 
docker stack rm kafka
docker stack rm detgen