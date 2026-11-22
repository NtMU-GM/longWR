test_that("the four Section 8 pairs contribute win 8+4, loss 3, tie 6", {
  d <- subjects()
  w <- c(2, 1, 3, 4, 100, 100)
  fit <- longwr_estimate(d, w)
  expect_equal(fit$wr, 4)
  expect_equal(unname(unlist(fit[c("p_win", "p_loss", "p_tie")])), c(12, 3, 6) / 21)
  expect_identical(fit$status, "ok")
  expect_equal(c(fit$n_11, fit$n_00, fit$n_pairs), c(2, 2, 4))
  expect_type(fit$n_pairs, "double")
  expect_equal(fit$history_counts, c("00" = 2, "01" = 1, "10" = 1, "11" = 2))
  adherers <- longwr_estimate(d[1:4, ], w[1:4])
  expect_equal(adherers$wr, fit$wr)
  expect_identical(adherers$missing_histories, c("01", "10"))
  expect_equal(longwr_estimate(d), longwr_estimate(d, rep(1, 6)))
  expect_equal(longwr_estimate(d)$wr, 2)
  d$A0 <- 1 - d$A0
  d$A1 <- 1 - d$A1
  expect_equal(longwr_estimate(d, w)$wr, 1 / fit$wr)
})

test_that("numeric row order and weight-object ID matching are respected", {
  d <- subjects()
  w <- c(2, 1, 3, 4, 0, 1)
  key <- structure(list(id = factor(d$id), w = w), class = "longwr_weights")
  ix <- c(5, 3, 2, 6, 4, 1)
  expected <- longwr_estimate(d, w)
  expect_equal(longwr_estimate(d[ix, ], key), expected)
  expect_equal(longwr_estimate(d[ix, ], w[ix]), expected)
  names(w) <- d$id
  expect_equal(longwr_estimate(d, w), expected)
  expect_error(longwr_estimate(d[ix, ], w), "row order")
  key$id <- seq_len(6)
  expect_error(longwr_estimate(d, key), "IDs")
  key$id <- rep("x", 6)
  expect_error(longwr_estimate(d, key), "unique")
  key$id <- d$id
  key$w <- 1:3
  expect_error(longwr_estimate(d, key), "one numeric")
  key$w <- NULL
  expect_error(longwr_estimate(d, key), "id and w")
  for (bad in list(1, matrix(w), as.character(w), list(w), factor(w)))
    expect_error(longwr_estimate(d, bad), "one numeric")
})

test_that("a missing regime or unusable weights carry an explicit reason", {
  d <- subjects()
  for (rows in list(1:2, 3:4, 5:6, integer())) {
    fit <- longwr_estimate(d[rows, ])
    expect_identical(fit$status, "empty_regime")
    expect_equal(fit$n_pairs, 0)
    expect_true(all(is.na(unlist(fit[c("wr", "p_win", "p_loss", "p_tie")]))))
    expect_true(nzchar(fit$reason))
  }
  for (x in list(c(0, 0, 1, 1, 1, 1), c(1, 1, 0, 0, 1, 1),
                 c(1:5, -1), c(1:5, NA), c(1:5, NaN), c(1:5, Inf))) {
    fit <- longwr_estimate(d, x)
    expect_identical(fit$status, "invalid_weights")
    expect_true(all(is.na(unlist(fit[c("wr", "p_win", "p_loss", "p_tie")]))))
    expect_true(nzchar(fit$reason))
  }
})

test_that("binary priority, exact score ties, and one-sided results are explicit", {
  d <- subjects()[c(1, 4), ]
  d$Y <- c(-100, 100)
  win <- longwr_estimate(d)
  expect_equal(c(win$p_win, win$p_loss, win$p_tie, win$wr), c(1, 0, 0, Inf))
  expect_identical(win$status, "zero_loss")
  d$B <- 0
  loss <- longwr_estimate(d)
  expect_equal(c(loss$p_win, loss$p_loss, loss$p_tie, loss$wr), c(0, 1, 0, 0))
  expect_identical(loss$status, "zero_win")
  d$Y <- 1
  tie <- longwr_estimate(d)
  expect_equal(c(tie$p_win, tie$p_loss, tie$p_tie, tie$wr), c(0, 0, 1, NA))
  expect_identical(tie$status, "all_ties")
  d$Y[1] <- 1 + .Machine$double.eps
  expect_equal(longwr_estimate(d)$p_win, 1)
  expect_equal(longwr_estimate(subjects(), c(1, 0, 1, 0, 0, 0))$status, "all_ties")
})

