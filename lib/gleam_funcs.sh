function download_gleam() {
  # If a previous download does not exist, then always re-download
  mkdir -p $(gleam_cache_path)

  if [ ${force_fetch} = true ] || [ ! -f $(gleam_cache_path)/$(gleam_download_file) ]; then
    set -v
    clean_gleam_downloads
    gleam_changed=true
    local download_url="https://github.com/gleam-lang/gleam/releases/download/v1.5.0/gleam-v${gleam_version}-x86_64-unknown-linux-musl.tar.gz"
      
    output_section "Fetching Gleam ${gleam_version}"

    if ! curl -s ${download_url} -o $(gleam_cache_path)/$(gleam_download_file); then
      output_section "Falling back to fetching Gleam ${gleam_version}"
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

  tar -xvf $(gleam_cache_path)/$(gleam_download_file) -C $(build_gleam_path)
  PATH=$(build_gleam_path):${PATH}
}

function gleam_download_file() {
  local otp_version=$(otp_version ${erlang_version})
  echo gleam-${gleam_version}.tar.gz
}

function clean_gleam_downloads() {
  rm -rf $(gleam_cache_path)
  mkdir -p $(gleam_cache_path)
}

function restore_mix() {
  if [ -d $(mix_backup_path) ]; then
    mkdir -p $(build_mix_home_path)
    cp -pR $(mix_backup_path)/* $(build_mix_home_path)
  fi

  if [ -d $(hex_backup_path) ]; then
    mkdir -p $(build_hex_home_path)
    cp -pR $(hex_backup_path)/* $(build_hex_home_path)
  fi
}

function backup_mix() {
  # Delete the previous backups
  rm -rf $(mix_backup_path) $(hex_backup_path)

  mkdir -p $(mix_backup_path) $(hex_backup_path)

  cp -pR $(build_mix_home_path)/* $(mix_backup_path)
  cp -pR $(build_hex_home_path)/* $(hex_backup_path)

  # https://github.com/HashNuke/heroku-buildpack-gleam/issues/194
  if [ $(build_hex_home_path) != $(runtime_hex_home_path) ]; then
    mkdir -p $(runtime_hex_home_path)
    cp -pR $(build_hex_home_path)/* $(runtime_hex_home_path)
  fi

  # https://github.com/HashNuke/heroku-buildpack-gleam/issues/194
  if [ $(build_mix_home_path) != $(runtime_mix_home_path) ]; then
    mkdir -p $(runtime_mix_home_path)
    cp -pR $(build_mix_home_path)/* $(runtime_mix_home_path)
  fi
}

function install_hex() {
  output_section "Installing Hex"
  mix local.hex --force
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
