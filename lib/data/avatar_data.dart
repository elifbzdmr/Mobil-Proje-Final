import 'package:flutter/material.dart';

class AvatarOption {
  const AvatarOption({
    required this.id,
    required this.emoji,
    required this.gradient,
  });

  final String id;
  final String emoji;
  final List<Color> gradient;
}

const avatarOptions = <AvatarOption>[
  AvatarOption(
    id: 'avatar_1',
    emoji: '🎧',
    gradient: <Color>[Color(0xFF4F7DFD), Color(0xFF6EA8FF)],
  ),
  AvatarOption(
    id: 'avatar_2',
    emoji: '🎤',
    gradient: <Color>[Color(0xFF00A896), Color(0xFF72D6C9)],
  ),
  AvatarOption(
    id: 'avatar_3',
    emoji: '🎸',
    gradient: <Color>[Color(0xFFFF7E5F), Color(0xFFFEB47B)],
  ),
  AvatarOption(
    id: 'avatar_4',
    emoji: '🎹',
    gradient: <Color>[Color(0xFF7F5AF0), Color(0xFFB794FF)],
  ),
  AvatarOption(
    id: 'avatar_5',
    emoji: '🎻',
    gradient: <Color>[Color(0xFFF95D6A), Color(0xFFFF9A8B)],
  ),
  AvatarOption(
    id: 'avatar_6',
    emoji: '🥁',
    gradient: <Color>[Color(0xFF577590), Color(0xFF90A8C3)],
  ),
];
