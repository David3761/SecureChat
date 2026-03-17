class DisappearingOption {
  final String label;
  final int? seconds;

  const DisappearingOption({required this.label, required this.seconds});
}

const List<DisappearingOption> kDisappearingOptions = [
  DisappearingOption(label: 'Off', seconds: null),
  DisappearingOption(label: '5 minutes', seconds: 300),
  DisappearingOption(label: '10 minutes', seconds: 600),
  DisappearingOption(label: '1 hour', seconds: 3600),
  DisappearingOption(label: '24 hours', seconds: 86400),
  DisappearingOption(label: '7 days', seconds: 604800),
  DisappearingOption(label: '30 days', seconds: 2592000),
];
