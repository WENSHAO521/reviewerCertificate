<?php
/**
 * Structured certificate layout: independent typography for the title, reviewer
 * name, journal name, acknowledgement text and detail lines, with long names
 * shrinking to fit and the whole layout scaling down to stay on one page.
 */

require_once dirname(__FILE__) . '/../bootstrap.php';
require_once BASE_SYS_DIR . '/classes/Certificate.php';
require_once BASE_SYS_DIR . '/classes/CertificateGenerator.php';

use APP\plugins\generic\reviewerCertificate\classes\CertificateGenerator;

class StructuredLayoutTest extends TestCase
{
    private function context()
    {
        return new class {
            public function getLocalizedName() { return 'Journal of Testing'; }
            public function getData($key) { return null; }
            public function getId() { return 2; }
            public function getPath() { return 'testjournal'; }
        };
    }

    private function generator(array $settings)
    {
        $generator = new CertificateGenerator();
        $generator->setPreviewMode(true);
        $generator->setContext($this->context());
        $generator->setTemplateSettings($settings + array(
            'fontFamily' => 'helvetica',
            'headerText' => 'Certificate of Recognition',
            'bodyTemplate' => CertificateGenerator::getDefaultBodyTemplate(),
            'footerText' => 'Issued by the editorial office',
            'pageOrientation' => 'L',
            'layoutMode' => 'structured',
        ));
        return $generator;
    }

    /**
     * Run the structured layout against a recording TCPDF and return the drawn
     * cells as [text, size, style, y].
     */
    private function render(CertificateGenerator $generator, $orientation = 'L')
    {
        $pdf = new class($orientation, 'mm', 'A4', true, 'UTF-8', false) extends \TCPDF {
            public $cells = array();
            public function MultiCell($w, $h, $txt, $border = 0, $align = 'J', $fill = false, $ln = 1, $x = null, $y = null, $reseth = true, $stretch = 0, $ishtml = false, $autopadding = true, $maxh = 0, $valign = 'T', $fitcell = false) {
                $this->cells[] = array($txt, $this->FontSizePt, $this->FontStyle, $this->GetY());
                return parent::MultiCell($w, $h, $txt, $border, $align, $fill, $ln, $x, $y, $reseth, $stretch, $ishtml, $autopadding, $maxh, $valign, $fitcell);
            }
        };
        $pdf->setPrintHeader(false);
        $pdf->setPrintFooter(false);
        $pdf->SetMargins(15, 15, 15);
        $pdf->SetAutoPageBreak(false);
        $pdf->AddPage();

        $font = new \ReflectionProperty(CertificateGenerator::class, 'effectiveFont');
        $font->setAccessible(true);
        $font->setValue($generator, 'helvetica');

        $variables = new \ReflectionMethod(CertificateGenerator::class, 'getTemplateVariables');
        $variables->setAccessible(true);
        $vars = $variables->invoke($generator);

        $settings = new \ReflectionProperty(CertificateGenerator::class, 'templateSettings');
        $settings->setAccessible(true);
        $s = $settings->getValue($generator);
        $replace = new \ReflectionMethod(CertificateGenerator::class, 'replaceVariables');
        $replace->setAccessible(true);

        $method = new \ReflectionMethod(CertificateGenerator::class, 'addStructuredContent');
        $method->setAccessible(true);
        $method->invoke($generator, $pdf, $replace->invoke($generator, $s['headerText'], $vars),
            $replace->invoke($generator, $s['footerText'], $vars), $vars);

        return array($pdf, $pdf->cells);
    }

    private function cell(array $cells, $needle)
    {
        foreach ($cells as $cell) {
            if (strpos($cell[0], $needle) !== false) {
                return $cell;
            }
        }
        $this->fail("No cell containing '$needle'");
    }

