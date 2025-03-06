# This code includes commands to generate figures of presented in Supplement S1

# Initial setup ----
library(MCMCvis)
library(tidyverse)
library(bayesplot)
library(gridExtra)
library(here)

out <- readRDS(paste("outputs/out_fit_dat.rds", sep = ""))
fit <- out$fit
jdat <- out$jdat
mcmc <- fit$samples
ns <- fit$mcmc.info$n.samples

# Figure S1 - PPC plot for freshwater residence model ----

r_obs <- as.vector(na.exclude(jdat$r))

not_na <- which(!is.na(jdat$r))

r_rep <- matrix(NA, nrow = ns, ncol = length(not_na))

for (j in 1:ns) {
  r_rep[j, ] <- as.vector(fit$sims.list$r.rep[j, ])[not_na]
}

A <- ppc_dens_overlay(r_obs, r_rep) + 
  annotate("text", x = 92, y = 0.044,  label = "(a)", size = 4) +
  xlab("Freshwater residence (days)") +
  ylab("Density") +
  theme_bw() + 
  theme(legend.position = "top")

B <- ppc_stat(r_obs, r_rep, stat = "mean", binwidth = 0.1) + 
  xlab("Freshwater residence (days)") +
  ylab("Frequency") +
  annotate("text", x = 15.4, y = 575,  label = "(b)", size = 4) +
  theme_bw() + 
  theme(legend.position = "top")

C <- ppc_stat(r_obs, r_rep, stat = "max", binwidth = 1) + 
  annotate("text", x = 98, y = 225,  label = "(c)", size = 4) +
  xlab("Freshwater residence (days)") +
  ylab("Frequency") +
  theme_bw() + 
  theme(legend.position = "top")

D <- ppc_stat(r_obs, r_rep, stat = "min", binwidth = 0.05) + 
  annotate("text", x = 0.6, y = 3600,  label = "(d)", size = 4) +
  xlab("Freshwater residence (days)") +
  ylab("Frequency") +
  theme_bw() + 
  theme(legend.position = "top")

grid.arrange(A, B, C, D, nrow = 2)

# # Figure S2 - PPC plot for state-space CJS model ----

# Observed frequencies of detection histories
y_obs <- as.data.frame(jdat$y[, 2:3]) %>%
  mutate(dh = paste(1, a2, a1, sep = "")) %>%
  count(dh)

# Observed frequencies of detection histories

y_rep <- data.frame()

for (j in 1:ns) {
  df_tmp <- as.data.frame(fit$sims.list$y.rep[j, , 2:3]) %>%
    mutate(dh = paste(1, V1, V2, sep = "")) %>%
    count(dh) %>%
    mutate(iter = j)
  
  y_rep <- rbind(y_rep, df_tmp)
}

# Plot observed vs expected frequencies
ggplot(y_rep, aes(x = n)) +
  geom_histogram(fill = "gray", colour = "black") +
  geom_vline(data = y_obs, aes(xintercept = n), colour = "blue", linewidth = 1) +
  scale_y_continuous(expand = c(0, 0, 0.1, 0.1)) +
  xlab("Number of detection histories") +
  ylab("Frequency") +
  facet_wrap(~ dh, scales = "free") +
  theme_bw() +
  theme(axis.title = element_text(size = 16),
        axis.text = element_text(size = 12),
        strip.text = element_text(size = 14))