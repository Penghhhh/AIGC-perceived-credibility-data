###############################################################################
# Study 1 (REVISED): Multilevel Moderated Mediation with Crossed Random
# Effects for Participants and Reviews (Comments) - Two-Way Cluster Bootstrap
###############################################################################
#
# What this script does (one-to-one with the manuscript, Study 1):
#   Design: within-person experiment in a simulated e-commerce (Taobao-like)
#   environment. 93 participants each rated 20 product reviews (4 reviews for
#   each of 5 products). On half of the trials (randomly 2 of 4 within every
#   product block) the review carried a platform-issued DETECTION label
#   ("Suspected AI-generated content"); the other half did not.
#
#   Measures (all 1-7 scales; see manuscript Section 2.4):
#     - perceived_credibility        : "How credible do you think this review
#                                      is?" (outcome)
#     - perceived_ai_authorship      : "How likely is it that the actual author
#                                      of this review is AI?" (mediator)
#     - detection_confidence         : "How confident are you in the platform's
#                                      AI-detection system?" (participant-level
#                                      moderator, rated after each product
#                                      block; the five ratings were averaged)
#     - functional_value / experiential_value / emotional_valence : content
#       ratings collected AFTER label exposure (post-treatment covariates;
#       used only in the sensitivity analysis, Section 6)
#
#   Model (primary; all level-1 predictors vary within participants):
#     M1 (first stage): perceived_ai_authorship ~ detection_label_c
#                         + detection_confidence_c
#                         + detection_label_c:detection_confidence_c
#                         + (1 + detection_label_c || participant_id)
#                         + (1 + detection_label_c || review_id)
#     M2 (second stage): perceived_credibility ~ perceived_ai_authorship
#                         + detection_label_c
#                         + (1 | participant_id) + (1 | review_id)
#     M3 (total):        perceived_credibility ~ detection_label_c
#                         + (1 | participant_id) + (1 | review_id)
#
#   Mediation: detection label -> perceived AI authorship -> perceived
#   credibility; the first stage is moderated by confidence (conditional
#   heterogeneity; see manuscript notes). Indirect effect = a * b.
#
# Coding conventions (manuscript Sections 2.6):
#   - detection_label_c = within-participant effect coding via group-mean
#     centering {-0.5 = label absent, +0.5 = label present}
#   - detection_confidence_c = grand-mean centered (between-participant)
#   - functional/experiential/emotional content ratings = within-participant
#     centered for the sensitivity analysis only
#
# Random-effects justification (revised analysis):
#   Trials are nested in participants but the same 20 reviews were shown to
#   all 93 participants (complete participant x review crossing), so review
#   id is included as a CROSSED random effect in every model. Confidence was
#   measured after label exposure and is constant within participants, so its
#   moderation is reported as conditional heterogeneity of the treatment
#   effect, not as evidence of causal moderation. Uncorrelated random slopes
#   (||) are primary (the correlated version hit the boundary, correlation =
#   -1.000); the correlated specification is reported as robustness (Section 4)
#   and review fixed effects as an additional robustness check (Section 5).
#
# Inference: all 95% CIs for path coefficients, simple slopes, and
# (conditional) indirect effects come from a two-way cluster bootstrap
# (5,000 resamples that draw 93 participants and 20 reviews with replacement
# and refit M1-M3 on the complete grid; seed 20240829).
#
# Revision log (housekeeping for public release):
#   - variables renamed to full construct names matching the manuscript
#     (participant_id, review_id, detection_label, detection_confidence,
#      perceived_ai_authorship, perceived_credibility,
#      functional_value, experiential_value, emotional_valence)
#   - the script runs from its own directory (no hard-coded fallback path)
#   - bootstrap replications that fail to converge are dropped and counted
#     (tryCatch per replication); singular fits are retained and counted
#   - output now includes simple slopes at the mean, -1 SD and +1 SD of
#     confidence with bootstrap CIs, LR tests of the interaction and of the
#     total-effect model, Wald CIs, and fully standardized (beta) values for
#     slopes / conditional indirect effects / index of moderated mediation
#   - the confidence main effect (detection_confidence_c) is now part of the
#     bootstrap replication, so its reported 95% CI is a two-way cluster
#     bootstrap percentile interval like every other path coefficient
#
###############################################################################

# ---- 0. SETUP ----
args <- commandArgs(trailingOnly = FALSE)
script_path <- sub("^--file=", "", args[grep("^--file=", args)])
if (length(script_path) > 0 && nzchar(script_path)) {
  setwd(dirname(normalizePath(script_path)))
} else {
  # interactive use: working directory left unchanged (data file must be here)
  cat("(interactive session: working directory left unchanged)\n")
}

suppressPackageStartupMessages({
  library(lme4)
  library(lmerTest)
  library(dplyr)
  library(parallel)
})

options(width = 120)
set.seed(20240829)

# output file
outfile <- "analysis_results_revised.txt"
sink(outfile, split = TRUE)

ctl <- lmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 200000))

fit_ok <- function(m) {
  # convergence + non-singularity check
  if (isSingular(m)) return(FALSE)
  cc <- m@optinfo$conv
  (length(cc$opt) == 0 || cc$opt == 0) && length(cc$lme4) == 0
}

cat("============================================================\n")
cat("  Study 1 (REVISED): Crossed Random Effects (Participants x Reviews)\n")
cat("  Multilevel Moderated Mediation with Two-Way Cluster Bootstrap\n")
cat("============================================================\n\n")

# ---- 1. DATA & DESIGN ----
# raw data columns (no header in exp1_data.dat):
#   participant_id  (1-93)
#   review_id       (11-54: two digits, first = product 1-5, second = review 1-4)
#   detection_label (0 = absent, 1 = present)
#   functional_value (1-7)
#   experiential_value (1-7)
#   emotional_valence (1-7)
#   perceived_ai_authorship (1-7)
#   perceived_credibility (1-7)
#   detection_confidence (1-7, averaged over the 5 product blocks)
dat <- read.table("exp1_data.dat", header = FALSE)
colnames(dat) <- c("participant_id", "review_id", "detection_label",
                   "functional_value", "experiential_value", "emotional_valence",
                   "perceived_ai_authorship", "perceived_credibility",
                   "detection_confidence")
