# eosio-docker

Provides a runtime-control environment that helps automate common eosio
node and wallet development.

# Status

Alpha

Known issues:

* The cleos wallet url path and port is hard-coded in rc.sh.  If this is fixed
it may be possible to run multiple eosio docker compose stacks at the same time.
* When stable the new ABI compiler should be added.

# Setup

Change directory to the folder containing your project's `docker-compose.yml` file
then source the `eosio.docker` runtime-control script.  If your project does not
have a `docker-compose.yml` file then source the runtime-control script from any
directory.

```bash
cd myproject/mycontract
. ~/eos/eosio.docker/rc.sh
```

Most commands appear using bash completion:
```bash
$ eosio.[tab][tab]
```

Usage:
```bash
eosio.init # Create or re-create persistent docker volumes
eosio.docker up -d # eosio.docker wraps docker-compose

./init.sh # create your own setup here (example below)

eosio.tail & # Tails all docker container, empty block log messages are hidden

./test.sh # your own compile deploy and test script (example below)

cleos get table # any cleos command

keosd ls # run a command in the wallet container

eosiocpp -n $(eosio.dir)/mycontract # smart contract creator / compiler
sudo chown $(whoami):$(whoami) mycontract

eosio.docker down # Stop all containers, data is saved unless eosio.init is called again
```

Init and test scripts can make for a quick blockchain reset and testing.  You
will create theses.

Run `myproject/mycontract/init.sh` after running `eosio.init`:
```bash
set -o xtrace
eosio.unlock 1> /dev/null || true

cleos create account eosio mycontract $EOSIO_DOCKER_PUBLIC_KEY
# ...
```

Run `myproject/mycontract/test.sh` to compile re-deploy and test:
```bash
set -o errexit

eosio.unlock 1> /dev/null || true

set -o xtrace

# eosio.init && ./init.sh # reset everything
eosio.build && eosio.deploy

cleos push action ...
```

# runwatch

For quick re-deploys and testing a `runwatch` function may be used to detect
files that changed or were saved.  This is not part of the runtime control environment.

```bash
# Save in ./bash_aliases
function runwatch() {
  # sudo apt install -y inotify-tools
  cmd=$1
  shift 1
  watch_files="$@"

  while :
  do
    echo ++ $cmd
    eval "$cmd"
    echo
    inotifywait --quiet --recursive --event close_write $watch_files || break
    echo -e "\n\n\n"
  done
}
```

```bash
runwatch ./test.sh *.?pp
```

# Build and Deploy

```bash
cd myproject
eosio.build mycontract
eosio.deploy mycontract

# or
cd myproject/mycontract
eosio.build && eosio.deploy
```

# Paths

Host system and docker equivalent paths:

```bash
cd myproject
ls mycontract
keosd ls $(eosio.dir)/mycontract
```

Using docker compose's `--workdir` option in `rc.sh` might make `eosio.dir`
optional.  This option is still new and not well supported.

# Docker compose

Be mindful that docker-compose will name its instances after your install
directory.
