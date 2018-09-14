set -o errexit

# EOSIO_DOCKER_DIR="$(dirname $(realpath $BASH_SOURCE))"
# cd "$EOSIO_DOCKER_DIR"
#
# source ./rc.sh # cleos command, yaml file..

volumes=$(egrep -o "[a-z]+-data-volume" $EOSIO_DOCKER_COMPOSE |sort|uniq)

set -o xtrace

# docker volumes
docker-compose -f "$EOSIO_DOCKER_COMPOSE" down -v --remove-orphans || true

for volume in $volumes
do
  docker volume rm -f $volume
  docker volume create --name=$volume
done

rm "$EOSIO_DOCKER_COMPOSE_DIR/.wallet-password.txt"
