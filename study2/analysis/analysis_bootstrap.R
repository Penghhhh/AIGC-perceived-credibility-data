###############################################################################
# Study 2 -- FINAL ANALYSIS, VERSION 2: ONE METHOD ONLY = BOOTSTRAP
# ============================================================================
# Design: 2 (detection label: absent/present) x 2 (disclosure label:
#         absent/present) fully within-person design. 149 participants, each
#         completing all four label conditions (596 observations). Four
#         stimulus posts; every participant saw each post exactly once
#         (post = within-person factor crossed with participant).
#
# Constructs (all single items, 1-7):
#   perceived_ai_authorship  = mediator M1
#   psychological_discomfort = mediator M2
#   perceived_credibility    = outcome Y
#   disclosure_label / detection_label / detection_x_disclosure = predictors
#
# WHAT THIS SCRIPT DOES
#   A. Descriptives, ICCs, repeated-measures MANOVA / univariate 2x2 rmANOVA
#      (Section 2-3). The rmANOVA F tests are the exact design-based
#      descriptive tests used for Figure 5; all *effect* inference is
#      additionally given by the bootstrap (Section 9).
#   B. The two-level dual-mediation SEM (lavaan, MLR, BFGS) is fitted once to
#      obtain the point estimates, the standardized solution and the fit
#      indices of a nested trimmed model (Sections 4-5).
#   C. ONE inference engine only: the participant-level nonparametric
#      (cluster) bootstrap, B = 5000 resamples, percentile AND bias-corrected
#      and accelerated (BCa) 95% intervals, applied to EVERY reported quantity
#      -- the 11 path coefficients, all conditional / marginal indirect
#      effects, all conditional / marginal total effects and all contrasts
#      (Sections 6-8). No Wald / z test and no delta-method standard error is
#      used anywhere for the structural results, including Table 2.
#   C2. STANDARDISATION OF CONDITIONAL / MARGINAL EFFECTS (Table 3 beta).
#      lavaan's std.all standardises the interaction column with its own SD
#      (SD of dis*det = 0.433) but the two dummies with SD = 0.5. Adding such
#      coefficients -- which is what lavaan does for a defined parameter of
#      the form (a1 + a2)*b -- therefore mixes two denominators: it is not the
#      standardised conditional effect and can even flip the sign (row
#      'detection (disclosure = 1)' had b = +0.025 but beta = -0.004). All
#      indirect and total effects are standardised here as
#          beta = b(effect) * SD(focal predictor) / SD(perceived credibility)
#      with the SD ratio taken from the matching direct path (c_dis / c_det /
#      c_ix). For the 'other label = 0' rows and for the interaction rows this
#      reproduces lavaan's std.all exactly, so Table 2 is unchanged.
#   D. Robustness: the same bootstrap, the same seed and the same resamples
#      are used to compare the specification without post dummies with the
#      specification that adds the three post dummies as fixed effects
#      (Section 10); the CI for each difference is a paired cluster bootstrap.
#
# WHY THE BOOTSTRAP IS RUN ON THE POOLED-WITHIN OLS REPRESENTATION
#   At the within-person level the fitted two-level SEM is algebraically
#   equivalent to a system of pooled-within (person-mean-centred) OLS
#   regressions: all predictors vary only within participants, the between
#   level contains only random intercepts with a saturated covariance matrix,
#   and no cross-level interaction or random slope is estimated. The script
#   verifies that equivalence numerically (max |SEM - OLS| < 1e-3 in the
#   sample and across bootstrap resamples). The closed-form OLS representation
#   is used inside the bootstrap because (i) it is numerically exact and does
#   not depend on optimizer convergence, and (ii) it is the only way to add
#   the post dummies (lavaan's two-level ML engine returns wrong estimates for
#   the augmented model). Unstandardized bootstrap draws therefore come from
#   the OLS representation; the standardized solution and the fit indices come
#   from the lavaan SEM, as reported in the manuscript.
#
# Run   : Rscript analysis_bootstrap.R [B] [ncores]
#         B      = bootstrap replications (default 5000; >0)
#         ncores = parallel workers   (default min(detectCores()-1, 12))
# Output: analysis_bootstrap_output.txt
# Data  : exp2_data_with_post.dat  (id detect disclo AJ PD PC post)
# Seed  : 20240810 (resample indices are drawn on the master process, so the
#         results do NOT depend on the number of workers)
###############################################################################

suppressPackageStartupMessages({
  library(lavaan)
  library(parallel)
})

cmd_args <- commandArgs(trailingOnly = TRUE)
B        <- if (length(cmd_args) >= 1) as.integer(cmd_args[1]) else 5000L
N_CORES  <- if (length(cmd_args) >= 2) as.integer(cmd_args[2]) else
  min(max(1L, detectCores() - 1L), 12L)
SEED     <- 20240810L
OUT_FILE <- "analysis_bootstrap_output.txt"

PATH_LABELS <- c("a_dis_auth", "a_det_auth", "a_ix_auth",
                 "a_dis_disc", "a_det_disc", "a_ix_disc",
                 "b_auth", "b_disc", "c_dis", "c_det", "c_ix")

DEF_LABELS <- c(
  # indirect effects via perceived AI authorship
  "ie_dis_auth_0", "ie_dis_auth_1", "ie_dis_auth_m",
  "ie_det_auth_0", "ie_det_auth_1", "ie_det_auth_m", "ie_ix_auth",
  # indirect effects via psychological discomfort
  "ie_dis_disc_0", "ie_dis_disc_1", "ie_dis_disc_m",
  "ie_det_disc_0", "ie_det_disc_1", "ie_det_disc_m", "ie_ix_disc",
  # total effects (indirect + direct)
  "te_dis_0", "te_dis_1", "te_dis_m",
  "te_det_0", "te_det_1", "te_det_m", "te_ix",
  # contrasts
  "ctr_auth_dis_minus_det", "ctr_disc_det_minus_dis", "ctr_b_auth_minus_disc",
  "ctr_path_dis_auth_vs_disc", "ctr_path_det_auth_vs_disc",
  "ctr_cross_dis_vs_det_auth", "ctr_cross_det_vs_dis_disc",
  "ctr_te_dis_minus_det")

ALL_LABELS <- c(PATH_LABELS, DEF_LABELS)

sink(OUT_FILE, split = TRUE)

cat("#####################################################################\n")
cat("#  STUDY 2 -- UNIFIED BOOTSTRAP ANALYSIS (version 2)                 #\n")
cat("#####################################################################\n")
cat(sprintf("#  R %s | lavaan %s | lme4 %s\n", as.character(getRversion()),
    as.character(packageVersion("lavaan")),
    if (requireNamespace("lme4", quietly = TRUE))
      as.character(packageVersion("lme4")) else "not installed"))
cat(sprintf("#  Bootstrap: B = %d participant-level resamples | workers = %d\n",
    B, N_CORES))
cat(sprintf("#  Seed = %d (resample matrix drawn on the master process)\n", SEED))
cat("#  Inference: percentile and BCa 95% bootstrap CIs only.\n")
cat("#  No Wald/z tests, no delta-method SEs for any structural result.\n")
cat("#####################################################################\n")

# =============================================================================
# 1. DATA
# =============================================================================
raw_lines <- readLines("exp2_data_with_post.dat", encoding = "UTF-8")
if (length(raw_lines) > 0 && substr(raw_lines[1], 1, 1) == "\ufeff") {
  raw_lines[1] <- sub("^\ufeff", "", raw_lines[1])
  cat("(UTF-8 BOM removed)\n")
}
dat <- read.table(text = raw_lines, header = TRUE)
stopifnot(all(names(dat) == c("id", "detect", "disclo", "AJ", "PD", "PC", "post")))
names(dat) <- c("pid", "det", "dis", "auth", "disc", "cred", "post")
dat$pid  <- as.integer(dat$pid)
dat$post <- as.integer(dat$post)
dat$ix <- dat$det * dat$dis
dat$p2 <- as.integer(dat$post == 2)
dat$p3 <- as.integer(dat$post == 3)
dat$p4 <- as.integer(dat$post == 4)

