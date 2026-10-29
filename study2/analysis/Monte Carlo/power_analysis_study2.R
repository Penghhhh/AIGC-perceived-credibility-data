# ==============================================================================
# Study 2: Monte Carlo Power Analysis (Corrected & Calibrated)
# Design  : 2 (detection label) x 2 (disclosure label) fully within-person,
#           with post-stimulus fixed effects (4 posts)
# Model   : Dual mediation - detection / disclosure labels -> perceived AI
#           authorship & psychological discomfort -> perceived credibility
# ==============================================================================
# Purpose (manuscript Section 3.3):
#   * A-priori power: minimum planned sample (N = 145)
#   * Post-hoc power : actual final sample (N = 149)
#
# Predictors are EFFECT CODED {-0.5, +0.5} exactly as in the real data:
#   detection_label  : -0.5 = absent, +0.5 = present
#   disclosure_label : -0.5 = absent, +0.5 = present
#   detection_x_disclosure = detection_label * disclosure_label
#
# Effect-size assumptions (SESOI; manuscript Section 3.3):
#   perceived AI authorship:
#     disclosure label -> AI authorship   beta = 0.40  (main driver)
#     detection label -> AI authorship    beta = 0.20
#     interaction                         beta = -0.25 (subadditivity)
#   psychological discomfort:
#     detection label -> discomfort       beta = 0.30  (main driver)
#     disclosure label -> discomfort      beta = 0.15
#     interaction                         beta = -0.15
#   perceived credibility (trimmed model):
#     perceived AI authorship -> credibility  beta = -0.30
#     psychological discomfort -> credibility beta = -0.18
#
# Post-stimulus (material) fixed effects for the 4 posts:
#   post_effects_auth / post_effects_disc / post_effects_cred
#
# Variance structure (random intercept SDs and residual SDs per outcome):
#   sd_participant_*: 0.35 / 0.60 / 0.40 ; residual: 0.95 / 0.85 / 0.85
#
# Power definition (joint-significance):
#   * discomfort path  : detection label -> discomfort AND discomfort ->
#                        credibility both significant at alpha = .05
#   * AI-authorship path: disclosure label -> AI authorship AND AI authorship
#                        -> credibility both significant
# ==============================================================================

# ---- packages (install automatically if missing) ----
if (!require(lme4)) install.packages("lme4")
if (!require(lmerTest)) install.packages("lmerTest")

library(lme4)
library(lmerTest)

# ---- 1. Simulation parameters (SESOI) ----
# ------------------------------------------------------------------------------
# Paths into perceived AI authorship
SESOI_dis_auth <- 0.40   # disclosure label -> AI authorship
SESOI_det_auth <- 0.20   # detection label -> AI authorship
SESOI_ix_auth  <- -0.25  # detection x disclosure interaction

# Paths into psychological discomfort
SESOI_det_disc <- 0.30   # detection label -> discomfort (main driver)
SESOI_dis_disc <- 0.15   # disclosure label -> discomfort
SESOI_ix_disc  <- -0.15  # detection x disclosure interaction

# Paths out of the mediators into perceived credibility (trimmed model:
# no direct paths from the labels to credibility)
SESOI_auth_cred <- -0.30  # AI authorship -> credibility
SESOI_disc_cred <- -0.18  # discomfort -> credibility (weaker b path)

# Post-stimulus (material) fixed effects (4 posts; post 1 = reference)
post_effects_auth <- c(0, 0.10, -0.10, 0.05)
post_effects_disc <- c(0, -0.10, 0.15, -0.05)
post_effects_cred <- c(0, 0.10, -0.10, 0.05)

# Random intercept (between-participant) SDs and residual SDs
sd_sub_auth <- 0.35; sd_res_auth <- 0.95
sd_sub_disc <- 0.60; sd_res_disc <- 0.85
sd_sub_cred <- 0.40; sd_res_cred <- 0.85

