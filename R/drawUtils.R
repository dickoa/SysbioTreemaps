#' @importFrom grid gpar
#' @importFrom grid grid.polygon
#' @importFrom grid grid.text
#' @importFrom grid grid.lines
#' @importFrom scales rescale
#' @importFrom gpclib area.poly
#' @importFrom methods as
#' @importFrom methods new
#' @importFrom stats median

# function to coerce and rescale different types of input to 
# numeric range between 1 and 100 (for color coding)
convertInput <- function(x, from = NULL, to = c(1, 100)) {
  if (is.character(x)) {
    if (all(!is.na(suppressWarnings(as.numeric(x))))) {
      x = as.numeric(x)
    } else {
      x = as.factor(x) %>%
        as.numeric
    }
  }
  if (is.numeric(x)) {
    scales::rescale(x, 
      from = {if (!is.null(from)) from else range(x)}, 
      to = to) %>%
      round %>%
      replace(., . > to[2], to[2]) %>%
      replace(., . < to[1], to[1])
  } else {
    stop("Input data is not of type numeric, factor, or character. Color-coding impossible.")
  }
}

drawPoly <- function(p, name, fill, lwd, col) {
  if (length(p@pts)) {
    pts <- getpts(p)
    grid::grid.polygon(
      pts$x,
      pts$y,
      default = "native",
      gp = gpar(col = col, lwd = lwd, fill = fill),
      name = name)
  }
}

polyRangeX <- function(p) {
  if (length(p@pts)) {
    pts <- getpts(p)
    range(pts$x)
  } else {
    NA
  }
}

polyRangeY <- function(p) {
  if (length(p@pts)) {
    pts <- getpts(p)
    range(pts$y)
  } else {
    NA
  }
}

drawRegions <- function(
  result,
  debug = FALSE,
  label = TRUE,
  label.col = grey(0.5),
  lwd = 2, col = grey(0.8), 
  fill = NA)
{
  names <- result$names
  k <- result$k
  sites <- result$s
  
  # draw polygon, pass graphical parameters to drawPoly function
  mapply(drawPoly, k, names, fill = fill,
    SIMPLIFY=FALSE,
    MoreArgs = list(lwd = lwd, col = col)
  )
  
  if (label) {
    
    # function to determine label sizes for each individual cell
    # based on cell dimension and label character length
    cex = sqrt(unlist(result$a)) * 0.01 / nchar(names)  %>%
      round(1)
    grid::grid.text(names,
      sites$x,
      sites$y,
      default = "native",
      gp = gpar(cex = cex, col = label.col)
    )
    
  }
}

# calculate sector polygon from boundary input
draw_sector <- function(
  level,
  lower_bound,
  upper_bound,
  diameter_inner,
  diameter_sector,
  name,
  custom_color) {
  
  # compute_sector from lower and upper bounds and diameter arguments
  segment <- c(lower_bound, upper_bound) * 2 * pi
  a <- diameter_inner + (diameter_sector * (level - 1))
  z <- seq(segment[1], segment[2], by = pi/400)
  xx <- c(a * cos(z), rev((a + diameter_sector) * cos(z)))
  yy <- c(a * sin(z), rev((a + diameter_sector) * sin(z)))
  # rescale for canvas dimensions [0, 2000] and convert into gpclib polygon
  poly = suppressWarnings(as(list(x = (xx+1)*1000, y = (yy+1)*1000), "gpc.poly"))
  
  # return list of polygon properties
  list(
    name = name,
    poly = poly,
    area = gpclib::area.poly(poly),
    lower_bound = lower_bound,
    upper_bound = upper_bound,
    level = level,
    custom_color = custom_color
  )
  
}

# function to draw labels for voronoi treemap
draw_label_voronoi <- function(
  cells, 
  label_level, 
  label_size,
  label_color
) {
  
  lapply(rev(cells), function(tm_slot) {
    
    if (tm_slot$level %in% label_level) {
      
      # determine label sizes for each individual cell
      # based on cell dimension and label character length
      label_cex <- sqrt(tm_slot$area) / (100 * nchar(tm_slot$name)) %>% round(1)
        
      # additionally scale labels size and color from supplied options
      if (length(label_size) == 1) {
        label_cex <- label_cex * label_size
      } else {
        label_cex <- label_cex * label_size[which(label_level %in% tm_slot$level)]
      }
      
      # determine label color
      if (length(label_color) == 1) {
        label_col <- label_color
      } else {
        label_col <- label_color[which(label_level %in% tm_slot$level)]
      }
      
      # draw labels
      grid::grid.text(
        tm_slot$name,
        tm_slot$site[1],
        tm_slot$site[2],
        default = "native",
        gp = gpar(cex = label_cex, col = label_col)
      )
      
    }
  }) %>% invisible
  
}


# function to draw labels for sunburst treemap
draw_label_sunburst <- function(
  cells, 
  label_level, 
  label_size,
  label_color,
  diameter
) {
  
  lapply(cells, function(tm_slot) {
    
    if (tm_slot$level %in% label_level) {
      
      # determine label size and color from supplied options
      if (length(label_size) > 1) {
        label_cex <- label_size[1]
        warning("'label_size' should only have length 1. Using first argument.")
      } else {
        label_cex <- label_size
      }
      
      if (length(label_color) > 1) {
        label_col <- label_color[1]
        warning("'label_color' should only have length 1. Using first argument.")
      } else {
        label_col <- label_color
      }
      
      # compute_sector from lower and upper bounds and diameter arguments
      segment <- c(tm_slot$lower_bound, tm_slot$upper_bound) * 2 * pi
      z <- seq(segment[1], segment[2], by = pi/400)
      if (diameter * cos(stats::median(z)) >= 0) side = 1 else side = -1
      sinz <- sin(median(z))
      cosz <- cos(median(z))
      d1 <- diameter+0.02
      d2 <- diameter+0.05
      d3 <- diameter+0.10
      
      # draw label arcs
      z <- z[-c(1, length(z))]
      grid::grid.lines(
        (c(d1 * cos(z[1]), d2 * cos(z), d1 * cos(tail(z, 1)))+1)*1000,
        (c(d1 * sin(z[1]), d2 * sin(z), d1 * sin(tail(z, 1)))+1)*1000,
        default.units = "native",
        gp = gpar(lwd = label_cex, col = label_col)
      )

      # draw label lines
      grid::grid.lines(
        x = (c(d2 * cosz, d2 * cosz + 0.15 * cosz * abs(sinz), d3 * side)+1)*1000,
        y = (c(d2 * sinz, d2 * sinz + 0.15 * sinz * abs(sinz),
          d2 * sinz + 0.15 * sinz * abs(sinz))+1)*1000,
        default.units = "native",
        gp = gpar(lwd = label_cex, col = label_col)
      )
      
      #draw label text
      grid::grid.text(
        label = substr(tm_slot$name, 1, 18),
        x = ((d3+0.02) * side+1)*1000,
        y = ((d2 * sinz + 0.15 * sinz * abs(sinz))+1)*1000,
        just = ifelse(side == 1, "left", "right"),
        default.units = "native",
        gp = gpar(cex = label_cex, col = label_col)
      )
      
    }
  }) %>% invisible
}
