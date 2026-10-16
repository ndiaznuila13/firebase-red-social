import 'package:flutter/material.dart';

enum PostFilterType {
  none,
  sunglasses,
  mustache,
  birthdayCone,
  partyGlasses,
  funnyHat,
  crown,
  catEars,
}

class PostFilterOption {
  final PostFilterType type;
  final String id;
  final String label;
  final String emoji;
  final IconData icon;

  const PostFilterOption({
    required this.type,
    required this.id,
    required this.label,
    required this.emoji,
    required this.icon,
  });

  static const List<PostFilterOption> options = [
    PostFilterOption(
      type: PostFilterType.none,
      id: 'none',
      label: 'Normal',
      emoji: '✨',
      icon: Icons.not_interested,
    ),
    PostFilterOption(
      type: PostFilterType.sunglasses,
      id: 'sunglasses',
      label: 'Lentes oscuros',
      emoji: '🕶️',
      icon: Icons.wb_sunny_outlined,
    ),
    PostFilterOption(
      type: PostFilterType.mustache,
      id: 'mustache',
      label: 'Bigote',
      emoji: '🥸',
      icon: Icons.face,
    ),
    PostFilterOption(
      type: PostFilterType.birthdayCone,
      id: 'birthday_cone',
      label: 'Cono de fiesta',
      emoji: '🥳',
      icon: Icons.celebration,
    ),
    PostFilterOption(
      type: PostFilterType.partyGlasses,
      id: 'party_glasses',
      label: 'Lentes fiesta',
      emoji: '⭐',
      icon: Icons.auto_awesome,
    ),
    PostFilterOption(
      type: PostFilterType.funnyHat,
      id: 'funny_hat',
      label: 'Sombrero chistoso',
      emoji: '🎩',
      icon: Icons.theater_comedy,
    ),
    PostFilterOption(
      type: PostFilterType.crown,
      id: 'crown',
      label: 'Corona real',
      emoji: '👑',
      icon: Icons.military_tech,
    ),
    PostFilterOption(
      type: PostFilterType.catEars,
      id: 'cat_ears',
      label: 'Gatito',
      emoji: '🐱',
      icon: Icons.pets,
    ),
  ];

  static PostFilterOption fromId(String? id) {
    if (id == null || id.isEmpty || id == 'none') {
      return options.first;
    }
    return options.firstWhere(
      (opt) => opt.id == id,
      orElse: () => options.first,
    );
  }
}
