# Match keyed weights over the entire cohort before selecting adherers. Raw
# vectors are positional, so their names can verify order but cannot repair it.
aligned_weights <- function(weights, ids) {
  if (is.null(weights)) return(rep(1, length(ids)))
  if (inherits(weights, "longwr_weights")) {
    if (!is.list(weights) || sum(names(weights) %in% "id") != 1L ||
        sum(names(weights) %in% "w") != 1L)
      stop("A longwr_weights object must contain exactly one id and w field each.")
    keys <- validate_ids(weights[["id"]])
    if (is.numeric(ids) != is.numeric(keys)) {
      numeric_ids <- if (is.numeric(ids)) ids else keys
      if (any(as.numeric(as.character(numeric_ids)) != numeric_ids))
        stop("Mixed numeric and character IDs require lossless text labels.")
    }
    index <- match(ids, keys)
    if (length(keys) != length(ids) || anyNA(index) || anyDuplicated(index))
      stop("Weight object IDs must match all data IDs exactly once.")
    w <- weights[["w"]]
    if (!plain_number(w) || length(w) != length(keys))
      stop("Expected one numeric weight per weight object ID.")
    return(unname(w[index]))
  }
  if (!plain_number(weights) || length(weights) != length(ids))
    stop("Provide one numeric weight per input row.")
  if (anyDuplicated(names(weights)))
    stop("Named numeric weights have ambiguous ID labels.")
  if (!is.null(names(weights))) {
    if (!identical(names(weights), as.character(ids)))
      stop("Named numeric weights must have data IDs in input row order.")
    if (is.numeric(ids) && any(as.numeric(names(weights)) != ids))
      stop("Named numeric weights require lossless text labels for numeric IDs.")
  }
  unname(weights)
}

# Log of a sum given its log terms. Subtract the largest term before
# exponentiating. Empty sets and zero-weight-only sets have log mass -Inf.
log_mass <- function(x) {
  if (!length(x)) return(-Inf)
  largest <- max(x)
  if (largest == -Inf) return(-Inf)
  largest + log(sum(exp(x - largest)))
}

# Compute log(w / sum(w)) for one nonempty regime of positive total weight.
# Centering on its maximum avoids forming either the raw sum or pair products.
normalized_log_weights <- function(w) {
  values <- log(w) - log(max(w))
  values - log_mass(values)
}

