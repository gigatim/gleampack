function download_rebar() {
  # If a previous download does not exist, then always re-download
  mkdir -p $(rebar_cache_path)

  rebar_download_file="${rebar_version}.tar.gz"
  if [ "${use_rebar_cache}" == "false" ] || [ ! -f "$(rebar_cache_path)/${rebar_download_file}" ]; then
    clean_rebar_downloads
    local download_url="https://github.com/erlang/rebar3/archive/${rebar_download_file}"
      
    output_section "Fetching Rebar ${rebar_version}"

    curl -sL ${download_url} -o $(rebar_cache_path)/${rebar_download_file}

    output_section "Verifying Rebar ${rebar_version}"
  else
    output_section "Using cached Rebar ${rebar_version}"
  fi
}

function install_rebar() {
  output_section "Installing Rebar ${rebar_version} $(rebar_changed)"

  local src_path="$(rebar_cache_path)/rebar3-src"
  local prior_dir=$(pwd)

  if [ ! -x ${src_path}/rebar3 ]; then
    mkdir -p $(rebar_cache_path)/rebar3-src
    if ! tar -xzf "$(rebar_cache_path)/${rebar_download_file}" -C "${src_path}" --strip-components=1; then
      output_line "Failed to extract Rebar archive"
      clean_rebar_downloads
      exit 1
    fi

    cd "${src_path}"
    HOME=$PWD ./bootstrap

    mkdir -p $(build_rebar_path)
    cd "${prior_dir}"
  fi

  cd "${src_path}"
  mkdir -p $(build_rebar_path)
  install -v ./rebar3 "$(build_rebar_path)/"
  cd "${prior_dir}"

  #apk add --virtual .erlang-rundeps $runDeps lksctp-tools ca-certificates
  #apk del.fetch-deps .build-deps # buildkit 

  PATH=$(build_rebar_path):${PATH}
}

function clean_rebar_downloads() {
  rm -rf $(rebar_cache_path)
  mkdir -p $(rebar_cache_path)
}

function rebar_changed() {
  if [ $rebar_changed = true ]; then
    echo "(changed)"
  fi
}
