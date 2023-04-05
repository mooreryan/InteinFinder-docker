version := "1.0.0-SNAPSHOT"
commit := "7547273"
full_version := version + "-" + commit
docker_repo := "mooreryan/inteinfinder"
img := docker_repo + ":" + full_version
if_docker_script := "scripts/InteinFinder-docker"

# Updating

update: build write_if_docker_script test push

build:
    docker build \
    --network=host \
    . \
    -t {{ docker_repo }}:{{ full_version }} \
    --build-arg IF_FULL_VERSION={{ full_version }}

push:
    docker push {{ docker_repo }}:{{ full_version }}

write_if_docker_script:
    #!/usr/bin/env bash
    set -euxo pipefail

    printf '#!/bin/bash

    docker run \
      --rm \
      -v $(pwd):$(pwd) \
      -w $(pwd) \
      --user $(id -u):$(id -g) \
      {{ img }} \
      "$@"
    ' > {{ if_docker_script }}

    chmod +x {{ if_docker_script }}

# Testing

test: rm_test_results unzip_assets && check_test_results rm_assets rm_test_results
    #!/usr/bin/env bash
    set -euxo pipefail

    cd _test
    ../{{ if_docker_script }} config.toml

check_test_results:
    #!/usr/bin/env bash
    set -euxo pipefail

    cd _test

    for f in {1_putative_intein_regions.tsv,2_intein_hit_checks.tsv,3_trimmed_inteins.faa}; do
      diff if_out/results/$f _expected/$f
    done

rm_test_results:
    if [ -d _test/if_out ]; then rm -r _test/if_out; fi

unzip_assets:
    tar -xzf _test/_assets.tar.gz -C _test

rm_assets:
    rm -r _test/_assets