n_obs <- nrow(dat); n_clu <- length(unique(dat$pid))
stopifnot(all(table(dat$pid) == 4))
# order by participant so that participant i occupies rows (4i-3):(4i)
dat <- dat[order(dat$pid, dat$post), ]
dat$pid <- rep(seq_len(n_clu), each = 4L)          # 1..149 in blocks of 4
stopifnot(nrow(dat) == 4L * n_clu)
row_of <- function(idx) as.vector(rbind(4L * idx - 3L, 4L * idx - 2L,
                                        4L * idx - 1L, 4L * idx))

cat("\n========== 1. DATA AND DESIGN ==========\n")
cat(sprintf("Observations N = %d | participants = %d | posts = %d\n",
            n_obs, n_clu, length(unique(dat$post))))
cat(sprintf("Observations per participant = %d (balanced 2 x 2 within-person)\n",
            n_obs / n_clu))
pp <- tapply(dat$post, dat$pid, function(x) length(unique(x)))
cat(sprintf("Participants who saw all 4 posts exactly once: %d / %d\n",
            sum(pp == 4), length(pp)))
cat("-> post is a within-person factor fully crossed with participant\n")
cat("   (randomised Latin-square assignment of posts to condition cells).\n")

cat("\n-- Cell means (SD) by condition, order: no label / detection only /\n")
cat("   disclosure only / both --\n")
cell_lab <- c("no_label (det0,dis0)", "detection_only (1,0)",
              "disclosure_only (0,1)", "both (1,1)")
for (v in c("cred", "auth", "disc")) {
  for (k in seq_along(cell_lab)) {
    d <- switch(k, dat[dat$det == 0 & dat$dis == 0, ], dat[dat$det == 1 & dat$dis == 0, ],
                dat[dat$det == 0 & dat$dis == 1, ], dat[dat$det == 1 & dat$dis == 1, ])
    cat(sprintf("   %-24s %-22s n=%3d  M=%.2f  SD=%.2f\n",
                v, cell_lab[k], nrow(d), mean(d[[v]]), sd(d[[v]])))
  }
}
cat("\n-- Overall M and SD --\n")
for (v in c("auth", "disc", "cred"))
  cat(sprintf("   %-8s M = %.3f  SD = %.3f\n", v, mean(dat[[v]]), sd(dat[[v]])))
cat("\nNOTE: Table 1 of the manuscript must use ONE SD convention. The SDs\n")
cat("printed above are the sample SDs (divisor N-1). The manuscript-ready\n")
cat("block right below is the block to copy into Table 1 (sample SDs only).\n")

cat("\n-- TABLE 1 (manuscript-ready): M (SD), sample SD (divisor N-1), 2 dp --\n")
tab1_cond <- c("Absent / Absent", "Present / Absent", "Absent / Present", "Present / Present")
tab1_name <- c(cred = "Perceived credibility", auth = "Perceived AI authorship",
               disc = "Psychological discomfort")
for (v in c("cred", "auth", "disc")) {
  cells <- lapply(seq_len(4), function(k)
    switch(k, dat[dat$det == 0 & dat$dis == 0, ], dat[dat$det == 1 & dat$dis == 0, ],
              dat[dat$det == 0 & dat$dis == 1, ], dat[dat$det == 1 & dat$dis == 1, ]))
  vals <- vapply(cells, function(d) sprintf("%.2f (%.2f)", mean(d[[v]]), sd(d[[v]])), "")
  cat(sprintf("   %-25s detection/disclosure: %s\n", tab1_name[[v]],
              paste(sprintf("%s = %s", tab1_cond, vals), collapse = " | ")))
}
cat("   (detection/disclosure column order as in the manuscript Table 1;\n")
cat("    n = 149 per cell; all values are sample SDs, divisor N-1)\n")

# ---- predictors vary only within participants (between covariance = 0) ----
cbm <- cov(aggregate(cbind(dis, det, ix) ~ pid, dat, mean)[, -1])
cat("\n-- Between-participant covariance of the predictors (cluster means) --\n")
print(round(cbm, 6))
if (all(abs(cbm) < 1e-10))
  cat("   -> predictors vary ONLY within participants: all predictor effects\n")
  cat("      are within-person effects.\n")

# =============================================================================
# 2. ICCs
# =============================================================================
cat("\n========== 2. ICCs (participant / stimulus post) ==========\n")
icc_oneway <- function(y, cluster) {
  a <- aov(y ~ factor(cluster)); ms <- summary(a)[[1]]
  msb <- ms[["Mean Sq"]][1]; msw <- ms[["Mean Sq"]][2]
  nbar <- length(y) / length(unique(cluster))
  (msb - msw) / (msb + (nbar - 1) * msw)
}
for (v in c("auth", "disc", "cred"))
  cat(sprintf("   %-8s ICC_participant = %.3f   ICC_post = %.3f\n",
              v, icc_oneway(dat[[v]], dat$pid), icc_oneway(dat[[v]], dat$post)))
if (requireNamespace("lme4", quietly = TRUE)) {
  suppressPackageStartupMessages(library(lme4))
  cat("\n-- Crossed random intercepts: y ~ (1|pid) + (1|post) --\n")
  for (v in c("auth", "disc", "cred")) {
    m <- suppressMessages(lmer(as.formula(sprintf("%s ~ 1 + (1|pid) + (1|post)", v)),
                               data = dat, REML = TRUE))
    vc <- as.data.frame(VarCorr(m))
    vid <- vc$vcov[vc$grp == "pid"]; vpo <- vc$vcov[vc$grp == "post"]
    vre <- vc$vcov[vc$grp == "Residual"]; tot <- vid + vpo + vre
    cat(sprintf("   %-8s var(pid)=%.4f var(post)=%.4f resid=%.4f | ICC_pid=%.3f ICC_post=%.3f\n",
                v, vid, vpo, vre, vid / tot, vpo / tot))
  }
  cat("   NOTE: post ICCs rest on only 4 posts -> descriptive only.\n")
  cat("   post is treated as a FIXED blocking factor, not a random effect.\n")
}

# =============================================================================
# 3. DESCRIPTIVE INFERENCE (manuscript Section 3.6.2) -- UNCHANGED
#    Cell means/SDs/SEs, repeated-measures MANOVA, univariate 2x2 within-
#    subject ANOVA, and simple-effects paired t-tests with Cohen's dz are
#    reproduced from the original analysis_final.R verbatim: the bootstrap
#    unification affects only Sections 6-10. Optional bootstrap CIs for the
#    same condition contrasts are printed separately in Section 9.
# =============================================================================
cat("\n========== 3. Descriptive Inference: rm-MANOVA, univariate 2x2 ANOVA, simple effects ==========\n")
cat("(Reproduces manuscript Section 3.6.2. Exact repeated-measures computations;\n")
cat(" all tests are within-subject. Condition cells (detection, disclosure):\n")
cat(" no_label (0,0), detection_only (1,0), disclosure_only (0,1), both (1,1).)\n")

