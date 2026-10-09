class WorkoutExercise {
  final String id;
  final String name;
  final String type; // 'reps', 'timed', 'reps_assistance', 'reps_weight'
  final int sets;
  final int? targetReps;
  final int? targetDuration;
  final String? note;

  const WorkoutExercise({
    required this.id,
    required this.name,
    required this.type,
    required this.sets,
    this.targetReps,
    this.targetDuration,
    this.note,
  });

  String get targetSummary {
    if (targetDuration != null && targetDuration! > 0) {
      return '$sets sets × ${targetDuration}s';
    }
    if (targetReps != null) {
      return '$sets sets × $targetReps reps';
    }
    return '$sets sets';
  }
}

class WorkoutDay {
  final String id;
  final String dayName;
  final int dayIndex; // 1 = Monday ... 7 = Sunday
  final String title;
  final String type; // 'workout' or 'rest_stretch'
  final String focus;
  final List<WorkoutExercise> exercises;

  const WorkoutDay({
    required this.id,
    required this.dayName,
    required this.dayIndex,
    required this.title,
    required this.type,
    required this.focus,
    required this.exercises,
  });
}

class CalisthenicsProgram {
  static const List<WorkoutDay> weeklyProgram = [
    WorkoutDay(
      id: 'monday',
      dayName: 'Monday',
      dayIndex: 1,
      title: 'Rest & Stretching',
      type: 'rest_stretch',
      focus: 'Active recovery, shoulder & hip mobility, spinal decompression',
      exercises: [
        WorkoutExercise(id: 'sh_stretch', name: 'Cross-body Shoulder Stretch', type: 'timed', sets: 2, targetDuration: 30, note: '30s per side'),
        WorkoutExercise(id: 'cat_cow', name: 'Cat-Cow', type: 'reps', sets: 2, targetReps: 10, note: 'Slow fluid spinal movement'),
        WorkoutExercise(id: 'hip_flexor', name: 'Hip Flexor Stretch', type: 'timed', sets: 2, targetDuration: 30, note: '30s each side'),
        WorkoutExercise(id: 'child_pose', name: "Child's Pose", type: 'timed', sets: 2, targetDuration: 30, note: 'Deep pelvic grounding'),
      ],
    ),
    WorkoutDay(
      id: 'tuesday',
      dayName: 'Tuesday',
      dayIndex: 2,
      title: 'Push + ABS',
      type: 'workout',
      focus: 'Chest, shoulders, triceps, anterior core',
      exercises: [
        WorkoutExercise(id: 'pushups_tue', name: 'Push-ups', type: 'reps', sets: 4, targetReps: 10, note: 'Strict ROM, chest to floor'),
        WorkoutExercise(id: 'assisted_dips_tue', name: 'Assisted Dips', type: 'reps_assistance', sets: 3, targetReps: 5, note: 'Controlled descent'),
        WorkoutExercise(id: 'pike_pushups_tue', name: 'Pike Push-ups', type: 'reps', sets: 3, targetReps: 8, note: 'Elevated hips, head forward'),
        WorkoutExercise(id: 'hanging_knee_tue', name: 'Hanging Knee Raises', type: 'reps', sets: 3, targetReps: 12, note: 'Strict pull, no swinging'),
        WorkoutExercise(id: 'reverse_crunches_tue', name: 'Reverse Crunches', type: 'reps', sets: 3, targetReps: 15, note: 'Posterior pelvic tilt'),
        WorkoutExercise(id: 'plank_tue', name: 'Forearm Plank', type: 'timed', sets: 3, targetDuration: 45, note: 'Glutes squeezed tight'),
      ],
    ),
    WorkoutDay(
      id: 'wednesday',
      dayName: 'Wednesday',
      dayIndex: 3,
      title: 'Pull',
      type: 'workout',
      focus: 'Lats, upper back, biceps, grip & decompression',
      exercises: [
        WorkoutExercise(id: 'pullups_wed', name: 'Pull-ups', type: 'reps', sets: 4, targetReps: 2, note: 'Dead hang to chin over bar'),
        WorkoutExercise(id: 'rows_wed', name: 'Australian Rows', type: 'reps', sets: 3, targetReps: 12, note: 'Scapular retraction'),
        WorkoutExercise(id: 'assisted_pullups_wed', name: 'Assisted Pull-ups', type: 'reps_assistance', sets: 3, targetReps: 5, note: 'Medium band assistance'),
        WorkoutExercise(id: 'biceps_wed', name: 'Band Biceps Curls', type: 'reps', sets: 3, targetReps: 12, note: 'Squeeze at peak'),
        WorkoutExercise(id: 'dead_hang_wed', name: 'Dead Hang', type: 'timed', sets: 2, targetDuration: 30, note: 'Spinal decompression'),
      ],
    ),
    WorkoutDay(
      id: 'thursday',
      dayName: 'Thursday',
      dayIndex: 4,
      title: 'Rest & Stretching',
      type: 'rest_stretch',
      focus: 'Upper body decompression, chest opening, posterior relief',
      exercises: [
        WorkoutExercise(id: 'triceps_stretch', name: 'Overhead Triceps Stretch', type: 'timed', sets: 2, targetDuration: 30, note: '30s each arm'),
        WorkoutExercise(id: 'doorway_chest', name: 'Doorway Chest Stretch', type: 'timed', sets: 2, targetDuration: 30, note: 'Pectoral opening'),
        WorkoutExercise(id: 'hamstring_stretch', name: 'Seated Hamstring Stretch', type: 'timed', sets: 2, targetDuration: 30, note: 'Straight back hinge'),
        WorkoutExercise(id: 'spinal_twist', name: 'Supine Spinal Twist', type: 'timed', sets: 2, targetDuration: 30, note: 'Gentle rotation'),
      ],
    ),
    WorkoutDay(
      id: 'friday',
      dayName: 'Friday',
      dayIndex: 5,
      title: 'Legs + Push-ups + ABS',
      type: 'workout',
      focus: 'Quads, posterior chain, chest volume, core stability',
      exercises: [
        WorkoutExercise(id: 'pushups_fri', name: 'Push-ups', type: 'reps', sets: 4, targetReps: 12, note: '4 sets of 12 reps'),
        WorkoutExercise(id: 'backpack_squats_fri', name: 'Backpack Squats', type: 'reps_weight', sets: 3, targetReps: 15, note: '10kg backpack'),
        WorkoutExercise(id: 'bulgarian_split_fri', name: 'Bulgarian Split Squats', type: 'reps', sets: 3, targetReps: 10, note: 'Rear foot elevated'),
        WorkoutExercise(id: 'backpack_rdl_fri', name: 'Backpack Romanian Deadlifts', type: 'reps_weight', sets: 3, targetReps: 12, note: 'Hamstring stretch'),
        WorkoutExercise(id: 'calf_raises_fri', name: 'Calf Raises', type: 'reps', sets: 3, targetReps: 20, note: 'Full stretch and pause'),
        WorkoutExercise(id: 'rkc_plank_fri', name: 'RKC Plank', type: 'timed', sets: 3, targetDuration: 30, note: 'Maximal tension hold'),
      ],
    ),
    WorkoutDay(
      id: 'saturday',
      dayName: 'Saturday',
      dayIndex: 6,
      title: 'Pull + Shoulders',
      type: 'workout',
      focus: 'Back strength, delts, core compression',
      exercises: [
        WorkoutExercise(id: 'pullups_sat', name: 'Pull-ups', type: 'reps', sets: 4, targetReps: 2, note: 'Strict form'),
        WorkoutExercise(id: 'rows_sat', name: 'Australian Rows', type: 'reps', sets: 3, targetReps: 12, note: 'Full contraction'),
        WorkoutExercise(id: 'pike_sat', name: 'Pike Push-ups', type: 'reps', sets: 3, targetReps: 8, note: 'Shoulder drive'),
        WorkoutExercise(id: 'lat_raises_sat', name: 'Band Lateral Raises', type: 'reps', sets: 3, targetReps: 15, note: 'Side deltoids'),
        WorkoutExercise(id: 'face_pulls_sat', name: 'Band Face Pulls', type: 'reps', sets: 3, targetReps: 15, note: 'Rear delts & rotator cuff'),
        WorkoutExercise(id: 'hollow_body_sat', name: 'Hollow Body Hold', type: 'timed', sets: 3, targetDuration: 30, note: 'Lower back glued to floor'),
      ],
    ),
    WorkoutDay(
      id: 'sunday',
      dayName: 'Sunday',
      dayIndex: 7,
      title: 'Active Recovery & Cardio',
      type: 'rest_stretch',
      focus: 'Cardiovascular health, joint longevity, mind reset',
      exercises: [
        WorkoutExercise(id: 'cardio_sun', name: 'Jump Rope or Brisk Walk', type: 'timed', sets: 1, targetDuration: 1500, note: '25 min steady aerobic pace'),
        WorkoutExercise(id: 'wrist_mobility_sun', name: 'Wrist & Forearm Mobility', type: 'timed', sets: 2, targetDuration: 30, note: 'Calisthenics prehab'),
        WorkoutExercise(id: 'deep_squat_sun', name: 'Deep Squat Hold', type: 'timed', sets: 2, targetDuration: 45, note: 'Ankle & hip mobility'),
      ],
    ),
  ];

  static WorkoutDay getDayForDateTime(DateTime dt) {
    final weekday = dt.weekday; // 1 = Mon ... 7 = Sun
    return weeklyProgram.firstWhere(
      (d) => d.dayIndex == weekday,
      orElse: () => weeklyProgram[0],
    );
  }
}
