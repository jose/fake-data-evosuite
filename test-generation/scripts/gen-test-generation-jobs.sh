#!/usr/bin/env bash
#
# ------------------------------------------------------------------------------
# This script creates as many jobs (where each job is the execution of EvoSuite
# on a specific SF110 class and configuration) as the number of SF110 class
# times number of seeds.
#
# Usage:
# gen-test-generation-jobs.sh
#   [--min_seed <int, e.g., 0>]
#   --max_seed <int, e.g., 30>
#   [--subjects_file_path <path, e.g., $SCRIPT_DIR/../../.third-parties/SF110/classes.txt>]
#   --components <path to all components that compose a single job, use ':' to define more than one component, e.g., $SCRIPT_DIR/components/header/hash-bang.txt:$SCRIPT_DIR/components/header/env.txt:$SCRIPT_DIR/components/header/args.txt:$SCRIPT_DIR/components/header/pre-generation.txt:$SCRIPT_DIR/components/body/evosuite-vanilla-call.txt:$SCRIPT_DIR/components/footer/post-generation.txt:$SCRIPT_DIR/components/footer/the-end.txt>
#   --output_dir_path <full path, e.g., $SCRIPT_DIR/../data/generated/evosuite-vanilla>
#   [help]
#
# Requirements:
#   Execution of ../../tools/get-tools.sh script.
# ------------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"
source "$SCRIPT_DIR/../../utils/scripts/utils.sh" || exit 1

# ------------------------------------------------------------------------- Envs

# Check whether the .third-parties' dir is available
THIRD_PARTIES="$SCRIPT_DIR/../../.third-parties"
[ -d "$THIRD_PARTIES" ] || die "[ERROR] $THIRD_PARTIES does not exist!"

# Check whether Java 8 has been installed and it is available
JAVA_HOME="$THIRD_PARTIES/jdk-8"
[ -d "$JAVA_HOME" ] || die "[ERROR] $JAVA_HOME does not exist! Did you run $THIRD_PARTIES/get-third-parties.sh?"

# Check whether the SF110 dataset is available
SF100_DIR="$THIRD_PARTIES/SF110"
[ -d "$SF100_DIR" ] || die "[ERROR] $SF100_DIR does not exist! Did you run $THIRD_PARTIES/get-third-parties.sh?"

# ------------------------------------------------------------------------- Args

USAGE="Usage: ${BASH_SOURCE[0]} \
  [--min_seed <int, e.g., 0>] \
  --max_seed <int, e.g., 30> \
  [--subjects_file_path <path, e.g., $SCRIPT_DIR/../../.third-parties/SF110/classes.txt>] \
  --components <path to all components that compose a single job, use ':' to define more than one component, e.g., $SCRIPT_DIR/components/header/hash-bang.txt:$SCRIPT_DIR/components/header/env.txt:$SCRIPT_DIR/components/header/args.txt:$SCRIPT_DIR/components/header/pre-generation.txt:$SCRIPT_DIR/components/body/evosuite-vanilla-call.txt:$SCRIPT_DIR/components/footer/post-generation.txt:$SCRIPT_DIR/components/footer/the-end.txt> \
  --output_dir_path <full path, e.g., $SCRIPT_DIR/../data/generated/evosuite-vanilla> \
  [help]"
if [ "$#" -ne "1" ] && [ "$#" -ne "6" ] && [ "$#" -ne "8" ] && [ "$#" -ne "10" ]; then
  die "$USAGE"
fi

MIN_SEED="0"
MAX_SEED=""
SUBJECTS_FILE_PATH="$SCRIPT_DIR/../../.third-parties/SF110/classes.txt"
COMPONENTS=""
OUTPUT_DIR_PATH=""

while [[ "$1" = --* ]]; do
  OPTION=$1; shift
  case $OPTION in
    (--min_seed)
      MIN_SEED=$1;
      shift;;
    (--max_seed)
      MAX_SEED=$1;
      shift;;
    (--subjects_file_path)
      SUBJECTS_FILE_PATH=$1;
      shift;;
    (--components)
      COMPONENTS=$1;
      shift;;
    (--output_dir_path)
      OUTPUT_DIR_PATH=$1;
      shift;;
    (--help)
      echo "$USAGE"
      exit 0
    (*)
      die "$USAGE";;
  esac
