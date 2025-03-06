# This code includes commands to run the data processing code and send the 
# required inputs to fit the integrated model in JAGS.

# Initial setup ----
library(jagsUI)
source("codes/R/02-process_fish_data.R")

# These function are needed to provide known states and initial values for the
# state-space CJS model. It helps with model fitting run time. The codes are 
# based on the codes by Kéry & Schaub (2012) Bayesian Population Analysis Using 
# WinBUGS: A Hierarchical Perspective.
source("codes/R/00-function_known_state.R")
source("codes/R/00-function_init_z.R")

# Paths and names of model and output files ----
model_file <- "codes/JAGS/model.R"
out_file <- "out_fit_dat.rds"

## Set up MCMC run ----
ni <- 2e6
nb <- ni / 2
nt <- (ni - nb) / 1000
nc <- 4
parcomp <- TRUE


# Set up for JAGS ----

## Bundle data ----

jdat <- list(I = nrow(res_dat), r = res_dat$fw_res,
             rel_id = res_dat$rel_id, rydt = res_dat$rel_ydt, 
             rfl2 = rf_dat$rainfall_l2_sdy, zrfl2 = rf_dat$zrainfall_l2_sdy,
             max.yday = max_yday, min.yday = min_yday,
             l = as.vector(scale(res_dat$length)),
             lower = res_dat$lower, upper = res_dat$upper, lake = res_dat$lake, 
             may23 = res_dat$may23, june09 = res_dat$june09, 
             june19 = res_dat$june19, a1.down = a1_down,
             y = dh, z = known_state(dh)) # note use of function to pass known states to JAGS 

## Make initial values function ----
z_ini <- init_z(dh)

ini <- function(){list(nu.r = runif(9, 2, 6), 
                       shape.nu.r = runif(1, 1, 3),
                       rate.nu.r = runif(1, 1, 3),
                       alpha.r = runif(1, -1, 1),
                       beta.r = c(runif(1, -1, 1), runif(8, -1, 1)),
                       alpha.phi = runif(1, -1, 1),
                       beta.phi = c(runif(1, -1, 1), runif(8, -1, 1)),
                       alpha.p = runif(1, -1, 1),
                       beta.p = runif(1, -1, 0),
                       z = z_ini)}

## Set parameters to monitor ----
pars <- c("nu.r", "alpha.r", "beta.r", "mu.r", "r.rep", "shape.nu.r", 
          "rate.nu.r", "alpha.phi", "beta.phi", "alpha.p", "phi", "mu_phi2",
          "beta.p", "p", "y.rep", "e", "te")

# Run JAGS ---- 

# Set seed to reproduce the exact same results as shown in the paper.
set.seed(123)

fit <- jagsUI(jdat, ini, pars, model_file, 
              n.chains = nc, n.iter = ni, n.burnin = nb, n.thin = nt, 
              parallel = parcomp)

saveRDS(list(fit = fit, jdat = jdat),
        paste("outputs/", out_file, sep =""))
