import gleam/io

pub fn main() {
  // 8-битово цяло число. В двоичен вид: 00000011
  io.debug(<<3>>)
  io.debug(<<3>> == <<3:size(8)>>)

  // 16-битово цяло число. В двоичен вид: 0001100000000011
  io.debug(<<6147:size(16)>>)

  // Битов масив с UTF8 данни
  io.debug(<<"Hello, Joe!":utf8>>)

  // Конкатенация
  let first = <<4>>
  let second = <<2>>
  io.debug(<<first:bits, second:bits>>)
}
