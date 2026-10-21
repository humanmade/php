#!/usr/bin/env bash
set -euo pipefail

reference=${1:?Expected a registry image reference with digest}
arch=${2:?Expected the Linux architecture}
local_image=${3:?Expected the locally tested image reference}

tested=$(docker image inspect "$local_image" --format '{{.Id}}')
manifest=$(docker buildx imagetools inspect "$reference" --raw)

# Provenance attestations wrap even a single-platform image in an OCI index.
# Resolve the runtime manifest, excluding the unknown/unknown attestation entry.
if jq -e '.manifests' <<< "$manifest" > /dev/null; then
  digest=$(jq -er --arg arch "$arch" '
    [.manifests[] | select(.platform.os == "linux" and .platform.architecture == $arch)]
    | if length == 1 then .[0].digest else error("Expected one matching Linux image") end
  ' <<< "$manifest")
  manifest=$(docker buildx imagetools inspect "${reference%@*}@$digest" --raw)
fi

pushed=$(jq -er '.config.digest | select(type == "string" and test("^sha256:[a-f0-9]{64}$"))' <<< "$manifest")
if [ "$tested" != "$pushed" ]; then
  echo "Image config mismatch for $reference: tested=$tested pushed=$pushed" >&2
  exit 1
fi
echo "Verified $reference matches tested image $tested"
