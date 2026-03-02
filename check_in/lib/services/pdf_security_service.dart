// import 'package:syncfusion_flutter_pdf/pdf.dart' as spdf;

// class PdfSecurityService {
  
//   /// Takes raw PDF bytes (from your existing pdf_service.dart)
//   /// and returns secured PDF bytes with password + restrictions applied
//   static Future<List<int>> applySecurity({
//     required List<int> pdfBytes,
//     required String userPassword,
//   }) async {
//     // Load the already-built PDF into Syncfusion
//     final spdf.PdfDocument document = spdf.PdfDocument(
//       inputBytes: pdfBytes,
//     );

//     // AES-256 encryption — same standard used for local storage
//     document.security.algorithm =
//         spdf.PdfEncryptionAlgorithm.aesx256Bit;

//     // Password patient must enter to OPEN the file
//     document.security.userPassword = userPassword;

//     // Owner password — controls permission settings (app-level, hidden from user)
//     document.security.ownerPassword =
//         'CHECKIN_OWNER_${DateTime.now().millisecondsSinceEpoch}';

//     // Restrict copy and edit — document is read-only
//     // Empty list = no permissions granted to the user
//     document.security.permissions = [];

//     final List<int> securedBytes = document.saveSync();
//     document.dispose();

//     return securedBytes;
//   }
// }



import 'package:syncfusion_flutter_pdf/pdf.dart' as spdf;

class PdfSecurityService {
  static Future<List<int>> applySecurity({
    required List<int> pdfBytes,
    required String userPassword,
  }) async {
    // Load the already-built PDF
    final spdf.PdfDocument document = spdf.PdfDocument(
      inputBytes: pdfBytes,
    );

    final spdf.PdfSecurity security = document.security;

    // AES-256 encryption
    security.algorithm = spdf.PdfEncryptionAlgorithm.aesx256Bit;

    // Password patient must enter to open the file
    security.userPassword = userPassword;

    // Owner password — controls permission settings (app-level, hidden from user)
    security.ownerPassword =
        'CHECKIN_OWNER_${DateTime.now().millisecondsSinceEpoch}';

    // Empty list = no permissions granted = fully read-only
    security.permissions
        .addAll(<spdf.PdfPermissionsFlags>[]);

    final List<int> securedBytes = document.saveSync();
    document.dispose();

    return securedBytes;
  }
}