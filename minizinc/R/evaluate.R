#' @title Evaluate models
#'
#' @description
#' This function is used to evaluate a given model. The function modifies
#' variable objects and sets `value` fields with found solutions. It also
#' returns TRUE/FALSE depending on whether Minizinc found a satisfiable solution.
#'
#' @param model
#'   Object of class \code{\link{Model}}.
#' @param solver
#'   Object of class \code{\link{Solver}}.
#'
#' @return (`logical(1)`). `TRUE` if model is satisfiable and `FALSE` otherwise.
#' @export
#' @examples
#' # Create and solve a Minizinc model
#' var1 = Variable$new(type = "int", kind = "decision", domain = c(0, 10))
#' var2 = Variable$new(type = "int", kind = "decision", domain = c(0, 5))
#'
#' constr = Constraint$new(constraint = "<", variables = c(var1, var2))
#'
#' model = Model$new(decision = c(var1, var2), constraints = c(constr),
#'                   objective = "satisfy")
#' solver = Solver$new(name = "gecode")
#'
#' # Example path
#' set_path("/home/damir/software/MiniZincIDE-2.4.2-bundle-linux/bin/minizinc")
#'
#' res = eval_model(model, solver)
#' print(res)
eval_model = function(model, solver) {
  decision = model$decision
  parameter = model$parameter
  constraints = model$constraints
  obj = model$objective

  # create tmp file that contains minizinc code
  ret = file.create("tmp.mzn")
  if(!ret) {
    stop("Cannot create a file with Minizinc code. Check permissions.",
         call. = TRUE)
  }

  # get Minizinc code
  code = convert_minizinc(decision, parameter, constraints)

  write(code, file = "tmp.mzn", append = FALSE)

  # get minizinc path
  path = get_path()
  if(is.null(path)) {
    stop("Path to Minizinc is not set. Set path using set_path()", call. = TRUE)
  }

  # build system command
  cmd = write_cmd(path, solver)
  system(cmd)

  # get results
  res = tryCatch(
    expr = {
      fromJSON(file = "tmp.out")
    },
    error = function(e) {
      return(NULL)
  })

  retval = TRUE

  # read file again
  if (is.null(res)) {
    res = readLines(con = "tmp.out", n = 1L)
    res = grepl(pattern = "UNSAT", res)
    if(res) {
      retval = FALSE
    }
  } else {
    # assign solutions to variables
    assign_vars(res, decision)
  }

  return(retval)
}


#' @title Convert to Minizinc code
#'
#' @description
#' This function converts R objects into Minizinc code.
#'
#' @param decision
#'   A list of decision \code{\link{Variable}} objects.
#' @param parameter
#'   A list of parameter \code{\link{Variable}} objects.
#' @param constraints
#'   A list of \code{\link{Constraint}} objects
#'
#' @return string with Minizinc code
#'
#' @keywords internal
convert_minizinc = function(decision, parameter, constraints) {
  # build minizinc code from objects
  code = ""

  # add parameter variables
  if(!is.null(parameter)) {
    for(i in 1:length(parameter)) {
      code = sprintf("%s%s: %s = %s;\n", code, parameter[[i]]$type,
                     parameter[[i]]$get_name(), parameter[[i]]$value)
    }
  }

  # add definitions for decision variables
  for(i in 1:length(decision)) {
    code = sprintf("%svar %s..%s: %s;\n", code, decision[[i]]$domain[1],
                   decision[[i]]$domain[2], decision[[i]]$get_name())
  }

  # add constraints
  for(i in 1:length(constraints)) {
    code = sprintf("%sconstraint %s %s %s;\n", code,
                   constraints[[i]]$variables[[1]]$get_name(), constraints[[i]]$constraint,
                   constraints[[i]]$variables[[2]]$get_name())
  }

  return(code)
}


#' @title Write system command
#'
#' @description
#' This function builds a system command to execute.
#'
#' @param path
#' A string with Minizinc path
#'
#' @param solver
#' \code{\link{Solver}} object
#'
#' @keywords internal
write_cmd = function(path, solver) {
  cmd = sprintf("%s tmp.mzn -o tmp.out", path)
  cmd = sprintf("%s --solver %s", cmd, solver$name)
  cmd = sprintf("%s --output-mode json", cmd)

  return(cmd)
}


#' @title Assign result to variables
#'
#' @description
#' Assigns results back to decision variable objects.
#'
#' @param result
#' A named list with results
#'
#' @param vars
#' A list of parameter \code{\link{Variable}} objects
#'
#' @keywords internal
assign_vars = function(result, vars) {
  for(i in 1:length(names(result))) {
    for(j in 1:length(vars)) {
      if(names(result)[i] == vars[[j]]$get_name()) {
        vars[[j]]$value = result[[i]]
        break
      }
    }
  }
}


#' @title Print variable values
#'
#' @description
#' Given a list of variables, this function prints their values.
#'
#' @param vars
#' A list of \code{\link{Variable}} objects
#'
#' @export
print_vars = function(vars) {
  for(i in 1:length(vars)) {
    cmd = sprintf("%s = %s", vars[[i]]$get_name(), vars[[i]]$value)
    print(eval(cmd))
  }
}
