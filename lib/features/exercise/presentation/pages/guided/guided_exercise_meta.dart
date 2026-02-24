class GuidedExerciseMeta {
  final String id;
  final String title;
  final String category;
  final String minutesLabel;
  final String description;

  const GuidedExerciseMeta({
    required this.id,
    required this.title,
    required this.category,
    required this.minutesLabel,
    required this.description,
  });
}

const guidedExercises = <GuidedExerciseMeta>[
  GuidedExerciseMeta(
    id: 'box-breathing',
    title: 'Box Breathing',
    category: 'Breathing',
    minutesLabel: '4 cycles',
    description: 'Inhale, hold, exhale, hold — steady and calm.',
  ),
  GuidedExerciseMeta(
    id: 'grounding-54321',
    title: '5-4-3-2-1 Grounding',
    category: 'Anxiety',
    minutesLabel: '~2 min',
    description: 'Bring attention back to the present moment.',
  ),
  GuidedExerciseMeta(
    id: 'gratitude-pause',
    title: 'Gratitude Pause',
    category: 'Reflection',
    minutesLabel: '2 min',
    description: 'Three quiet prompts to reflect and reset.',
  ),
  GuidedExerciseMeta(
    id: 'body-stretch',
    title: 'Body Stretch Timer',
    category: 'Body',
    minutesLabel: '~4 min',
    description: 'Six simple stretches, one at a time.',
  ),
];