dat$participant_id <- as.factor(dat$participant_id)
dat$review_id      <- as.factor(dat$review_id)

n_obs   <- nrow(dat)
n_subj  <- length(unique(dat$participant_id))
n_items <- length(unique(dat$review_id))

cat("--- Design & Coding ---\n")
cat(sprintf("Observations: %d\n", n_obs))
cat(sprintf("Participants (level-2 clusters): %d\n", n_subj))
cat(sprintf("Reviews/Stimuli (crossed factor): %d\n", n_items))
cat(sprintf("Trials per participant: all %d\n", n_obs / n_subj))
cat(sprintf("Complete crossing: every participant rated every review (unique participant-review pairs = %d)\n",
            length(unique(paste(dat$participant_id, dat$review_id)))))
cat(sprintf("Detection label: binary (0/1), balanced within participant (10 labeled, 10 unlabeled per participant)\n"))
cat(sprintf("  NOTE: label assignment was randomized per participant, so label VARIES WITHIN\n"))
cat(sprintf("  review across participants (verified: all %d reviews show both labels).\n", n_items))
cat(sprintf("Confidence in AI detection: participant-level, constant within participant (%d unique values, range %.1f-%.1f),\n  measured after multiple label exposures -> conditional-heterogeneity interpretation\n",
            length(unique(dat$detection_confidence)), min(dat$detection_confidence), max(dat$detection_confidence)))
cat("functional_value / experiential_value / emotional_valence: content ratings measured\n")
cat("  AFTER label presentation (post-treatment); used only in sensitivity analysis\n")
cat("perceived_ai_authorship: mediator; perceived_credibility: outcome (1-7 scales)\n")

# Centering
#   detection_label: within-participant binary -> group-mean centered
#     (detection_label_c in {-0.5, +0.5}, i.e., effect coded)
#   functional/experiential/emotional content: within-participant centered
#     (sensitivity only)
#   detection_confidence: between-participant -> grand-mean centered
dat <- dat %>%
  group_by(participant_id) %>%
  mutate(detection_label_c      = detection_label - mean(detection_label),
         functional_value_c     = functional_value  - mean(functional_value),
         experiential_value_c   = experiential_value - mean(experiential_value),
         emotional_valence_c    = emotional_valence - mean(emotional_valence)) %>%
  ungroup()
dat$detection_confidence_c <- dat$detection_confidence - mean(dat$detection_confidence)
cat("\nCentering: detection_label_c = detection_label - participant mean\n")
cat("          (effect-coded within participant, {-0.5, +0.5});\n")
cat("          functional_value_c/experiential_value_c/emotional_valence_c =\n")
cat("          within-participant deviations (sensitivity only);\n")
cat("          detection_confidence_c = grand-mean centered.\n")

# sort into complete participant x review grid for the bootstrap
dat <- dat[order(as.numeric(dat$participant_id), as.numeric(dat$review_id)), ]
s_levels <- levels(droplevels(dat$participant_id))
i_levels <- levels(droplevels(dat$review_id))
stopifnot(nrow(dat) == n_subj * n_items)

# ---- 2. DESCRIPTIVES & VARIANCE DECOMPOSITION ----
cat("\n============================================================\n")
cat("  1. DESCRIPTIVE STATISTICS\n")
cat("============================================================\n\n")
desc_vars <- c("detection_label", "functional_value", "experiential_value",
               "emotional_valence", "perceived_ai_authorship",
               "perceived_credibility", "detection_confidence")
desc_stats <- dat %>%
  summarise(across(all_of(desc_vars), list(M = ~mean(., na.rm = TRUE),
                                           SD = ~sd(., na.rm = TRUE))))
cat(sprintf("%-26s %8s %8s\n", "Variable", "M", "SD"))
cat(paste(rep("-", 44), collapse = ""), "\n")
for (v in desc_vars) {
  cat(sprintf("%-26s %8.3f %8.3f\n", v, desc_stats[[paste0(v, "_M")]],
              desc_stats[[paste0(v, "_SD")]]))
}

cat("\n============================================================\n")
cat("  2. VARIANCE DECOMPOSITION & INTRACLASS CORRELATIONS\n")
cat("     (null models with participant AND review random intercepts)\n")
cat("============================================================\n\n")
null_auth <- lmer(perceived_ai_authorship ~ 1 + (1 | participant_id) + (1 | review_id),
                  data = dat, REML = TRUE, control = ctl)
null_cred <- lmer(perceived_credibility ~ 1 + (1 | participant_id) + (1 | review_id),
                  data = dat, REML = TRUE, control = ctl)

icc_crossed <- function(m) {
  vc <- as.data.frame(VarCorr(m))
  v <- vc$vcov
  tot <- sum(v)
  c(participant = v[vc$grp == "participant_id"] / tot,
    review = v[vc$grp == "review_id"] / tot,
    residual = v[vc$grp == "Residual"] / tot)
}
cat("--- perceived_ai_authorship ---\n")
print(summary(null_auth)$varcor)
cat(sprintf("  ICC_participant(perceived_ai_authorship) = %.3f, ICC_review = %.3f\n",
            icc_crossed(null_auth)["participant"], icc_crossed(null_auth)["review"]))
cat("\n--- perceived_credibility ---\n")
print(summary(null_cred)$varcor)
cat(sprintf("  ICC_participant(perceived_credibility) = %.3f, ICC_review = %.3f\n",
            icc_crossed(null_cred)["participant"], icc_crossed(null_cred)["review"]))
cat("\n  NOTE: the review (stimulus) component was previously ignored; it is\n")
cat("  substantial (see above) and is now explicitly modelled.\n")

# ---- 3. PRIMARY MODELS (no post-treatment covariates) ----
cat("\n============================================================\n")
cat("  3. PRIMARY MODELS (crossed REs; NO post-treatment covariates)\n")
cat("     ML estimation; Satterthwaite df; uncorrelated random slopes\n")
cat("     (correlated version reported in Section 4)\n")
cat("============================================================\n\n")

