# Outputs log line
#
# Usage:
#
#     output_line "Cloning repository"
#
function output_line() {
  local spacing="      "
  echo "${spacing} $1"
}

# Outputs section heading
#
# Usage:
#
#     output_section "Application tasks"
#
function output_section() {
  local indentation="----->"
  echo "${indentation} $1"
}

function output_warning() {
  local spacing="      "
  echo -e "${spacing} \e[31m$1\e[0m"
}

function output_stderr() {
  # Outputs to stderr in case it is inside a function so it does not
  # disturb the return value. Useful for debugging.
  echo "$@" 1>&2;
}


function assert_gleam_version_set() {
  custom_config_file=$1

  # 0 when found
  # 1 when not found
  # 2 when file does not exist

  set +e
  # this command is allowed to return a non-zero exit code since that is how we check if the gleam version is set.
  grep -q -e "^gleam_version=" $custom_config_file 2>/dev/null
  set -e

  if [ $? -ne 0 ]; then
    # For now, just print a warning. In the future, we will fail and require an explicit
    # gleam_version to be set.
    output_line ""
    output_warning "IMPORTANT: The default gleam_version will be removed on 2021-06-01. Please explicitly set an gleam_version in your gleam_buildpack.config before then or your deploys will fail."
    output_line ""
  fi
}

function extract_asdf_version() {
  local file="${build_path}/.tool-versions"
  local package=$1

  if [ -f $file ]; then
    grep "^$package" $file | tail -n 1 | awk '{print $2}'
  fi
}

function load_config() {
  output_section "Checking Erlang and Gleam versions"

  local custom_config_file="${build_path}/gleam_buildpack.config"

  # Source for default versions file from buildpack first
  source "${build_pack_path}/gleam_buildpack.config"

  erlang_version=$(extract_asdf_version "erlang")
  gleam_version=$(extract_asdf_version "gleam")

  if [ -f $custom_config_file ];
  then
    source $custom_config_file
    assert_gleam_version_set $custom_config_file
  fi

  if [ -z "$erlang_version" ] || [ -z "$gleam_version" ]; then
    output_line "Sorry, an gleam_buildpack.config or asdf .tool-versions file is required."
    output_line "Please see https://github.com/gigalixir/gigalixir-buildpack-gleam#configuration"
    exit 1
  fi

  fix_erlang_version
  fix_gleam_version

  output_line "Will use the following versions:"
  output_line "* Stack ${STACK}"
  output_line "* Erlang ${erlang_version}"
  output_line "* Gleam ${gleam_version[0]} ${gleam_version[1]}"
}


function export_env_vars() {
  whitelist_regex=${2:-''}
  blacklist_regex=${3:-'^(PATH|GIT_DIR|CPATH|CPPATH|LD_PRELOAD|LIBRARY_PATH)$'}
  if [ -d "$env_path" ]; then
    output_section "Will export the following config vars:"
    for e in $(ls $env_path); do
      echo "$e" | grep -E "$whitelist_regex" | grep -vE "$blacklist_regex" &&
      export "$e=$(cat $env_path/$e)"
      :
    done
  fi
}

function check_stack() {
  if [ "${STACK}" = "cedar" ]; then
    echo "ERROR: cedar stack is not supported, upgrade to cedar-14"
    exit 1
  fi

  if [ ! -f "${cache_path}/stack" ] || [ $(cat "${cache_path}/stack") != "${STACK}" ]; then
    output_section "Stack changed, will rebuild"
    $(clear_cached_files)
  fi

  echo "${STACK}" > "${cache_path}/stack"
}

# remove any cache files that are not under the stack-based
# cache directory specified by the `stack_based_cache_path`
# function
function clean_old_cache_files() {
  rm -rf \
    $(build_erlang_path) \
    ${cache_path}/deps_backup \
    ${cache_path}/build_backup \
    ${cache_path}/.mix \
    ${cache_path}/.hex
  rm -rf ${cache_path}/OTP-*.zip
  rm -rf ${cache_path}/gleam*.zip
}

function clean_cache() {
  clean_old_cache_files

  if [ $always_rebuild = true ]; then
    output_section "Cleaning all cache to force rebuilds"
    $(clear_cached_files)
  fi
}

function clear_cached_files() {
  rm -rf $(stack_based_cache_path)
}

function fix_erlang_version() {
  erlang_version=$(echo "$erlang_version" | sed 's/[^0-9.]*//g')
  if echo "$erlang_version" | grep -E "^[0-9]+$" > /dev/null; then
    erlang_version="${erlang_version}.0"
  elif echo "$erlang_version" | grep -E "\.0\.0$" > /dev/null; then
    erlang_version=$(echo "$erlang_version" | sed 's/\.0\.0$/.0/')
  fi
}

function fix_gleam_version() {
  # TODO: this breaks if there is an carriage return behind gleam_version=(branch main)^M
  if [ ${#gleam_version[@]} -eq 2 ] && [ ${gleam_version[0]} = "branch" ]; then
    force_fetch=true
    gleam_version=${gleam_version[1]}

  elif [ ${#gleam_version[@]} -eq 1 ]; then
    force_fetch=false

    # If we detect a version string (e.g. 1.14 or 1.14.0) we prefix it with "v"
    if [[ ${gleam_version} =~ ^[0-9]+\.[0-9]+ ]]; then
      if [[ ${gleam_version} =~ ^[0-9]+\.[0-9]+\.[0-9]+-rc\.[0-9]+$ ]]; then
        echo "Detected release candidate"
      else
        # strip out any non-digit non-dot characters
        gleam_version=$(echo "$gleam_version" | sed 's/[^0-9.]*//g')
      fi
      gleam_version=v${gleam_version}
    fi

  else
    output_line "Invalid Gleam version specified"
    output_line "See the README for allowed formats at:"
    output_line "https://github.com/gigalixir/gigalixir-buildpack-gleam"
    exit 1
  fi

  if [ -z "$gleam_version" ]; then
    output_line "Unable to detect gleam version"
    exit 1
  fi
}