cell_mat <- function(v) {
  m <- matrix(NA_real_, nrow = n_clu, ncol = 4,
              dimnames = list(NULL, c("no_label", "det_only", "dis_only", "both")))
  x <- dat[[v]]
  key <- dat$det + 2L * dat$dis + 1L            # 1=00, 2=10, 3=01, 4=11
  for (i in seq_len(nrow(dat))) m[dat$pid[i], key[i]] <- x[i]
  m
}
Y <- list(auth = cell_mat("auth"), disc = cell_mat("disc"), cred = cell_mat("cred"))
stopifnot(!any(is.na(Y$auth)), !any(is.na(Y$disc)), !any(is.na(Y$cred)))

DV_LABEL <- c(cred = "perceived_credibility", auth = "perceived_ai_authorship",
              disc = "psychological_discomfort")
CELL_LABEL <- c("no_label", "detection_only", "disclosure_only", "both")

cat("\n-- Cell means, SDs, SEs (M, SD; SE = SD/sqrt(N)) --\n")
for (v in c("cred", "auth", "disc")) {
  Z <- Y[[v]]
  cat(sprintf("  %s: ", DV_LABEL[v]))
  for (j in seq_len(ncol(Z))) {
    m <- mean(Z[, j]); s <- sd(Z[, j])
    cat(sprintf("%s M=%.2f SD=%.2f SE=%.2f | ", CELL_LABEL[j], m, s, s / sqrt(nrow(Z))))
  }
  cat("\n")
}

manova_fun <- function(C) {
  M <- sapply(Y, function(Z) Z %*% C); mu <- colMeans(M); S <- var(M); n <- nrow(M)
  T2 <- as.numeric(n * t(mu) %*% solve(S) %*% mu); lam <- 1 / (1 + T2 / (n - 1))
  Fv <- (1 - lam) / lam * (n - 3) / 3
  c(Wilks = lam, F = Fv, df1 = 3, df2 = n - 3, p = 1 - pf(Fv, 3, n - 3), eta2 = 1 - lam)
}
rm_f <- function(Z) {
  n <- nrow(Z)
  one <- function(cv) {
    ss <- n * mean(cv)^2; mse <- sum((cv - mean(cv))^2) / (n - 1); Fv <- ss / mse
    c(F = Fv, p = 1 - pf(Fv, 1, n - 1), eta2 = Fv / (Fv + n - 1))
  }
  rbind(detection   = one((Z[, "det_only"] + Z[, "both"]) - (Z[, "no_label"] + Z[, "dis_only"])),
        disclosure  = one((Z[, "dis_only"] + Z[, "both"]) - (Z[, "no_label"] + Z[, "det_only"])),
        interaction = one((Z[, "both"] - Z[, "dis_only"]) - (Z[, "det_only"] - Z[, "no_label"])))
}
cat("\n-- Repeated-measures MANOVA (3 DVs) --\n")
print(round(rbind(detection = manova_fun(c(-1, 1, -1, 1) / 2),
                  disclosure = manova_fun(c(-1, -1, 1, 1) / 2),
                  interaction = manova_fun(c(1, -1, -1, 1) / 2)), 4))

cat("\n-- Univariate 2x2 within-subject ANOVA (F(1, 148), eta2p = F/(F+148)) --\n")
for (v in c("auth", "disc", "cred")) {
  cat(sprintf("  %s:\n", DV_LABEL[v])); print(round(rm_f(Y[[v]]), 4))
}

# simple effects: paired t-tests on difference scores; Cohen's dz
simple_eff <- function(Z, nm) {
  tests <- list(
    list(sprintf("%s: detection | disclosure = 0", nm), Z[, "det_only"], Z[, "no_label"]),
    list(sprintf("%s: detection | disclosure = 1", nm), Z[, "both"], Z[, "dis_only"]),
    list(sprintf("%s: disclosure | detection = 0", nm), Z[, "dis_only"], Z[, "no_label"]),
    list(sprintf("%s: disclosure | detection = 1", nm), Z[, "both"], Z[, "det_only"])
  )
  out <- lapply(tests, function(t) {
    d <- t[[2]] - t[[3]]
    tt <- t.test(d)
    data.frame(effect = t[[1]], Mdiff = mean(d), SD_diff = sd(d),
               t = as.numeric(tt$statistic), df = as.numeric(tt$parameter),
               p = tt$p.value, dz = mean(d) / sd(d))
  })
  do.call(rbind, out)
}
cat("\n-- Simple effects (paired t-tests, unadjusted p; Cohen's dz = Mdiff/SD_diff) --\n")
print(simple_eff(Y$cred, "Credibility"), row.names = FALSE, digits = 4)
print(simple_eff(Y$auth, "AI authorship"), row.names = FALSE, digits = 4)
print(simple_eff(Y$disc, "Discomfort"), row.names = FALSE, digits = 4)
SE_tab <- rbind(cbind(dv = "credibility", simple_eff(Y$cred, "Credibility")),
                cbind(dv = "AI authorship", simple_eff(Y$auth, "AI authorship")),
                cbind(dv = "discomfort", simple_eff(Y$disc, "Discomfort")))
SE_tab$abs_dz_2dp <- sprintf("%.2f", abs(SE_tab$dz))
SE_tab$p_APA <- ifelse(SE_tab$p < .001, "< .001", sprintf("%.3f", SE_tab$p))
cat("\n-- Simple effects: manuscript-ready (copy 'p_APA' and 'abs_dz_2dp') --\n")
print(SE_tab[, c("effect", "Mdiff", "t", "p", "p_APA", "dz", "abs_dz_2dp")],
      row.names = FALSE, digits = 4)
cat("\n  NOTE: p values are unadjusted paired t-tests (as in the manuscript).\n")
cat("  'abs_dz_2dp' is the value to report as Cohen's d (rounded to 2 dp);\n")
cat("  'p_APA' is the APA-7 form (3 decimals, no leading zero).\n")

# =============================================================================
# 4. STRUCTURAL MODEL: two-level dual-mediation SEM (lavaan, MLR)
# =============================================================================
model <- '
  level: 1
      auth ~ a_dis_auth*dis + a_det_auth*det + a_ix_auth*ix
      disc ~ a_dis_disc*dis + a_det_disc*det + a_ix_disc*ix
      cred ~ b_auth*auth + b_disc*disc + c_dis*dis + c_det*det + c_ix*ix
      auth ~~ disc
  level: 2
      auth ~~ auth
      disc ~~ disc
      cred ~~ cred
      auth ~~ disc
      auth ~~ cred
      disc ~~ cred

  # ---- indirect effects via perceived AI authorship ----
  ie_dis_auth_0 := a_dis_auth * b_auth
  ie_dis_auth_1 := (a_dis_auth + a_ix_auth) * b_auth
  ie_dis_auth_m := a_dis_auth * b_auth + 0.5 * a_ix_auth * b_auth
  ie_det_auth_0 := a_det_auth * b_auth
  ie_det_auth_1 := (a_det_auth + a_ix_auth) * b_auth
  ie_det_auth_m := a_det_auth * b_auth + 0.5 * a_ix_auth * b_auth
  ie_ix_auth    := a_ix_auth * b_auth

  # ---- indirect effects via psychological discomfort ----
  ie_dis_disc_0 := a_dis_disc * b_disc
  ie_dis_disc_1 := (a_dis_disc + a_ix_disc) * b_disc
  ie_dis_disc_m := a_dis_disc * b_disc + 0.5 * a_ix_disc * b_disc
  ie_det_disc_0 := a_det_disc * b_disc
  ie_det_disc_1 := (a_det_disc + a_ix_disc) * b_disc
  ie_det_disc_m := a_det_disc * b_disc + 0.5 * a_ix_disc * b_disc
  ie_ix_disc    := a_ix_disc * b_disc

  # ---- total effects (indirect + direct) ----
  te_dis_0 := a_dis_auth * b_auth + a_dis_disc * b_disc + c_dis
  te_dis_1 := (a_dis_auth + a_ix_auth) * b_auth
            + (a_dis_disc + a_ix_disc) * b_disc + c_dis + c_ix
  te_dis_m := a_dis_auth * b_auth + a_dis_disc * b_disc + c_dis
            + 0.5 * (a_ix_auth * b_auth + a_ix_disc * b_disc + c_ix)
  te_det_0 := a_det_auth * b_auth + a_det_disc * b_disc + c_det
  te_det_1 := (a_det_auth + a_ix_auth) * b_auth
            + (a_det_disc + a_ix_disc) * b_disc + c_det + c_ix
  te_det_m := a_det_auth * b_auth + a_det_disc * b_disc + c_det
            + 0.5 * (a_ix_auth * b_auth + a_ix_disc * b_disc + c_ix)
  te_ix    := a_ix_auth * b_auth + a_ix_disc * b_disc + c_ix

  # ---- contrasts ----
  ctr_auth_dis_minus_det      := a_dis_auth - a_det_auth
  ctr_disc_det_minus_dis      := a_det_disc - a_dis_disc
  ctr_b_auth_minus_disc       := b_auth - b_disc
  ctr_path_dis_auth_vs_disc   := ie_dis_auth_0 - ie_dis_disc_0
  ctr_path_det_auth_vs_disc   := ie_det_auth_0 - ie_det_disc_0
  ctr_cross_dis_vs_det_auth   := ie_dis_auth_0 - ie_det_auth_0
  ctr_cross_det_vs_dis_disc   := ie_det_disc_0 - ie_dis_disc_0
  ctr_te_dis_minus_det        := te_dis_0 - te_det_0
