subjects <- function() {
  data.frame(id = letters[1:6], A0 = c(1, 1, 0, 0, 1, 0),
             A1 = c(1, 1, 0, 0, 0, 1), L0 = 1:6, L1 = 6:1,
             B = c(0, 1, 0, 1, 1, 0), Y = c(1, 4, 1, 2, -99, 99))
}
