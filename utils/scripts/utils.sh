#!/usr/bin/env bash

UTILS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"
USER_HOME_DIR="$(cd ~ && pwd)"

export _JAVA_OPTIONS="-Xmx8192M -XX:MaxHeapSize=1024M"
export MAVEN_OPTS="-Xmx1024M"
export ANT_OPTS="-Xmx2048M -XX:MaxHeapSize=1024M"

#
# Print error message to the stdout and exit.
#
die() {
  echo "$@" >&2
  exit 1
}

#
# Get number of CPUs
#
_get_number_of_cpus() {
  local USAGE="Usage: ${FUNCNAME[0]}"
  if [ "$#" != 0 ] ; then
    echo "$USAGE" >&2
    return 1
  fi

  num_cpus="1" # by default
  dist=$(uname)
  if [ "$dist" == "Darwin" ]; then
    num_cpus=$(sysctl -n hw.ncpu)
  elif [ "$dist" == "Linux" ]; then
    num_cpus=$(cat /proc/cpuinfo | grep 'cpu cores' | sort -u | cut -f2 -d':' | cut -f2 -d' ')
  fi

  echo "$num_cpus"
  return 0
}

#
# Check whether the machine has the software that allows one to run jobs
# in parallel.  Return true ('0') if yes, otherwise it returns false ('1').
#
_can_I_run_jobs_simultaneously() {
  if sbatch --version > /dev/null 2>&1; then
    return 0 # true
  fi
  if man parallel > /dev/null 2>&1; then
    return 0 # true
  fi
  return 1 # false
}

#
# Given a relative path, this function converts it into a full/absolute path.
#
rel_to_abs_filename() {
  local USAGE="Usage: ${FUNCNAME[0]}"
  if [ "$#" != 1 ] ; then
    echo "$USAGE" >&2
    return 1
  fi

  rel_filename="$1"
  echo "$(cd "$(dirname "$rel_filename")" && pwd)/$(basename "$rel_filename")" || return 1

  return 0
}

#
# Wrapper to the [dos2unix](https://dos2unix.sourceforge.io/) utility program.
#
fix_line_break() {
  local USAGE="Usage: ${FUNCNAME[0]} <path>"
  if [ "$#" != "1" ] ; then
    echo "$USAGE" >&2
    return 1
  fi

  # Args
  local file_to_fix_path="$1"
  [ -f "$file_to_fix_path" ] || die "[ERROR] File $file_to_fix_path does not exist!"
  [ -s "$file_to_fix_path" ] || return 0

  # Convert file $file_to_fix_path and overwrite output to it
  dos2unix --keepdate --oldfile "$file_to_fix_path" || die "[ERROR] Failed to run dos2unix on $file_to_fix_path!"

  # Check if file ends with a new line
  c=$(tail -c 1 "$file_to_fix_path")
  if [ "$c" != "" ]; then
    # No new line, add one
    echo >> "$file_to_fix_path"
  fi

  return 0
}
# Export function `fix_line_break` so that it could be used in a `find` call, e.g., `find ... -exec bash -c 'fix_line_break "$0"' {} \;`
export -f fix_line_break

# EOF