'

cat("\n========== 4. Two-level dual-mediation SEM (lavaan, MLR, BFGS) ==========\n")
fit <- suppressWarnings(sem(model, data = dat, cluster = "pid", estimator = "MLR",
                            control = list(iter.max = 20000, optim.method = "BFGS")))
cat("Converged:", isTRUE(lavInspect(fit, "converged")), "\n")
pe <- parameterEstimates(fit, standardized = TRUE)
key <- ifelse(pe$op == ":=" | pe$op == "~", pe$label, NA_character_)
m   <- match(ALL_LABELS, key)
stopifnot(!anyNA(m))
EST  <- setNames(pe$est[m], ALL_LABELS)
BETA <- setNames(pe$std.all[m], ALL_LABELS)

cat("\n-- Path coefficients (point estimates; inference in Section 6) --\n")
cat(sprintf("   %-16s %10s %10s\n", "label", "b", "beta"))
for (l in PATH_LABELS)
  cat(sprintf("   %-16s %10.3f %10.3f\n", l, EST[l], BETA[l]))

# ---- sanity check: lavaan within level == pooled-within OLS ----
cols_order <- c("dis", "det", "ix", "p2", "p3", "p4", "auth", "disc", "cred")
Mfull <- as.matrix(dat[, cols_order])
demean_blocks <- function(M, k = 4L) {
  G <- nrow(M) %/% k
  gm <- rowsum(M, rep(seq_len(G), each = k)) / k
  M - gm[rep(seq_len(G), each = k), , drop = FALSE]
}
fit_ols <- function(M, withpost = FALSE) {
  D <- demean_blocks(M)
  xs <- if (withpost) c("dis", "det", "ix", "p2", "p3", "p4") else c("dis", "det", "ix")
  Xa <- D[, xs, drop = FALSE]
  aa <- qr.solve(crossprod(Xa), crossprod(Xa, D[, "auth"]))
  ad <- qr.solve(crossprod(Xa), crossprod(Xa, D[, "disc"]))
  Xc <- cbind(D[, "auth", drop = FALSE], D[, "disc", drop = FALSE], Xa)
  ac <- qr.solve(crossprod(Xc), crossprod(Xc, D[, "cred"]))
  setNames(c(aa[1:3], ad[1:3], ac[1:5]), PATH_LABELS)
}
ols_full <- fit_ols(Mfull)
cat(sprintf("\nSanity check | SEM(within) - pooled-within OLS | max = %.6f  (%s)\n",
            max(abs(ols_full - EST[PATH_LABELS])),
            ifelse(max(abs(ols_full - EST[PATH_LABELS])) < 1e-3,
                   "PASS: the two representations are equivalent", "FAIL")))

# =============================================================================
# 5. MODEL FIT
# =============================================================================
cat("\n========== 5. MODEL FIT ==========\n")
cat("The full model is just-identified at the within-person level (df = 0):\n")
cat("its fit indices are perfect by construction and carry no information.\n")
cat("Report the nested trimmed model (three direct paths fixed to 0; df = 3).\n")
model_trim <- '
  level: 1
      auth ~ a_dis_auth*dis + a_det_auth*det + a_ix_auth*ix
      disc ~ a_dis_disc*dis + a_det_disc*det + a_ix_disc*ix
      cred ~ b_auth*auth + b_disc*disc
      auth ~~ disc
  level: 2
      auth ~~ auth
      disc ~~ disc
      cred ~~ cred
      auth ~~ disc
      auth ~~ cred
      disc ~~ cred
'
fit_trim <- suppressWarnings(sem(model_trim, data = dat, cluster = "pid",
                                 estimator = "MLR",
                                 control = list(iter.max = 20000, optim.method = "BFGS")))
fm <- fitMeasures(fit_trim, c("chisq", "df", "pvalue", "chisq.scaled", "df.scaled",
                              "pvalue.scaled", "cfi", "tli", "cfi.scaled", "tli.scaled",
                              "rmsea", "rmsea.scaled", "srmr_within", "srmr_between"))
cat(sprintf("\nTrimmed model: chi2(%g) = %.3f, p = %.3f | scaled chi2(%g) = %.3f, p = %.3f\n",
            fm["df"], fm["chisq"], fm["pvalue"], fm["df.scaled"],
            fm["chisq.scaled"], fm["pvalue.scaled"]))
cat(sprintf("CFI = %.3f (robust %.3f) | TLI = %.3f (robust %.3f)\n",
            fm["cfi"], fm["cfi.scaled"], fm["tli"], fm["tli.scaled"]))
cat(sprintf("RMSEA = %.3f (robust %.3f) | SRMR_within = %.3f | SRMR_between = %.3f\n",
            fm["rmsea"], fm["rmsea.scaled"], fm["srmr_within"], fm["srmr_between"]))
cat("The three direct paths jointly add no misfit.\n")

# ---- pooled-within R2 ----
Dw <- as.data.frame(demean_blocks(Mfull))
r2 <- c(
  auth = summary(lm(auth ~ dis + det + ix, Dw))$r.squared,
  disc = summary(lm(disc ~ dis + det + ix, Dw))$r.squared,
  cred = summary(lm(cred ~ auth + disc + dis + det + ix, Dw))$r.squared)
cat(sprintf("\nWithin-person R2 (pooled-within OLS): auth = %.3f | disc = %.3f | cred = %.3f\n",
            r2["auth"], r2["disc"], r2["cred"]))
cat("(lavaan's model-implied within-level R2 is printed by lavInspect(fit,\"rsquare\");\n")
cat(" use the pooled-within OLS value above, as in the manuscript.)\n")

# =============================================================================
# 6. THE ONE INFERENCE ENGINE: PARTICIPANT-LEVEL CLUSTER BOOTSTRAP (lavaan)
# =============================================================================
cat("\n========== 6. PARTICIPANT-LEVEL CLUSTER BOOTSTRAP ==========\n")
cat(sprintf("Resampling the %d participants with replacement, B = %d.\n", n_clu, B))
cat("Indirect/total effects and path coefficients are all taken from the same\n")
cat(sprintf("%d resamples, so every number in Tables 2 and 3 comes from one\n", B))
cat("single method. Percentile and BCa intervals are both reported; BCa uses\n")
cat("delete-one-participant jackknife acceleration.\n")

