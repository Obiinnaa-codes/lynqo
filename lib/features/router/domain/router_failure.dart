sealed class RouterFailure {
  const RouterFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

final class RouterNotReachable extends RouterFailure {
  const RouterNotReachable([super.message = 'The MiFi is not reachable.']);
}

final class ConnectionTimeout extends RouterFailure {
  const ConnectionTimeout([
    super.message = 'Connection to the MiFi timed out.',
  ]);
}

final class AuthenticationRequired extends RouterFailure {
  const AuthenticationRequired([
    super.message = 'The MiFi is reachable but authentication is required.',
  ]);
}

final class AuthenticationFailed extends RouterFailure {
  const AuthenticationFailed([super.message = 'Authentication failed.']);
}

final class InvalidResponse extends RouterFailure {
  const InvalidResponse([
    super.message = 'The MiFi returned an invalid response.',
  ]);
}

final class UnsupportedRouter extends RouterFailure {
  const UnsupportedRouter([
    super.message = 'This router is not supported yet.',
  ]);
}

final class UnknownRouterApi extends RouterFailure {
  const UnknownRouterApi([
    super.message =
        'The MiFi was reached but its API could not be identified yet.',
  ]);
}

final class NetworkUnavailable extends RouterFailure {
  const NetworkUnavailable([
    super.message = 'No network connection is available.',
  ]);
}
