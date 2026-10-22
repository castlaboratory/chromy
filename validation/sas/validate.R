# Validation of chromy against SAS PROC SURVEYSELECT METHOD=PPS_SEQ.
#
# Run from this folder after receiving the three CSVs the SAS script
# (surveyselect_chromy.sas) exports:
#
#   Rscript validate.R
#
# Each system consumes its own random-number generator, so the hits of a
# single run cannot match draw for draw; what must agree is everything the
# design determines (expected hits, the serpentine order) and everything
# the method promises in distribution (exact n, minimum replacement, hits
# converging to their expectation).

frame <- read.csv("frame.csv")
reference <- read.csv("chromy_reference.csv")
single <- read.csv("sas_single_run.csv")
reps <- read.csv("sas_replications.csv")

n <- 15
ok <- function(test, label) {
  cat(sprintf("[%s] %s\n", if (test) "ok" else "FALHOU", label))
  invisible(test)
}
results <- c()

# 1. ExpectedHits: deterministic, must agree to export precision. SAS's
# PPS_SEQ is pure minimum replacement (expected hits above one allowed;
# certainties are a separate SAS option), so the design to match is
# chromy's min_replacement = TRUE.
m <- merge(reps[!duplicated(reps$unit), c("unit", "ExpectedHits")],
           reference[c("unit", "expected_hits")], by = "unit")
delta_lambda <- max(abs(m$ExpectedHits - m$expected_hits))
results["lambda"] <- ok(delta_lambda < 1e-8,
  sprintf("ExpectedHits identicos (maior diferenca: %.2e, %d unidades observadas)",
          delta_lambda, nrow(m)))

# 2. The sample size is exact in every replication.
hits_by_seed <- tapply(reps$NumberHits, reps$seed, sum)
results["exact_n"] <- ok(all(hits_by_seed == n),
  sprintf("soma dos hits = %d em todas as %d sementes", n, length(hits_by_seed)))

# 3. Minimum replacement in every replication.
viol <- sum(reps$NumberHits != floor(reps$ExpectedHits) &
            reps$NumberHits != ceiling(reps$ExpectedHits))
results["pmr"] <- ok(viol == 0,
  sprintf("hits sempre em {floor, ceil} do esperado (%d violacoes)", viol))

# 4. Expected hits are delivered: observed frequency vs lambda, in MC SEs.
# Under minimum replacement hits are floor(lambda) + Bernoulli(frac), so
# the Monte Carlo variance is frac * (1 - frac).
n_seeds <- length(unique(reps$seed))
observed <- tapply(reps$NumberHits, reps$unit, sum) / n_seeds
observed <- observed[match(reference$unit, names(observed))]
observed[is.na(observed)] <- 0
lambda <- reference$expected_hits
frac <- lambda - floor(lambda)
mc_se <- sqrt(frac * (1 - frac) / n_seeds)
z <- abs(observed - lambda) / pmax(mc_se, 1e-9)
z <- z[frac > 1e-12]   # integer expected hits have no MC error
results["freq"] <- ok(max(z) < 4,
  sprintf("frequencia observada ~ ExpectedHits (max |z| = %.2f em %d unidades)",
          max(z), length(z)))

# 5. The serpentine order, unit by unit.
chromy_order <- reference$unit[order(reference$serp_position)]
sas_order <- single$unit[0]
if (file.exists("sas_sorted_frame.csv")) {
  sas_order <- read.csv("sas_sorted_frame.csv")$unit
}
if (length(sas_order) == length(chromy_order)) {
  same <- sas_order == chromy_order
  results["serp"] <- ok(all(same),
    sprintf("ordem serpentina identica (%d/%d posicoes)", sum(same), length(same)))
  if (!all(same)) {
    cat("  primeiras divergencias (posicao: SAS vs chromy):\n")
    d <- which(!same)[1:min(5, sum(!same))]
    for (p in d) cat(sprintf("  %d: %s vs %s\n", p, sas_order[p], chromy_order[p]))
  }
} else {
  cat("[aviso] sas_sorted_frame.csv ausente ou incompleto; ordem nao comparada\n")
}

cat(sprintf("\n%d/%d verificacoes passaram.\n", sum(results), length(results)))
if (!all(results)) quit(status = 1)
