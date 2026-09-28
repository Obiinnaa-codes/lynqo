class RouterSmsMessage {
  const RouterSmsMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.read,
    this.receivedEpochSeconds,
  });

  final String id;
  final String sender;
  final String text;
  final bool read;
  final int? receivedEpochSeconds;
}
