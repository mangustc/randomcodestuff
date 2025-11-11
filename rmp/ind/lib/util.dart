int calculateAge(DateTime birthDate) {
  DateTime currentDate = DateTime.now();
  int age = currentDate.year - birthDate.year;

  if (currentDate.month < birthDate.month ||
      (currentDate.month == birthDate.month && currentDate.day < birthDate.day)) {
    age--;
  }
  return age;
}