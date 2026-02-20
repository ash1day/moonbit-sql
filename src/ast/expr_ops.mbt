/// Equality: self = other
pub fn Expr::eq(self : Expr, other : Expr) -> Expr {
  Binary(self, Eq, other)
}

/// Inequality: self <> other
pub fn Expr::ne(self : Expr, other : Expr) -> Expr {
  Binary(self, Ne, other)
}

/// Greater than: self > other
pub fn Expr::gt(self : Expr, other : Expr) -> Expr {
  Binary(self, Gt, other)
}

/// Less than: self < other
pub fn Expr::lt(self : Expr, other : Expr) -> Expr {
  Binary(self, Lt, other)
}

/// Greater than or equal: self >= other
pub fn Expr::gte(self : Expr, other : Expr) -> Expr {
  Binary(self, Ge, other)
}

/// Less than or equal: self <= other
pub fn Expr::lte(self : Expr, other : Expr) -> Expr {
  Binary(self, Le, other)
}

/// Logical AND: self AND other
pub fn Expr::and_(self : Expr, other : Expr) -> Expr {
  Binary(self, And, other)
}

/// Logical OR: self OR other
pub fn Expr::or_(self : Expr, other : Expr) -> Expr {
  Binary(self, Or, other)
}

/// LIKE pattern match
pub fn Expr::like(self : Expr, pattern : String) -> Expr {
  Binary(self, Like, Value(String(pattern)))
}

/// IS NULL check
pub fn Expr::is_null(self : Expr) -> Expr {
  IsNull(self)
}

/// IS NOT NULL check
pub fn Expr::is_not_null(self : Expr) -> Expr {
  IsNotNull(self)
}

/// IN list check
pub fn Expr::in_list(self : Expr, values : Array[Expr]) -> Expr {
  InList(self, values)
}

/// NOT IN list check
pub fn Expr::not_in_list(self : Expr, values : Array[Expr]) -> Expr {
  NotInList(self, values)
}

/// BETWEEN check
pub fn Expr::between(self : Expr, low : Expr, high : Expr) -> Expr {
  Between(self, low, high)
}

/// NOT BETWEEN check
pub fn Expr::not_between(self : Expr, low : Expr, high : Expr) -> Expr {
  NotBetween(self, low, high)
}

/// IN subquery check
pub fn Expr::in_subquery(self : Expr, sub : SelectStatement) -> Expr {
  InSubquery(self, sub)
}

/// NOT IN subquery check
pub fn Expr::not_in_subquery(self : Expr, sub : SelectStatement) -> Expr {
  NotInSubquery(self, sub)
}

/// Addition: self + other
pub fn Expr::add(self : Expr, other : Expr) -> Expr {
  Binary(self, Add, other)
}

/// Subtraction: self - other
pub fn Expr::sub_(self : Expr, other : Expr) -> Expr {
  Binary(self, Sub, other)
}

/// Multiplication: self * other
pub fn Expr::mul(self : Expr, other : Expr) -> Expr {
  Binary(self, Mul, other)
}

/// Division: self / other
pub fn Expr::div(self : Expr, other : Expr) -> Expr {
  Binary(self, Div, other)
}

/// Logical NOT: NOT self
pub fn Expr::not_(self : Expr) -> Expr {
  Unary(Not, self)
}

/// Negation: -self
pub fn Expr::neg(self : Expr) -> Expr {
  Unary(Neg, self)
}
