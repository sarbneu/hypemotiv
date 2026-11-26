library;

class SoundOption {
  const SoundOption({required this.name, required this.url});

  final String name;
  final String url;
}

const String _audioDir = 'assets/audio';

const List<SoundOption> defaultSoundOptions = <SoundOption>[
  SoundOption(
    name: 'Military Wake Up',
    url: '$_audioDir/military-bugle-wake-up-call.mp3',
  ),
  SoundOption(
    name: 'Nuclear Siren',
    url: '$_audioDir/nuclear-alarm-siren.mp3',
  ),
  SoundOption(
    name: 'Danger Siren',
    url: '$_audioDir/danger-siren-alarm.mp3',
  ),
  SoundOption(
    name: 'Bass Boosted Alarm',
    url: '$_audioDir/samsung-bass-boosted-alarm.mp3',
  ),
  SoundOption(
    name: 'Airhorn',
    url: '$_audioDir/airhorn.mp3',
  ),
  SoundOption(
    name: 'Bruh',
    url: '$_audioDir/bruh.mp3',
  ),
];

final List<SoundOption> morningRageOptions =
    defaultSoundOptions.take(5).toList();