# ---- 2. Core simulation function ----
# ------------------------------------------------------------------------------
simulate_study2_power <- function(n_subj, n_sim = 1000, seed = 20240906) {
  set.seed(seed)
  cat(sprintf("\nRunning Study 2 Simulation for N = %d (%d draws)...\n",
              n_subj, n_sim))

  res <- vapply(1:n_sim, function(i) {
    # Each participant sees all four label conditions (fully within-person,
    # effect coded) and the four posts are randomly assigned to the cells
    df_list <- lapply(1:n_subj, function(pid) {
      conds <- data.frame(
        participant_id   = pid,
        detection_label  = c(-0.5, 0.5, -0.5, 0.5),
        disclosure_label = c(-0.5, -0.5, 0.5, 0.5),
        post_id = sample(1:4, 4, replace = FALSE)
      )
      conds$detection_x_disclosure <-
        conds$detection_label * conds$disclosure_label

      u0_auth <- rnorm(1, 0, sd_sub_auth)
      u0_disc <- rnorm(1, 0, sd_sub_disc)
      u0_cred <- rnorm(1, 0, sd_sub_cred)

      # generate the two mediators and the outcome
      conds$perceived_ai_authorship <- 4.0 +
        SESOI_det_auth * conds$detection_label +
        SESOI_dis_auth * conds$disclosure_label +
        SESOI_ix_auth  * conds$detection_x_disclosure +
        post_effects_auth[conds$post_id] + u0_auth + rnorm(4, 0, sd_res_auth)

      conds$psychological_discomfort <- 3.0 +
        SESOI_det_disc * conds$detection_label +
        SESOI_dis_disc * conds$disclosure_label +
        SESOI_ix_disc  * conds$detection_x_disclosure +
        post_effects_disc[conds$post_id] + u0_disc + rnorm(4, 0, sd_res_disc)

      conds$perceived_credibility <- 5.0 +
        SESOI_auth_cred * conds$perceived_ai_authorship +
        SESOI_disc_cred * conds$psychological_discomfort +
        post_effects_cred[conds$post_id] + u0_cred + rnorm(4, 0, sd_res_cred)

      conds
    })

    df <- do.call(rbind, df_list)
    df$post_id <- as.factor(df$post_id)

    ctrl <- lmerControl(optimizer = "bobyqa")

    # mediator / outcome equations (post as fixed factor)
    m_auth <- suppressWarnings(try(
      lmer(perceived_ai_authorship ~ detection_label + disclosure_label +
             detection_x_disclosure + post_id + (1 | participant_id),
           data = df, control = ctrl), silent = TRUE))
    m_disc <- suppressWarnings(try(
      lmer(psychological_discomfort ~ detection_label + disclosure_label +
             detection_x_disclosure + post_id + (1 | participant_id),
           data = df, control = ctrl), silent = TRUE))
    m_cred <- suppressWarnings(try(
      lmer(perceived_credibility ~ perceived_ai_authorship +
             psychological_discomfort + post_id + (1 | participant_id),
           data = df, control = ctrl), silent = TRUE))

    p_det_disc <- 1; p_disc_cred <- 1; p_dis_auth <- 1; p_auth_cred <- 1

    if (!inherits(m_disc, "try-error")) {
      s_disc <- summary(m_disc)$coefficients
      if ("detection_label" %in% rownames(s_disc))
        p_det_disc <- s_disc["detection_label", "Pr(>|t|)"]
    }
    if (!inherits(m_auth, "try-error")) {
      s_auth <- summary(m_auth)$coefficients
      if ("disclosure_label" %in% rownames(s_auth))
        p_dis_auth <- s_auth["disclosure_label", "Pr(>|t|)"]
    }
    if (!inherits(m_cred, "try-error")) {
      s_cred <- summary(m_cred)$coefficients
      if ("psychological_discomfort" %in% rownames(s_cred))
        p_disc_cred <- s_cred["psychological_discomfort", "Pr(>|t|)"]
      if ("perceived_ai_authorship" %in% rownames(s_cred))
        p_auth_cred <- s_cred["perceived_ai_authorship", "Pr(>|t|)"]
    }

    # joint significance:
    #   discomfort path   = Detection -> Discomfort -> Credibility
    power_disc_path <- ifelse(p_det_disc < 0.05 & p_disc_cred < 0.05, 1, 0)
    #   AI-authorship path = Disclosure -> AI authorship -> Credibility
    power_auth_path <- ifelse(p_dis_auth < 0.05 & p_auth_cred < 0.05, 1, 0)

    return(c(power_disc_path, power_auth_path))
  }, numeric(2))

  return(rowMeans(res, na.rm = TRUE) * 100)
}

# ---- 3. Run simulations ----
# ------------------------------------------------------------------------------
power_145 <- simulate_study2_power(n_subj = 145, n_sim = 1000, seed = 123)
power_149 <- simulate_study2_power(n_subj = 149, n_sim = 1000, seed = 456)

cat("\n======================= Final results =======================\n")
cat(sprintf("[A-priori planning N = 145]\n"))
cat(sprintf("- Discomfort path (Detection -> Discomfort -> Credibility): %.2f%%\n",
            power_145[1]))
cat(sprintf("- AI-authorship path (Disclosure -> AI authorship -> Credibility): %.2f%%\n",
            power_145[2]))
cat(sprintf("[Post-hoc power N = 149]\n"))
cat(sprintf("- Discomfort path (Detection -> Discomfort -> Credibility): %.2f%%\n",
            power_149[1]))
cat(sprintf("- AI-authorship path (Disclosure -> AI authorship -> Credibility): %.2f%%\n",
            power_149[2]))
cat("==============================================================\n")
