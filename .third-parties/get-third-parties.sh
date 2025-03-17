#!/usr/bin/env bash
#
# ------------------------------------------------------------------------------
# This script downloads and sets up the following third parties:
#   - [JDK 8u292-b10](https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/tag/jdk8u292-b10)
#   - [Apache Maven v3.8.8](https://maven.apache.org/index.html)
#   - [SF110 v20130704](https://www.evosuite.org/experimental-data/sf110)
#   - [EvoSuite v1.2.1-SNAPSHOT (6d2e848c683e15ce9eb9a7ace506993ea46db022)](https://github.com/EvoSuite/evosuite/tree/6d2e848c683e15ce9eb9a7ace506993ea46db022)
#   - [R's packages](https://www.r-project.org)
#
# Usage:
#   get-third-parties.sh
# ------------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"
source "$SCRIPT_DIR/../utils/scripts/utils.sh" || exit 1

# -------------------------------------------------------------------------- Env

# Check whether 'wget' is available
wget --version > /dev/null 2>&1 || die "[ERROR] Could not find 'wget' to download all dependencies. Please install 'wget' and re-run the script."

# Check whether 'git' is available
git --version > /dev/null 2>&1 || die "[ERROR] Could not find 'git' to clone git repositories. Please install 'git' and re-run the script."

# Check whether 'dos2unix' is available
dos2unix --version || die "[ERROR] Could not find 'dos2unix' to clone git repositories. Please install 'dos2unix' and re-run the script."

# Check whether parallel is available
parallel --version > /dev/null 2>&1 || die "[ERROR] Could not find 'parallel' to run experiments/scripts in parallel. Please install 'GNU Parallel' and re-run the script."

# Check whether 'Rscript' is available
Rscript --version > /dev/null 2>&1 || die "[ERROR] Could not find 'Rscript' to perform, e.g., statistical analysis. Please install 'Rscript' and re-run the script."

# ------------------------------------------------------------------------- Main

OS_NAME=$(uname -s | tr "[:upper:]" "[:lower:]")
OS_ARCH=$(uname -m | tr "[:upper:]" "[:lower:]")

[[ $OS_NAME == *"linux"* ]] || die "[ERROR] All scripts have been developed and tested on Linux, and as we are not sure they will work on other OS, we can continue running this script."

#
# Download JDK...
#

echo ""
echo "Setting up JDK..."

JDK_VERSION="8u292"
JDK_BUILD_VERSION="b10"
JDK_FILE="OpenJDK8U-jdk_x64_linux_hotspot_${JDK_VERSION}${JDK_BUILD_VERSION}.tar.gz"
JDK_TMP_DIR="$SCRIPT_DIR/jdk$JDK_VERSION-$JDK_BUILD_VERSION"
JDK_DIR="$SCRIPT_DIR/jdk-8"
JDK_URL="https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk$JDK_VERSION-$JDK_BUILD_VERSION/$JDK_FILE"

# Remove any previous file or directory
rm -rf "$SCRIPT_DIR/$JDK_FILE" "$JDK_TMP_DIR" "$JDK_DIR"

# Get distribution file
wget -np -nv "$JDK_URL" -O "$SCRIPT_DIR/$JDK_FILE"
if [ "$?" -ne "0" ] || [ ! -s "$SCRIPT_DIR/$JDK_FILE" ]; then
  die "[ERROR] Failed to download $JDK_URL!"
fi

tar -xvzf "$JDK_FILE" # extract it
if [ "$?" -ne "0" ] || [ ! -d "$JDK_TMP_DIR" ]; then
  die "[ERROR] Failed to extract $SCRIPT_DIR/$JDK_FILE!"
fi

mv -f "$JDK_TMP_DIR" "$JDK_DIR" || die "[ERROR] Failed to move $JDK_TMP_DIR to $JDK_DIR!"

# Set Java HOME for subsequent commands
export JAVA_HOME="$JDK_DIR"
export PATH="$JAVA_HOME/bin:$PATH"

# Check whether 'javac' is available
javac -version > /dev/null 2>&1 || die "[ERROR] Failed to find the javac executable."

rm -f "$SCRIPT_DIR/$JDK_FILE" # Clean up

#
# Download Apache Maven
#

echo ""
echo "Setting up Maven..."

MVN_VERSION="3.8.8"
MVN_FILE="apache-maven-$MVN_VERSION-bin.zip"
MVN_URL="https://dlcdn.apache.org/maven/maven-3/$MVN_VERSION/binaries/$MVN_FILE"
MVN_TMP_DIR="$SCRIPT_DIR/apache-maven-$MVN_VERSION"
MVN_DIR="$SCRIPT_DIR/apache-maven"

# remove any previous file or directory
rm -rf "$SCRIPT_DIR/$MVN_FILE" "$MVN_TMP_DIR" "$MVN_DIR"

# get file
wget --no-check-certificate -np -nv "$MVN_URL" -O "$SCRIPT_DIR/$MVN_FILE"
if [ "$?" -ne "0" ] || [ ! -s "$SCRIPT_DIR/$MVN_FILE" ]; then
  die "[ERROR] Failed to download $MVN_URL!"
