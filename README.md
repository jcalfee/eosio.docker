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

eosio.docker up -d # eosio.docker wrappes docker-compose

eosio.tail & # Tails all docker container, empty block log messages are hidden

./init.sh # Initial accounts for your contract
./test.sh # Compile re-deploy and test (cleos, etc)
eosio.docker down # Stop all containers, data is saved unless eosio.init is used
cleos get table # any cleos command
keosd ls # run a command in the wallet container

eosiocpp -n $(eosio.dir)/mycontract # smart contract creator / compiler
sudo chown $(whoami):$(whoami) mycontract
```

Build and deploy:
```bash
cd myproject
eosio.build mycontract
eosio.deploy mycontract

# or
cd myproject/mycontract
eosio.build && eosio.deploy
```

Equivalent paths:
```bash
cd myproject
ls mycontract
keosd ls $(eosio.dir)/mycontract
```

Be mindful that docker-compose will name its instances after your install
directory.