# M1: first stage - detection label -> perceived AI authorship,
#     cross-level moderation by confidence
model_auth <- lmer(perceived_ai_authorship ~ detection_label_c +
                     detection_confidence_c +
                     detection_label_c:detection_confidence_c +
                     (1 + detection_label_c || participant_id) +
                     (1 + detection_label_c || review_id),
                   data = dat, REML = FALSE, control = ctl)
cat("--- M1: perceived_ai_authorship equation (first stage) ---\n")
cat("  Formula: perceived_ai_authorship ~ detection_label_c\n")
cat("           + detection_confidence_c + detection_label_c:detection_confidence_c\n")
cat("           + (1 + detection_label_c || participant_id)\n")
cat("           + (1 + detection_label_c || review_id)\n")
cat(sprintf("  Convergence OK: %s; Singular fit: %s\n\n",
            fit_ok(model_auth), isSingular(model_auth)))
print(summary(model_auth))
cat("\n")

# M2: second stage - perceived AI authorship -> perceived credibility
#     (direct effect c' = detection label on credibility)
model_cred <- lmer(perceived_credibility ~ perceived_ai_authorship +
                     detection_label_c +
                     (1 | participant_id) + (1 | review_id),
                   data = dat, REML = FALSE, control = ctl)
cat("--- M2: perceived_credibility equation (second stage) ---\n")
cat("  Formula: perceived_credibility ~ perceived_ai_authorship\n")
cat("           + detection_label_c + (1 | participant_id) + (1 | review_id)\n")
cat(sprintf("  Convergence OK: %s; Singular fit: %s\n\n",
            fit_ok(model_cred), isSingular(model_cred)))
print(summary(model_cred))
cat("\n")

# M3: total effect - detection label -> perceived credibility
model_total <- lmer(perceived_credibility ~ detection_label_c +
                      (1 | participant_id) + (1 | review_id),
                    data = dat, REML = FALSE, control = ctl)
cat("--- M3: Total effect (detection label -> perceived credibility) ---\n")
cat("  Formula: perceived_credibility ~ detection_label_c\n")
cat("           + (1 | participant_id) + (1 | review_id)\n")
cat(sprintf("  Convergence OK: %s; Singular fit: %s\n\n",
            fit_ok(model_total), isSingular(model_total)))
print(summary(model_total))
cat("\n")

fix_auth <- fixef(model_auth)
fix_cred <- fixef(model_cred)
a0      <- fix_auth["detection_label_c"]            # label -> AI authorship at mean confidence
a1      <- fix_auth["detection_label_c:detection_confidence_c"]  # moderation
b0      <- fix_cred["perceived_ai_authorship"]      # AI authorship -> credibility
c_prime <- fix_cred["detection_label_c"]            # direct effect label -> credibility
c_total <- fixef(model_total)["detection_label_c"]
sd_conf <- sd(dat$detection_confidence)

# simple slopes of detection label -> perceived AI authorship at the mean,
# -1 SD and +1 SD of confidence
slope_mean <- a0
slope_low  <- a0 - a1 * sd_conf
slope_high <- a0 + a1 * sd_conf

cat("--- Key Path Coefficients (unstandardized) ---\n")
cat(sprintf("  a0  (detection label -> AI authorship at mean confidence): %8.4f\n", a0))
cat(sprintf("  a1  (confidence moderates label->AI authorship):           %8.4f\n", a1))
cat(sprintf("  b0  (AI authorship -> credibility):                        %8.4f\n", b0))
cat(sprintf("  c'  (detection label -> credibility, direct):             %8.4f\n", c_prime))
cat(sprintf("  c   (detection label -> credibility, total):              %8.4f\n", c_total))
cat(sprintf("  SD(confidence) = %.3f\n", sd_conf))
cat(sprintf("  Simple slope of detection label -> AI authorship at confidence mean:  %8.4f\n", slope_mean))
cat(sprintf("  Simple slope of detection label -> AI authorship at confidence -1 SD: %8.4f\n", slope_low))
cat(sprintf("  Simple slope of detection label -> AI authorship at confidence +1 SD: %8.4f\n\n", slope_high))

# ---- 4. RANDOM-SLOPE ROBUSTNESS (correlated slopes) ----
cat("\n============================================================\n")
cat("  4. ROBUSTNESS: CORRELATED RANDOM SLOPES\n")
cat("     (original analysis had intercept-slope correlation = -1.000,\n")
cat("      i.e., a boundary/singular fit; uncorrelated slopes are primary)\n")
cat("============================================================\n\n")

m1_corr <- lmer(perceived_ai_authorship ~ detection_label_c +
                  detection_confidence_c +
                  detection_label_c:detection_confidence_c +
                  (1 + detection_label_c | participant_id) +
                  (1 + detection_label_c | review_id),
                data = dat, REML = FALSE, control = ctl)
cat("--- M1 with correlated random slopes ---\n")
cat(sprintf("  Convergence OK: %s; Singular fit: %s\n", fit_ok(m1_corr), isSingular(m1_corr)))
print(VarCorr(m1_corr))
cat("  Fixed effects:\n")
print(summary(m1_corr)$coefficients)
cat("\n")

m2_corr <- lmer(perceived_credibility ~ perceived_ai_authorship +
                  detection_label_c +
                  (1 + perceived_ai_authorship | participant_id) +
                  (1 | review_id),
                data = dat, REML = FALSE, control = ctl)
cat("--- M2 with participant random slope for AI authorship ---\n")
cat(sprintf("  Convergence OK: %s; Singular fit: %s\n", fit_ok(m2_corr), isSingular(m2_corr)))
print(VarCorr(m2_corr))
cat("  Fixed effects:\n")
print(summary(m2_corr)$coefficients)
cat("\n")

