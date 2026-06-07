class SignedUploadUrlModel {
  final String signedUrl;
  final String bucket;
  final String path;

  const SignedUploadUrlModel({
    required this.signedUrl,
    required this.bucket,
    required this.path,
  });

  factory SignedUploadUrlModel.fromJson(
    Map<String, dynamic> json, {
    required String fallbackBucket,
    required String fallbackPath,
  }) {
    final data = json['data'];

    Map<String, dynamic> source = json;

    if (data is Map<String, dynamic>) {
      source = data;
    }

    final signedUrl =
        source['signed_url']?.toString() ??
        source['signedUrl']?.toString() ??
        source['upload_url']?.toString() ??
        source['uploadUrl']?.toString() ??
        source['url']?.toString() ??
        '';

    return SignedUploadUrlModel(
      signedUrl: signedUrl,
      bucket: source['bucket']?.toString() ?? fallbackBucket,
      path: source['path']?.toString() ?? fallbackPath,
    );
  }
}
