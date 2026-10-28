import 'dart:async';
import 'dart:io';

import 'package:obs_websocket/obs_websocket.dart';

import '../../domain/obs_failure.dart';

/// obs-websocket close codes (WebSocketCloseCode enum of the 5.x protocol).
abstract final class ObsCloseCode {
  static const authenticationFailed = 4009;
  static const unsupportedRpcVersion = 4010;
}

/// obs-websocket RequestStatus codes used for human messages.
abstract final class ObsRequestStatus {
  static const notReady = 207;
  static const missingRequestField = 300;
  static const invalidRequestField = 400;
  static const outputRunning = 500;
  static const outputNotRunning = 501;
  static const outputPaused = 502;
  static const outputNotPaused = 503;
  static const outputDisabled = 504;
  static const resourceNotFound = 600;
  static const resourceAlreadyExists = 601;
  static const invalidResourceType = 602;
  static const invalidResourceState = 604;
  static const invalidInputKind = 605;
  static const resourceNotConfigurable = 606;
  static const resourceCreationFailed = 700;
  static const resourceActionFailed = 701;
  static const requestProcessingFailed = 702;
}

/// OS error codes for "connection refused" on Linux/Android, macOS/iOS
/// and Windows.
const _refusedCodes = {111, 61, 10061};
const _timedOutCodes = {110, 60, 10060};
const _unreachableCodes = {101, 113, 51, 65, 10051, 10065};
const _lookupCodes = {7, 8, -2, 11001};

/// Translates anything thrown while talking to OBS into an [ObsFailure].
///
/// [closeCode] is the WebSocket close code, when the server closed the socket
/// during the handshake (e.g. 4009 = wrong password).
ObsFailure mapObsError(Object error, {int? closeCode, String? resource}) {
  if (error is ObsFailure) return error;

  if (closeCode == ObsCloseCode.authenticationFailed) {
    return const ObsFailure(ObsFailureKind.wrongPassword);
  }
  if (closeCode == ObsCloseCode.unsupportedRpcVersion) {
    return const ObsFailure(ObsFailureKind.unsupportedVersion);
  }

  final detail = error.toString();

  return switch (error) {
    ObsRequestException(:final code, :final comment) => _mapRequestStatus(
      code,
      resource: resource,
      detail: comment ?? detail,
    ),
    ObsAuthenticationException() => ObsFailure(
      ObsFailureKind.wrongPassword,
      detail: detail,
    ),
    ObsConnectionException() => ObsFailure(
      ObsFailureKind.notObs,
      detail: detail,
    ),
    ObsArgumentException() => ObsFailure(
      ObsFailureKind.invalidAddress,
      detail: detail,
    ),
    TimeoutException() => ObsFailure(ObsFailureKind.timeout, detail: detail),
    SocketException() => _mapSocket(error),
    WebSocketException() => ObsFailure(ObsFailureKind.notObs, detail: detail),
    HandshakeException() => ObsFailure(ObsFailureKind.notObs, detail: detail),
    FormatException() || ArgumentError() => ObsFailure(
      ObsFailureKind.invalidAddress,
      detail: detail,
    ),
    _ => ObsFailure(ObsFailureKind.unknown, detail: detail),
  };
}

ObsFailure _mapSocket(SocketException error) {
  final detail = error.toString();
  final code = error.osError?.errorCode;
  final text = '${error.message} ${error.osError?.message ?? ''}'.toLowerCase();

  if (code != null && _refusedCodes.contains(code) ||
      text.contains('connection refused') ||
      text.contains('actively refused')) {
    return ObsFailure(ObsFailureKind.serverOff, detail: detail);
  }
  if (text.contains('failed host lookup') ||
      text.contains('nodename nor servname') ||
      text.contains('no address associated') ||
      code != null && _lookupCodes.contains(code)) {
    return ObsFailure(ObsFailureKind.invalidAddress, detail: detail);
  }
  if (code != null && _timedOutCodes.contains(code) ||
      text.contains('timed out')) {
    return ObsFailure(ObsFailureKind.timeout, detail: detail);
  }
  if (code != null && _unreachableCodes.contains(code) ||
      text.contains('unreachable') ||
      text.contains('no route to host')) {
    return ObsFailure(ObsFailureKind.unreachable, detail: detail);
  }
  return ObsFailure(ObsFailureKind.unreachable, detail: detail);
}

ObsFailure _mapRequestStatus(int code, {String? resource, String? detail}) {
  final kind = switch (code) {
    ObsRequestStatus.notReady => ObsFailureKind.requestFailed,
    ObsRequestStatus.outputRunning => ObsFailureKind.outputAlreadyActive,
    ObsRequestStatus.outputNotRunning => ObsFailureKind.outputNotActive,
    ObsRequestStatus.outputPaused ||
    ObsRequestStatus.outputNotPaused => ObsFailureKind.invalidState,
    ObsRequestStatus.outputDisabled => ObsFailureKind.outputDisabled,
    ObsRequestStatus.resourceNotFound => ObsFailureKind.resourceNotFound,
    ObsRequestStatus.resourceAlreadyExists => ObsFailureKind.alreadyExists,
    ObsRequestStatus.invalidResourceType ||
    ObsRequestStatus.invalidResourceState ||
    ObsRequestStatus.resourceNotConfigurable => ObsFailureKind.invalidState,
    ObsRequestStatus.invalidInputKind => ObsFailureKind.invalidInputKind,
    _ => ObsFailureKind.requestFailed,
  };
  return ObsFailure(kind, resource: resource, detail: detail);
}
