  String formatDuration(Duration duration) {
    String durationString = duration.toString();

    String dur = durationString.split('.')[0].replaceFirst('0:', '');

    return dur;
  }