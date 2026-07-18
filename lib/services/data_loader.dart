import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/timeline_source.dart';

class DataLoaderException implements Exception {
  final String message;
  final File? file;
  final Exception? cause;

  DataLoaderException(this.message, {this.file, this.cause});

  @override
  String toString() => 'DataLoaderException: $message';
}

class DirectoryNotFoundException extends DataLoaderException {
  DirectoryNotFoundException(String message) : super(message);
}

class JsonParseException extends DataLoaderException {
  JsonParseException(String message, {File? file, Exception? cause})
    : super(message, file: file, cause: cause);
}

class DataLoaderService {
  final String dataDirectory;
  final String? configFile;

  DataLoaderService({required this.dataDirectory, this.configFile});

  Future<List<TimelineSource>> discoverSources() async {
    List<File> files;

    if (configFile != null) {
      try {
        final configFiles = await _loadConfigFile();
        files = configFiles.map((path) => File(path)).toList();
      } catch (e) {
        files = await _scanDirectory();
      }
    } else {
      files = await _scanDirectory();
    }

    final sources = <TimelineSource>[];
    final failedFiles = <String>[];

    for (final file in files) {
      try {
        final source = await _parseFile(file);
        sources.add(source);
      } catch (e) {
        failedFiles.add(file.path);
      }
    }

    if (sources.isEmpty && failedFiles.isNotEmpty) {
      throw DataLoaderException('所有文件加载失败: ${failedFiles.join(", ")}');
    }

    return sources;
  }

  Future<List<String>> _loadConfigFile() async {
    final file = File(configFile!);
    if (!await file.exists()) {
      throw DataLoaderException('配置文件不存在: $configFile');
    }

    final content = await file.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    final files = json['files'] as List<dynamic>;

    return files.cast<String>();
  }

  Future<List<File>> _scanDirectory() async {
    final dir = Directory(dataDirectory);
    if (!await dir.exists()) {
      throw DirectoryNotFoundException('数据目录不存在: $dataDirectory');
    }

    final files = await dir
        .list(recursive: false)
        .where((entity) => entity is File && entity.path.endsWith('.json'))
        .cast<File>()
        .toList();

    return files;
  }

  Future<TimelineSource> _parseFile(File file) async {
    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final id = p.basenameWithoutExtension(file.path);

      return TimelineSource.fromJson(id, json);
    } catch (e) {
      if (e is FormatException) {
        throw JsonParseException(
          'JSON 解析失败: ${file.path}',
          file: file,
          cause: e,
        );
      }
      rethrow;
    }
  }
}