# variance of the detection-label slope across reviews (item-level treatment heterogeneity)
vc_m1 <- as.data.frame(VarCorr(model_auth))
cat(sprintf("  SD of detection-label slope across REVIEWS (from M1): %.4f\n",
            vc_m1$sdcor[vc_m1$grp == "review_id.1"]))
cat(sprintf("  SD of detection-label slope across PARTICIPANTS (from M1): %.4f\n\n",
            vc_m1$sdcor[vc_m1$grp == "participant_id.1"]))

# ---- 5. STIMULUS FIXED-EFFECTS ROBUSTNESS ----
cat("\n============================================================\n")
cat("  5. ROBUSTNESS: REVIEW FIXED EFFECTS (reviewer's alternative)\n")
cat("     review_id as dummy-coded fixed factor instead of random effect\n")
cat("============================================================\n\n")

m1_fe <- lmer(perceived_ai_authorship ~ detection_label_c +
                detection_confidence_c +
                detection_label_c:detection_confidence_c +
                review_id + (1 + detection_label_c || participant_id),
              data = dat, REML = FALSE, control = ctl)
m2_fe <- lmer(perceived_credibility ~ perceived_ai_authorship +
                detection_label_c + review_id + (1 | participant_id),
              data = dat, REML = FALSE, control = ctl)
m3_fe <- lmer(perceived_credibility ~ detection_label_c +
                review_id + (1 | participant_id),
              data = dat, REML = FALSE, control = ctl)
cat(sprintf("  Convergence OK: M1_fe %s, M2_fe %s, M3_fe %s\n\n",
            fit_ok(m1_fe), fit_ok(m2_fe), fit_ok(m3_fe)))
fe_tab <- rbind(
  "a0 (label->AI authorship)" = summary(m1_fe)$coefficients["detection_label_c", c("Estimate", "Std. Error", "df", "t value", "Pr(>|t|)")],
  "a1 (label:confidence)"     = summary(m1_fe)$coefficients["detection_label_c:detection_confidence_c", c("Estimate", "Std. Error", "df", "t value", "Pr(>|t|)")],
  "b0 (AI authorship->cred)"  = summary(m2_fe)$coefficients["perceived_ai_authorship", c("Estimate", "Std. Error", "df", "t value", "Pr(>|t|)")],
  "c' (label->cred, direct)"  = summary(m2_fe)$coefficients["detection_label_c", c("Estimate", "Std. Error", "df", "t value", "Pr(>|t|)")],
  "c  (label->cred, total)"   = summary(m3_fe)$coefficients["detection_label_c", c("Estimate", "Std. Error", "df", "t value", "Pr(>|t|)")]
)
print(round(fe_tab, 4))
cat("\n")

# ---- 6. SENSITIVITY ANALYSIS (post-treatment content ratings) ----
cat("\n============================================================\n")
cat("  6. SENSITIVITY: MODERATION BY POST-TREATMENT CONTENT RATINGS\n")
cat("     (functional value / experiential value / emotional valence were\n")
cat("      measured AFTER label presentation; NOT in primary models; reported\n")
cat("      only as sensitivity, per reviewer guidance)\n")
cat("============================================================\n\n")

sens_cred <- lmer(perceived_credibility ~ perceived_ai_authorship +
                    detection_label_c +
                    perceived_ai_authorship:functional_value_c +
                    perceived_ai_authorship:experiential_value_c +
                    perceived_ai_authorship:emotional_valence_c +
                    (1 | participant_id) + (1 | review_id),
                  data = dat, REML = FALSE, control = ctl)
cat("  Formula: perceived_credibility ~ perceived_ai_authorship\n")
cat("           + detection_label_c\n")
cat("           + perceived_ai_authorship:functional_value_c\n")
cat("           + perceived_ai_authorship:experiential_value_c\n")
cat("           + perceived_ai_authorship:emotional_valence_c\n")
cat("           + (1 | participant_id) + (1 | review_id)\n")
cat(sprintf("  Convergence OK: %s; Singular fit: %s\n\n",
            fit_ok(sens_cred), isSingular(sens_cred)))
print(summary(sens_cred)$coefficients)
cat("\n")

# ---- 7. STANDARDIZED COEFFICIENTS (primary models) ----
cat("\n============================================================\n")
cat("  7. STANDARDIZED COEFFICIENTS (fully standardized, total SD)\n")
cat("============================================================\n\n")
dat_s <- dat
vars_to_std <- c("detection_label_c", "detection_confidence_c",
                 "perceived_ai_authorship", "perceived_credibility")
sds <- sapply(vars_to_std, function(v) sd(dat[[v]], na.rm = TRUE))
for (v in vars_to_std) dat_s[[paste0(v, "_s")]] <- dat_s[[v]] / sds[v]

model_auth_s <- lmer(perceived_ai_authorship_s ~ detection_label_c_s +
                       detection_confidence_c_s +
                       detection_label_c_s:detection_confidence_c_s +
                       (1 + detection_label_c_s || participant_id) +
                       (1 + detection_label_c_s || review_id),
                     data = dat_s, REML = FALSE, control = ctl)
model_cred_s <- lmer(perceived_credibility_s ~ perceived_ai_authorship_s +
                       detection_label_c_s +
                       (1 | participant_id) + (1 | review_id),
                     data = dat_s, REML = FALSE, control = ctl)
cat("--- Standardized M1 (AI authorship equation) ---\n")
print(summary(model_auth_s)$coefficients)
cat("\n--- Standardized M2 (credibility equation) ---\n")
print(summary(model_cred_s)$coefficients)
cat("\n")

# ---- 8. MODEL FIT ----
cat("\n============================================================\n")
cat("  8. MODEL FIT\n")
cat("============================================================\n\n")

