/// Sound choices shown in the alarm picker.
library;

class SoundOption {
  const SoundOption({required this.name, required this.url});

  final String name;
  final String url;
}

const List<SoundOption> defaultSoundOptions = <SoundOption>[
  SoundOption(
    name: 'Bruh',
    url: 'https://www.myinstants.com/media/sounds/bruh-sound-effect_WstdzdM.mp3',
  ),
  SoundOption(
    name: 'Airhorn',
    url: 'https://www.myinstants.com/media/sounds/airhorn.mp3',
  ),
  SoundOption(
    name: 'Roblox OOF',
    url: 'https://www.myinstants.com/media/sounds/roblox-oof.mp3',
  ),
  SoundOption(
    name: 'Emotional Damage',
    url: 'https://www.myinstants.com/media/sounds/emotional-damage.mp3',
  ),
  SoundOption(
    name: 'FBI Open Up',
    url: 'https://www.myinstants.com/media/sounds/fbi-open-up.mp3',
  ),
  SoundOption(
    name: 'Bell',
    url: 'https://www.myinstants.com/media/sounds/bell.mp3',
  ),
];
