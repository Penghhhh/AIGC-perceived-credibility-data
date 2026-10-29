# ==============================================================================
# Study 1: A-priori & Post-hoc Power Analysis via Monte Carlo Simulation
# Design  : Fully crossed random effects (Participants x Reviews)
# Model   : Multilevel moderated mediation (detection label -> perceived AI
#           authorship -> perceived credibility, moderated by confidence in
#           the platform's AI detection system)
# ==============================================================================
# Purpose (manuscript Section 2.3):
#   * A-priori power: minimum planned sample (N = 80 participants, each rating
#     all 20 reviews -> 1,600 trials).
#   * Post-hoc power : actual final sample (N = 93 participants -> 1,860
#     trials).
#
# Effect-size assumptions (SESOI, smallest effect sizes of interest):
#   * detection label -> perceived AI authorship (a0):      beta = 0.20
#   * detection label x confidence -> AI authorship (a1):   beta = 0.20
#   * perceived AI authorship -> perceived credibility (b): beta = -0.25
#   * residual direct effect label -> credibility (c'):     beta = -0.10
#
# Random-effect variance structure is calibrated to the real data (final
# version):
#   first stage (perceived AI authorship):
#     participant random intercept  sd ~ 0.45  (data: 0.435)
#     participant random slope      sd ~ 0.35  (data: 0.376)
#     review random intercept       sd ~ 1.20  (data: 1.251)
#     review random slope           sd ~ 0.20  (data: 0.181)
#     residual                      sd ~ 1.15  (data: 1.160)
#   second stage (perceived credibility):
#     participant random intercept  sd ~ 0.30  (data: 0.278)
#     review random intercept       sd ~ 0.15  (data: 0.131)
#     residual                      sd ~ 0.70  (data: 0.704)
#
# Power definition: joint-significance test of the moderated-mediation chain,
# i.e., both the interaction term (label x confidence, a1) and the b path
# (AI authorship -> credibility) are significant at alpha = 0.05.
# ==============================================================================

# ---- packages (install automatically if missing) ----
if (!require(lme4)) install.packages("lme4")
if (!require(lmerTest)) install.packages("lmerTest")

library(lme4)
library(lmerTest)

# ---- 1. Simulation parameters ----
# ------------------------------------------------------------------------------
# SESOI (smallest effect sizes of interest), unstandardized slopes
SESOI_a0 <- 0.20   # detection label -> perceived AI authorship (a0)
SESOI_a1 <- 0.20   # detection label x confidence (a1, interaction)
SESOI_b  <- -0.25  # perceived AI authorship -> perceived credibility (b)
SESOI_cp <- -0.10  # residual direct effect: label -> credibility (c')

# Random-effect SDs, first stage (mediator: perceived AI authorship)
sd_sub_int_aj <- 0.45  # participant random intercept
sd_sub_slp_aj <- 0.35  # participant random slope of label
sd_itm_int_aj <- 1.20  # review (stimulus) random intercept
sd_itm_slp_aj <- 0.20  # review (stimulus) random slope of label
sd_resid_aj   <- 1.15  # level-1 residual

# Random-effect SDs, second stage (outcome: perceived credibility)
sd_sub_int_pc <- 0.30  # participant random intercept
sd_itm_int_pc <- 0.15  # review (stimulus) random intercept
sd_resid_pc   <- 0.70  # level-1 residual

