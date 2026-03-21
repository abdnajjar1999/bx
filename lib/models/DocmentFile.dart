
class DocumentFile{

  final String name;
  final String createdBy;
  final String url;
  final String type;
  final String createdAt;



  DocumentFile({required this.name, required this.url, required this.type, required this.createdAt, required this.createdBy, });
  factory DocumentFile.fromJson(Map<String, dynamic> json) {
    return DocumentFile(
      name: json['name'],
      url: json['url'],
      type: json['type'],
      createdAt: json['createdAt'],
      createdBy: json['createdBy'],
      
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'type': type,
      'createdAt': createdAt,
      'createdBy': createdBy,
    };
  }
}
