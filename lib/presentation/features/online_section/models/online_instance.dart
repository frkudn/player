import 'package:equatable/equatable.dart';

class OnlineInstance extends Equatable {
  final String name;
  final String url;
  final String description;
  final bool isCustom;

  const OnlineInstance({
    required this.name,
    required this.url,
    required this.description,
    this.isCustom = false,
  });

  factory OnlineInstance.fromJson(Map<String, dynamic> j) => OnlineInstance(
        name: j['name'] as String,
        url: j['url'] as String,
        description: j['description'] as String? ?? '',
        isCustom: j['isCustom'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'url': url,
        'description': description,
        'isCustom': isCustom,
      };

  @override
  List<Object?> get props => [name, url, isCustom];
}
