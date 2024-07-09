import gleam/io

pub fn main() {
  let add_one = fn(x) { x + 1 }
  let exclaim = fn(x) { x <> "!" }

  // Невалидно, Int и String не са съвместими типове
  // twice(10, exclaim)

  // Тук променливата за тип е заменена с типа Int
  io.debug(twice(10, add_one))

  // Тук променливата за тип е заменена с типа String
  io.debug(twice("Hello", exclaim))
}

// Името `value` (стойност) реферира към един и същи тип на няколко места
fn twice(argument: value, my_function: fn(value) -> value) -> value {
  my_function(my_function(argument))
}
