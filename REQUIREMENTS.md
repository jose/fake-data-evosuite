# Requirements

This markdown file focus on the requirements of any software or script available or used in the artifact.

## User

It is expected / assumed the user is able to navigate in / out directories on the command line and comfortable running bash commands using the command line.  Minimum / Basic knowledge of Bash, Python, and R might be required to read and / or modify any script.

## Machine

A Unix-based machine.  Any bash command, tool, or script available or mentioned in the artifact's documentation has been tested only on a Unix-based machine and therefore might not work on other operating systems, e.g., Windows.

## Software

#### [GIT](https://git-scm.com) and [GNU wget](https://www.gnu.org/software/wget)

To be able to automatically get the required artefacts, e.g., to get [SF110](https://www.evosuite.org/experimental-data/sf110) dataset, [GIT](https://git-scm.com) and [GNU wget](https://www.gnu.org/software/wget) must be installed and available on your machine.  To assess whether both programs are installed and available, please run the following commands

```bash
(git  --version > /dev/null 2>&1 && echo "git is installed and available")  || echo "ERROR: git is not installed or available" # (< 1 second)
(wget --version > /dev/null 2>&1 && echo "wget is installed and available") || echo "ERROR: wget is not installed or available" # (< 1 second)
```

In case either [GIT](https://git-scm.com) or [GNU wget](https://www.gnu.org/software/wget) is not installed, please visit its' official webpage and follow the installation instructions.

#### [dos2unix](https://dos2unix.sourceforge.io)

Some machines might create files with the Windows line ending (i.e., carriage return (CR) and line feed (LF)) instead of the Linux line ending (i.e., line feed (LF)) which might cause some issues later when counting the number of lines in a file, loading CSV files, etc.

```bash
dos2unix --version > /dev/null 2>&1 && echo "dos2unix is installed and available") || echo "ERROR: dos2unix is not installed or available" # (< 1 second)
```

In case [dos2unix](https://dos2unix.sourceforge.io) is not installed, please visit it's official webpage and follow the installation instructions.

#### [GNU Parallel](https://www.gnu.org/software/parallel)

To be able to run experiments in parallel.  To assess whether it is installed and available, please run the following command

```bash
(parallel --version > /dev/null 2>&1 && echo "parallel is installed and available") || echo "ERROR: parallel is not installed or available" # (< 1 second)
```

In case [GNU Parallel](https://www.gnu.org/software/parallel) is not installed, please visit it's official webpage and follow the installation instructions.

#### [R Project for Statistical Computing](https://www.r-project.org)

To be able to automatically run any statistical analysis, [R](https://www.r-project.org) must be installed and available on your machine.  To assess whether it is installed and available, please run the following command

```bash
(Rscript --version > /dev/null 2>&1 && echo "R is installed and available") || echo "ERROR: R is not installed or available" # (< 1 second)
```

In case [R](https://www.r-project.org) is not installed, please visit the official webpage and follow the installation instructions.
