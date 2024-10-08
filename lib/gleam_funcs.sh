function check_gleam_cache() {
  use_gleam_cache=false

  if [ -f $(gleam_cache_path)/${gleam_download_file} ]; then
    if [ -f $(gleam_cache_path)/${gleam_download_file}.sha256 ]; then
      cd $(gleam_cache_path)
      if sha256sum -c ${gleam_download_file}.sha256 --status; then
        use_gleam_cache=true
      fi
      cd -
    fi
  fi
}

function update_gleam_cache_state() {
  gleam_download_file="gleam-${gleam_version}-x86_64-unknown-linux-musl.tar.gz"

  use_gleam_cache=false
  if [ "${force_fetch}" != "true" ]; then
    check_gleam_cache
  fi
}

function download_gleam() {
  # If a previous download does not exist, then always re-download
  mkdir -p $(gleam_cache_path)

  update_gleam_cache_state
  if [ "${use_gleam_cache}" == "false" ]; then
    clean_gleam_downloads
    gleam_changed=true
    local base_url="https://github.com/gleam-lang/gleam/releases/download/"
    local download_url="${base_url}${gleam_version}/${gleam_download_file}"
    local sha_url="${download_url}.sha256"
      
    output_section "Fetching Gleam ${gleam_version}"

    curl -sL ${download_url} -o $(gleam_cache_path)/${gleam_download_file}
    curl -sL ${sha_url} -o $(gleam_cache_path)/${gleam_download_file}.sha256

    output_section "Verifying Gleam ${gleam_version}"
    check_gleam_cache
    if [ "${use_gleam_cache}" == "false" ]; then
      output_line "Checksum verification failed for Gleam download"
      exit 1
    fi
  else
    output_section "Using cached Gleam ${gleam_version}"
  fi
}

function install_gleam() {
  set -v
  output_section "Installing Gleam ${gleam_version} $(gleam_changed)"

  mkdir -p $(build_gleam_path)

  tar -xvf $(gleam_cache_path)/${gleam_download_file} -C $(build_gleam_path)
  PATH=$(build_gleam_path):${PATH}
}

function clean_gleam_downloads() {
  rm -rf $(gleam_cache_path)
  mkdir -p $(gleam_cache_path)
}

function install_rebar() {
  output_section "Installing rebar"

  mix local.rebar --force
}

function gleam_changed() {
  if [ $gleam_changed = true ]; then
    echo "(changed)"
    clean_gleam_version_dependent_cache
  fi
}

function otp_version() {
  echo $(echo "$1" | awk 'match($0, /^[0-9][0-9]/) { print substr( $0, RSTART, RLENGTH )}')
}
