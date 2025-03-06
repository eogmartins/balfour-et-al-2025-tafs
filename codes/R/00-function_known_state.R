known_state <- function(x) {
  state <- x
  for (i in 1:nrow(x)){
    n1 <- 1
    n2 <- max(which(x[i, ] == 1))
    state[i, n1:n2] <- 1
    }
  state[state == 0] <- NA
  
  return(state)
}