
### eosio-docker runtime-control environment
## Usage: source docker/rc.sh

# private key (wallet import format)
export EOSIO_DOCKER_PRIVATE_KEY=${1-5KQwrPbwdL6PhXujxW37FSSQZ1JiwsST4cqQzDeyXtP79zkvFD3}
export EOSIO_DOCKER_PUBLIC_KEY=${2-EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV}

set -a # export all functions and variables
trap "set +a" ERR EXIT INT QUIT TERM HUP

EOSIO_DOCKER_DIR="$(dirname $(realpath $BASH_SOURCE))"

if test -f ./docker-compose.yml
then
  # project specific docker-compose.yml, requires eosio mounted to ./
  # volumes:
  #  - ./:/eosio # data for cleos set contract, etc.
  EOSIO_DOCKER_COMPOSE="$PWD/docker-compose.yml"
  EOSIO_MOUNT=$PWD
else
  # eosio generic, mounts eosio volume to .. so eosio.dir can resolve paths
  EOSIO_DOCKER_COMPOSE="$EOSIO_DOCKER_DIR/docker-compose.yml"
  EOSIO_MOUNT=$(realpath $EOSIO_DOCKER_DIR/..)
fi

EOSIO_DOCKER_COMPOSE_DIR=$(dirname $EOSIO_DOCKER_COMPOSE)

function cleos() {
  docker-compose -f "$EOSIO_DOCKER_COMPOSE" exec keosd \
  cleos -u http://nodeosd:8888 --wallet-url http://localhost:8900 "$@"
}

function keosd() { docker-compose -f "$EOSIO_DOCKER_COMPOSE" exec keosd "$@"; }
function nodeosd() { docker-compose -f "$EOSIO_DOCKER_COMPOSE" exec nodeosd "$@"; }

function eosiocpp() {
  docker-compose -f "$EOSIO_DOCKER_COMPOSE" exec keosd eosiocpp "$@"

  # --workdir is only in a newer docker api API 1.35+ (see `docker version`)
  # eosio_dir=$(eosio.dir)
  # docker-compose -f "$EOSIO_DOCKER_COMPOSE" exec --workdir $eosio_dir keosd eosiocpp "$@"
}

function eosio.init() {
  "$EOSIO_DOCKER_DIR"/init.sh "$@"
  # read -n1 -p "Reset everything on the eosio-docker wallet and blockchain? [Y/n] " response
  # case "$response" in
  #    [yY])
  #     "$EOSIO_DOCKER_DIR"/init.sh "$@"
  #     ;;
  #    ?) echo "canceled";;
  # esac
}

## Run eosio's docker-compose from any directory:
# eosio-docker up -d
# eosio-docker down
function eosio.docker() {
  echo ++ docker-compose -f "$EOSIO_DOCKER_COMPOSE" "$@"
  docker-compose -f "$EOSIO_DOCKER_COMPOSE" "$@"
}

function eosio.unlock() {
  password_file="$EOSIO_DOCKER_COMPOSE_DIR/.wallet-password.txt"
  if ! test -f "$password_file"
  then
    # wallet
    cleos wallet create --to-console | tee /dev/tty |\
      egrep -o "PW[A-Za-z0-9]*" > "$password_file"

    cleos wallet import --private-key $EOSIO_DOCKER_PRIVATE_KEY
  fi
  cleos wallet unlock --password $(cat "$password_file")
}

# Tail the docker-compose nodes.
# Use `docker-compose logs` instead to check for new blocks.  This function
# removes the new block messages making this background job friendly.
function eosio.tail() {
  docker-compose -f "$EOSIO_DOCKER_COMPOSE"\
  logs -f 2>&1 | egrep -v '\[trxs: 0, lib: [0-9]+, confirmed: 0\]$'
}

function eosio.dir() {
  dir=$(realpath ${1-$PWD})
  echo -n "/eosio${dir:${#EOSIO_MOUNT}}"
}

# Beta .. It is building only from the cpp file..
function eosio.build() {
  contract=${1-$(basename $PWD)}
  contract_dir=${1-.}
  eosio_dir=$(eosio.dir)

  trap "set +o xtrace" ERR EXIT
  set -o xtrace

  eosiocpp -o $eosio_dir/$contract_dir/$contract.wast\
    $eosio_dir/$contract_dir/$contract.cpp

  eosiocpp -g $eosio_dir/$contract_dir/$contract.abi\
    $eosio_dir/$contract_dir/$contract.cpp
}

function eosio.deploy() {
  account=${1-$(basename $PWD)}
  contract_dir=${1-.}
  contract=${2-$account}
  permission=${3-$account}

  eosio_dir=$(eosio.dir)

  set_dir=$eosio_dir/$contract_dir
  set_wasm=$contract.wasm
  set_abi=$contract.abi

  trap "set +o xtrace" ERR EXIT
  set -o xtrace

  cleos set contract $account "$set_dir" "$set_wasm" "$set_abi" -p $permission
}

set -a