test_that("regime normalization withstands overflow and preserves rare mass", {
  d <- subjects()
  w <- c(2, 1, 3, 4, 0, 0)
  baseline <- longwr_estimate(d, w)
  expect_equal(longwr_estimate(d, w * c(8e307, 8e307, 4e307, 4e307, 1, 1)), baseline)
  fit <- longwr_estimate(d, c(1, 1e-100, 1e-100, 1, 1, 1))
  expect_equal(fit$p_loss / 1e-200, 1)
  expect_equal(fit$wr / 1e200, 1)
  expect_equal(fit$p_tie / 1e-100, 1)
  fit <- longwr_estimate(d, c(1, 1e-200, 1e-200, 1, 1, 1))
  expect_identical(fit$status, "numeric_range")
  expect_equal(fit$wr, Inf)
})

test_that("public interface accepts externally named data and exact weights", {
  d <- subjects()
  names(d) <- c("subject", "first dose", "last dose", "pre value", "visit", "event", "score")
  fit <- longwr_estimate(d, c(2, 1, 3, 4, 0, 0), "subject", c("first dose", "last dose"),
                         "pre value", "visit", c("event", "score"))
  expect_equal(fit$wr, 4)
})

test_that("WINS reproduces the crude and weighted point calculations", {
  skip_if_not_installed("WINS")
  d <- subjects()
  compare <- function(d, supplied) {
    selected <- d$A0 == d$A1
    arms <- data.frame(id = which(selected), arm = d$A0[selected],
                       Y_1 = d$B[selected], Y_2 = d$Y[selected])
    for (method in c("unadjusted", "iptw")) {
      w <- if (method == "iptw") supplied
      fit <- longwr_estimate(d, w)
      reference <- WINS::win.stat(arms, ep_type = c("binary", "continuous"),
                                  arm.name = c(1, 0), priority = 1:2, tau = c(0, 0),
                                  np_direction = c("smaller", "larger"), method = method,
                                  iptw.weight = w[selected], digit = 12, summary.print = FALSE)
      expect_equal(fit$wr, unname(reference$Win_statistic$Win_Ratio["WR"]), tolerance = 1e-10)
      expect_equal(fit$p_win, reference$Win_prop$P_trt, tolerance = 1e-10)
      expect_equal(fit$p_loss, reference$Win_prop$P_con, tolerance = 1e-10)
      expect_equal(fit$p_tie, 1 - reference$Win_prop$P_trt - reference$Win_prop$P_con,
                   tolerance = 1e-10)
    }
  }
  compare(d, c(2, 1, 3, 4, 1, 1))
  # Unequal regime sizes, interleaved switchers and distinct row weights.
  more <- d[c(4, 1, 6, 2, 3, 3, 1, 5, 4), ]
  more$id <- seq_len(nrow(more))
  more$Y <- c(1, 1, 8, 4, 3, 1, 0, 2, -2)
  compare(more, seq_len(nrow(more)))
})

test_that("direct masses agree with explicit pairs on repeated outcomes", {
  set.seed(615)
  d <- subjects()[rep(1:6, 8), ]
  d$id <- seq_len(nrow(d))
  d$B <- sample(0:1, nrow(d), replace = TRUE)
  d$Y <- sample(-2:2, nrow(d), replace = TRUE)
  w <- sample(0:9, nrow(d), replace = TRUE)
  pairs <- expand.grid(i = which(d$A0 == 1 & d$A1 == 1),
                       j = which(d$A0 == 0 & d$A1 == 0))
  # This integer key is ordered only for this fixture's scores (-2 through 2).
  key <- 5 * (1 - d$B) + d$Y
  direction <- sign(key[pairs$i] - key[pairs$j])
  mass <- w[pairs$i] * w[pairs$j]
  expected <- c(sum(mass[direction == 1]), sum(mass[direction == -1]),
                sum(mass[direction == 0])) / sum(mass)
  fit <- longwr_estimate(d, w)
  expect_equal(c(fit$p_win, fit$p_loss, fit$p_tie), expected)
  expect_equal(fit$wr, expected[1] / expected[2])
})

