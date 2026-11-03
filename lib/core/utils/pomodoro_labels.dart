/// Value labels of the Pomodoro Timer settings, with the singular for one.
String formatMinutesLabel(int minutes) =>
    minutes == 1 ? '1 min' : '$minutes mins';

String formatSessionsLabel(int sessions) =>
    sessions == 1 ? '1 session' : '$sessions sessions';
