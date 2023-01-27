String getUserInitials(String name) {
  List<String> words = name.split(" ");

  if (words.length > 1) {
    String firstWordFirstLetter = words[0].substring(0, 1);
    String secondWordFirstLetter = words[1].substring(0, 1);

    String initials = "$firstWordFirstLetter$secondWordFirstLetter";

    return initials;
  } else {
    String firstWordFirstLetter = words[0].substring(0, 1);
    return firstWordFirstLetter;
  }
}