#' Direct prioritized win ratio for sustained treatment histories
#'
#' Compares every observed 11 subject with every observed 00 subject. Lower
#' adverse-event status wins first. For equal status, higher score wins, with
#' an exact tie for equal scores. Weights are normalized within each regime.
#'
#' @details Each 11 subject with weight \eqn{w_i} is compared with each 00
#' subject with weight \eqn{w_j}. Their pair contributes
#' \eqn{(w_i/S_{11})(w_j/S_{00})}, where each S is the sum of weights in
#' its regime. Summing these contributions separately for wins, losses and
#' ties gives their probabilities. WR is the win mass divided by the loss mass.
#' Multiplying all weights in either regime by a positive constant cancels.
#'
#' The direct comparison takes \eqn{O(n_{11} n_{00})} time. It stores
#' three log masses per 11 subject and comparison vectors over the 00
#' subjects, using \eqn{O(n_{11} + n_{00})} working storage. Full-cohort validation and
#' weight alignment also use time and space linear in the cohort size for a
#' fixed set of columns.
#'
#' With appropriate sequential inverse probability weights, this estimates a
#' marginal comparison of independent draws under sustained 11 and 00 in the
#' baseline population. This interpretation requires consistency, sequential
#' exchangeability, positivity and valid treatment probabilities. Unit weights
#' describe the observed 11 and 00 groups. Histories 01 and 10 enter the
#' full-cohort validation and counts only.
#'
#' @param data Data frame with one independent subject per row. Supply complete
#'   finite numeric covariates and endpoints. Binary fields accept 0/1 or
#'   logical values. Independence and measurement timing are caller assumptions.
#' @param weights NULL for a crude adherer comparison, or finite nonnegative
#'   numeric weights in exact input row order, including switchers. If named,
#'   names must uniquely and losslessly label row IDs in order. A list of
#'   class \code{longwr_weights} with unique \code{id} and numeric
#'   cumulative \code{w} vectors is matched
#'   by ID. Mixed numeric and character IDs require lossless text labels.
#'   The caller supplies weights appropriate to the target population.
#' @param id Name of the unique numeric, character, or factor subject ID.
#' @param treatment Two binary treatment column names in decision order.
#' @param baseline Names of one or more covariates measured before decision 0.
#' @param updated Names of one or more covariates updated before decision 1.
#' @param outcomes Names of the final binary adverse event and numeric score,
#'   in priority order. All mapped columns must be distinct.
#' @return A list with \code{wr} (11 wins divided by 11 losses),
#'   \code{p_win}, \code{p_loss}, and \code{p_tie} (normalized pair masses),
#'   \code{n_11}, \code{n_00} (observed regime sizes), \code{n_pairs}
#'   (their product, including zero-weight pairs), \code{history_counts}
#'   (named counts for 00, 01, 10, 11), \code{missing_histories} (labels of
#'   unobserved histories), \code{status}, and \code{reason}.
#'   Status is \code{ok} for an ordinary estimate. For \code{zero_loss},
#'   \code{zero_win}, and \code{all_ties}, WR is Inf, 0, and NA respectively.
#'   \code{empty_regime} and \code{invalid_weights} (nonfinite, negative, or
#'   zero total in a target regime) yield NA for WR and all probabilities.
#'   \code{numeric_range} flags a positive probability or positive finite
#'   ratio outside the representable range when both directions have mass.
#'   A genuine zero win or loss retains its status if a positive probability
#'   underflows to zero. The reason records that underflow. Nonfinite or
#'   negative supplied weights take precedence over a missing regime.
#'   The reason is NA for an ordinary estimate. Malformed mappings and weight
#'   dimensions or IDs raise errors.
#' @examples
#' trial <- data.frame(person = 1:4, first = c(1, 1, 0, 0),
#'                     last = c(1, 1, 0, 0), age = 41:44, visit = 4:1,
#'                     adverse = c(0, 1, 0, 1), score = c(1, 4, 1, 2))
#' fit <- longwr_estimate(trial, c(2, 1, 3, 4), id = "person",
#'                        treatment = c("first", "last"), baseline = "age",
#'                        updated = "visit", outcomes = c("adverse", "score"))
#' fit$wr
#' @export
longwr_estimate <- function(data, weights = NULL, id = "id", treatment = c("A0", "A1"),
                            baseline = "L0", updated = "L1", outcomes = c("B", "Y")) {
  d <- validate_schema(data, id, treatment, baseline, updated, outcomes)
  w <- aligned_weights(weights, d$id)
  treated <- which(d$A0 == 1 & d$A1 == 1)
  control <- which(d$A0 == 0 & d$A1 == 0)
  counts <- tabulate(1 + 2 * d$A0 + d$A1, nbins = 4)
  names(counts) <- c("00", "01", "10", "11")
  result <- list(wr = NA_real_, p_win = NA_real_, p_loss = NA_real_, p_tie = NA_real_,
                 n_11 = length(treated), n_00 = length(control),
                 n_pairs = as.double(length(treated)) * length(control),
                 history_counts = counts, missing_histories = names(counts)[counts == 0],
                 status = "ok", reason = NA_character_)
  if (any(!is.finite(w)) || any(w < 0)) {
    result$status <- "invalid_weights"
    result$reason <- "Every supplied subject weight must be finite and nonnegative."
    return(result)
  }
  if (!length(treated) || !length(control)) {
    result$status <- "empty_regime"
    result$reason <- "Both histories 11 and 00 need at least one subject."
    return(result)
  }
  if (!any(w[treated] > 0) || !any(w[control] > 0)) {
    result$status <- "invalid_weights"
    result$reason <- "Weights must be finite and nonnegative with positive mass in each target regime."
    return(result)
  }

  trt_w <- normalized_log_weights(w[treated])
  con_w <- normalized_log_weights(w[control])
  trt_b <- d$B[treated]
  trt_y <- d$Y[treated]
  con_b <- d$B[control]
  con_y <- d$Y[control]
  row_mass <- matrix(-Inf, nrow = length(treated), ncol = 3)
  # All treated subjects with the same event status share these comparisons.
  # Write each contribution at its original row to preserve summation order.
  for (b in 0:1) {
    event_win <- b < con_b
    same_event <- b == con_b
    for (i in which(trt_b == b)) {
      wins <- event_win | (same_event & trt_y[i] > con_y)
      ties <- same_event & trt_y[i] == con_y
      losses <- !(wins | ties)
      # Sum the loss weights directly. Subtracting win and tie masses from
      # one could erase a small positive loss probability through roundoff.
      row_mass[i, ] <- trt_w[i] + c(log_mass(con_w[wins]), log_mass(con_w[losses]),
                                    log_mass(con_w[ties]))
    }
  }
  masses <- apply(row_mass, 2L, log_mass)
  # The categories partition all pairs. Renormalizing their combined mass
  # removes roundoff at the boundary, including an exhaustive tie probability.
  probabilities <- exp(masses - log_mass(masses))
  result$p_win <- probabilities[1]
  result$p_loss <- probabilities[2]
  result$p_tie <- probabilities[3]
  if (all(masses[1:2] == -Inf)) {
    result$status <- "all_ties"
    result$reason <- "Every positive-weight pair tied."
  } else {
    # The log ratio can be finite even when both displayed probabilities
    # underflow. Only a log mass of -Inf denotes an empty positive-weight category.
    result$wr <- exp(masses[1] - masses[2])
    if (masses[1] == -Inf) {
      result$status <- "zero_win"
      result$reason <- "No positive-weight pair was a win."
    } else if (masses[2] == -Inf) {
      result$status <- "zero_loss"
      result$reason <- "No positive-weight pair was a loss."
    }
    underflow <- any(is.finite(masses) & probabilities == 0)
    if (result$status == "ok" && (underflow || result$wr %in% c(0, Inf))) {
      result$status <- "numeric_range"
      result$reason <- "A positive mass or finite ratio is outside double precision range."
    } else if (underflow) {
      result$reason <- paste(result$reason, "A positive probability rounded to zero by underflow.")
    }
  }
  result
}
