pub type Option(inner) {
  Some(inner)
  None
}

// Опция от символен низ
pub const name: Option(String) = Some("Annah")

//Опция от цяло число
pub const level: Option(Int) = Some(10)
