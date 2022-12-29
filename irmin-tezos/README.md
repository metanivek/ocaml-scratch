exploring tezos data stored with irmin-pack

download a tarball from https://xtz-shots.io/mainnet/#rolling-tarball

example of running (with context hash that is in the tarball)
``` sh
# list contracts directory
dune exec -- ./main.exe \
-store /home/metanivek/tmp/rolling-node/data/context/ \
-hash CoWLnZaqauuQpm9ewRuUDEU4wWWnD9S9xzW1BQXJnDNSmcKxNf9r \
-path data/contracts

# list root
dune exec -- ./main.exe \
-store /home/metanivek/tmp/rolling-node/data/context/ \
-hash CoWLnZaqauuQpm9ewRuUDEU4wWWnD9S9xzW1BQXJnDNSmcKxNf9r \
```
