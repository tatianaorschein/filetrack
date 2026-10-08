import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:filetrack/models/dossier.dart';
import 'package:filetrack/models/transmission.dart';

class PdfExportService {
  static final PdfExportService instance = PdfExportService._init();

  PdfExportService._init();

  /// Génère et ouvre le rapport PDF officiel d'un dossier avec son historique complet
  Future<void> exportDossierHistoryPdf({
    required Dossier dossier,
    required List<Transmission> transmissions,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // En-tête Institutionnel Hydro-Mekin
            pw.Row(
              main: pw.MainAxisAlignment.spaceBetween,
              cross: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  cross: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "HYDRO-MEKIN",
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.Text(
                      "Mekin Hydroelectric Development Corporation",
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                    ),
                    pw.Text(
                      "SDCAF - Sous-Direction des Affaires Financières",
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  cross: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      "RÉPUBLIQUE DU CAMEROUN",
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      "Paix - Travail - Patrie",
                      style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      "Date : ${DateTime.now().toString().substring(0, 10)}",
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 1, color: PdfColors.blue900),
            pw.SizedBox(height: 12),

            // Titre du Document
            pw.Center(
              child: pw.Text(
                "FICHE DE SUIVI ET PARCOURS DU DOSSIER",
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ),
            pw.SizedBox(height: 16),

            // Section 1 : Informations Générales du Dossier
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                cross: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    main: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        "Identifiant : ${dossier.id}",
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.Text(
                        "Dernier emplacement : ${dossier.currentStatus}",
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                          color: PdfColors.grey900,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    "Objet / Titre : ${dossier.title}",
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    children: [
                      pw.Text("Service créateur : ${dossier.creatorServiceId} | ",
                          style: const pw.TextStyle(fontSize: 9)),
                      pw.Text("Date de création : ${dossier.createdAt.substring(0, 10)}",
                          style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Section 2 : Tableau des Transmissions
            pw.Text(
              "Historique Chronologique des Transmissions",
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 8),

            pw.Table.fromTextArray(
              headers: [
                'N°',
                'Date/Heure',
                'Émetteur',
                'Destinataire',
                'Statut',
                'Observations & PDF'
              ],
              data: List.generate(transmissions.length, (index) {
                final tr = transmissions[index];
                final hasPdf = tr.attachmentPath != null && tr.attachmentPath!.isNotEmpty;
                final pdfNote = hasPdf ? "\n[Scan PDF joint]" : "";

                return [
                  "${index + 1}",
                  tr.dateTime.length >= 16 ? tr.dateTime.substring(0, 16) : tr.dateTime,
                  "${tr.senderServiceId}\n(${tr.senderUserId})",
                  tr.type == 'externe'
                      ? "EXTERNE\n(${tr.externalOrganization ?? ''})"
                      : tr.receiverServiceId,
                  tr.status.toUpperCase(),
                  "${tr.observation}$pdfNote",
                ];
              }),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 9,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
              ),
            ),
            pw.SizedBox(height: 30),

            // Section 3 : Bloc d'authentification / Visa
            pw.Row(
              mainpw: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  cross: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text("Le Service Émetteur / Visa",
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 30),
                    pw.Text("_____________________",
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
                  ],
                ),
                pw.Column(
                  cross: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text("Le Chef de Service SDCAF",
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 30),
                    pw.Text("_____________________",
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    // Ouvre le module d'impression/exportation natif Android/Windows
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: "Historique_FileTrack_${dossier.id}.pdf",
    );
  }
}