fi

unzip "$MVN_FILE" # extract it
if [ "$?" -ne "0" ] || [ ! -d "$MVN_TMP_DIR" ]; then
  die "[ERROR] Failed to extract $SCRIPT_DIR/$MVN_FILE!"
fi

mv -f "$MVN_TMP_DIR" "$MVN_DIR" || die "[ERROR] Failed to move $MVN_TMP_DIR to $MVN_DIR!"

# Add Apache Maven to the PATH for subsequent commands
export PATH="$MVN_DIR/bin:$PATH"
# Check whether 'mvn' is available
mvn -version > /dev/null 2>&1 || die "[ERROR] Failed to find the mvn executable."

rm -f "$SCRIPT_DIR/$MVN_FILE" # clean up

#
# Get SF110
# http://www.evosuite.org/files/SF110-20130704.zip
#

echo ""
echo "Setting up SF110..."

SF100_VERSION="20130704"
SF100_FILE="SF110-$SF100_VERSION.zip"
SF100_URL="http://www.evosuite.org/files/$SF100_FILE"
SF100_TMP_DIR="$SCRIPT_DIR/SF110-20130704"
SF100_DIR="$SCRIPT_DIR/SF110"

# remove any previous file or directory
rm -rf "$SCRIPT_DIR/$SF100_FILE" "$SF100_TMP_DIR"

# get file
wget --no-check-certificate -np -nv "$SF100_URL" -O "$SCRIPT_DIR/$SF100_FILE"
if [ "$?" -ne "0" ] || [ ! -s "$SCRIPT_DIR/$SF100_FILE" ]; then
  die "[ERROR] Failed to download $SF100_URL!"
fi

unzip "$SCRIPT_DIR/$SF100_FILE" # extract it
if [ "$?" -ne "0" ] || [ ! -d "$SF100_TMP_DIR" ]; then
  die "[ERROR] Failed to extract $SCRIPT_DIR/$SF100_FILE!"
fi

mv -f "$SF100_TMP_DIR" "$SF100_DIR" || die "[ERROR] Failed to move $SF100_TMP_DIR to $SF100_DIR!"

rm -f "$SCRIPT_DIR/$SF100_FILE" # clean up

#
# Setting test generation tools/approaches
#

TEST_GENERATION_TOOLS="$SCRIPT_DIR/test-generation-tools"
rm -rf "$TEST_GENERATION_TOOLS"
mkdir "$TEST_GENERATION_TOOLS"

echo ""
echo "Setting up EvoSuite vanilla..."

EVOSUITE_DIR="$SCRIPT_DIR/evosuite-vanilla"
EVOSUITE_GEN_JAR="$EVOSUITE_DIR/master/target/evosuite-master-1.2.1-SNAPSHOT.jar"
EVOSUITE_RT_JAR="$EVOSUITE_DIR/standalone_runtime/target/evosuite-standalone-runtime-1.2.1-SNAPSHOT.jar"

# remove any previous file and directory
rm -rf "$EVOSUITE_DIR"

git clone https://github.com/EvoSuite/evosuite.git "$EVOSUITE_DIR"
if [ "$?" -ne "0" ] || [ ! -d "$EVOSUITE_DIR" ]; then
  die "[ERROR] Failed to clone EvoSuite's repository!"
fi

pushd . > /dev/null 2>&1
cd "$EVOSUITE_DIR"
  # Switch to master
  git checkout master
  # Switch to latest commit
  git checkout 6d2e848c683e15ce9eb9a7ace506993ea46db022 || die "[ERROR] Commit '6d2e848c683e15ce9eb9a7ace506993ea46db022' not found!"
  # Compile EvoSuite
  mvn clean package -DskipTests=true || die "[ERROR] Failed to package EvoSuite!"
popd > /dev/null 2>&1

[ -s "$EVOSUITE_GEN_JAR" ] || die "[ERROR] $EVOSUITE_GEN_JAR does not exist or it is empty!"
[ -s "$EVOSUITE_RT_JAR" ]  || die "[ERROR] $EVOSUITE_RT_JAR does not exist or it is empty!"

# Place 'evosuite.jar'
cp -v "$EVOSUITE_GEN_JAR" "$TEST_GENERATION_TOOLS/evosuite-vanilla.jar"    || die "[ERROR] Failed to create $TEST_GENERATION_TOOLS/evosuite-vanilla.jar!"
cp -v "$EVOSUITE_RT_JAR"  "$TEST_GENERATION_TOOLS/evosuite-vanilla-rt.jar" || die "[ERROR] Failed to create $TEST_GENERATION_TOOLS/evosuite-vanilla-rt.jar!"

#
# Setup the other copies of EvoSuite
#

# TODO our own fork with our own improvements

#
# R packages
#

echo ""
echo "Setting up R..."

Rscript "$SCRIPT_DIR/get-libraries.R" "$SCRIPT_DIR" || die "[ERROR] Failed to install/load all required R packages!"

echo ""
echo "DONE! All third parties have been successfully installed and configured."

# EOF
