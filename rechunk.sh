IMG=ghcr.io/ripps818/cachyos-boppos-bootc:znver4
podman pull $IMG # image must be available locally
export CHUNKAH_CONFIG_STR="$(podman inspect $IMG)"
podman run --rm --mount=type=image,src=$IMG,dest=/chunkah \
  -e CHUNKAH_CONFIG_STR quay.io/jlebon/chunkah build | podman load