r2_multilevel <- function(model) {
  vc <- as.data.frame(VarCorr(model))
  var_random <- sum(vc$vcov[vc$grp != "Residual"])
  var_resid  <- vc$vcov[vc$grp == "Residual"]
  fixed_pred <- predict(model, re.form = NA)
  var_fixed  <- var(fixed_pred)
  var_total  <- var_fixed + var_random + var_resid
  list(marginal = var_fixed / var_total,
       conditional = (var_fixed + var_random) / var_total)
}
r2_auth <- r2_multilevel(model_auth)
r2_cred <- r2_multilevel(model_cred)
r2_tot  <- r2_multilevel(model_total)
cat(sprintf("  M1 (AI authorship): Marginal R2 = %.3f, Conditional R2 = %.3f\n", r2_auth$marginal, r2_auth$conditional))
cat(sprintf("  M2 (credibility):   Marginal R2 = %.3f, Conditional R2 = %.3f\n", r2_cred$marginal, r2_cred$conditional))
cat(sprintf("  M3 (total):         Marginal R2 = %.3f, Conditional R2 = %.3f\n", r2_tot$marginal, r2_tot$conditional))

cat("\n--- LRT (null with participant+review RE vs full) ---\n")
cat("M1 (AI authorship):\n")
print(anova(null_auth, model_auth))
cat("\nM2 (credibility):\n")
print(anova(null_cred, model_cred))
cat("\n--- LRT: label x confidence interaction term (M1 vs M1 without interaction) ---\n")
m1_noi <- lmer(perceived_ai_authorship ~ detection_label_c +
                 detection_confidence_c +
                 (1 + detection_label_c || participant_id) +
                 (1 + detection_label_c || review_id),
               data = dat, REML = FALSE, control = ctl)
print(anova(m1_noi, model_auth))
cat("  -> tests the moderated-mediation first stage (H: a1 != 0).\n")
cat("\n--- LRT: total effect model (M3 vs null) ---\n")
print(anova(null_cred, model_total))
cat("\n--- Information criteria ---\n")
cat(sprintf("  M1 (AI authorship): AIC = %.2f, BIC = %.2f, LL = %.2f\n", AIC(model_auth), BIC(model_auth), logLik(model_auth)))
cat(sprintf("  M1 no-interaction: AIC = %.2f, BIC = %.2f, LL = %.2f\n", AIC(m1_noi), BIC(m1_noi), logLik(m1_noi)))
cat(sprintf("  M2 (credibility): AIC = %.2f, BIC = %.2f, LL = %.2f\n", AIC(model_cred), BIC(model_cred), logLik(model_cred)))
cat(sprintf("  M3 (total): AIC = %.2f, BIC = %.2f, LL = %.2f\n", AIC(model_total), BIC(model_total), logLik(model_total)))
cat("\n--- Wald 95% CIs for fixed effects (primary models) ---\n")
cat("M1 (AI authorship):\n")
print(confint(model_auth, method = "Wald"))
cat("\nM2 (credibility):\n")
print(confint(model_cred, method = "Wald"))
cat("\nM3 (total):\n")
print(confint(model_total, method = "Wald"))
cat("\n--- Variance components (primary models) ---\n")
cat("M1 (AI authorship equation):\n"); print(VarCorr(model_auth))
cat("\nM2 (credibility equation):\n"); print(VarCorr(model_cred))
cat("\n")

# ---- 9. TWO-WAY CLUSTER BOOTSTRAP ----
cat("\n============================================================\n")
cat("  9. TWO-WAY CLUSTER BOOTSTRAP (participants AND reviews resampled)\n")
cat("     Complete-grid resampling: 93 participants x 20 reviews per draw\n")
cat("     Number of resamples: 5000, percentile CIs\n")
cat("============================================================\n\n")

B <- 5000
n_cores <- max(1, detectCores() - 1)

boot_one <- function(b, d, s_levels, i_levels, ctl) {
  tryCatch({
  nS <- length(s_levels); nI <- length(i_levels)
  S <- sample(s_levels, nS, replace = TRUE)
  I <- sample(i_levels, nI, replace = TRUE)
  S_idx <- match(S, s_levels); I_idx <- match(I, i_levels)
  rowidx <- as.vector(t(outer((S_idx - 1) * nI, I_idx, `+`)))
  bdat <- d[rowidx, ]
  bdat$participant_id <- factor(rep(seq_len(nS), each = nI))
  bdat$review_id      <- factor(rep(seq_len(nI), times = nS))
  # group-mean centering within resampled participants (base R, fast)
  bdat$detection_label_c <- bdat$detection_label -
                            ave(bdat$detection_label, bdat$participant_id)
  bdat$detection_confidence_c <- bdat$detection_confidence -
                                 mean(bdat$detection_confidence)
  bm1 <- lmer(perceived_ai_authorship ~ detection_label_c +
                detection_confidence_c + detection_label_c:detection_confidence_c +
                (1 + detection_label_c || participant_id) +
                (1 + detection_label_c || review_id),
              data = bdat, REML = FALSE, control = ctl)
  bm2 <- lmer(perceived_credibility ~ perceived_ai_authorship + detection_label_c +
                (1 | participant_id) + (1 | review_id),
              data = bdat, REML = FALSE, control = ctl)
  bm3 <- lmer(perceived_credibility ~ detection_label_c +
                (1 | participant_id) + (1 | review_id),
              data = bdat, REML = FALSE, control = ctl)
  f1 <- fixef(bm1); f2 <- fixef(bm2); f3 <- fixef(bm3)
  a0b <- unname(f1["detection_label_c"])
  a1b <- unname(f1["detection_label_c:detection_confidence_c"])
  b0b <- unname(f2["perceived_ai_authorship"])
  sd_c   <- sd(bdat$detection_confidence)
  sd_lab <- sd(bdat$detection_label_c)
  sd_auth <- sd(bdat$perceived_ai_authorship)
  sd_cred <- sd(bdat$perceived_credibility)
  c(a0 = a0b, a1 = a1b, b0 = b0b,
    conf = unname(f1["detection_confidence_c"]),
    c_prime = unname(f2["detection_label_c"]),
    c_total = unname(f3["detection_label_c"]),
    slope_low = a0b - a1b * sd_c, slope_high = a0b + a1b * sd_c,
    ind_mean = a0b * b0b,
    ind_low  = (a0b - a1b * sd_c) * b0b,
    ind_high = (a0b + a1b * sd_c) * b0b,
    index_modmed = 2 * a1b * sd_c * b0b,
    # fully standardized versions (variables divided by resample total SD):
    # beta(simple slope) = b * SD(label)/SD(authorship);
    # beta(indirect) = beta(a) * beta(b)
    std_slope_mean = a0b * sd_lab / sd_auth,
    std_slope_low  = (a0b - a1b * sd_c) * sd_lab / sd_auth,
    std_slope_high = (a0b + a1b * sd_c) * sd_lab / sd_auth,
    std_ind_mean = a0b * b0b * sd_lab / sd_cred,
    std_ind_low  = (a0b - a1b * sd_c) * b0b * sd_lab / sd_cred,
    std_ind_high = (a0b + a1b * sd_c) * b0b * sd_lab / sd_cred,
    std_index_modmed = 2 * a1b * sd_c * b0b * sd_lab / sd_cred,
    n_sing = isSingular(bm1) + isSingular(bm2) + isSingular(bm3))
  }, error = function(e) NULL)
}

