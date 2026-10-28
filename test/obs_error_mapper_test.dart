import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_pad/data/obs/obs_error_mapper.dart';
import 'package:obs_pad/domain/connection_profile.dart';
import 'package:obs_pad/domain/obs_failure.dart';
import 'package:obs_websocket/obs_websocket.dart';

void main() {
  group('mapObsError – connection problems', () {
    test('close code 4009 means wrong password', () {
      final failure = mapObsError(
        const ObsAuthenticationException('no Identified opcode'),
        closeCode: 4009,
      );
      expect(failure.kind, ObsFailureKind.wrongPassword);
      expect(failure.isPermanent, isTrue);
    });

    test('authentication exception without close code is wrong password', () {
      expect(
        mapObsError(const ObsAuthenticationException('x')).kind,
        ObsFailureKind.wrongPassword,
      );
    });

    test('close code 4010 means OBS too old', () {
      expect(
        mapObsError(StateError('closed'), closeCode: 4010).kind,
        ObsFailureKind.unsupportedVersion,
      );
    });

    for (final (label, code) in [
      ('Linux/Android', 111),
      ('macOS/iOS', 61),
      ('Windows', 10061),
    ]) {
      test('connection refused on $label means server off', () {
        final error = SocketException(
          'Connection refused',
          osError: OSError('Connection refused', code),
        );
        expect(mapObsError(error).kind, ObsFailureKind.serverOff);
      });
    }

    test('timeout means wrong IP or firewall', () {
      expect(
        mapObsError(TimeoutException('connect')).kind,
        ObsFailureKind.timeout,
      );
      const socketTimeout = SocketException(
        'Connection timed out',
        osError: OSError('Connection timed out', 110),
      );
      expect(mapObsError(socketTimeout).kind, ObsFailureKind.timeout);
    });

    test('no route to host / network unreachable means different network', () {
      expect(
        mapObsError(
          const SocketException('x', osError: OSError('No route to host', 113)),
        ).kind,
        ObsFailureKind.unreachable,
      );
      expect(
        mapObsError(
          const SocketException(
            'x',
            osError: OSError('Network is unreachable', 51),
          ),
        ).kind,
        ObsFailureKind.unreachable,
      );
    });

    test('failed host lookup means invalid address', () {
      const error = SocketException(
        "Failed host lookup: 'meu-pc'",
        osError: OSError('No address associated with hostname', 7),
      );
      expect(mapObsError(error).kind, ObsFailureKind.invalidAddress);
    });

    test('non-websocket server means not OBS', () {
      expect(
        mapObsError(
          const WebSocketException('Connection was not upgraded to websocket'),
        ).kind,
        ObsFailureKind.notObs,
      );
    });

    test('ObsFailure passes through unchanged', () {
      const failure = ObsFailure(ObsFailureKind.serverOff);
      expect(identical(mapObsError(failure), failure), isTrue);
    });

    test('unknown errors keep the detail', () {
      final failure = mapObsError(Exception('boom'));
      expect(failure.kind, ObsFailureKind.unknown);
      expect(failure.detail, contains('boom'));
    });
  });

  group('mapObsError – request status codes', () {
    ObsFailure request(int code) => mapObsError(
      ObsRequestException(
        requestType: 'SetCurrentProgramScene',
        code: code,
        comment: 'comment',
      ),
      resource: 'Cena 1',
    );

    test('600 = resource not found, keeps the name', () {
      final failure = request(600);
      expect(failure.kind, ObsFailureKind.resourceNotFound);
      expect(failure.resource, 'Cena 1');
      expect(failure.isConnectionProblem, isFalse);
    });

    test('output codes', () {
      expect(request(500).kind, ObsFailureKind.outputAlreadyActive);
      expect(request(501).kind, ObsFailureKind.outputNotActive);
      expect(request(504).kind, ObsFailureKind.outputDisabled);
    });

    test('other codes', () {
      expect(request(601).kind, ObsFailureKind.alreadyExists);
      expect(request(604).kind, ObsFailureKind.invalidState);
      expect(request(605).kind, ObsFailureKind.invalidInputKind);
      expect(request(702).kind, ObsFailureKind.requestFailed);
    });
  });

  group('validateHost', () {
    test('accepts IPs and host names', () {
      expect(validateHost('192.168.0.15'), isNull);
      expect(validateHost(' 100.101.102.103 '), isNull);
      expect(validateHost('meu-pc.local'), isNull);
    });

    test('rejects common mistakes', () {
      expect(validateHost(''), HostValidation.empty);
      expect(validateHost('ws://192.168.0.15'), HostValidation.hasScheme);
      expect(validateHost('192.168.0.15:4455'), HostValidation.hasPort);
      expect(validateHost('192.168.0.300'), HostValidation.invalid);
      expect(validateHost('192.168.0'), HostValidation.invalid);
    });
  });
}
