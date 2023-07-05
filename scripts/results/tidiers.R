tidy.Egger <- function(m) {
  tibble::tibble(
    term = c("beta", "intercept"),
    estimate = c(m$Estimate, m$Intercept),
    std.error = c(m$StdError.Est, m$StdError.Int),
    conf.low = c(m$CILower.Est, m$CILower.Int),
    conf.high = c(m$CIUpper.Est, m$CIUpper.Int),
    p.value = c(m$Pvalue.Est, m$Pvalue.Int)
  )
}
tidy.IVW <- function(m) {
  tibble::tibble(
    term = "beta",
    estimate = m$Estimate,
    std.error = m$StdError,
    conf.low = m$CILower,
    conf.high = m$CIUpper,
    p.value = m$Pvalue
  )
}
tidy.MRMBE <- tidy.IVW
tidy.WeightedMedian <- tidy.IVW
tidy.cause <- function(m) {
  with(
    summary(m$causal),
    tibble::tibble(
      term = "beta",
      estimate = quants[1, "gamma"],
      conf.low = quants[2, "gamma"],
      conf.high = quants[3, "gamma"]
    )
  )
}
tidy.MVEgger <- function(m) {
  tibble::tibble(
    term = c(m$Exposure, "intercept"),
    estimate = c(m$Estimate, m$Intercept),
    std.error = c(m$StdError.Est, m$StdError.Int),
    conf.low = c(m$CILower.Est, m$CILower.Int),
    conf.high = c(m$CIUpper.Est, m$CIUpper.Int),
    p.value = c(m$Pvalue.Est, m$Pvalue.Int)
  )
}
tidy.MVIVW <- function(m) {
  tibble::tibble(
    term = m$Exposure,
    estimate = m$Estimate,
    std.error = m$StdError,
    conf.low = m$CILower,
    conf.high = m$CIUpper,
    p.value = m$Pvalue
  )
}
tidy.MVLasso <- tidy.MVIVW
tidy.MVMedian <- tidy.MVIVW

glance.Egger <- function(m) {
    tibble::tibble(
    nobs = m$SNPs,
    sigma = m$RSE,
    i.squared = m$I.sq,
    cochran.qe = m$Heter.Stat[[1]],
    p.value.cochran.qe = m$Heter.Stat[[2]]
  )
}
glance.IVW <- function(m) {
  tibble::tibble(
    nobs = m$SNPs,
    sigma = m$RSE,
    cochran.qe = m$Heter.Stat[[1]],
    p.value.cochran.qe = m$Heter.Stat[[2]]
  )
}
glance.MRMBE <- function(m) {
  tibble::tibble(nobs = m$SNPs)
}
glance.WeightedMedian <- glance.MRMBE
glance.cause <- function(m) {
  tibble::tibble(
    p.value.causal                = summary(m)$p,
    sharing.causal.delta.elpd     = m$elpd[3,"delta_elpd"],
    sharing.causal.se.delta.elpd  = m$elpd[3,"se_delta_elpd"],
    sharing.causal.z              = m$elpd[3,"z"],
  )
}
glance.MVEgger <- glance.IVW
glance.MVIVW <- glance.IVW
glance.MVLasso <- glance.MRMBE
glance.MVMedian <- glance.MRMBE
glance.MRInput <- function(m) {
  tibble::tibble(
    nobs = length(m$snps),
    f.statistic.mean = mean((m$betaX^2) / (m$betaXse^2))
  )
}