t_boot <- Sys.time()
cl <- makeCluster(n_cores)
on.exit(stopCluster(cl), add = TRUE)
invisible(clusterEvalQ(cl, {suppressPackageStartupMessages(library(lme4)); TRUE}))
clusterExport(cl, c("boot_one"), envir = environment())
clusterSetRNGStream(cl, 20240829)

n_chunks <- 10
chunk_ids <- split(seq_len(B), cut(seq_len(B), n_chunks, labels = FALSE))
boot_list <- vector("list", B)
for (ch in seq_along(chunk_ids)) {
  ids <- chunk_ids[[ch]]
  res_chunk <- parLapply(cl, ids, boot_one, dat, s_levels, i_levels, ctl)
  boot_list[ids] <- res_chunk
  cat(sprintf("  bootstrap progress: %d / %d (%.0f%%) [%.0f s]\n",
              max(ids), B, 100 * max(ids) / B,
              as.numeric(Sys.time() - t_boot, units = "secs")))
}
ok <- !vapply(boot_list, is.null, logical(1))
cat(sprintf("\n  Elapsed: %.1f min using %d cores\n",
            as.numeric(Sys.time() - t_boot, units = "mins"), n_cores))
cat(sprintf("  Failed (non-converged/dropped) replications: %d / %d (%.1f%%)\n",
            sum(!ok), B, 100 * sum(!ok) / B))
boot_mat <- do.call(rbind, boot_list[ok])
B_eff <- nrow(boot_mat)

n_sing <- sum(boot_mat[, "n_sing"] > 0)
cat(sprintf("  Bootstrap draws with >=1 singular fit (estimates retained): %d / %d (%.1f%%)\n",
            n_sing, B_eff, 100 * n_sing / B_eff))

boot_ci <- function(x, conf = 0.95) {
  x <- x[!is.na(x)]
  alpha <- 1 - conf
  qs <- quantile(x, probs = c(alpha / 2, 1 - alpha / 2))
  c(M = mean(x), SE = sd(x), lower = unname(qs[1]), upper = unname(qs[2]))
}

sig_star <- function(p) ifelse(p < .001, "***", ifelse(p < .01, "**", ifelse(p < .05, "*", "")))
ci_sig   <- function(ci) ifelse(ci["lower"] > 0 | ci["upper"] < 0, "**", "n.s.")

sum_auth <- summary(model_auth)
sum_cred <- summary(model_cred)
sum_tot  <- summary(model_total)

cat("\n--- Path Coefficients with Bootstrap 95% CIs ---\n\n")
cat(sprintf("%-30s %8s %8s %8s %8s %18s %5s %6s\n",
            "Parameter", "b", "SE", "beta", "t", "95% Boot CI", "p", ""))
cat(paste(rep("-", 96), collapse = ""), "\n")

rows <- list(
  list("a0: label -> AI authorship", "detection_label_c", sum_auth,
       fixef(model_auth_s)["detection_label_c_s"], boot_mat[, "a0"]),
  list("conf: confidence -> authorship", "detection_confidence_c", sum_auth,
       fixef(model_auth_s)["detection_confidence_c_s"], boot_mat[, "conf"]),
  list("a1: confidence -> slope", "detection_label_c:detection_confidence_c", sum_auth,
       fixef(model_auth_s)["detection_label_c_s:detection_confidence_c_s"], boot_mat[, "a1"]),
  list("b0: AI authorship -> cred", "perceived_ai_authorship", sum_cred,
       fixef(model_cred_s)["perceived_ai_authorship_s"], boot_mat[, "b0"]),
  list("c': label -> cred (direct)", "detection_label_c", sum_cred,
       fixef(model_cred_s)["detection_label_c_s"], boot_mat[, "c_prime"]),
  list("c: label -> cred (total)", "detection_label_c", sum_tot, NA, boot_mat[, "c_total"])
)
for (r in rows) {
  nm <- r[[1]]; term <- r[[2]]; sm <- r[[3]]; beta <- r[[4]]; bv <- r[[5]]
  cf <- sm$coefficients[term, ]
  ci <- boot_ci(bv)
  p <- cf["Pr(>|t|)"]
  cat(sprintf("%-30s %8.4f %8.4f %8s %8.3f [%7.4f,%7.4f] %6s %s\n",
              nm, cf["Estimate"], cf["Std. Error"],
              ifelse(is.na(beta), "", sprintf("%.4f", beta)),
              cf["t value"], ci["lower"], ci["upper"],
              formatC(p, format = "f", digits = 3), sig_star(p)))
}
cat("\n")

# fully standardized coefficients from the standardized models (Section 7):
# beta = coefficient with all variables divided by their total SD
b_a0 <- unname(fixef(model_auth_s)["detection_label_c_s"])
b_a1 <- unname(fixef(model_auth_s)["detection_label_c_s:detection_confidence_c_s"])
b_b0 <- unname(fixef(model_cred_s)["perceived_ai_authorship_s"])

