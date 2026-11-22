# Exclude classed numeric storage such as dates and factor codes.
plain_number <- function(x) {
  is.null(dim(x)) && !is.object(x) && typeof(x) %in% c("double", "integer")
}

# Preserve numeric IDs at their original precision. Match factors by label.
validate_ids <- function(x) {
  if (is.factor(x) && is.null(dim(x))) x <- as.character(x)
  if (!(plain_number(x) || (is.character(x) && is.null(dim(x)))) ||
      anyNA(x) || anyDuplicated(x) ||
      (is.numeric(x) && any(!is.finite(x))) ||
      (is.character(x) && any(!nzchar(trimws(x))))) {
    stop("IDs must be unique, nonmissing, finite numbers or nonempty strings.")
  }
  unname(x)
}

# Return all mapped rows in input order with distinct internal column names.
# In particular, unusual external names never enter a formula or expression.
validate_schema <- function(data, id = "id", treatment = c("A0", "A1"),
                            baseline = "L0", updated = "L1", outcomes = c("B", "Y")) {
  if (!is.data.frame(data)) stop("data must be a data frame.")
  roles <- list(id = id, treatment = treatment, baseline = baseline,
                updated = updated, outcomes = outcomes)
  for (role in names(roles)) {
    x <- roles[[role]]
    if (!is.character(x) || !is.null(dim(x)) || !length(x) ||
        anyNA(x) || any(!nzchar(x))) stop("Invalid column mapping for ", role, ".")
  }
  if (length(id) != 1L || length(treatment) != 2L || length(outcomes) != 2L)
    stop("Map one ID, two ordered treatments and two ordered outcomes.")
  fields <- unlist(roles, use.names = FALSE)
  if (anyDuplicated(fields)) stop("Mapped column names must be distinct across all roles.")
  for (field in fields) {
    if (sum(names(data) %in% field) != 1L)
      stop("Expected exactly one column named '", field, "'.")
  }

  result <- data.frame(id = validate_ids(data[[id]]))
  for (field in fields[-1L]) {
    x <- data[[field]]
    if (is.logical(x) && is.null(dim(x)) && field != outcomes[2L]) x <- as.integer(x)
    if (!plain_number(x) || any(!is.finite(x)))
      stop("Column '", field, "' must contain finite numeric values.")
    if (field %in% c(treatment, outcomes[1L]) && any(!x %in% c(0, 1)))
      stop("Column '", field, "' must use binary 0/1 coding.")
    result[[ncol(result) + 1L]] <- x
  }
  names(result) <- c("id", "A0", "A1", paste0("baseline", seq_along(baseline)),
                     paste0("updated", seq_along(updated)), "B", "Y")
  result
}
