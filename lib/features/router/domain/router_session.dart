/// Opaque authenticated router session for data-layer API calls.
///
/// Not exposed to presentation code; credentials and tokens stay in
/// [RouterSecureStorage] and auth services.
class RouterSession {
  const RouterSession({required this.profileId});

  final String profileId;
}
