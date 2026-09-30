class DataModel {
  final int id;
  final String title;
  final String body;

  const DataModel({
    required this.id,
    required this.title,
    required this.body,
  });

  factory DataModel.fromJson(Map<String, dynamic> json) {
    return DataModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  factory DataModel.fromResponse(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      return DataModel.fromJson(responseData);
    }
    throw const FormatException('Expected a JSON object for DataModel');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          body == other.body;

  @override
  int get hashCode => Object.hash(id, title, body);

  @override
  String toString() => 'DataModel(id: $id, title: $title, body: $body)';
}
