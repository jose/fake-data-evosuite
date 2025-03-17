#!/usr/bin/env bash
#
# ------------------------------------------------------------------------------
# This script runs the many jobs in the provided directory either using
# [GNU Parallel](https://www.gnu.org/software/parallel) or the cluster's API,
# if any.
#
# Usage:
# run-jobs.sh
#   --jobs_dir_path <full path>
#   [--seconds_per_job <time in seconds allowed to run each job, 360 seconds by default.]
#   [--max_number_batches <maximum number of batches (where one batch is composed by many jobs), 32 by default>]
#   [help]
# ------------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"
source "$SCRIPT_DIR/utils.sh" || exit 1

# ----------------------------------------------------------------- Requirements

# Check whether the machine has the software that allows one to run jobs in parallel
_can_I_run_jobs_simultaneously || die "[ERROR] Scripts are optimized to run on clusters with a SGE system or a machine with [GNU Parallel](https://www.gnu.org/software/parallel). Please make sure it is the case."

#
# Generate a header for a batch based on the host's name.
#
_generate_batch_header() {
  local USAGE="Usage: ${FUNCNAME[0]} <batch script file patch> <batch timeout in seconds>"
  if [ "$#" != "2" ]; then
    echo "$USAGE" >&2
    return 1
  fi

  # Args
  local batch_script_file_path="$1"
  local batch_timeout_in_seconds="$2"

  # Local vars
  local host_name=$(hostname)
  local timeout=$(printf '%02d:%02d:%02d\n' $((batch_timeout_in_seconds/3600)) $((batch_timeout_in_seconds%3600/60)) $((batch_timeout_in_seconds%60)))

  # hash-bang
  echo "#!/usr/bin/env bash"

  if [[ $host_name == "iceberg-"* ]] || [[ $host_name == "sharc-"* ]]; then # e.g., iceberg-login1 or harc-login2.shef.ac.uk
    #
    # https://www.sheffield.ac.uk/wrgrid/iceberg or https://www.sheffield.ac.uk/cics/research/hpc/sharc
    #
    echo "#$ -l h_rt=$timeout"
    echo "#$ -l rmem=8G"
    echo "#$ -e $batch_script_file_path.err"
    echo "#$ -o $batch_script_file_path.out"
  elif [[ $host_name == *".polaris.leeds.ac.uk" ]]; then # e.g., login1.polaris.leeds.ac.uk
    #
    # https://n8hpc.org.uk
    #
    echo "#$ -l h_rt=$timeout"
    echo "#$ -l h_vmem=8G"
    echo "#$ -pe smp 2"
    echo "#$ -e $batch_script_file_path.err"
    echo "#$ -o $batch_script_file_path.out"
  elif [[ $host_name == *".bob.macc.fct.pt" ]] || [ "$host_name" == "slurmsub.grid.fe.up.pt" ] || [[ $host_name == "login-node" ]]; then # e.g., c805-001.bob.macc.fct.pt, slurmsub.grid.fe.up.pt, login-node at login-node.di.fc.ul
    echo "#SBATCH --job-name=$(basename "$batch_script_file_path")"
    echo "#SBATCH --output=$batch_script_file_path.out"
    echo "#SBATCH --error=$batch_script_file_path.err"
    echo "#SBATCH --nodes=1 # ensure that all cores are on one machine"
    # sbatch does not launch tasks, it requests an allocation of resources and
    # submits a batch script.  This option advises the Slurm controller that job
    # steps run within the allocation will launch a maximum of number tasks
    # and to provide for sufficient resources.  The default is one task per
    # node, but note that the --cpus-per-task option will change this default.
    echo "#SBATCH --ntasks=1"
    # Request that `ntasks` be invoked on each node.  If used with the --ntasks
    # option, the --ntasks option will take precedence and the --ntasks-per-node
    # will be treated as a maximum count of tasks per node.  Meant to be used
    # with the --nodes option.  This is related to --cpus-per-task=ncpus, but
    # does not require knowledge of the actual number of cpus on each node.
    # In some cases, it is more convenient to be able to request that no more
    # than a specific number of tasks be invoked on each node.
    echo "#SBATCH --ntasks-per-node=1"
    # Advise the Slurm controller that ensuing job steps will require `ncpus`
    # number of processors per task.  Without this option, the controller will
    # just try to allocate one processor per task.
    # For instance, consider an application that has 4 tasks, each requiring 3
    # processors.  If our cluster is comprised of quad-processors nodes and we
    # simply ask for 12 processors, the controller might give us only 3 nodes.
    # However, by using the --cpus-per-task=3 options, the controller knows that
    # each task requires 3 processors on the same node, and the controller will
    # grant an allocation of 4 nodes, one for each of the 4 tasks.
    echo "#SBATCH --cpus-per-task=1"
    # Minimum  memory required per allocated CPU.  Default units are megabytes.
    echo "#SBATCH --mem-per-cpu=8192"
    # Set a minimum time limit on the job allocation.
    echo "#SBATCH --time=$timeout"
    if [[ $host_name == "login-node" ]]; then
      echo "#SBATCH --partition=compute # run jobs in 'compute' partition"
    fi
    if [[ $host_name != "login-node" ]]; then
      echo "module purge # unload all loaded modules"
    fi
  fi

  echo ""
  return 0
}

