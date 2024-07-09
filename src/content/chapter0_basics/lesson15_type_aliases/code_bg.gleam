import gleam/io

pub type UserId =
  Int

pub fn main() {
  let one: UserId = 1
  let two: Int = 2

  // UserId и Int са един и същи тип
  io.debug(one == two)
}
