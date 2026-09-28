class RouterWifiBandSnapshot {
  const RouterWifiBandSnapshot({
    required this.bandLabel,
    this.ssid,
    this.status,
  });

  final String bandLabel;
  final String? ssid;
  final String? status;
}
