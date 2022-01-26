#!/usr/bin/env Rscript

argv <- commandArgs(trailingOnly = TRUE)
pdf(argv[1], 7, 5 + length(argv))
layout(matrix(1:(length(argv)*2), byrow = TRUE, ncol = 2), widths = c(3, 1))
col <- c('lightblue', 'darkblue', 'red3', 'darkred')
for(i in argv[-1]){
  # Gspp
  a <- read.table(i, sep = '\t', header = TRUE, row.names = 1)
  b <- barplot(t(a), beside = TRUE, las = 1,
    col = col, ylab = 'Quality', main = i)
  left.end <- min(b) - 1
  right.end <- max(b) + 1
  rect(left.end, 0, right.end, 50, border = NA, col = rgb(1,1,1,3/4))
  arrows(x0 = left.end, x1 = right.end, y0 = c(0,50), y1 = c(0,50),
    lty = c(1,3), length = 0)
  abline(v = seq(left.end, right.end, by = nrow(b)+1), col = grey(1/2))
  # Summaries
  a.50 <- a
  a.50[is.na(a.50) | a.50 < 50] <- 0
  barplot(colMeans(a.50), las = 1, col = col, horiz = TRUE)
}
t <- dev.off()

