test_that("the package namespace loads", {
  expect_identical(unname(getNamespaceName(loadNamespace("longWR"))), "longWR")
})
