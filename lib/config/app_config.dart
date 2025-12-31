class AppConfig {
  // App Info
  static const String appName = 'XChangeHUb';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Learn by Teaching, Grow Together';

  // Skills (Predefined popular skills)
  static const List<String> popularSkills = [
    // Programming
    'Flutter',
    'React',
    'Python',
    'JavaScript',
    'Java',
    'Kotlin',
    'Swift',
    'Node.js',
    'Django',
    'Firebase',
    'MongoDB',
    'SQL',
    'Git',
    
    // Design
    'UI/UX Design',
    'Figma',
    'Adobe XD',
    'Photoshop',
    'Illustrator',
    'Graphic Design',
    '3D Modeling',
    'Video Editing',
    
    // Business
    'Digital Marketing',
    'SEO',
    'Content Writing',
    'Social Media Marketing',
    'Business Analysis',
    'Project Management',
    'Excel',
    'Data Analysis',
    
    // Languages
    'English',
    'Spanish',
    'French',
    'German',
    'Japanese',
    'Mandarin',
    
    // Creative
    'Photography',
    'Music Production',
    'Drawing',
    'Animation',
    'Voice Acting',
    
    // Other
    'Public Speaking',
    'Leadership',
    'Time Management',
    'Machine Learning',
    'Blockchain',
    'Cybersecurity',
  ];

  // XP Rewards
  static const int xpForTeaching = 50;
  static const int xpForLearning = 30;
  static const int xpForBeginnerProject = 100;
  static const int xpForIntermediateProject = 250;
  static const int xpForAdvancedProject = 500;

  // Platform Commission
  static const double platformCommissionPercentage = 10.0; // 10%

  // Limits
  static const int maxSkillsToTeach = 10;
  static const int maxSkillsToLearn = 10;
  static const int maxBioLength = 500;

  // Timeouts
  static const int requestTimeout = 30; // seconds
}