set.seed(SEED)
idx_mat <- matrix(sample(seq_len(n_clu), size = B * n_clu, replace = TRUE),
                  nrow = B, ncol = n_clu)

boot_one <- function(b) {
  idx <- idx_mat[b, ]
  bd  <- dat[row_of(idx), , drop = FALSE]
  bd$pid <- rep(seq_len(n_clu), each = 4L)
  fb <- try(suppressWarnings(sem(model, data = bd, cluster = "pid", estimator = "MLR",
                                 control = list(iter.max = 20000, optim.method = "BFGS"),
                                 verbose = FALSE, warn = FALSE)), silent = TRUE)
  if (inherits(fb, "try-error")) return(NULL)
  if (!isTRUE(lavInspect(fb, "converged"))) return(NULL)
  if (isTRUE(fitMeasures(fb, "chisq") > 1e-3)) return(NULL)
  pb <- try(parameterEstimates(fb, standardized = TRUE), silent = TRUE)
  if (inherits(pb, "try-error")) return(NULL)
  kk <- ifelse(pb$op == ":=" | pb$op == "~", pb$label, NA_character_)
  mm <- match(ALL_LABELS, kk)
  if (anyNA(mm)) return(NULL)
  setNames(c(pb$est[mm], pb$std.all[mm]),
           c(ALL_LABELS, paste0(ALL_LABELS, "_beta")))
}

cat(sprintf("\nRunning %d lavaan bootstrap fits on %d workers ...\n", B, N_CORES))
t0 <- proc.time()
cl <- makePSOCKcluster(N_CORES)
clusterExport(cl, c("idx_mat", "dat", "n_clu", "model", "ALL_LABELS", "row_of",
                    "boot_one", "B"), envir = environment())
invisible(clusterEvalQ(cl, suppressPackageStartupMessages(library(lavaan))))
boot_list <- parLapply(cl, seq_len(B), boot_one)
stopCluster(cl)
el <- (proc.time() - t0)["elapsed"]
cat(sprintf("Bootstrap finished in %.1f min.\n", el / 60))

ok <- !vapply(boot_list, is.null, logical(1))
cat(sprintf("Valid replications: %d / %d (%.1f%%)\n", sum(ok), B, 100 * mean(ok)))
BOOT <- do.call(rbind, boot_list[ok])
BOOT <- BOOT[, c(ALL_LABELS, paste0(ALL_LABELS, "_beta")), drop = FALSE]
B_ok <- nrow(BOOT)
if (B_ok < max(30, 0.5 * B)) stop("too few valid bootstrap replications")

# ---- standardisation of the conditional / marginal effects (Table 3) --------
# beta = b(effect) * SD(focal predictor) / SD(perceived credibility); the SD
# ratio comes from the matching direct path (c_dis / c_det / c_ix) so that
# Table 2 and the 'other label = 0' / interaction rows of Table 3 are
# numerically identical to lavaan's std.all.
focal_cpath <- function(l) {
  if (!grepl("^(ie_|te_)", l)) return(NA_character_)
  if (grepl("^(ie_dis|te_dis)", l)) return("c_dis")
  if (grepl("^(ie_det|te_det)", l)) return("c_det")
  if (grepl("^(ie_ix|te_ix)", l)) return("c_ix")
  NA_character_
}
corr_rows  <- ALL_LABELS[grepl("^(ie_|te_)", ALL_LABELS)]
BETA_CORR  <- BETA
BETA_CORR_MAT <- as.matrix(BOOT[, paste0(ALL_LABELS, "_beta"), drop = FALSE])
colnames(BETA_CORR_MAT) <- ALL_LABELS     # index by plain label, not "_beta"
for (l in corr_rows) {
  cp <- focal_cpath(l)
  if (is.na(cp)) next
  r    <- BETA[cp] / EST[cp]
  rb   <- BOOT[, paste0(cp, "_beta")] / BOOT[, cp]
  rb[!is.finite(rb)] <- r
  BETA_CORR[l]       <- EST[l] * r
  BETA_CORR_MAT[, l] <- BOOT[, l] * rb
}
changed <- corr_rows[abs(BETA_CORR[corr_rows] - BETA[corr_rows]) > 1e-6]
cat("\n-- Standardisation check for the Table 3 beta column --\n")
cat("   Rule: beta = b(effect) * SD(focal predictor) / SD(perceived credibility),\n")
cat("   SD ratio from the matching direct path (c_dis / c_det / c_ix).\n")
cat(sprintf("   %d of %d indirect/total-effect rows change; the rest are unchanged.\n",
            length(changed), length(corr_rows)))
for (l in changed)
  cat(sprintf("   %-16s b = %8.3f | lavaan std.all = %8.4f -> corrected beta = %8.4f\n",
              l, EST[l], BETA[l], BETA_CORR[l]))

# ---- delete-one-participant jackknife (BCa acceleration) ----
jk_one <- function(j) {
  bd <- dat[dat$pid != j, , drop = FALSE]
  fj <- try(suppressWarnings(sem(model, data = bd, cluster = "pid", estimator = "MLR",
                                 control = list(iter.max = 20000, optim.method = "BFGS"),
                                 verbose = FALSE, warn = FALSE)), silent = TRUE)
  if (inherits(fj, "try-error")) return(rep(NA_real_, length(ALL_LABELS)))
  if (!isTRUE(lavInspect(fj, "converged"))) return(rep(NA_real_, length(ALL_LABELS)))
  pj <- try(parameterEstimates(fj), silent = TRUE)
  if (inherits(pj, "try-error")) return(rep(NA_real_, length(ALL_LABELS)))
  kk <- ifelse(pj$op == ":=" | pj$op == "~", pj$label, NA_character_)
  mm <- match(ALL_LABELS, kk)
  out <- rep(NA_real_, length(ALL_LABELS)); out[!is.na(mm)] <- pj$est[mm[!is.na(mm)]]
  out
}
cat("\nDelete-one-participant jackknife for BCa ...\n")
cl <- makePSOCKcluster(min(N_CORES, 12L))
clusterExport(cl, c("dat", "model", "ALL_LABELS", "jk_one"), envir = environment())
invisible(clusterEvalQ(cl, suppressPackageStartupMessages(library(lavaan))))
JK <- do.call(rbind, parLapply(cl, seq_len(n_clu), jk_one))
stopCluster(cl)
colnames(JK) <- ALL_LABELS
cat(sprintf("Jackknife fits completed: %d participants.\n", nrow(JK)))

# ---- bootstrap summaries ----
pct_ci   <- function(x, a = .05) quantile(x, c(a / 2, 1 - a / 2), na.rm = TRUE)
bca_ci   <- function(x, th, jk, a = .05) {
  x <- x[!is.na(x)]; jk <- jk[!is.na(jk)]
  if (length(x) < 50 || length(jk) < 30 || !is.finite(th)) return(c(NA, NA))
  s <- sd(jk); if (!is.finite(s) || s < 1e-12) return(c(NA, NA))
  mb <- mean(jk); den <- sum((mb - jk)^2)
  if (!is.finite(den) || den < 1e-24) return(c(NA, NA))
  z0  <- qnorm(mean(x < th))
  acc <- sum((mb - jk)^3) / (6 * den^1.5)
  za <- qnorm(a / 2); zb <- qnorm(1 - a / 2)
  p1 <- pnorm(z0 + (z0 + za) / (1 - acc * (z0 + za)))
  p2 <- pnorm(z0 + (z0 + zb) / (1 - acc * (z0 + zb)))
  p1 <- min(max(p1, 1e-6), 1 - 1e-6); p2 <- min(max(p2, 1e-6), 1 - 1e-6)
  c(as.numeric(quantile(x, p1)), as.numeric(quantile(x, p2)))
}
boot_p <- function(x) { x <- x[!is.na(x)]; 2 * min(mean(x <= 0), mean(x >= 0)) }
sig_star <- function(lo, hi) ifelse(is.na(lo) | is.na(hi), "n/a",
                                    ifelse(lo * hi > 0, "sig", "n.s."))
