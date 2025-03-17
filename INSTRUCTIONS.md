# Instructions to repeat and reproduce the analyses and results in the associated paper

The following sections provides step-by-step instructions to repeat and reproduce the analyses, tables, and figures reported in the associated paper.

## Requirements

All commands / scripts have been tested and used on a Unix-based machine and therefore might not work on other operating systems, e.g., Windows.  This document also assumes the reader is comfortable running bash commands and navigating in/out directories on the command line.

The subsequent analyses require the following tools to be installed and available on your machine (unless the [docker](https://www.docker.com) option is used):
- [GIT](https://git-scm.com) and [GNU wget](https://www.gnu.org/software/wget)
- [GNU Parallel](https://www.gnu.org/software/parallel)
- [R Project for Statistical Computing](https://www.r-project.org)

Visit the [REQUIREMENTS.md](REQUIREMENTS.md) file for more details.

## Setup

### [Docker](https://www.docker.com) option

For an easy setup, we recommend our [docker image](https://hub.docker.com/r/josecarloscampos/___TBA___) that includes all scripts, data, and instructions required to [repeat and reproduce](https://www.acm.org/publications/policies/artifact-review-and-badging-current) the study '___TBA___'.  Otherwise, follow the setup instructions in the next section 'Non-Docker option'.

First, pull the docker image

```bash
docker pull josecarloscampos/___TBA___
```

Second, connect to the docker image

```bash
docker run --interactive --tty --privileged \
  --volume $(pwd):/___TBA___ \
  --workdir /___TBA___/ josecarloscampos/___TBA___
```

which should lead you to the root directory of the artifact.  Then, follow the following sections which provide step-by-step instructions on which commands to run to repeat and reproduce the experiments described in the associated paper.

### Non-[Docker](https://www.docker.com) option

In the top-level directory [`.third-parties/`](.third-parties/), run the following command

```bash
bash get-third-parties.sh # (~20 minutes)
```

In case the execution does not finished successfully, the script will print out a message informing the user of the error.  One should follow the instructions to fix the error and re-run the script.  In case the execution of the script finished successfully, one should see the message `DONE! All third parties have been successfully installed and configured.` on the stdout.

Visit the [INSTALL.md](INSTALL.md) file for more details.

## Experiment / Analysis A

<!-- TODO: TBA -->

## Experiment / Analysis B

<!-- TODO: TBA -->

## Experiment / Analysis C

<!-- TODO: TBA -->
