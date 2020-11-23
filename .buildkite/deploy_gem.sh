#!/usr/bin/env bash

export VERSION=$(jq -r "./lib/data-migrate/version" <version.json)

docker-compose --project-name $BUILDKITE_JOB_ID build deploy
docker-compose --project-name $BUILDKITE_JOB_ID run deploy gem push --config-file ./.gem/credentials --key gemstash --host https://gemstash.zp-int.com/private ruby/data-migrate-$VERSION.gem
docker-compose --project-name $BUILDKITE_JOB_ID down
