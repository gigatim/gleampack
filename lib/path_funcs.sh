function build_platform_tools_path() {
  echo "${build_path}/.platform_tools"
}

function runtime_platform_tools_path() {
  echo "${runtime_path}/.platform_tools"
}

function build_erlang_path() {
  echo "$(build_platform_tools_path)/erlang"
}

function runtime_erlang_path() {
  echo "$(runtime_platform_tools_path)/erlang"
}

function build_gleam_path() {
  echo "$(build_platform_tools_path)/gleam/bin"
}

function runtime_gleam_path() {
  echo "$(runtime_platform_tools_path)/gleam"
}

function build_rebar_path() {
  echo "$(runtime_platform_tools_path)/rebar3"
}

function build_hex_home_path() {
  echo "${build_path}/.hex"
}

function runtime_hex_home_path() {
  echo "${runtime_path}/.hex"
}

function build_mix_home_path() {
  echo "${build_path}/.mix"
}

function runtime_mix_home_path() {
  echo "${runtime_path}/.mix"
}

function stack_based_cache_path() {
  echo "${cache_path}/gigalixir-buildpack-gleam/stack-cache"
}

function deps_backup_path() {
  echo $(stack_based_cache_path)/deps_backup
}

function build_backup_path() {
  echo $(stack_based_cache_path)/build_backup
}

function mix_backup_path() {
  echo $(stack_based_cache_path)/.mix
}

function hex_backup_path() {
  echo $(stack_based_cache_path)/.hex
}

function erlang_cache_path() {
  echo $(stack_based_cache_path)/erlang
}

function gleam_cache_path() {
  echo $(stack_based_cache_path)/gleam
}

function rebar_cache_path() {
  echo $(stack_based_cache_path)/rebar
}