done

# Check whether all arguments have been initialized
[ "$MIN_SEED" != "" ]           || die "[ERROR] Missing --min_seed argument!"
[ "$MAX_SEED" != "" ]           || die "[ERROR] Missing --max_seed argument!"
[ "$SUBJECTS_FILE_PATH" != "" ] || die "[ERROR] Missing --subjects_file_path argument!"
[ "$COMPONENTS" != "" ]         || die "[ERROR] Missing --components argument!"
[ "$OUTPUT_DIR_PATH" != "" ]    || die "[ERROR] Missing --output_dir_path argument!"

# Check whether required directories/files do exist
[ -s "$SUBJECTS_FILE_PATH" ] || die "[ERROR] $SUBJECTS_FILE_PATH does not exist!"

# ------------------------------------------------------------------------- Main

rm -rf "$OUTPUT_DIR_PATH"
mkdir -p "$OUTPUT_DIR_PATH" || die "[ERROR] Failed to create $OUTPUT_DIR_PATH!"

# Create experiment's directories
           reports_dir_path="$OUTPUT_DIR_PATH/reports"
             tests_dir_path="$OUTPUT_DIR_PATH/tests"
              logs_dir_path="$OUTPUT_DIR_PATH/logs"
              jobs_dir_path="$OUTPUT_DIR_PATH/jobs"
master_job_script_file_path="$jobs_dir_path/master-job.sh"
mkdir -p "$reports_dir_path" "$tests_dir_path" "$logs_dir_path" "$jobs_dir_path"
touch "$master_job_script_file_path"

# Create master job script based on the defined components
for component in $(echo "$COMPONENTS" | tr ':' ' '); do
  cat "$component" >> "$master_job_script_file_path"
done
sed -i "s|___UTILS_SCRIPT_PATH___|$SCRIPT_DIR/../../utils/scripts/utils.sh|" "$master_job_script_file_path"

# Create jobs
while read -r row; do
  project_name=$(echo "$row" | cut -f1 -d$'\t')
         class=$(echo "$row" | cut -f2 -d$'\t')

  for seed in $(seq "$MIN_SEED" "$MAX_SEED"); do
    echo "[DEBUG] $project_name :: $class :: $seed"
     job_report_dir_path="$reports_dir_path/$project_name/$class/$seed"
       job_test_dir_path="$tests_dir_path/$project_name/$class/$seed"
        job_log_dir_path="$logs_dir_path/$project_name/$class/$seed"
       job_log_file_path="$job_log_dir_path/job.log"
     job_script_dir_path="$jobs_dir_path/$project_name/$class/$seed"
    job_script_file_path="$job_script_dir_path/job.sh"

    mkdir -p "$job_report_dir_path" "$job_test_dir_path" "$job_log_dir_path" "$job_script_dir_path"
    touch "$job_log_file_path" "$job_script_file_path"

    echo "#!/usr/bin/env bash"                                   > "$job_script_file_path"
    echo "#"                                                    >> "$job_script_file_path"
    echo "# timefactor:1"                                       >> "$job_script_file_path"
    echo "export THIRD_PARTIES=\"$THIRD_PARTIES\""              >> "$job_script_file_path"
    echo "export JAVA_HOME=\"$JAVA_HOME\""                      >> "$job_script_file_path"
    echo "export SF100_DIR=\"$SF100_DIR\""                      >> "$job_script_file_path"
    echo "bash $master_job_script_file_path \
  --project \"$project_name\" \
  --class \"$class\" \
  --seed \"$seed\" \
  --report_dir_path \"$job_report_dir_path\" \
  --test_dir_path \"$job_test_dir_path\" > \"$job_log_file_path\" 2>&1" >> "$job_script_file_path"
  done
done < <(cat "$SUBJECTS_FILE_PATH")

echo "DONE!"
exit 0

# EOF
