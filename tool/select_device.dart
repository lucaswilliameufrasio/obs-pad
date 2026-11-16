import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> arguments) async {
  final flutter = Platform.environment['OBS_PAD_FLUTTER'] ?? 'flutter';
  final kind = Platform.environment['OBS_PAD_DEVICE_KIND'];
  final result = await Process.run(flutter, ['devices', '--machine']);
  if (result.exitCode != 0) {
    stderr.write(result.stderr);
    exitCode = result.exitCode;
    return;
  }

  final devices = (jsonDecode(result.stdout as String) as List)
      .whereType<Map<String, dynamic>>()
      .where((device) => device['isSupported'] == true)
      .where((device) {
        final platform = device['targetPlatform'];
        if (platform is! String) {
          return false;
        }
        if (kind == 'phone') {
          return platform.startsWith('android') || platform.startsWith('ios');
        }
        if (kind == 'desktop') {
          return platform.startsWith('darwin') ||
              platform.startsWith('linux') ||
              platform.startsWith('windows');
        }
        return false;
      })
      .toList();
  if (devices.isEmpty) {
    stderr.writeln(
      'Nenhum dispositivo compatível encontrado. Conecte um celular ou inicie um emulador.',
    );
    exitCode = 1;
    return;
  }

  stdout.writeln('Escolha onde executar o aplicativo:');
  for (var index = 0; index < devices.length; index++) {
    final device = devices[index];
    stdout.writeln('  ${index + 1}) ${device['name']} (${device['id']})');
  }
  stdout.write('Número do dispositivo (ou 0 para cancelar): ');
  final choice = int.tryParse(stdin.readLineSync() ?? '');
  if (choice == 0) {
    return;
  }
  if (choice == null || choice < 1 || choice > devices.length) {
    stderr.writeln('Opção inválida.');
    exitCode = 1;
    return;
  }

  final process = await Process.start(flutter, [
    'run',
    '-d',
    devices[choice - 1]['id'] as String,
    ...arguments,
  ], mode: ProcessStartMode.inheritStdio);
  exitCode = await process.exitCode;
}
