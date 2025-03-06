model {
  
  # Freshwater residence model ----
  
  ## Likelihood ----
  
  for (i in 1:I) {
 
    # Using generalized gamma with r = 1 so that a Weibull distribution is 
    # assumed for freshwater residence time. This function implements the
    # accelerated failure time parameterization of the Weibull, which converges 
    # faster than using the function dweibull, which uses a proportional hazards 
    # parameterization.See JAGS manual for more details and this post:
    # https://sourceforge.net/p/mcmc-jags/discussion/610037/thread/5bc96037/
    
    r[i] ~ dggamma(1, lam.r[i], nu.r[rel_id[i]])
 
    log(lam.r[i]) <- alpha.r +
                     beta.r[1] * l[i] +
                     beta.r[2] * upper[i] +
                     beta.r[3] * lake[i] +
                     beta.r[4] * june09[i] +
                     beta.r[5] * june19[i] +
                     beta.r[6] * lake[i] * june09[i] +
                     beta.r[7] * lake[i] * june19[i] +
                     beta.r[8] * upper[i] * june09[i] +
                     beta.r[9] * upper[i] * june19[i]
  }
    
  
  ## Priors ----
  
  for (g in 1:9) {
    nu.r[g] ~ dgamma(shape.nu.r, rate.nu.r)
  }
  
  shape.nu.r ~ dgamma(0.1, 0.1)
  
  rate.nu.r ~ dgamma(0.1, 0.1)
  
  alpha.r ~ dnorm(0, 0.1)
  
  for (b in 1:9) {
    beta.r[b] ~ dnorm(0, 0.1)
  }
  
  # Derived quantities ----
  
  ## Quantities for model check ----
  
  for (i in 1:I) {
    r.rep[i] ~ dggamma(1, lam.r[i], nu.r[rel_id[i]])
  }
  
  ## Quantities for CJS model (exit day) ----  

  for (i in 1:I) {
    e[i] <- rydt[i] + r[i]
    te[i] <- ifelse(trunc(e[i]) > max.yday,
                    # For r[i] samples that added to e[i] exceeded the maximum
                    # duration of study (infrequent), use the last day of study
                    max.yday - (min.yday - 1),
                    trunc(e[i]) - (min.yday - 1))
  }


  # CJS Model (state-space formulation) ----

  # Likelihood ----

  # Survival between release and the first array

  for (i in 1:I) {
    logit(phi[i, 1]) <- alpha.phi +
                        beta.phi[1] * l[i] +
                        beta.phi[2] * upper[i] +
                        beta.phi[3] * lake[i] +
                        beta.phi[4] * june09[i] +
                        beta.phi[5] * june19[i] +
                        beta.phi[6] * lake[i] * june09[i] +
                        beta.phi[7] * lake[i] * june19[i] +
                        beta.phi[8] * upper[i] * june09[i] +
                        beta.phi[9] * upper[i] * june19[i]
    
    # Survival between antennas is assumed the same regardless of size and 
    # release site and date. The parameter mu_phi2 is assigned a vague prior 
    # below.
    phi[i, 2] <- mu_phi2
    
    # Detection probability as a function of 2-day lagged rainfall
    p[i, 2] <- ilogit(alpha.p + beta.p[1] * zrfl2[te[i]])
    
    # Detection probability set to 0 observed or predicted date of passage by 
    # array falls within period lower antenna was down. Otherwise, detection is 
    # a function of 2-day lagged rainfall.
    p[i, 3] <- ifelse(te[i] >= a1.down[1] && te[i] <= a1.down[2],
                      0,
                      ilogit(alpha.p + beta.p[1] * zrfl2[te[i]]))

    for (s in 2:3) {# s = 1: release; s = 2: upper antenna; s = 3: lower antenna
      ### State process ----
      z[i, s] ~ dbern(phi[i, s - 1 ] * z[i, s - 1])
      ### Observation process ----
      y[i, s] ~ dbern(p[i, s] * z[i, s])
    }

  }

  # Priors ----

  alpha.phi ~ dnorm(0, 0.1)

  for (b in 1:9) {
    beta.phi[b] ~ dnorm(0, 0.1)
  }

  mu_phi2 ~ dbeta(1, 1)

  alpha.p ~ dnorm(0, 0.1)

  beta.p ~ dnorm(0, 0.1)

  # Derived quantities ----

  ## Quantities for model check ----

  for (i in 1:I) {
    for (s in 2:3) {
      y.rep[i, s] ~ dbern(p[i, s] * z[i, s])
    }
  }

}