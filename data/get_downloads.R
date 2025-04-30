library(here)
library(cranlogs)
library(bigrquery)
library(gh)
library(jsonlite)
library(tidyverse)
library(tidymodels)

# Python Package Downloads -----------------------------------------------

# https://packaging.python.org/en/latest/guides/analyzing-pypi-package-downloads/
# Set up new Google Big Query project: `pypi-downloads-458318`
billing <- "pypi-downloads-458318"

python_packages <- c("great-tables", "shiny", "vetiver", "plotnine", "siuba")
packages_sql <- paste0("'", paste(python_packages, collapse = "','"), "'")

mirrors <- c("bandersnatch", "z3c.pypimirror", "Artifactory", "devpi")
mirrors_sql <- paste0("'", paste(mirrors, collapse = "','"), "'")

sql <- sprintf(
  "
SELECT 
    COUNT(*) AS downloads,
    DATE(timestamp) AS `date`,
    file.project AS package
FROM `bigquery-public-data.pypi.file_downloads`
WHERE
    file.project IN (%s)
    AND DATE(timestamp) >= '2023-10-25'
    AND details.installer.name NOT IN (%s)
GROUP BY `date`, file.project
ORDER BY `date`",
  packages_sql,
  mirrors_sql
)

tb <- bq_project_query(billing, sql)
python_downloads <- bq_table_download(tb)
python_downloads |> write_csv(here("data", "python_package_downloads.csv"))

# R Package Downloads ------------------------------------------------------
tidyverse <- tibble(
  package = tidyverse_packages(FALSE),
  project = "tidyverse"
)

tidymodels <- tibble(
  package = tidymodels_packages(FALSE),
  project = "tidymodels"
)

repos_json <- gh::gh("/orgs/{org}/repos", org = "r-lib", .limit = Inf)
names <- sapply(repos_json, "[[", "name")
rlib_repos <- intersect(names, rownames(available.packages()))

rlib <- tibble(
  package = rlib_repos,
  project = "r-lib"
)

connectivity <- tibble(
  package = c("sparklyr", "tensorflow", "keras", "odbc", "reticulate"),
  project = "connectivity"
)

r_packages <-
  tibble(
    package = c("shiny", "gt", "vetiver", "webR"),
    project = c("shiny", "gt", "vetiver", "webR"),
  ) |>
  bind_rows(
    tidyverse,
    tidymodels,
    rlib,
    connectivity
  )

r_package_downloads <- r_packages |>
  rowwise() |>
  mutate(downloads = list(cran_downloads(package, from = "2017-01-01")))

r_package_downloads |>
  unnest(downloads, names_sep = "_") |>
  select(-downloads_package) |>
  rename(date = downloads_date, downloads = downloads_count) |>
  write_csv(here("data", "r_package_downloads.csv"))

# IDE downloads ----------------------------------------------------------

#----RStudio and Quarto downloads
# DOWNLOAD_URL <- "https://www.rstudio.org/internal/metrics/downloads.csv.gz"

rstudio_dls <-
  read_csv(
    here("data", "downloads.csv"),
    col_names = c("filename", "date", "downloads")
  ) |>
  filter(date >= ymd("2017-01-01"))

rstudio_dls <- rstudio_dls %>%
  mutate(
    type = case_when(
      str_detect(filename, "docs|admin-guide") ~ "docs",
      str_detect(filename, "-monitor-") ~ "monitor",
      str_detect(filename, "rstudio-server-pro") ~ "RSP",
      str_detect(filename, "rstudio-server") ~ "RS-os",
      str_detect(filename, "rstudio-connect") ~ "RSC",
      str_detect(filename, "shiny-server-commercial") ~ "SSP",
      str_detect(filename, "shiny-server") ~ "SS-os",
      str_detect(filename, "rstudio-pm") ~ "RSPM",
      str_detect(filename, regex("^rstudio-", ignore_case = TRUE)) ~ "desktop",
      str_detect(filename, "^desktop") ~ "desktop",
      #RZ additions
      str_detect(filename, "electron") ~ "desktop",
      str_detect(filename, "quarto-") ~ "quarto"
    )
  )

## Just keep open-source/desktop rstudio dls.
rstudio_open_source_downloads <- rstudio_dls |>
  filter(type %in% c("RS-os", "desktop"))
rstudio_open_source_downloads |>
  group_by(date) |>
  summarise(downloads = sum(downloads)) |>
  write_csv(here("data", "rstudio_os_downloads.csv"))

## Quarto downloads from when it was hosted on rstudio.com
quarto_rstudio_dls <-
  rstudio_dls |>
  filter(type %in% c("quarto")) |>
  mutate(
    version = str_extract(filename, "[01]\\.[0-9]\\.[0-9]+"),
    major_minor = str_extract(version, "[01]\\.[0-9]"),
  )


# Quarto Downloads -------------------------------------------------------

# Run helper script to generate `releases.csv`
# ./helpers/github_quarto.sh

releases <- read_csv(here("data", "releases.csv")) |>
  filter(!str_detect(name, "changelog"), !str_detect(name, "checksums")) %>%
  rename(downloads = download_count, filename = name) |>
  mutate(
    date = date(created),
    version = str_extract(filename, "[01]\\.[0-9]\\.[0-9]+"),
    major_minor = str_extract(version, "[01]\\.[0-9]")
  )


releases |>
  bind_rows(quarto_rstudio_dls) |>
  mutate(
    major_minor = ifelse(major_minor %in% c("0.2", "0.3"), "0.9", major_minor)
  ) |>
  group_by(major_minor) |>
  summarise(
    downloads = sum(downloads),
    min_date = min(as.Date(date)),
    max_date = max(as.Date(date))
  ) |>
  write_csv(here("data", "quarto_downloads.csv"))
