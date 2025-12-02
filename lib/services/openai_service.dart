import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  final Dio _dio;
  final String _apiKey;
  final String _baseUrl = 'https://api.openai.com/v1';
  CancelToken? _cancelToken;

  OpenAIService() : _apiKey = dotenv.get('OPENAI_API_KEY'), _dio = Dio() {
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    };
  }

  Stream<String> createChatCompletionStream({
    required String model,
    required List<Map<String, dynamic>> messages,
    void Function()? onStop, // Thêm callback onStop
  }) {
    final streamController = StreamController<String>();
    _cancelToken = CancelToken();

    _dio.options.responseType = ResponseType.stream;

    _dio
        .post(
          '$_baseUrl/chat/completions',
          data: {'model': model, 'messages': messages, 'stream': true},
          cancelToken: _cancelToken, // Truyền CancelToken vào request
        )
        .then((response) {
          final stream = response.data.stream;

          stream.listen(
            (data) {
              final String chunk = utf8.decode(data);

              final lines = chunk.split('\n');
              for (var line in lines) {
                if (line.startsWith('data: ')) {
                  final jsonData = line.substring(6).trim();

                  if (jsonData == '[DONE]') continue;

                  try {
                    final Map<String, dynamic> parsed =
                        jsonDecode(jsonData) as Map<String, dynamic>;

                    if (parsed['choices'] != null &&
                        parsed['choices'].isNotEmpty &&
                        parsed['choices'][0]['delta'] != null &&
                        parsed['choices'][0]['delta']['content'] != null) {
                      final content = parsed['choices'][0]['delta']['content'];
                      streamController.add(content);
                    }
                  } catch (e) {
                    print('Error parsing chunk: $e');
                  }
                }
              }
            },
            onDone: () {
              streamController.close();
            },
            onError: (error) {
              if (error is DioException &&
                  error.type == DioExceptionType.cancel) {
                // Request được hủy bởi người dùng
                debugPrint('Request cancelled by user');
                onStop?.call(); // Gọi callback onStop nếu có
              } else {
                debugPrint('Error in stream: ${error.toString()}');
                streamController.addError(error);
              }
              streamController.close();
            },
          );
        })
        .catchError((error) {
          if (error is DioException && error.type == DioExceptionType.cancel) {
            debugPrint('Request cancelled by user');
            onStop?.call(); // Gọi callback onStop nếu có
          } else {
            debugPrint('Error in stream: $error');
            streamController.addError(error);
          }
          streamController.close();
        });

    return streamController.stream;
  }

  void stopStreaming() {
    if (_cancelToken != null && !_cancelToken!.isCancelled) {
      _cancelToken!.cancel('User stopped generation');
    }
  }

  Future<Map<String, dynamic>> createChatCompletion({
    required String model,
    required List<Map<String, dynamic>> messages,
  }) async {
    final response = await _dio.post(
      '$_baseUrl/chat/completions',
      data: {'model': model, 'messages': messages},
    );

    return response.data;
  }

  Future<String> handleUploadFile({required File file}) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/files',
        data: FormData.fromMap({
          'file': await MultipartFile.fromFile(file.path),
          'purpose': 'user_data',
        }),
      );
      debugPrint('File uploaded successfully: ${response.data}');
      return response.data['id'] as String;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      throw Exception('Failed to upload file: $e');
    }
  }
}

Map<String, dynamic> convertMessageToMap(dynamic message) {
  final Map<String, dynamic> result = {
    'role': message.role.toString().split('.').last,
  };

  if (message.content is List) {
    final contentList = message.content as List;
    if (contentList.isNotEmpty && contentList.first.text != null) {
      result['content'] = contentList.map((item) => item.text).join('');
    } else {
      result['content'] = '';
    }
  } else {
    result['content'] = message.content?.toString() ?? '';
  }

  return result;
}

Map<String, dynamic> createImageMessage({
  required String text,
  required String imageUrl,
  required String role,
}) {
  return {
    'role': role,
    'content': [
      {'type': 'text', 'text': text},
      {
        'type': 'image_url',
        'image_url': {'url': imageUrl, 'detail': 'auto'},
      },
    ],
  };
}
