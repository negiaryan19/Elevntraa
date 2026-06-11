import 'package:freezed_annotation/freezed_annotation.dart';

part 'report_attachment.freezed.dart';
part 'report_attachment.g.dart';

/// A scanned/attached previous medical report for a visit. [path] is the
/// absolute file path of the saved image on the device; [caption] is an
/// optional doctor-supplied label (e.g. "Blood test - 2 Jan").
@freezed
class ReportAttachment with _$ReportAttachment {
  const factory ReportAttachment({
    required String path,
    @Default('') String caption,
  }) = _ReportAttachment;

  factory ReportAttachment.fromJson(Map<String, dynamic> json) =>
      _$ReportAttachmentFromJson(json);
}
