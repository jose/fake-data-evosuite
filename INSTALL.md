# Install

This markdown file provides installation instructions of any required software.

The top-level directory [`.third-parties/`](.third-parties/) provides a script named [`get-third-parties.sh`](.third-parties/get-third-parties.sh) which is responsible for automatically:

- Assessing whether the requirements described in [REQUIREMENTS.md](REQUIREMENTS.md) are fulfilled.
- Installing a specific version of Java (i.e., JDK 8u292-b10) in the top-level directory [`.third-parties/`](.third-parties/).
- Installing a specific version of [Apache Maven](https://maven.apache.org/index.html) (i.e., v3.8.8).
- Getting [SF110](https://www.evosuite.org/experimental-data/sf110) v20130704 dataset.
- Installing the latest version of [EvoSuite](https://github.com/EvoSuite/evosuite) vanilla (i.e., 6d2e848c683e15ce9eb9a7ace506993ea46db022).
- Installing the following [R](https://www.r-project.org)'s packages under user's R's library directory through the [`get-libraries.R`](get-libraries.R) script:
  * [data.table: Extension of 'data.frame'](https://cran.r-project.org/web/packages/data.table/index.html)
  * [stringr: Simple, Consistent Wrappers for Common String Operations](https://cran.r-project.org/web/packages/stringr/index.html)
  * [ggplot2: Create Elegant Data Visualisations Using the Grammar of Graphics](https://cran.r-project.org/web/packages/ggplot2/index.html)
  * [extrafont: Tools for Using Fonts](https://cran.r-project.org/web/packages/extrafont/index.html)

and it can be executed as:

```bash
bash get-third-parties.sh # (~20 minutes)
```

In case the execution does not finished successfully, the script will print out a message informing the user of the error.  One should follow the instructions to fix the error and re-run the script.  In case the execution of the script finished successfully, one should see the message `DONE! All third parties have been successfully installed and configured.` on the stdout.