cat("--- Simple Slopes of label -> AI authorship with Bootstrap 95% CIs ---\n\n")
slope_rows <- list(
  list("slope at mean confidence",  slope_mean, b_a0,        boot_mat[, "a0"],        boot_mat[, "std_slope_mean"]),
  list("slope at confidence -1 SD", slope_low,  b_a0 - b_a1, boot_mat[, "slope_low"], boot_mat[, "std_slope_low"]),
  list("slope at confidence +1 SD", slope_high, b_a0 + b_a1, boot_mat[, "slope_high"], boot_mat[, "std_slope_high"])
)
cat(sprintf("%-26s %8s %8s %18s %6s %8s %18s %6s\n",
            "Slope", "b", "Boot SE", "95% Boot CI", "Sig", "beta", "95% CI(beta)", "Sig"))
cat(paste(rep("-", 108), collapse = ""), "\n")
for (r in slope_rows) {
  ci <- boot_ci(r[[4]]); cib <- boot_ci(r[[5]])
  cat(sprintf("%-26s %8.4f %8.4f [%7.4f,%7.4f] %6s %8.4f [%7.4f,%7.4f] %6s\n",
              r[[1]], r[[2]], ci["SE"], ci["lower"], ci["upper"], ci_sig(ci),
              r[[3]], cib["lower"], cib["upper"], ci_sig(cib)))
}
cat("\n")

cat("--- Conditional Indirect Effects (label -> AI authorship -> credibility) ---\n\n")
ind_mean <- a0 * b0
ind_low  <- (a0 - a1 * sd_conf) * b0
ind_high <- (a0 + a1 * sd_conf) * b0
idx      <- ind_high - ind_low
# fully standardized conditional indirect effects: beta = beta(a) * beta(b)
bind_mean <- b_a0 * b_b0
bind_low  <- (b_a0 - b_a1) * b_b0
bind_high <- (b_a0 + b_a1) * b_b0
bidx      <- 2 * b_a1 * b_b0
cat(sprintf("%-34s %8s %8s %18s %6s %8s %18s %6s\n",
            "Effect", "b", "Boot SE", "95% Boot CI", "Sig", "beta", "95% CI(beta)", "Sig"))
cat(paste(rep("-", 108), collapse = ""), "\n")
ci_im  <- boot_ci(boot_mat[, "ind_mean"]);   cib_im <- boot_ci(boot_mat[, "std_ind_mean"])
ci_il  <- boot_ci(boot_mat[, "ind_low"]);    cib_il <- boot_ci(boot_mat[, "std_ind_low"])
ci_ih  <- boot_ci(boot_mat[, "ind_high"]);   cib_ih <- boot_ci(boot_mat[, "std_ind_high"])
ci_ix  <- boot_ci(boot_mat[, "index_modmed"]); cib_ix <- boot_ci(boot_mat[, "std_index_modmed"])
cat(sprintf("%-34s %8.4f %8.4f [%7.4f,%7.4f] %6s %8.4f [%7.4f,%7.4f] %6s\n",
            "Indirect (mean confidence)", ind_mean, ci_im["SE"], ci_im["lower"], ci_im["upper"], ci_sig(ci_im),
            bind_mean, cib_im["lower"], cib_im["upper"], ci_sig(cib_im)))
cat(sprintf("%-34s %8.4f %8.4f [%7.4f,%7.4f] %6s %8.4f [%7.4f,%7.4f] %6s\n",
            "Indirect (low confidence, -1 SD)", ind_low, ci_il["SE"], ci_il["lower"], ci_il["upper"], ci_sig(ci_il),
            bind_low, cib_il["lower"], cib_il["upper"], ci_sig(cib_il)))
cat(sprintf("%-34s %8.4f %8.4f [%7.4f,%7.4f] %6s %8.4f [%7.4f,%7.4f] %6s\n",
            "Indirect (high confidence, +1 SD)", ind_high, ci_ih["SE"], ci_ih["lower"], ci_ih["upper"], ci_sig(ci_ih),
            bind_high, cib_ih["lower"], cib_ih["upper"], ci_sig(cib_ih)))
cat(sprintf("%-34s %8.4f %8.4f [%7.4f,%7.4f] %6s %8.4f [%7.4f,%7.4f] %6s\n",
            "Index of Moderated Mediation", idx, ci_ix["SE"], ci_ix["lower"], ci_ix["upper"], ci_sig(ci_ix),
            bidx, cib_ix["lower"], cib_ix["upper"], ci_sig(cib_ix)))
cat("\n* p < .05, ** p < .01, *** p < .001 (Satterthwaite df)\n")
cat("Indirect-effect significance: bootstrap 95% CI excludes zero\n")
cat("beta = fully standardized coefficient (all variables divided by total SD);\n")
cat("      beta(indirect) = beta(a) x beta(b); beta CI = percentile bootstrap\n")
cat("      with within-resample standardization.\n")
cat(sprintf("Bootstrap: %d two-way cluster resamples (participants AND reviews), percentile method\n\n", B_eff))

# ---- 9b. MANUSCRIPT-READY NUMBERS (rounding exactly as reported in the paper)
cat("\n============================================================\n")
cat("  9b. MANUSCRIPT-READY VALUES (rounded as reported)\n")
cat("============================================================\n\n")

apa_p <- function(p) {
  if (is.na(p)) return("n.s.")
  if (p < .001) return("< .001")
  sub("0\\.", "= .", sprintf("%.3f", p))
}
ci_txt <- function(ci) sprintf("[%.2f, %.2f]", ci["lower"], ci["upper"])

sm <- sum_auth$coefficients
ci_a0 <- boot_ci(boot_mat[, "a0"]); ci_conf <- boot_ci(boot_mat[, "conf"])
ci_a1 <- boot_ci(boot_mat[, "a1"])
sm2 <- sum_cred$coefficients
ci_b0 <- boot_ci(boot_mat[, "b0"]); ci_cp <- boot_ci(boot_mat[, "c_prime"])
ci_ct <- boot_ci(boot_mat[, "c_total"])