#
# Run a batch script using host's infrastructure.
#
_run_batch_script() {
  local USAGE="Usage: ${FUNCNAME[0]} <batch script file patch>"
  if [ "$#" != "1" ]; then
    echo "$USAGE" >&2
    return 1
  fi

  local batch_script_file_path="$1"
  [ -s "$batch_script_file_path" ] || die "[ERROR] $batch_script_file_path does not exist or it is empty!"

  echo "[DEBUG] Running $batch_script_file_path ..."

  local host_name=$(hostname)
  if [[ $host_name == "iceberg-"* ]] || [[ $host_name == "sharc-"* ]] || [[ $host_name == *".polaris.leeds.ac.uk" ]]; then
    qsub "$batch_script_file_path"
  elif [[ $host_name == *".bob.macc.fct.pt" ]] || [ "$host_name" == "slurmsub.grid.fe.up.pt" ] || [[ $host_name == "login-node" ]]; then
    sbatch "$batch_script_file_path"
  else
    bash "$batch_script_file_path"
  fi

  return 0
}

# ------------------------------------------------------------------------- Args

USAGE="Usage: ${BASH_SOURCE[0]} \
  --jobs_dir_path <full path> \
  [--seconds_per_job <time in seconds allowed to run each job, 360 seconds by default.] \
  [--max_number_batches <maximum number of batches (where one batch is composed by many jobs), 32 by default>] \
  [help]"
if [ "$#" -ne "1" ] && [ "$#" -ne "2" ] && [ "$#" -ne "4" ] && [ "$#" -ne "6" ]; then
  die "$USAGE"
fi

jobs_dir_path=""
seconds_per_job="360"
max_number_batches="32" # A batch is composed by one or more jobs

while [[ "$1" = --* ]]; do
  OPTION=$1; shift
  case $OPTION in
    (--jobs_dir_path)
      jobs_dir_path=$1;
      shift;;
    (--seconds_per_job)
      seconds_per_job=$1;
      shift;;
    (--max_number_batches)
      max_number_batches=$1;
      shift;;
    (--help)
      echo "$USAGE"
      exit 0
    (*)
      die "$USAGE";;
  esac
done

# Check whether all arguments have been initialized
[ "$jobs_dir_path" != "" ]      || die "[ERROR] Missing --jobs_dir_path argument!"
[ "$seconds_per_job" != "" ]    || die "[ERROR] Missing --seconds_per_job argument!"
[ "$max_number_batches" != "" ] || die "[ERROR] Missing --max_number_batches argument!"

# Check whether required directories/files do exist
[ -d "$jobs_dir_path" ]         || die "[ERROR] $jobs_dir_path does not exist!"

# ------------------------------------------------------------------------- Main

# Remove any previously generated batch file/job
find "$jobs_dir_path" -mindepth 1 -maxdepth 1 -type f -name "batch-*.sh*" -exec rm -f {} \;
find "$jobs_dir_path" -mindepth 1 -maxdepth 1 -type f -name "batch-*.txt" -exec rm -f {} \;

# How many jobs have not been completed successfully?
number_of_jobs_to_run=0
for script_file_path in $(find "$jobs_dir_path" -type f -name "job.sh"); do
  log_file_path=$(cat "$script_file_path" | sed -En 's|.* "(.*/job.log)" .*|\1|p')
  if [ -s "$log_file_path" ]; then # Log exists and it is not empty
    if ! tail -n1 "$log_file_path" | grep -q "^DONE\!$"; then
      number_of_jobs_to_run=$((number_of_jobs_to_run+1))
    fi
  else
    number_of_jobs_to_run=$((number_of_jobs_to_run+1))
  fi
done
echo "[DEBUG] number of jobs to run: $number_of_jobs_to_run"

# Number of batches that could be executed in parallel, given machine's limits
number_of_jobs_per_batch=$(echo "($number_of_jobs_to_run + $max_number_batches - 1) / $max_number_batches" | bc)
echo "[DEBUG] number of jobs per batch: $number_of_jobs_per_batch"