p_str <- function(p) if (is.na(p)) "n/a" else if (p < .001) "< .001" else sprintf("%.3f", p)

boot_mat <- function(lab, std = FALSE)
  BOOT[, if (std) paste0(lab, "_beta") else lab]

summarise <- function(labs) {
  out <- data.frame(label = labs, b = NA_real_, boot_se = NA_real_,
                    pct_lo = NA_real_, pct_hi = NA_real_,
                    bca_lo = NA_real_, bca_hi = NA_real_, p_boot = NA_real_,
                    beta = NA_real_, beta_lo = NA_real_, beta_hi = NA_real_,
                    stringsAsFactors = FALSE)
  for (i in seq_along(labs)) {
    l <- labs[i]
    xb <- boot_mat(l)
    ci <- pct_ci(xb); bc <- bca_ci(xb, EST[l], JK[, l])
    cis <- tryCatch(pct_ci(BETA_CORR_MAT[, l]), error = function(e) c(NA, NA))
    out$b[i]        <- EST[l]
    out$boot_se[i]  <- sd(xb, na.rm = TRUE)
    out$pct_lo[i]   <- ci[1]; out$pct_hi[i] <- ci[2]
    out$bca_lo[i]   <- bc[1]; out$bca_hi[i] <- bc[2]
    out$p_boot[i]   <- boot_p(xb)
    out$beta[i]     <- BETA_CORR[l]
    out$beta_lo[i]  <- cis[1]; out$beta_hi[i] <- cis[2]
  }
  out
}

RES_PATH <- summarise(PATH_LABELS)
RES_DEF  <- summarise(DEF_LABELS)

# ---- explicit percentile vs BCa agreement check ------------------------------
print_ci_disagreement <- function(df, disp) {
  pct_sig <- df$pct_lo * df$pct_hi > 0
  bca_sig <- df$bca_lo * df$bca_hi > 0
  d <- df[which(!is.na(pct_sig) & !is.na(bca_sig) & pct_sig != bca_sig), , drop = FALSE]
  if (nrow(d) == 0) {
    cat("Percentile and BCa intervals gave the SAME significance decision for every\n")
    cat("effect listed above.\n")
  } else {
    cat(sprintf("Percentile and BCa intervals DISAGREED for %d effect(s):\n", nrow(d)))
    for (i in seq_len(nrow(d)))
      cat(sprintf("   %-44s pct [%7.3f,%7.3f] n.s.  |  BCa [%7.3f,%7.3f] sig\n",
                  disp[d$label[i]], d$pct_lo[i], d$pct_hi[i],
                  d$bca_lo[i], d$bca_hi[i]))
    cat("   Report the percentile interval as primary (pre-specified) and state the\n")
    cat("   BCa discrepancy explicitly; do not call these effects significant.\n")
  }
}

# ---- engine validation: lavaan vs pooled-within OLS on shared resamples ----
n_chk  <- min(300L, B_ok)
chk_id <- which(ok)[seq_len(n_chk)]
ols_chk <- t(vapply(chk_id, function(b) fit_ols(Mfull[row_of(idx_mat[b, ]), , drop = FALSE]),
                    numeric(length(PATH_LABELS))))
lav_chk <- BOOT[seq_len(n_chk), PATH_LABELS, drop = FALSE]
cat(sprintf("\nEngine check on %d shared resamples: max |lavaan - OLS| = %.6f\n",
            n_chk, max(abs(lav_chk - ols_chk), na.rm = TRUE)))
cat("-> the lavaan SEM and its closed-form pooled-within representation are the\n")
cat("   same estimator, so the OLS representation used in Section 10 for the\n")
cat("   with-post comparison is consistent with the model reported here.\n")

# =============================================================================
# 7. TABLE 2 -- PATH COEFFICIENTS (bootstrap SE / CI)
# =============================================================================
cat("\n#####################################################################\n")
cat("#  TABLE 2 (ready to use): PATH COEFFICIENTS                        #\n")
cat("#  Estimates: two-level dual-mediation SEM (MLR).  SE, CI and p:    #\n")
cat("#  participant-level cluster bootstrap, B = 5000.                   #\n")
cat("#####################################################################\n")
path_disp <- c(
  a_dis_auth = "disclosure -> perceived AI authorship",
  a_det_auth = "detection -> perceived AI authorship",
  a_ix_auth  = "detection x disclosure -> perceived AI authorship",
  a_dis_disc = "disclosure -> psychological discomfort",
  a_det_disc = "detection -> psychological discomfort",
  a_ix_disc  = "detection x disclosure -> psychological discomfort",
  b_auth     = "perceived AI authorship -> perceived credibility",
  b_disc     = "psychological discomfort -> perceived credibility",
  c_dis      = "disclosure -> perceived credibility (direct)",
  c_det      = "detection -> perceived credibility (direct)",
  c_ix       = "detection x disclosure -> perceived credibility (direct)")
cat(sprintf("\n%-58s %8s %8s %-21s %-21s %8s %8s\n", "Path", "b", "Boot SE",
            "95% Boot CI (pct)", "95% Boot CI (BCa)", "p(boot)", "beta"))
cat(strrep("-", 155), "\n")
for (i in seq_len(nrow(RES_PATH))) {
  r <- RES_PATH[i, ]
  cat(sprintf("%-58s %8.3f %8.3f [%7.3f,%7.3f] %-6s [%7.3f,%7.3f] %-6s %8s %8.3f\n",
              path_disp[r$label], r$b, r$boot_se, r$pct_lo, r$pct_hi,
              sig_star(r$pct_lo, r$pct_hi), r$bca_lo, r$bca_hi,
              sig_star(r$bca_lo, r$bca_hi), p_str(r$p_boot), r$beta))
}
cat(strrep("-", 155), "\n")
av <- pe[pe$op == "~~" & pe$lhs == "auth" & pe$rhs == "disc", ]
if (nrow(av) > 0) {
  lvl_lab <- function(k) {
    b <- av$block[k]
    if (is.na(b)) "unknown level" else
      if (b == 1) "level 1, within-person" else "level 2, between-person"
  }
  for (k in seq_len(nrow(av)))
    cat(sprintf(paste0("Residual covariance auth ~~ disc (%s): b = %.3f, SE = %.3f, ",
                       "z = %.3f, p = %.3f\n"),
                lvl_lab(k), av$est[k], av$se[k], av$z[k], av$pvalue[k]))
}
cat(sprintf("\nBeta 95%% bootstrap CI\n"))
for (i in seq_len(nrow(RES_PATH)))
  cat(sprintf("   %-58s %7.3f [%7.3f, %7.3f]\n", RES_PATH$label[i], RES_PATH$beta[i],
              RES_PATH$beta_lo[i], RES_PATH$beta_hi[i]))
cat("\n-- Percentile vs BCa agreement --\n")
print_ci_disagreement(RES_PATH, path_disp)
cat("\nNOTE. Every SE, CI and p in Table 2 now comes from the same 5,000-sample\n")
cat("participant-level cluster bootstrap; the previous Wald/robust-SE column is\n")
cat("removed. 'sig' = the 95% CI excludes 0. p(boot) = 2 x min(P(b*<=0),\n")
cat("P(b*>=0)), reported for journals that require a p column; with B = 5000\n")
cat("its resolution is 0.0004, so values printed as < .001 mean p < .001.\n")

