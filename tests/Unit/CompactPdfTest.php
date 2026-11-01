<?php
/**
 * Unit tests for CompactTCPDF: certificate PDFs embed only the DejaVu Sans
 * glyphs they use, so a text-only certificate stays in the tens of KB.
 */

require_once dirname(__FILE__) . '/../bootstrap.php';
require_once BASE_SYS_DIR . '/classes/CertificateGenerator.php';

use APP\plugins\generic\reviewerCertificate\classes\CertificateGenerator;
use APP\plugins\generic\reviewerCertificate\classes\CompactTCPDF;

class CompactPdfTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        if (!class_exists('TCPDF')) {
            $this->markTestSkipped('TCPDF not installed');
        }
        require_once BASE_SYS_DIR . '/classes/CompactTCPDF.php';
    }

    private function render($pdf)
    {
        $pdf->setPrintHeader(false);
        $pdf->setPrintFooter(false);
        $pdf->AddPage();
        foreach (['', 'B', 'I'] as $style) {
            $pdf->SetFont('dejavusans', $style, 14);
            $pdf->Write(8, 'Certificate of Reviewing — Dr. Jane Smith, Ελληνικά, Сертифікат');
            $pdf->Ln();
        }
        return $pdf->Output('', 'S');
    }

    /** @return string[] Decompressed embedded TrueType font programs */
    private function embeddedFonts($pdf)
    {
        preg_match_all('#/Length (\d+) /Filter /FlateDecode /Length1 \d+ >> stream\n#', $pdf, $m, PREG_OFFSET_CAPTURE);
        $fonts = [];
        foreach ($m[0] as $i => $match) {
            $start = $match[1] + strlen($match[0]);
            $fonts[] = gzuncompress(substr($pdf, $start, (int) $m[1][$i][0]));
        }
        return $fonts;
    }

    public function testCompactOutputIsMuchSmallerThanPlainTcpdf(): void
    {
        $plain = $this->render(new \TCPDF('L', 'mm', 'A4', true, 'UTF-8', false));
        $compact = $this->render(new CompactTCPDF('L', 'mm', 'A4', true, 'UTF-8', false));

        $this->assertStringStartsWith('%PDF-', $compact);
        $this->assertCount(3, $this->embeddedFonts($compact), 'Regular, bold and italic stay embedded');
        $this->assertLessThan(strlen($plain) * 0.4, strlen($compact),
            sprintf('compact %d bytes vs plain %d bytes', strlen($compact), strlen($plain)));
    }

    public function testEmbeddedFontsKeepValidChecksums(): void
    {
        $compact = $this->render(new CompactTCPDF('L', 'mm', 'A4', true, 'UTF-8', false));
        foreach ($this->embeddedFonts($compact) as $font) {
            $font .= str_repeat("\x00", (4 - strlen($font) % 4) % 4);
            $sum = 0;
            foreach (unpack('N*', $font) as $word) {
                $sum = ($sum + $word) & 0xFFFFFFFF;
            }
            $this->assertSame(0xB1B0AFBA, $sum, 'Whole-font checksum must match head.checkSumAdjustment');
        }
    }

    public function testCidToGidMapKeepsOnlyUsedCharacters(): void
    {
        $map = '';
        for ($cid = 0; $cid < 65536; $cid++) {
            $map .= pack('n', $cid % 5000 + 1);
        }
        $out = CompactTCPDF::compactCidToGidMap($map, [65 => true, 0x3A9 => true]);

        $this->assertSame(131072, strlen($out));
        $this->assertSame(66, unpack('n', substr($out, 130, 2))[1]);
        $this->assertSame(0x3A9 + 1, unpack('n', substr($out, 2 * 0x3A9, 2))[1]);
        $this->assertSame(0, unpack('n', substr($out, 132, 2))[1]);
    }

    public function testTextOnlyCertificateIsUnder45Kb(): void
    {
        $generator = new CertificateGenerator();
        $generator->setPreviewMode(true);
        $generator->setContext($this->createMockContext(1, 'Test Journal', 'TJ'));
        $generator->setTemplateSettings([
            'fontFamily' => 'dejavusans',
            'headerText' => 'Certificate of Reviewing',
            'bodyTemplate' => 'Thank you {{$reviewerName}} for reviewing for {{$journalName}}',
            'footerText' => 'Editor-in-Chief',
        ]);

        $pdf = $generator->generatePDF();

        $this->assertStringStartsWith('%PDF-', $pdf);
        $this->assertLessThan(45 * 1024, strlen($pdf), 'DejaVu Sans subsets must only hold the used glyphs');
    }

    public function testCjkScriptSelectsMatchingFont(): void
    {
        new \TCPDF(); // defines K_PATH_FONTS
        $this->assertSame('msungstdlight', CertificateGenerator::selectCjkFont(['審稿證書', 'Dr. Jane Smith']));
        $this->assertSame('stsongstdlight', CertificateGenerator::selectCjkFont(['审稿证书']));
        $this->assertSame('kozminproregular', CertificateGenerator::selectCjkFont(['査読証明書', 'ありがとう']));
        $this->assertSame('hysmyeongjostdmedium', CertificateGenerator::selectCjkFont(['심사 증명서']));
        $this->assertNull(CertificateGenerator::selectCjkFont(['Сертифікат', 'Ελληνικά', 'Café']));
    }

    public function testChineseCertificateUsesCjkFontWithLatinWidths(): void
    {
        $generator = new CertificateGenerator();
        $generator->setPreviewMode(true);
        $generator->setContext($this->createMockContext(1, 'Test Journal', 'TJ'));
        $generator->setTemplateSettings([
            'fontFamily' => 'dejavusans',
            'headerText' => '審稿證書',
            'bodyTemplate' => '感謝 {{$reviewerName}} 為本刊審稿',
            'footerText' => '',
        ]);

        $pdf = $generator->generatePDF();

        $this->assertStringContainsString('/BaseFont /MSungStd-Light-Acro', $pdf);
        // Latin glyphs need their real widths, or "Dr. Jane Smith" is spaced out
        $this->assertMatchesRegularExpression('#/Subtype /CIDFontType0 /BaseFont /MSungStd-Light-Acro /CIDSystemInfo <<[^>]*>> /FontDescriptor \d+ 0 R /DW 1000\n/W \[ ?\d#', $pdf);
        $this->assertLessThan(45 * 1024, strlen($pdf));
    }
}
