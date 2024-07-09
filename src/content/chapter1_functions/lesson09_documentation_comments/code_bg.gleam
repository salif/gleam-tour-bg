//// Модул, съдържащ някои необичайни функции и типове.

/// Тип, чиято стойност не може да се конструира.
/// Можете ли да се досетите защо?
pub type Never {
  Never(Never)
}

/// Извиква функция два пъти с първоначална стойност.
///
pub fn twice(argument: value, my_function: fn(value) -> value) -> value {
  my_function(my_function(argument))
}

/// Извиква функция три пъти с първоначална стойност.
///
pub fn thrice(argument: value, my_function: fn(value) -> value) -> value {
  my_function(my_function(my_function(argument)))
}