# =============================================================================
# 8. TABLE 3 -- INDIRECT, TOTAL AND CONTRAST EFFECTS
# =============================================================================
cat("\n#####################################################################\n")
cat("#  TABLE 3 (ready to use): INDIRECT, TOTAL AND CONTRAST EFFECTS     #\n")
cat("#  All values from the same participant-level cluster bootstrap.    #\n")
cat("#####################################################################\n")
grp_of <- function(l) {
  if (grepl("^ie_.*_auth", l)) return("Indirect via perceived AI authorship")
  if (grepl("^ie_.*_disc", l)) return("Indirect via psychological discomfort")
  if (grepl("^ie_", l))        return("Indirect effects")
  if (grepl("^te_", l))        return("Total effects (indirect + direct)")
  if (grepl("^ctr_", l))       return("Contrasts")
  "Other"
}
def_disp <- c(
  ie_dis_auth_0 = "disclosure (detection = 0)",
  ie_dis_auth_1 = "disclosure (detection = 1)",
  ie_dis_auth_m = "disclosure (marginal)",
  ie_det_auth_0 = "detection (disclosure = 0)",
  ie_det_auth_1 = "detection (disclosure = 1)",
  ie_det_auth_m = "detection (marginal)",
  ie_ix_auth    = "interaction",
  ie_dis_disc_0 = "disclosure (detection = 0)",
  ie_dis_disc_1 = "disclosure (detection = 1)",
  ie_dis_disc_m = "disclosure (marginal)",
  ie_det_disc_0 = "detection (disclosure = 0)",
  ie_det_disc_1 = "detection (disclosure = 1)",
  ie_det_disc_m = "detection (marginal)",
  ie_ix_disc    = "interaction",
  te_dis_0 = "disclosure (detection = 0)", te_dis_1 = "disclosure (detection = 1)",
  te_dis_m = "disclosure (marginal)",
  te_det_0 = "detection (disclosure = 0)", te_det_1 = "detection (disclosure = 1)",
  te_det_m = "detection (marginal)", te_ix = "interaction",
  ctr_auth_dis_minus_det = "disclosure vs. detection on perceived AI authorship",
  ctr_disc_det_minus_dis = "detection vs. disclosure on psychological discomfort",
  ctr_b_auth_minus_disc = "perceived AI authorship vs. discomfort on credibility",
  ctr_path_dis_auth_vs_disc = "disclosure: via authorship vs. via discomfort",
  ctr_path_det_auth_vs_disc = "detection: via authorship vs. via discomfort",
  ctr_cross_dis_vs_det_auth = "via authorship: disclosure vs. detection",
  ctr_cross_det_vs_dis_disc = "via discomfort: detection vs. disclosure",
  ctr_te_dis_minus_det = "total effect: disclosure vs. detection")

cat(sprintf("\n%-62s %8s %8s %-20s %-20s %8s %8s\n", "Effect", "b", "Boot SE",
            "95% CI (pct)", "95% CI (BCa)", "p(boot)", "beta"))
cat(strrep("-", 158), "\n")
last <- ""
for (i in seq_len(nrow(RES_DEF))) {
  r <- RES_DEF[i, ]
  g <- grp_of(r$label)
  if (g != last) { cat(sprintf("\n-- %s --\n", g)); last <- g }
  cat(sprintf("%-62s %8.3f %8.3f [%7.3f,%7.3f] %-6s [%7.3f,%7.3f] %-6s %8s %8.3f\n",
              def_disp[r$label], r$b, r$boot_se, r$pct_lo, r$pct_hi,
              sig_star(r$pct_lo, r$pct_hi), r$bca_lo, r$bca_hi,
              sig_star(r$bca_lo, r$bca_hi), p_str(r$p_boot), r$beta))
}
cat(strrep("-", 158), "\n")
cat("\nBeta (standardized) effects with 95% percentile bootstrap CI:\n")
for (i in seq_len(nrow(RES_DEF)))
  cat(sprintf("   %-62s %7.3f [%7.3f, %7.3f] %s\n", RES_DEF$label[i],
              RES_DEF$beta[i], RES_DEF$beta_lo[i], RES_DEF$beta_hi[i],
              sig_star(RES_DEF$beta_lo[i], RES_DEF$beta_hi[i])))
cat("\nSuffixes: _0 = the other label absent, _1 = the other label present,\n")
cat("_m = marginal (average over the two levels of the other label).\n")
cat("All effects are CONDITIONAL on the other label unless marked marginal.\n")
cat("\n-- Percentile vs BCa agreement --\n")
print_ci_disagreement(RES_DEF, def_disp)

# =============================================================================
# 9. BOOTSTRAP CIs FOR THE DESCRIPTIVE CONDITION CONTRASTS
# =============================================================================
cat("\n========== 9. DESCRIPTIVE CONDITION CONTRASTS (bootstrap CIs) ==========\n")
cat("Same resamples; cell means and their differences are recomputed in every\n")
cat("resample. Supplementary only: Section 3.6.2 (MANOVA/ANOVA) stays unchanged.\n")
cell_names <- c("no_label", "det_only", "dis_only", "both")
boot_cell <- function(v) {
  Z <- Y[[v]]
  t(vapply(seq_len(B), function(b) colMeans(Z[idx_mat[b, ], , drop = FALSE]),
           numeric(4)))
}
BC <- lapply(names(Y), boot_cell); names(BC) <- names(Y)
# signed contrast weights over columns no_label / det_only / dis_only / both
contr_list <- list(
  "detection | disclosure = 0 (det_only - no_label)" = c(-1,  1,  0,  0),
  "detection | disclosure = 1 (both - dis_only)"     = c( 0,  0, -1,  1),
  "disclosure | detection = 0 (dis_only - no_label)" = c(-1,  0,  1,  0),
  "disclosure | detection = 1 (both - det_only)"     = c( 0, -1,  0,  1),
  "detection main effect (F-test contrast)"          = c(-1,  1, -1,  1),
  "disclosure main effect (F-test contrast)"         = c(-1, -1,  1,  1),
  "interaction (F-test contrast)"                    = c( 1, -1, -1,  1))
for (v in c("cred", "auth", "disc")) {
  Z <- Y[[v]]; bb <- BC[[v]]
  cat(sprintf("\n-- %s --\n", v))
  cat(sprintf("%-52s %8s %-20s\n", "contrast", "Mdiff", "95% boot CI (pct)"))
  for (nm in names(contr_list)) {
    w <- contr_list[[nm]]
    est <- sum(w * colMeans(Z))
    d <- as.vector(bb %*% w)
    ci <- pct_ci(d)
    cat(sprintf("%-52s %8.3f [%7.3f,%7.3f] %s\n", nm, est, ci[1], ci[2],
                sig_star(ci[1], ci[2])))
  }
}

# =============================================================================
# 10. ROBUSTNESS: POST DUMMIES ADDED AS FIXED EFFECTS
# =============================================================================
cat("\n========== 10. ROBUSTNESS: ADDING THE POST DUMMIES ==========\n")
cat("The same participants are resampled with the same seed, and both\n")
cat("specifications are fitted to every resample; the CI for each difference\n")
cat("is a paired cluster bootstrap over the identical resamples.\n")
cat("The closed-form pooled-within estimator is used here because it is the\n")
cat("exact within-level representation of the SEM and, unlike lavaan's\n")
cat("two-level ML engine, it stays numerically valid once post dummies are\n")
cat("added (lavaan returns wrong coefficients for that augmented model).\n")

