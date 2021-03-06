% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/evaluate.R
\name{convert_minizinc}
\alias{convert_minizinc}
\title{Convert to Minizinc code}
\usage{
convert_minizinc(decision, parameter, constraints)
}
\arguments{
\item{decision}{A list of decision \code{\link{Variable}} objects.}

\item{parameter}{A list of parameter \code{\link{Variable}} objects.}

\item{constraints}{A list of \code{\link{Constraint}} objects}
}
\value{
string with Minizinc code
}
\description{
This function converts R objects into Minizinc code.
}
\keyword{internal}