    public function testBodyLinesAreClassifiedByRole(): void
    {
        $this->assertSame('name', CertificateGenerator::classifyBodyLine('{{$reviewerName}}'));
        $this->assertSame('name', CertificateGenerator::classifyBodyLine('  {{$reviewerFirstName}} {{$reviewerLastName}} '));
        $this->assertSame('name', CertificateGenerator::classifyBodyLine('{$reviewerName}'));
        $this->assertSame('journal', CertificateGenerator::classifyBodyLine('{{$journalName}}'));
        $this->assertSame('journal', CertificateGenerator::classifyBodyLine('{{$journalName}} ({{$journalAcronym}})'));
        $this->assertSame('detail', CertificateGenerator::classifyBodyLine('Review completed on {{$reviewDate}}'));
        $this->assertSame('detail', CertificateGenerator::classifyBodyLine('Code: {{$certificateCode}}'));
        $this->assertSame('body', CertificateGenerator::classifyBodyLine('This certificate is awarded to'));
        // A name embedded in a sentence is body text, not the emphasised name line
        $this->assertSame('body', CertificateGenerator::classifyBodyLine('Awarded to {{$reviewerName}} for reviewing'));
        $this->assertSame('body', CertificateGenerator::classifyBodyLine('Manuscript: {{$submissionTitle}}'));
    }

    public function testDefaultTypographyMatchesTheSuggestedHierarchy(): void
    {
        list(, $cells) = $this->render($this->generator(array()));

        $this->assertSame(array(28.0, 'B'), array((float) $this->cell($cells, 'Certificate of Recognition')[1], $this->cell($cells, 'Certificate of Recognition')[2]));
        $this->assertSame(array(25.0, 'B'), array((float) $this->cell($cells, 'Dr. Jane Smith')[1], $this->cell($cells, 'Dr. Jane Smith')[2]));
        $this->assertSame(17.0, (float) $this->cell($cells, 'Journal of Testing')[1]);
        $this->assertSame(13.0, (float) $this->cell($cells, 'This certificate is awarded to')[1]);
        $this->assertSame(10.0, (float) $this->cell($cells, 'Review completed on')[1]);
        $this->assertSame(10.0, (float) $this->cell($cells, 'Issued by the editorial office')[1]);
        $this->assertSame(10.0, (float) $this->cell($cells, 'Certificate Code: PREVIEW12345')[1]);

        // Footer and certificate code come after all body content
        $this->assertGreaterThan($this->cell($cells, 'Manuscript:')[3], $this->cell($cells, 'Issued by')[3]);
        $this->assertGreaterThan($this->cell($cells, 'Issued by')[3], $this->cell($cells, 'Certificate Code')[3]);
    }

    public function testTypographySettingsAreIndependentAndClamped(): void
    {
        list(, $cells) = $this->render($this->generator(array(
            'nameFontSize' => 30, 'nameBold' => 0, 'journalFontSize' => '18', 'journalBold' => 1,
            'bodyFontSize' => 14, 'detailFontSize' => 'nonsense',
        )));

        $this->assertSame('', $this->cell($cells, 'Dr. Jane Smith')[2]);
        $this->assertSame('B', $this->cell($cells, 'Journal of Testing')[2]);
        $this->assertSame(18.0, (float) $this->cell($cells, 'Journal of Testing')[1]);
        // Title is unaffected by the other elements' settings
        $this->assertSame(28.0, (float) $this->cell($cells, 'Certificate of Recognition')[1]);
        $this->assertSame(14.0, (float) $this->cell($cells, 'This certificate is awarded to')[1]);
        // Invalid detail size falls back to its default
        $this->assertSame(10.0, (float) $this->cell($cells, 'Certificate Code')[1]);
    }

