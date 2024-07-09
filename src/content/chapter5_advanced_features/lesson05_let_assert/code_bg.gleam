import gleam/io

pub fn main() {
  let a = unsafely_get_first_element([123])
  io.debug(a)

  let b = unsafely_get_first_element([])
  io.debug(b)
}

pub fn unsafely_get_first_element(items: List(a)) -> a {
  // Това ще предизвика panic, ако списъкът е празен.
  // Обикновен `let` не би позволил този частичен шаблон 
  let assert [first, ..] = items
  first
}
