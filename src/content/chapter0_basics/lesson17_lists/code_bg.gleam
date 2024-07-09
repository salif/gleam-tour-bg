import gleam/io

pub fn main() {
  let ints = [1, 2, 3]

  io.debug(ints)

  // Добавяне на елементи отпред
  io.debug([-1, 0, ..ints])

  // Разокоментирайте, за да видите грешка
  // io.debug(["zero", ..ints])

  // Оригиналните списъци не се променят
  io.debug(ints)
}
