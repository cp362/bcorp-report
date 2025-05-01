library(ggplot2)
library(tidyverse)
library(thematic)
library(ragg)
library(showtext)

posit_colors <- list(
  blue = "#447099",
  grey = "#404041",
  orange = "#EE6331",
  dark_blue_2 = "#213D4F",
  dark_blue_3 = "#17212B",
  light_blue_1 = "#D1DBE5",
  light_blue_2 = "#A2B8CB"
)

thematic_on(
  bg = "white",
  fg = posit_colors$grey,
  accent = posit_colors$blue,
  font = "Open Sans"
)

python <- read_csv(here("data", "python_package_downloads.csv"))
r <- read_csv(here("data", "r_package_downloads.csv"))
rstudio <- read_csv(here("data", "rstudio_os_downloads.csv"))
quarto <- read_csv(here("data", "quarto_downloads.csv"))

plot_defaults <- list(
  scale_y_continuous(
    labels = scales::label_number(scale_cut = scales::cut_short_scale())
  ),
  xlab(""),
  ylab("Cumulative Downloads"),
  theme(
    panel.background = element_rect(fill = "#EDF0F5"),
    plot.margin = margin(5.5, 8.5, 5.5, 5.5)
  )
)

growth_plot <- function(data, y = downloads) {
  data |>
    ggplot(aes(x = date, y = cumsum(as.numeric(downloads)))) +
    geom_line(color = posit_colors$blue, linewidth = 0.75) +
    scale_x_date(labels = scales::label_date_short()) +
    plot_defaults
}