# Create batches
batch_id=1
batch_jobs_file_path="$jobs_dir_path/batch-$batch_id.txt"; rm -f "$batch_jobs_file_path"
count_number_jobs_in_batch=0
echo "[DEBUG] Creating batch-$batch_id"

for script in $(find "$jobs_dir_path" -type f -name "job.sh" | shuf); do
  # Has this job been completed successfully?
  log_file_path=$(cat "$script" | sed -En 's|.* "(.*/job.log)" .*|\1|p')
  if [ -s "$log_file_path" ]; then # Log exists and it is not empty
    if tail -n1 "$log_file_path" | grep -q "^DONE\!$"; then
      continue
    else
      # In case of re-run of a unsuccessfully execution, clean up the log file
      rm -f "$log_file_path"; touch "$log_file_path"
    fi
  else
    touch "$log_file_path"
  fi

  timefactor=$(grep "^# timefactor:" "$script" | cut -f2 -d':')
  script_seconds_per_job=$(echo "$seconds_per_job * $timefactor" | bc)
  echo "timeout --signal=SIGTERM ${script_seconds_per_job}s bash $script" >> "$batch_jobs_file_path"

  count_number_jobs_in_batch=$((count_number_jobs_in_batch+1))
  if [ "$count_number_jobs_in_batch" -ge "$number_of_jobs_per_batch" ]; then
    count_number_jobs_in_batch=0 # Reset counter of jobs in a batch
    batch_id=$((batch_id+1)) # Increment batch counter
    batch_jobs_file_path="$jobs_dir_path/batch-$batch_id.txt"; rm -f "$batch_jobs_file_path"
    echo "[DEBUG] Creating batch-$batch_id"
  fi
done
# How many?
number_of_batches_to_run=$(find "$jobs_dir_path" -mindepth 1 -maxdepth 1 -type f -name "batch-*.txt" | wc -l)
echo "[DEBUG] number of batches to run: $number_of_batches_to_run"

# Create jobs
host_name=$(hostname)
for batch_id in $(seq 1 $number_of_batches_to_run); do
  echo "[DEBUG] Creating job-$batch_id"

  batch_jobs_file_path="$jobs_dir_path/batch-$batch_id.txt"
  [ -s "$batch_jobs_file_path" ] || die "[ERROR] $batch_jobs_file_path does not exist or it is empty!"
  batch_script_file_path="$jobs_dir_path/batch-$batch_id.sh"
  rm -f "$batch_script_file_path"

  # How much time would a batch require to run all jobs
  batch_total_time_in_seconds=$(grep "^timeout --signal=SIGTERM " "$batch_jobs_file_path" | cut -f3 -d' ' | tr -d 's' | paste -sd+ - | bc)
  if [[ $host_name == "login-node" ]] && [ "$batch_total_time_in_seconds" -gt "172800" ]; then # > 2 days
    # Jobs in the navigator cluster can only run for two days
    batch_total_time_in_seconds="172800"
  fi

  # Init batch file
  _generate_batch_header \
    "$batch_script_file_path" \
    "$batch_total_time_in_seconds" > "$batch_script_file_path" || die "[ERROR] Failed to init batch file $batch_script_file_path!"

  if [[ $host_name == "iceberg-"* ]] || [[ $host_name == "sharc-"* ]] || [[ $host_name == *".polaris.leeds.ac.uk" ]] || [[ $host_name == *".bob.macc.fct.pt" ]] || [ "$host_name" == "slurmsub.grid.fe.up.pt" ] || [[ $host_name == "login-node" ]]; then
    cat "$batch_jobs_file_path" >> "$batch_script_file_path"
  else
    echo "parallel --progress -j $(cat /proc/cpuinfo | grep 'cpu cores' | sort -u | cut -f2 -d':' | cut -f2 -d' ') -a $batch_jobs_file_path" >> "$batch_script_file_path"
  fi

  echo ""               >> "$batch_script_file_path"
  echo "echo \"DONE!\"" >> "$batch_script_file_path"
  echo "exit 0"         >> "$batch_script_file_path"
  echo ""               >> "$batch_script_file_path"
  echo "# EOF"          >> "$batch_script_file_path"
done

# Run/Submit batches
for batch_script_file_path in $(find "$jobs_dir_path" -mindepth 1 -maxdepth 1 -type f -name "batch-*.sh" | shuf); do
  _run_batch_script "$batch_script_file_path" || die "[ERROR] Failed to run $batch_script_file_path!"
done

echo "DONE!"
exit 0

# EOF