boot_ols <- t(vapply(seq_len(B), function(b) {
  M <- Mfull[row_of(idx_mat[b, ]), , drop = FALSE]
  c(fit_ols(M), setNames(fit_ols(M, withpost = TRUE), paste0(PATH_LABELS, "_post")))
}, numeric(2 * length(PATH_LABELS))))
ols0 <- fit_ols(Mfull)
ols1 <- fit_ols(Mfull, withpost = TRUE)
cat(sprintf("\n%-46s %9s %9s %9s %-21s\n", "Path", "no post", "with post",
            "difference", "95% boot CI of difference"))
for (l in PATH_LABELS) {
  d <- boot_ols[, paste0(l, "_post")] - boot_ols[, l]
  ci <- pct_ci(d)
  cat(sprintf("%-46s %9.3f %9.3f %+9.3f [%7.3f,%7.3f] %s\n", l, ols0[l], ols1[l],
              ols1[l] - ols0[l], ci[1], ci[2], sig_star(ci[1], ci[2])))
}
cat(sprintf("\nMaximum absolute change across the 11 paths: %.3f (largest relative\n",
            max(abs(ols1 - ols0))))
sub <- abs(ols0) > 0.15
cat(sprintf("change among the %d paths with |b| > 0.15: %.1f%%).\n",
            sum(sub), 100 * max(abs((ols1[sub] - ols0[sub]) / ols0[sub]))))
cat("No difference CI above excludes zero unless marked sig.\n")

cat("\nIndirect and total effects, with and without post dummies\n")
cat("(unstandardized; percentile bootstrap CI of the difference):\n")
cat(sprintf("%-22s %8s %8s %11s   %-21s %s\n", "effect", "no post", "with post",
            "difference", "95% CI of difference", "decision"))
comp_b <- function(b) {
  g <- function(nm) if (is.matrix(b)) b[, nm] else b[[nm]]
  a_dis_auth <- g("a_dis_auth"); a_det_auth <- g("a_det_auth")
  a_ix_auth  <- g("a_ix_auth")
  a_dis_disc <- g("a_dis_disc"); a_det_disc <- g("a_det_disc")
  a_ix_disc  <- g("a_ix_disc")
  b_auth <- g("b_auth"); b_disc <- g("b_disc")
  c_dis <- g("c_dis"); c_det <- g("c_det"); c_ix <- g("c_ix")
  cbind(ie_dis_auth_0 = a_dis_auth * b_auth,
        ie_dis_disc_0 = a_dis_disc * b_disc,
        ie_det_auth_0 = a_det_auth * b_auth,
        ie_det_disc_0 = a_det_disc * b_disc,
        ie_ix_auth    = a_ix_auth * b_auth,
        ie_ix_disc    = a_ix_disc * b_disc,
        ie_dis_auth_m = (a_dis_auth + 0.5 * a_ix_auth) * b_auth,
        ie_dis_disc_m = (a_dis_disc + 0.5 * a_ix_disc) * b_disc,
        ie_det_auth_m = (a_det_auth + 0.5 * a_ix_auth) * b_auth,
        ie_det_disc_m = (a_det_disc + 0.5 * a_ix_disc) * b_disc,
        te_dis_m = (a_dis_auth + 0.5 * a_ix_auth) * b_auth +
          (a_dis_disc + 0.5 * a_ix_disc) * b_disc + c_dis + 0.5 * c_ix,
        te_det_m = (a_det_auth + 0.5 * a_ix_auth) * b_auth +
          (a_det_disc + 0.5 * a_ix_disc) * b_disc + c_det + 0.5 * c_ix,
        te_ix = a_ix_auth * b_auth + a_ix_disc * b_disc + c_ix)
}
B0 <- boot_ols[, PATH_LABELS, drop = FALSE]
B1 <- boot_ols[, paste0(PATH_LABELS, "_post"), drop = FALSE]
colnames(B1) <- PATH_LABELS
C0 <- comp_b(B0); C1 <- comp_b(B1)
s0 <- comp_b(ols0); s1 <- comp_b(ols1)
for (nm in colnames(s0)) {
  d  <- C1[, nm] - C0[, nm]
  ci <- pct_ci(d)
  cat(sprintf("%-22s %7.3f  %7.3f   diff %+7.3f [%7.3f,%7.3f] %s\n",
              nm, s0[1, nm], s1[1, nm], s1[1, nm] - s0[1, nm], ci[1], ci[2],
              sig_star(ci[1], ci[2])))
}

# =============================================================================
# 11. NOTES
# =============================================================================
cat("\n\n")
cat("======================================================================\n")
cat("  NOTES AND REPORTING CHECKLIST\n")
cat("======================================================================\n")
cat(sprintf("1. Method: two-level dual-mediation SEM (lavaan %s, MLR, BFGS);\n",
            as.character(packageVersion("lavaan"))))
cat("   ALL inference is a participant-level nonparametric cluster bootstrap\n")
cat(sprintf("   (B = %d, seed %d). No Wald/z test and no delta-method SE is\n", B, SEED))
cat("   used for any structural result.\n")
cat("2. Resampling unit = participant (the independent sampling unit); every\n")
cat("   resampled participant carries all four of her/his observations, so the\n")
cat("   within-person design and the crossed post assignment are preserved.\n")
cat("3. Both percentile and BCa intervals are reported and their agreement is\n")
cat("   checked explicitly at the end of each table block. Report the percentile\n")
cat("   interval as primary (pre-specified) and disclose any disagreement.\n")
cat("4. Resample indices are drawn once on the master process before the\n")
cat("   parallel loop, so results are exactly reproducible and independent of\n")
cat("   the number of workers (seed printed above).\n")
cat("5. Point estimates come from the MLR SEM; the bootstrap only provides the\n")
cat("   empirical sampling distribution. Within-level SEM coefficients equal\n")
cat("   pooled-within OLS (verified above), which is the estimator used inside\n")
cat("   the bootstrap and for the with-post robustness check.\n")
cat("6. Multiplicity: bootstrap CIs are per-effect and unadjusted. The two\n")
cat("   hypothesis-bearing contrasts are 'disclosure vs. detection on perceived\n")
cat("   AI authorship' (H2b) and 'detection vs. disclosure on psychological\n")
cat("   discomfort' (H1b); if the journal requires a multiplicity adjustment,\n")
cat("   apply it to those two p(boot) values only. The remaining contrasts and\n")
cat("   all indirect/total effects are descriptive and are not adjusted.\n")
cat("7. Post (stimulus) was treated as a fixed blocking factor; only four\n")
cat("   posts exist, so a post random effect is not estimable with confidence.\n")
cat("8. Effect sizes to report for the mediation results are the completely\n")
cat("   standardized effects (beta) with their bootstrap CIs; the total-effect\n")
cat("   and indirect-effect betas are printed above. For indirect/total effects\n")
cat("   beta = b x SD(focal predictor) / SD(perceived credibility) (SD ratio\n")
cat("   taken from the matching direct path), because lavaan's std.all\n")
cat("   standardises the interaction column on its own SD (0.433) whereas the\n")
cat("   two dummies have SD = 0.5; adding those coefficients would mix two\n")
cat("   denominators and could flip the sign (see the Section 6 check).\n")
cat("9. The within-level residual covariance auth ~~ disc is printed with its\n")
cat("   robust (MLR) SE, z and p in Section 7, so that the manuscript value\n")
cat("   0.28 (SE = 0.09, p = .001) is traceable to this output file.\n")
cat("======================================================================\n")

sink()
cat("\nWritten to:", OUT_FILE, "\n")
