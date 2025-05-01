# Posit's Benefit Corporation Annual Report

This repository holds the source for the PDF version of Posit's Benefit Corporation Annual Report found at <https://posit.co/about/pbc-report/>.

The report content lives in `pbc-report.qmd` and is produced using `format: typst` with the custom template partials in `typst-template.typ` and `typst-show.typ`.

## Local rendering

The plots are generated on render so you'll need R. 
When you first open the project (in RStudio or Positron), renv should bootstrap itself:

```
# Bootstrapping renv 1.0.5 ---------------------------------------------------
- Downloading renv ... 
OK
- Installing renv  ... OK

- Project '~/Desktop/bcorp-report' loaded. [renv 1.0.5]
- One or more packages recorded in the lockfile are not installed.
- Use `renv::status()` for more details.
```

Then to get the required packages, on the R Console, run:

```{.r}
renv::restore()
```

To preview the report:

```{.bash}
quarto preview pbc-report.qmd
```

