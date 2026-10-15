///|
pub suberror BuildError {
  EmptyValues(String)
  EmptyAssignments(String)
  InvalidFuncName(String)
  EmptyConflictColumns(String)
  EmptyWhenClauses(String)
  ConflictingInsertSource(String)
}