# ---- 2. Core simulation function ----
# ------------------------------------------------------------------------------
simulate_power <- function(n_subj, n_item = 20, n_sim = 1000, seed = 20240829) {

  set.seed(seed)

  cat(sprintf("\nStarting simulation for N_subj = %d, N_sim = %d...\n",
              n_subj, n_sim))

  res <- vapply(1:n_sim, function(i) {

    # Step A: participant-level data
    #   (between-subject random effects + grand-mean centered confidence)
    sub_df <- data.frame(
      participant_id = factor(1:n_subj),
      confidence_c   = rnorm(n_subj, mean = 0, sd = 1),
      u0_sub_aj      = rnorm(n_subj, 0, sd_sub_int_aj),
      u1_sub_aj      = rnorm(n_subj, 0, sd_sub_slp_aj),
      u0_sub_pc      = rnorm(n_subj, 0, sd_sub_int_pc)
    )

    # Step B: review-level data (crossed random effects of the stimuli)
    itm_df <- data.frame(
      review_id = factor(1:n_item),
      u0_itm_aj = rnorm(n_item, 0, sd_itm_int_aj),
      u1_itm_aj = rnorm(n_item, 0, sd_itm_slp_aj),
      u0_itm_pc = rnorm(n_item, 0, sd_itm_int_pc)
    )

    # Step C: fully crossed participant x review grid
    sim_df <- expand.grid(participant_id = factor(1:n_subj),
                          review_id = factor(1:n_item))
    sim_df <- merge(sim_df, sub_df, by = "participant_id")
    sim_df <- merge(sim_df, itm_df, by = "review_id")
    sim_df <- sim_df[order(sim_df$participant_id, sim_df$review_id), ]

    # Within-participant label assignment: exactly 10 unlabeled (-0.5) and
    # 10 labeled (+0.5) reviews per participant (effect coding)
    sim_df$detection_label_c <- as.vector(replicate(
      n_subj,
      sample(c(rep(-0.5, n_item / 2), rep(0.5, n_item / 2)))))

    # Step D: generate the outcome variables
    sim_df$e_aj <- rnorm(nrow(sim_df), 0, sd_resid_aj)
    sim_df$perceived_ai_authorship <-
      0 +
      (SESOI_a0 + sim_df$u1_sub_aj + sim_df$u1_itm_aj) * sim_df$detection_label_c +
      0.20 * sim_df$confidence_c +          # assumed baseline effect of confidence
      SESOI_a1 * sim_df$detection_label_c * sim_df$confidence_c +
      sim_df$u0_sub_aj + sim_df$u0_itm_aj + sim_df$e_aj

    sim_df$e_pc <- rnorm(nrow(sim_df), 0, sd_resid_pc)
    sim_df$perceived_credibility <-
      0 +
      SESOI_b  * sim_df$perceived_ai_authorship +
      SESOI_cp * sim_df$detection_label_c +
      sim_df$u0_sub_pc + sim_df$u0_itm_pc + sim_df$e_pc

    # Step E: fit the two multilevel models
    #   (uncorrelated random slopes ||, bobyqa optimizer for speed)
    ctrl <- lmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 20000))

    # M1: first stage - predict perceived AI authorship
    m1 <- suppressWarnings(try(
      lmer(perceived_ai_authorship ~ detection_label_c * confidence_c +
             (1 + detection_label_c || participant_id) +
             (1 + detection_label_c || review_id),
           data = sim_df, control = ctrl), silent = TRUE))

    # M2: second stage - predict perceived credibility
    m2 <- suppressWarnings(try(
      lmer(perceived_credibility ~ perceived_ai_authorship + detection_label_c +
             (1 | participant_id) + (1 | review_id),
           data = sim_df, control = ctrl), silent = TRUE))

    # Step F: extract p-values for the joint-significance test
    p_a1 <- 1
    p_b  <- 1

    if (!inherits(m1, "try-error")) {
      sum_m1 <- summary(m1)$coefficients
      if ("detection_label_c:confidence_c" %in% rownames(sum_m1))
        p_a1 <- sum_m1["detection_label_c:confidence_c", "Pr(>|t|)"]
    }
    if (!inherits(m2, "try-error")) {
      sum_m2 <- summary(m2)$coefficients
      if ("perceived_ai_authorship" %in% rownames(sum_m2))
        p_b <- sum_m2["perceived_ai_authorship", "Pr(>|t|)"]
    }

    # success only if both paths are significant at alpha = 0.05
    return(ifelse(p_a1 < 0.05 & p_b < 0.05, 1, 0))
  }, numeric(1))

  power_est <- mean(res, na.rm = TRUE)
  cat(sprintf("\n==> Estimated Power (N = %d): %.2f%%\n\n",
              n_subj, power_est * 100))
  return(power_est * 100)
}

# ---- 3. A-priori and post-hoc power ----
# ------------------------------------------------------------------------------
N_SIM <- 1000

# A. A-priori sample-size planning: planned N = 80
power_apriori <- simulate_power(n_subj = 80, n_item = 20, n_sim = N_SIM,
                                seed = 123)

# B. Post-hoc power: actual final N = 93
power_posthoc <- simulate_power(n_subj = 93, n_item = 20, n_sim = N_SIM,
                                seed = 456)

cat(sprintf("[Final results]\n"))
cat(sprintf("- A-priori planning (N = 80):  %.2f%%\n", power_apriori))
cat(sprintf("- Post-hoc power  (N = 93):   %.2f%%\n", power_posthoc))