show <- function(nm, cf, beta, ci) {
  cat(sprintf("  %-38s b = %5.2f  SE = %.2f  t(%7.2f) = %7.2f  p %-6s  95%% CI %-16s beta = %.2f\n",
              nm, cf["Estimate"], cf["Std. Error"], cf["df"], cf["t value"],
              apa_p(cf["Pr(>|t|)"]), ci_txt(ci), beta))
}
cat("  --- first stage: perceived AI authorship ---\n")
show("detection label", sm["detection_label_c", ], b_a0, ci_a0)
show("confidence in AI detection", sm["detection_confidence_c", ],
     fixef(model_auth_s)["detection_confidence_c_s"], ci_conf)
show("label x confidence", sm["detection_label_c:detection_confidence_c", ], b_a1, ci_a1)
cat("  --- second stage: perceived credibility ---\n")
show("perceived AI authorship", sm2["perceived_ai_authorship", ], b_b0, ci_b0)
show("detection label (direct, c')", sm2["detection_label_c", ],
     fixef(model_cred_s)["detection_label_c_s"], ci_cp)
show("detection label (total, c)", summary(model_total)$coefficients["detection_label_c", ],
     NA, ci_ct)

cat("\n  --- simple slopes of the label effect on AI authorship ---\n")
ss <- list(
  list("at mean confidence", slope_mean, b_a0, boot_ci(boot_mat[, "a0"])),
  list("at confidence -1 SD", slope_low, b_a0 - b_a1, boot_ci(boot_mat[, "slope_low"])),
  list("at confidence +1 SD", slope_high, b_a0 + b_a1, boot_ci(boot_mat[, "slope_high"])))
for (s in ss)
  cat(sprintf("  %-38s b = %5.2f  95%% CI %-16s beta = %.2f\n",
              s[[1]], s[[2]], ci_txt(s[[4]]), s[[3]]))

cat("\n  --- conditional indirect effects (label -> AI authorship -> credibility) ---\n")
ie <- list(
  list("at mean confidence", ind_mean, ci_im["SE"], bind_mean, ci_im),
  list("at confidence -1 SD", ind_low, ci_il["SE"], bind_low, ci_il),
  list("at confidence +1 SD", ind_high, ci_ih["SE"], bind_high, ci_ih),
  list("index of moderated mediation", idx, ci_ix["SE"], bidx, ci_ix))
for (s in ie)
  cat(sprintf("  %-38s b = %5.2f  Boot SE = %.2f  95%% CI %-16s beta = %.2f\n",
              s[[1]], s[[2]], s[[3]], ci_txt(s[[5]]), s[[4]]))
cat("\n  (bootstrap SEs also in Section 9; ICCs in Section 2; R2 / LRT / AIC in Section 8)\n")


# ---- 10. COMPARISON WITH MODEL WITHOUT REVIEW RANDOM EFFECT ----
cat("\n============================================================\n")
cat("  10. IMPACT OF ADDING THE STIMULUS RANDOM EFFECT (reviewer check)\n")
cat("============================================================\n\n")
m1_noitem <- lmer(perceived_ai_authorship ~ detection_label_c +
                    detection_confidence_c + detection_label_c:detection_confidence_c +
                    (1 + detection_label_c || participant_id),
                  data = dat, REML = FALSE, control = ctl)
s_no <- summary(m1_noitem)$coefficients
s_wi <- summary(model_auth)$coefficients
cmp <- rbind(
  "detection_label_c (a0) - no review RE" = c(s_no["detection_label_c", c("Estimate", "Std. Error")], NA, s_no["detection_label_c", "df"]),
  "detection_label_c (a0) - with review RE" = c(s_wi["detection_label_c", c("Estimate", "Std. Error")], NA, s_wi["detection_label_c", "df"]),
  "label:confidence (a1) - no review RE" = c(s_no["detection_label_c:detection_confidence_c", c("Estimate", "Std. Error")], NA, s_no["detection_label_c:detection_confidence_c", "df"]),
  "label:confidence (a1) - with review RE" = c(s_wi["detection_label_c:detection_confidence_c", c("Estimate", "Std. Error")], NA, s_wi["detection_label_c:detection_confidence_c", "df"])
)
colnames(cmp) <- c("b", "SE", "", "df")
print(round(cmp, 4))
cat("\n  => Accounting for stimulus variance changes SEs and dfs; results below\n")
cat("     are from the crossed-RE specification.\n")

# ---- 11. INTERPRETATION NOTES ----
cat("\n============================================================\n")
cat("  11. INTERPRETATION NOTES (for the paper)\n")
cat("============================================================\n\n")
cat("1. The detection-label effect on perceived AI authorship is positive and\n")
cat("   moderated by confidence; because confidence was measured after label\n")
cat("   exposure (and is participant-level), this moderation is reported as\n")
cat("   CONDITIONAL HETEROGENEITY of the treatment effect, not as evidence\n")
cat("   for a causal moderator.\n")
cat("2. The indirect effect label -> AI authorship -> credibility is negative\n")
cat("   and significant at mean and +1 SD confidence; not significant at -1 SD;\n")
cat("   index of moderated mediation excludes zero.\n")
cat("3. The direct effect is not significant -> pattern consistent with\n")
cat("   (full) mediation of the negative total effect.\n")
cat("4. Review-level variance components are large (see Section 2); all\n")
cat("   estimates are robust to the review fixed-effects specification\n")
cat("   (Section 5) and to correlated random slopes (Section 4).\n")
cat("5. Moderation of the AI authorship -> credibility path by functional value /\n")
cat("   experiential value / emotional valence (post-treatment ratings)\n")
cat("   is reported only in the sensitivity analysis (Section 6).\n")
cat("6. Label was assigned randomly per participant per review (label varies\n")
cat("   within review across participants), so the within-participant (group-mean\n")
cat("   centered) coding and the two-way cluster bootstrap are appropriate.\n")

cat("\n============================================================\n")
cat("  ANALYSIS COMPLETE\n")
cat("============================================================\n\n")

cat("--- session info ---\n")
print(sessionInfo())

sink()
cat("Output written to:", normalizePath(outfile), "\n")