    public function testLongReviewerNameShrinksToFitOneLine(): void
    {
        $generator = $this->generator(array());
        $s = array('bodyTemplate' => "Awarded to\n\n{{\$reviewerName}}");

        $long = str_repeat('Maximilian Alexander ', 6) . 'Smith';
        $vars = new \ReflectionMethod(CertificateGenerator::class, 'buildStructuredBlocks');
        $vars->setAccessible(true);
        $blocks = $vars->invoke($generator, $s['bodyTemplate'], array('reviewerName' => $long));
        $this->assertSame('name', $blocks[1]['role']);

        $fit = new \ReflectionMethod(CertificateGenerator::class, 'fitFontSize');
        $fit->setAccessible(true);
        $font = new \ReflectionProperty(CertificateGenerator::class, 'effectiveFont');
        $font->setAccessible(true);
        $font->setValue($generator, 'helvetica');
        $pdf = new \TCPDF('L', 'mm', 'A4', true, 'UTF-8', false);
        $pdf->AddPage();

        $width = $pdf->getPageWidth() - 30;
        $shortSize = $fit->invoke($generator, $pdf, 'Dr. Jane Smith', 'B', 25, 15, $width);
        $this->assertSame(25.0, $shortSize, 'Short names keep their configured size');

        $medium = 'Professor Maximilian Alexander Bartholomew von Hohenzollern-Sigmaringen';
        $mediumSize = $fit->invoke($generator, $pdf, $medium, 'B', 25, 15, $width);
        $this->assertLessThan(25.0, $mediumSize);
        $pdf->SetFont('helvetica', 'B', $mediumSize);
        $this->assertLessThanOrEqual($width, $pdf->GetStringWidth($medium));

        // Too long even at the floor: stays at the floor and wraps
        $this->assertSame(15.0, $fit->invoke($generator, $pdf, $long, 'B', 25, 15, $width));
    }

    public function testOverlongContentScalesDownToStayOnOnePage(): void
    {
        $lines = array();
        for ($i = 0; $i < 30; $i++) {
            $lines[] = 'A long acknowledgement paragraph that keeps going for a while, line ' . $i;
        }
        list($pdf, $cells) = $this->render($this->generator(array(
            'bodyTemplate' => "{{\$reviewerName}}\n\n" . implode("\n\n", $lines),
        )));

        $last = end($cells);
        $this->assertSame('Certificate Code: PREVIEW12345', $last[0]);
        $this->assertLessThanOrEqual($pdf->getPageHeight() - 15, $pdf->GetY(), 'Content must end above the bottom margin');
        $this->assertSame(1, $pdf->getNumPages());
        $this->assertLessThan(25.0, (float) $this->cell($cells, 'Dr. Jane Smith')[1], 'Everything scales together');
    }

    public function testOutOfRangeSizesAreClamped(): void
    {
        $generator = $this->generator(array('bodyFontSize' => 500, 'nameFontSize' => -4));
        $method = new \ReflectionMethod(CertificateGenerator::class, 'getTypographySetting');
        $method->setAccessible(true);
        $this->assertSame(72, $method->invoke($generator, 'bodyFontSize'));
        $this->assertSame(6, $method->invoke($generator, 'nameFontSize'));
    }

    public function testStructuredPdfIsGeneratedOnOnePage(): void
    {
        $pdf = $this->generator(array())->generatePDF();
        $this->assertStringStartsWith('%PDF-', $pdf);
        $this->assertMatchesRegularExpression('#/Type /Pages /Kids \[[^\]]*\] /Count 1#', $pdf);
    }

    public function testClassicIsTheDefaultLayout(): void
    {
        $generator = new CertificateGenerator();
        $method = new \ReflectionMethod(CertificateGenerator::class, 'getLayoutMode');
        $method->setAccessible(true);

        $generator->setTemplateSettings(array());
        $this->assertSame('classic', $method->invoke($generator), 'Existing installs must not change layout');
        $generator->setTemplateSettings(array('layoutMode' => null));
        $this->assertSame('classic', $method->invoke($generator));
        $generator->setTemplateSettings(array('layoutMode' => 'bogus'));
        $this->assertSame('classic', $method->invoke($generator));
        $generator->setTemplateSettings(array('layoutMode' => 'structured'));
        $this->assertSame('structured', $method->invoke($generator));
    }

    public function testDownloadAndPreviewPassTypographySettings(): void
    {
        $handler = file_get_contents(BASE_SYS_DIR . '/controllers/CertificateHandler.php');
        $core = file_get_contents(BASE_SYS_DIR . '/classes/ReviewerCertificatePluginCore.php');
        foreach (array($handler, $core) as $source) {
            $this->assertStringContainsString("'layoutMode'", $source);
            $this->assertStringContainsString('getTypographySettingDefinitions()', $source);
        }
    }
}
