class ModelOption {
  String quantization;
  String downloadLink;

  ModelOption({required this.downloadLink, required this.quantization});
  
  factory ModelOption.fromJson(Map<String, String> json) {
    return ModelOption(
      downloadLink: json["download_link"] as String, 
      quantization: json["quantization"] as String
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true; // Same object instance
    return other is ModelOption && // Check if other is same type
           other.downloadLink == downloadLink && // Compare properties
           other.quantization == quantization;
  }

  @override
  int get hashCode => downloadLink.hashCode ^ quantization.hashCode;
  
  @override
  String toString() {
    return "$quantization : $downloadLink";
  }
}