test_that("custom mappings preserve rows and multiple covariates", {
  d <- subjects()
  names(d) <- c("record", "first dose", "second", "pre!", "post", "adverse", "score")
  d$age <- 20:25
  d$flag <- rep(c(FALSE, TRUE), 3)
  s <- validate_schema(d, "record", c("first dose", "second"), c("pre!", "age"),
                       c("post", "flag"), c("adverse", "score"))
  expect_identical(s$id, d$record)
  expect_identical(s$baseline2, d$age)
  expect_equal(s$updated2, as.integer(d$flag))
  expect_equal(s$Y, d$score)
})

test_that("malformed mappings and ambiguous columns are rejected", {
  d <- subjects()
  expect_error(validate_schema(as.matrix(d)), "data frame")
  for (mapping in list(NULL, character(), NA_character_, "", 2, matrix("L0")))
    expect_error(validate_schema(d, baseline = mapping), "baseline")
  for (field in c("id", "A0", "A1", "L1", "B", "Y"))
    expect_error(validate_schema(d, baseline = field), "distinct")
  expect_error(validate_schema(d, treatment = "A0"), "two ordered")
  expect_error(validate_schema(d, outcomes = "B"), "two ordered")
  expect_error(validate_schema(d, id = c("id", "key")), "one ID")
  expect_error(validate_schema(d, updated = "absent"), "absent")
  names(d)[2] <- "id"
  expect_error(validate_schema(d), "exactly one")
})

test_that("every mapped row including switchers must satisfy the contract", {
  d <- subjects()
  for (field in names(d)[-1]) {
    for (value in list(NA_real_, NaN, Inf, -Inf, "bad", factor(1:6), matrix(1:6))) {
      bad <- d
      bad[[field]] <- rep_len(value, 6)
      if (is.matrix(value)) bad[[field]] <- value
      expect_error(validate_schema(bad), field)
    }
  }
  for (field in c("A0", "A1", "B")) {
    bad <- d
    bad[[field]][6] <- 2
    expect_error(validate_schema(bad), "binary")
  }
  for (ids in list(rep(1, 6), c(1:5, NA), c(1:5, Inf), c(letters[1:5], " "))) {
    d$id <- ids
    expect_error(validate_schema(d), "IDs")
  }
})

test_that("factor IDs are vectors of subject labels", {
  d <- subjects()
  d$id <- factor(d$id)
  expect_identical(validate_schema(d)$id, letters[1:6])
  dim(d$id) <- c(6, 1)
  expect_error(validate_schema(d), "IDs")
})
