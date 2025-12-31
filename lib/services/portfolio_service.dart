import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/user_model.dart';
import '../models/portfolio_item_model.dart';
import 'user_service.dart';

class PortfolioService {
  final UserService _userService = UserService();

  // Generate PDF portfolio
  Future<File> generatePortfolioPDF(UserModel user) async {
    try {
      final portfolio = await _userService.getUserPortfolio(user.uid);
      
      final pdf = pw.Document();

      // Add pages
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            // Header
            _buildHeader(user),
            pw.SizedBox(height: 20),
            
            // About section
            _buildAboutSection(user),
            pw.SizedBox(height: 20),
            
            // Skills section
            _buildSkillsSection(user),
            pw.SizedBox(height: 20),
            
            // Portfolio items
            _buildPortfolioSection(portfolio),
          ],
        ),
      );

      // Save to file
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/portfolio_${user.username}.pdf');
      await file.writeAsBytes(await pdf.save());

      return file;
    } catch (e) {
      throw Exception('Failed to generate PDF: $e');
    }
  }

  // Build header section
  pw.Widget _buildHeader(UserModel user) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue700,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            user.fullName,
            style: pw.TextStyle(
              fontSize: 32,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '@${user.username}',
            style: const pw.TextStyle(
              fontSize: 16,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _buildStatBox('Level ${user.level}', '${user.xpPoints} XP'),
              pw.SizedBox(width: 20),
              _buildStatBox('Rating', '${user.averageRating.toStringAsFixed(1)} ⭐'),
              pw.SizedBox(width: 20),
              _buildStatBox('Exchanges', '${user.completedExchanges}'),
              pw.SizedBox(width: 20),
              _buildStatBox('Projects', '${user.completedProjects}'),
            ],
          ),
        ],
      ),
    );
  }

  // Build stat box
  pw.Widget _buildStatBox(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0x26FFFFFF), // White with 15% opacity
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Build about section
  pw.Widget _buildAboutSection(UserModel user) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'About',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          user.bio ?? 'No bio provided',
          style: const pw.TextStyle(fontSize: 14),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Email: ${user.email}',
          style: const pw.TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  // Build skills section
  pw.Widget _buildSkillsSection(UserModel user) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Skills',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        if (user.skillsToTeach.isNotEmpty) ...[
          pw.Text(
            'Can Teach:',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Wrap(
            spacing: 5,
            runSpacing: 5,
            children: user.skillsToTeach.map((skill) => 
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue100,
                  borderRadius: pw.BorderRadius.circular(15),
                ),
                child: pw.Text(skill, style: const pw.TextStyle(fontSize: 12)),
              ),
            ).toList(),
          ),
          pw.SizedBox(height: 10),
        ],
        if (user.skillsToLearn.isNotEmpty) ...[
          pw.Text(
            'Want to Learn:',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Wrap(
            spacing: 5,
            runSpacing: 5,
            children: user.skillsToLearn.map((skill) => 
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green100,
                  borderRadius: pw.BorderRadius.circular(15),
                ),
                child: pw.Text(skill, style: const pw.TextStyle(fontSize: 12)),
              ),
            ).toList(),
          ),
        ],
      ],
    );
  }

  // Build portfolio section
  pw.Widget _buildPortfolioSection(List<PortfolioItemModel> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Portfolio',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        if (items.isEmpty)
          pw.Text('No portfolio items yet', style: const pw.TextStyle(fontSize: 14))
        else
          ...items.map((item) => _buildPortfolioItem(item)),
      ],
    );
  }

  // Build individual portfolio item
  pw.Widget _buildPortfolioItem(PortfolioItemModel item) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 15),
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                item.title,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue100,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  item.type.toUpperCase(),
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(item.description, style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 8),
          pw.Wrap(
            spacing: 5,
            runSpacing: 5,
            children: item.skills.map((skill) => 
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Text(skill, style: const pw.TextStyle(fontSize: 10)),
              ),
            ).toList(),
          ),
          if (item.rating != null) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              'Rating: ${item.rating!.toStringAsFixed(1)} ⭐',
              style: const pw.TextStyle(fontSize: 12),
            ),
          ],
          if (item.review != null && item.review!.isNotEmpty) ...[
            pw.SizedBox(height: 5),
            pw.Text(
              '"${item.review}"',
              style: pw.TextStyle(
                fontSize: 11,
                fontStyle: pw.FontStyle.italic,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Share portfolio
  Future<void> sharePortfolio(File pdfFile) async {
    try {
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: 'Check out my XChangeHUb portfolio!',
      );
    } catch (e) {
      throw Exception('Failed to share portfolio: $e');
    }
  }

  // Print portfolio
  Future<void> printPortfolio(File pdfFile) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      await Printing.layoutPdf(onLayout: (_) => bytes);
    } catch (e) {
      throw Exception('Failed to print portfolio: $e');
    }
  }
}