test_that("ambiguous weight fields and ambiguous printed IDs are rejected", {
  d <- subjects()
  obj <- structure(list(id = d$id, w = rep(1, 6), w = 1:6), class = "longwr_weights")
  expect_error(longwr_estimate(d, obj), "exactly one")
  d$id <- c(1, 1 + .Machine$double.eps, 3:6)
  w <- setNames(c(2, 1, 3, 4, 1, 1), as.character(d$id))
  expect_error(longwr_estimate(d, w), "ambiguous")
  # Numeric keys retain both distinct double values even when text labels collide.
  obj <- structure(list(id = rev(d$id), w = rev(unname(w))), class = "longwr_weights")
  expect_equal(longwr_estimate(d, obj)$wr, 4)
})

test_that("an empty regime does not mask invalid supplied weight values", {
  fit <- longwr_estimate(subjects()[1:2, ], c(NA_real_, 1))
  expect_identical(fit$status, "invalid_weights")
  expect_true("00" %in% fit$missing_histories)
})

test_that("one-sided comparisons retain structural status under underflow", {
  d <- subjects()[1:4, ]
  d$B <- 0
  d$Y <- c(1, 0, 0, 0)
  w <- c(1e-300, 1e300, 1, 1)
  fit <- longwr_estimate(d, w)
  expect_identical(fit$status, "zero_loss")
  expect_identical(fit$wr, Inf)
  expect_identical(fit$p_win, 0)
  expect_match(fit$reason, "underflow")
  d$Y <- -d$Y
  fit <- longwr_estimate(d, w)
  expect_identical(fit$status, "zero_win")
  expect_identical(fit$wr, 0)
  expect_match(fit$reason, "underflow")
})

test_that("an exhaustive tie category has probability exactly one", {
  d <- subjects()
  d$B <- d$Y <- 0
  set.seed(615)
  for (i in 1:32) {
    fit <- longwr_estimate(d, runif(6))
    expect_identical(fit$p_tie, 1)
  }
})

test_that("the pair count survives integer overflow even for a nonestimable fit", {
  n <- 47000L
  arm <- rep(0:1, each = n)
  d <- data.frame(id = seq_along(arm), A0 = arm, A1 = arm, L0 = 0, L1 = 0, B = 0, Y = 0)
  fit <- longwr_estimate(d, as.numeric(arm))
  expect_identical(fit$n_pairs, 2209000000)
  expect_identical(fit$status, "invalid_weights")
})

test_that("mixed ID types must match without numeric rounding", {
  d <- subjects()
  d$id <- 1:6
  obj <- structure(list(id = as.character(d$id), w = c(2, 1, 3, 4, 1, 1)),
                   class = "longwr_weights")
  expect_equal(longwr_estimate(d, obj)$wr, 4)
  d$id[1] <- 1 + .Machine$double.eps
  expect_error(longwr_estimate(d, obj), "lossless")
  expect_error(longwr_estimate(d, setNames(obj$w, obj$id)), "lossless")
})

test_that("both tiny directional probabilities can underflow while WR is finite", {
  d <- subjects()[c(1, 2, 2, 3), ]
  d$id <- 1:4
  d$B <- 0
  d$Y <- c(0, 1, -1, 0)
  fit <- longwr_estimate(d, c(1e300, 2e-300, 1e-300, 1))
  expect_identical(fit$status, "numeric_range")
  expect_equal(fit$wr, 2)
  expect_equal(c(fit$p_win, fit$p_loss, fit$p_tie), c(0, 0, 1))
})

test_that("independent frequency tables reproduce every three-level outcome pattern", {
  # Integer weights expand the two empirical distributions into repeated draws.
  # Ordered levels (1,2,3) correspond to (B,Y) = (1,100), (0,-1), (0,0).
  d <- subjects()[1:4, ]
  patterns <- as.matrix(expand.grid(rep(list(1:3), 4)))
  for (row in seq_len(nrow(patterns))) {
    level <- patterns[row, ]
    d$B <- c(1, 0, 0)[level]
    d$Y <- c(100, -1, 0)[level]
    diffs <- outer(rep(level[1:2], c(2, 1)), rep(level[3:4], c(3, 4)), "-")
    probs <- c(mean(diffs > 0), mean(diffs < 0), mean(diffs == 0))
    fit <- longwr_estimate(d, c(2, 1, 3, 4))
    expect_equal(c(fit$p_win, fit$p_loss, fit$p_tie), probs)
  }
})
