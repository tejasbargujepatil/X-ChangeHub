enum BadgeType {
  bronze,
  silver,
  gold,
  platinum,
  special
}

class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final BadgeType type;
  final int requiredXP;
  final String? requirement;
  
  const BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.type,
    this.requiredXP = 0,
    this.requirement,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'type': type.name,
      'requiredXP': requiredXP,
      'requirement': requirement,
    };
  }

  factory BadgeModel.fromMap(Map<String, dynamic> map) {
    return BadgeModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      iconUrl: map['iconUrl'] ?? '',
      type: BadgeType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => BadgeType.bronze,
      ),
      requiredXP: map['requiredXP'] ?? 0,
      requirement: map['requirement'],
    );
  }
}

// Predefined badges
class Badges {
  static const List<BadgeModel> availableBadges = [
    BadgeModel(
      id: 'first_exchange',
      name: 'First Exchange',
      description: 'Completed your first skill exchange',
      iconUrl: 'assets/badges/first_exchange.png',
      type: BadgeType.bronze,
    ),
    BadgeModel(
      id: 'exchange_master',
      name: 'Exchange Master',
      description: 'Completed 50 skill exchanges',
      iconUrl: 'assets/badges/exchange_master.png',
      type: BadgeType.gold,
      requiredXP: 500,
    ),
    BadgeModel(
      id: 'freelance_starter',
      name: 'Freelance Starter',
      description: 'Completed your first freelance project',
      iconUrl: 'assets/badges/freelance_starter.png',
      type: BadgeType.bronze,
    ),
    BadgeModel(
      id: 'top_rated',
      name: 'Top Rated',
      description: 'Maintained 4.5+ rating with 20+ reviews',
      iconUrl: 'assets/badges/top_rated.png',
      type: BadgeType.platinum,
    ),
    BadgeModel(
      id: 'mentor',
      name: 'Mentor',
      description: 'Taught 100+ skill exchanges',
      iconUrl: 'assets/badges/mentor.png',
      type: BadgeType.gold,
      requiredXP: 1000,
    ),
  ];
}
