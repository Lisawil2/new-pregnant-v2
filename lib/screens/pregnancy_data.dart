class PregnancyData {
  final int week;
  final String size; // Not used in TrackerScreen but included for HomeScreen
  final String development;
  final String imagePath;

  PregnancyData({
    required this.week,
    required this.size,
    required this.development,
    required this.imagePath,
  });

  static final List<String> babyDevelopment = [
    "Your baby is a tiny cluster of cells.",
    "The heart begins to form and beat.",
    "Arm and leg buds start to appear.",
    "Eyes and ears are forming.",
    "The neural tube closes, forming the spine.",
    "Facial features start to develop.",
    "Your baby is about the size of a grape.",
    "Fingers and toes begin to form.",
    "Major organs are developing rapidly.",
    "Your baby can move, though you can’t feel it.",
    "Hair follicles start to form.",
    "Your baby is about the size of a plum.",
    "The digestive system is developing.",
    "Your baby can suck their thumb.",
    "Bones are beginning to harden.",
    "Your baby is about the size of an avocado.",
    "The heartbeat is audible via ultrasound.",
    "Your baby can make facial expressions.",
    "The kidneys start functioning.",
    "Your baby is about the size of a mango.",
    "You may feel baby’s first movements.",
    "The lungs are developing rapidly.",
    "Your baby can hear your voice.",
    "Your baby is about the size of a banana.",
    "Fat layers begin to form under the skin.",
    "The eyes can open and close.",
    "Your baby is about the size of an ear of corn.",
    "The brain is growing rapidly.",
    "Your baby can grasp and respond to touch.",
    "The immune system is strengthening.",
    "Your baby is about the size of a cauliflower.",
    "Hair and nails continue to grow.",
    "Your baby practices breathing movements.",
    "The nervous system is maturing.",
    "Your baby is about the size of a coconut.",
    "The body is preparing for birth.",
    "Your baby is gaining weight quickly.",
    "The lungs are nearly fully developed.",
    "Your baby is about the size of a pineapple.",
    "Your baby is ready for the outside world!",
    "Your baby is fully developed for birth.",
  ];

  static final Map<int, String> babyDevelopmentImages = {
    1: 'assets/weekimage/week-1.jpg',
    2: 'assets/weekimage/week-2.jpg',
    3: 'assets/weekimage/week-3.jpg',
    4: 'assets/weekimage/week-4.jpg',
    5: 'assets/weekimage/week-5.jpg',
    6: 'assets/weekimage/week-6.jpg',
    7: 'assets/weekimage/week-7.jpg',
    8: 'assets/weekimage/week-8.jpg',
    9: 'assets/weekimage/week-9.jpg',
    10: 'assets/weekimage/week-10.jpg',
    11: 'assets/weekimage/week-11.jpg',
    12: 'assets/weekimage/week-12.jpg',
    13: 'assets/weekimage/week-13.jpg',
    14: 'assets/weekimage/week-14.jpg',
    15: 'assets/weekimage/week-15.jpg',
    16: 'assets/weekimage/week-16.jpg',
    17: 'assets/weekimage/week-17.jpg',
    18: 'assets/weekimage/week-18.jpg',
    19: 'assets/weekimage/week-19.jpg',
    20: 'assets/weekimage/week-20.jpg',
    21: 'assets/weekimage/week-21.jpg',
    22: 'assets/weekimage/week-22.jpg',
    23: 'assets/weekimage/week-23.jpg',
    24: 'assets/weekimage/week-24.jpg',
    25: 'assets/weekimage/week-25.jpg',
    26: 'assets/weekimage/week-26.jpg',
    27: 'assets/weekimage/week-27.jpg',
    28: 'assets/weekimage/week-28.jpg',
    29: 'assets/weekimage/week-29.jpg',
    30: 'assets/weekimage/week-30.jpg',
    31: 'assets/weekimage/week-31.jpg',
    32: 'assets/weekimage/week-32.jpg',
    33: 'assets/weekimage/week-33.jpg',
    34: 'assets/weekimage/week-34.jpg',
    35: 'assets/weekimage/week-35.jpg',
    36: 'assets/weekimage/week-36.jpg',
    37: 'assets/weekimage/week-37.jpg',
    38: 'assets/weekimage/week-38.jpg',
    39: 'assets/weekimage/week-39.jpg',
    40: 'assets/weekimage/week-40.jpg',
  };

  static final List<String> sizeComparisons = [
    "Poppy Seed", // Week 1
    "Sesame Seed", // Week 2
    "Lentil", // Week 3
    "Blueberry", // Week 4
    "Apple Seed", // Week 5
    "Pea", // Week 6
    "Grape", // Week 7
    "Raspberry", // Week 8
    "Green Olive", // Week 9
    "Prune", // Week 10
    "Lime", // Week 11
    "Plum", // Week 12
    "Peach", // Week 13
    "Lemon", // Week 14
    "Apple", // Week 15
    "Avocado", // Week 16
    "Onion", // Week 17
    "Sweet Potato", // Week 18
    "Mango", // Week 19
    "Banana", // Week 20
    "Carrot", // Week 21
    "Spaghetti Squash", // Week 22
    "Ear of Corn", // Week 23
    "Cantaloupe", // Week 24
    "Cauliflower", // Week 25
    "Eggplant", // Week 26
    "Cucumber", // Week 27
    "Cabbage", // Week 28
    "Butternut Squash", // Week 29
    "Zucchini", // Week 30
    "Kale", // Week 31
    "Honeydew Melon", // Week 32
    "Pineapple", // Week 33
    "Winter Melon", // Week 34
    "Coconut", // Week 35
    "Romaine Lettuce", // Week 36
    "Swiss Chard", // Week 37
    "Leek", // Week 38
    "Watermelon", // Week 39
    "Pumpkin", // Week 40
  ];

  get title => null;

  static PregnancyData getDataForWeek(int week) {
    week = week.clamp(1, 40);
    return PregnancyData(
      week: week,
      size: sizeComparisons[week - 1],
      development: babyDevelopment[week - 1],
      imagePath: babyDevelopmentImages[week] ?? 'assets/weekimage/default_baby.jpg',
    );
  }
}
