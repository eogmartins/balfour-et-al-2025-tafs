init_z <- function(x) {
  for (i in 1:nrow(x)) {
    if (sum(x[i, ]) == 1) { 
      next 
    } else {
      n2 <- max(which(x[i, ] == 1))
      x[i, 1:n2] <- NA
    }
  }
  x[, 1] <- NA
  return(x)
}