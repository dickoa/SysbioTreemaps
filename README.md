---
title: "Create Voronoi and Sunburst Treemaps from Hierarchical Data"
author: "Michael Jahn"
date: "2019-02-19"
output: github_document
#output: rmarkdown::html_vignette
#vignette: >
#  %\VignetteIndexEntry{}
#  %\VignetteEngine{knitr::rmarkdown}
#  %\VignetteEncoding{UTF-8}
---



## Description

This package can be used to generate and plot Voronoi treemaps or
sunburst treemaps from hierarchical data. 

<img src="vignettes/tm.png" title="plot of chunk unnamed-chunk-3" alt="plot of chunk unnamed-chunk-3" width="600px" style="display: block; margin: auto;" />

There are different implementations for
Voronoi tesselations in R, the simplest being the deldir() function (from package
deldir). However, deldir and other do not handle nested Voronoi tesselations, nor
do they perform additively weighted Voronoi tesselation. This is an important
demand for systems biology and other applications where one likes to scale the cell
size (or area) to a set of predefined weights. The functions provided in this package
allow both the additively weighted Voronoi tesselation, and the nesting of different
hierarchical levels in one plot. The underlying functions for the tesselation
were developed and published by Paul Murrell, University of Auckland, and serve
as the basis for this package. They are called by a recursive wrapper function,
voronoiTreemap(), which subdivides the plot area in polygonal cells according to
the highest hierarchical level.  It then continues with the tesselation on the next 
lower level uisng the child cell of the previous level as the new parental plotting
cell, and so on. The sunburst treemap is a computationally less demanding treemap that
does not require iterative refinement, but simply generates circle sectors that are
sized according to predefined weights. It is also a arecursive algorithm and can be
used to draw sectors of different hierarchical level with increasing granularity.

## Requirements

The C++ code requires the [CGAL](https://www.cgal.org/download.html) library.
Installation for (Ubuntu-like) Linux:

`sudo apt install libcgal-dev`

## Installation

To install the package directly from github, use this function from devtools package:

```
require(devtools)
devtools::install_github(https://github.com/m-jahn/SysbioTreemaps)
```
The package is not available on CRAN yet. 

## Usage

Create a simple example data frame

```
library(dplyr)
library(SysbioTreemaps)

data <- tibble(
  A=rep(c("a", "b", "c"), each=15),
  B=sample(letters[4:13], 45, replace=TRUE),
  C=sample(1:100, 45)
) %>% arrange(A, B, C)
```

Compute the treemap. It will return a list of grid graphics objects.

```
tm <- voronoiTreemap(
  data = data,
  levels = c("A", "B", "C"),
  cell.size = "C",
  cell.color = "A",
  maxIteration = 50,
)
```
Draw the treempap.

```
drawTreemap(tm)
```

## References

The Voronoi tesselation is based on functions from Paul Murrell, https://www.stat.auckland.ac.nz/~paul/Reports/VoronoiTreemap/voronoiTreeMap.html 
