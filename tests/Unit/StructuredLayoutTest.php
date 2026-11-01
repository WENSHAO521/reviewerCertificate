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
                $this->cells[] = array($txt, $this->FontSizePt, $this->FontStyle, $this->GetY(), $this->TextColor, $align, $this->GetX());
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
        $this->assertSame('title', CertificateGenerator::classifyBodyLine(' {{$certificateTitle}} '));
        $this->assertSame('body', CertificateGenerator::classifyBodyLine('Awarded for 1 review in {{$reviewMonthYear}}'));
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

        // Text exactly as wide as the cell still wraps in MultiCell because of the
        // cell padding, so it must shrink rather than keep its size
        $pdf->SetFont('helvetica', 'B', 25);
        $exact = $pdf->GetStringWidth('Dr. Jane Smith');
        $this->assertLessThan(25.0, $fit->invoke($generator, $pdf, 'Dr. Jane Smith', 'B', 25, 15, $exact));
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

    private function recognitionSettings(array $overrides = array())
    {
        return $overrides + array(
            'headerText' => 'Certificate of Reviewing',
            'bodyTemplate' => "{{\$journalName}}\n\n{{\$certificateTitle}}\n\nAwarded for 1 review in {{\$reviewMonthYear}}\npresented to\n\n{{\$reviewerName}}\n\nin recognition of the review contributed to the journal",
            'footerText' => 'The Editors of {{$journalName}}',
            'titleFontSize' => 46, 'titleBold' => 0, 'titleColor' => '#1B6F8A',
            'nameUppercase' => 1,
            'footerFontSize' => 13, 'footerBold' => 1, 'footerPosition' => 'bottomLeft', 'footerBottomSpacing' => 24,
            'sideMargin' => 55,
        );
    }

    public function testTitlePlaceholderMovesTheTitleBelowTheJournalName(): void
    {
        list(, $cells) = $this->render($this->generator($this->recognitionSettings()));

        $titles = array_values(array_filter($cells, function ($c) { return $c[0] === 'Certificate of Reviewing'; }));
        $this->assertCount(1, $titles, 'The title is drawn once, where the placeholder is, not also at the top');
        $this->assertGreaterThan($this->cell($cells, 'Journal of Testing')[3], $titles[0][3]);
        $this->assertSame('', $titles[0][2], 'Title bold can be turned off');
        foreach ($cells as $cell) {
            $this->assertStringNotContainsString('certificateTitle', $cell[0]);
        }
    }

    public function testRoleColourIsAppliedAndRestored(): void
    {
        list(, $cells) = $this->render($this->generator($this->recognitionSettings(array('textColorR' => 34, 'textColorG' => 34, 'textColorB' => 34))));

        $this->assertStringContainsString(sprintf('%.6F %.6F %.6F rg', 27 / 255, 111 / 255, 138 / 255), $this->cell($cells, 'Certificate of Reviewing')[4]);
        $default = sprintf('%.6F %.6F %.6F rg', 34 / 255, 34 / 255, 34 / 255);
        $this->assertStringContainsString($default, $this->cell($cells, 'presented to')[4]);
        $this->assertStringContainsString($default, $this->cell($cells, 'DR. JANE SMITH')[4]);
    }

    public function testReviewerNameCanBeUppercased(): void
    {
        list(, $cells) = $this->render($this->generator($this->recognitionSettings()));
        $this->assertSame('B', $this->cell($cells, 'DR. JANE SMITH')[2]);
    }

    public function testFooterCanBeAnchoredBottomLeft(): void
    {
        list($pdf, $cells) = $this->render($this->generator($this->recognitionSettings()));
        $footer = $this->cell($cells, 'The Editors of Journal of Testing');

        $this->assertSame('L', $footer[5]);
        $this->assertSame(13.0, (float) $footer[1]);
        $this->assertSame('B', $footer[2]);
        // Pinned near the bottom edge, below every flowing element
        $this->assertGreaterThan($pdf->getPageHeight() * 0.75, $footer[3]);
        foreach ($cells as $cell) {
            if ($cell !== $footer) {
                $this->assertLessThan($footer[3], $cell[3]);
            }
        }
    }

    public function testStructuredStringSettingsAreSanitised(): void
    {
        $this->assertSame('#1b6f8a', CertificateGenerator::sanitizeStructuredStringSetting('titleColor', '1B6F8A'));
        $this->assertSame('#1b6f8a', CertificateGenerator::sanitizeStructuredStringSetting('titleColor', ' #1b6f8a '));
        $this->assertSame('', CertificateGenerator::sanitizeStructuredStringSetting('titleColor', 'red'));
        $this->assertSame('', CertificateGenerator::sanitizeStructuredStringSetting('titleColor', array('#000000')));
        $this->assertSame('bottomLeft', CertificateGenerator::sanitizeStructuredStringSetting('footerPosition', 'bottomLeft'));
        $this->assertSame('flow', CertificateGenerator::sanitizeStructuredStringSetting('footerPosition', 'top'));
    }

    public function testReviewMonthYearVariable(): void
    {
        $method = new \ReflectionMethod(CertificateGenerator::class, 'getTemplateVariables');
        $method->setAccessible(true);
        $this->assertSame(date('F Y'), $method->invoke($this->generator(array()))['reviewMonthYear']);
    }

    public function testTextThatFitsDoesNotWrap(): void
    {
        list(, $cells) = $this->render($this->generator($this->recognitionSettings()));
        $title = $this->cell($cells, 'Certificate of Reviewing');
        // One line: the next element starts within a single line height
        $next = $this->cell($cells, 'Awarded for 1 review');
        $this->assertLessThan($title[1] * 0.3528 * 1.25 * 1.5 + 12, $next[3] - $title[3]);
    }

    // ------------------------------------------------- logo / cover / seal images

    /**
     * Run applyImageOverlays() against a recording TCPDF; returns name => [x, y, w, h].
     */
    private function overlays(array $settings, $orientation = 'L')
    {
        $dir = CertificateGenerator::getBackgroundUploadDir(1);
        if (!is_dir($dir)) {
            mkdir($dir, 0755, true);
        }
        foreach (array('logo' => array(400, 400), 'cover' => array(300, 400), 'seal' => array(200, 200)) as $name => $dims) {
            $path = $dir . '/' . $name . '_test.png';
            $image = imagecreatetruecolor($dims[0], $dims[1]);
            imagepng($image, $path);
            imagedestroy($image);
            $this->overlayFiles[] = $path;
            if (!array_key_exists($name . 'Image', $settings)) {
                $settings[$name . 'Image'] = $path;
            }
        }
        $generator = new CertificateGenerator();
        $generator->setTemplateSettings($settings);
        $pdf = new class($orientation, 'mm', 'A4', true, 'UTF-8', false) extends \TCPDF {
            public $images = array();
            public function Image($file, $x = null, $y = null, $w = 0, $h = 0, $type = '', $link = '', $align = '', $resize = false, $dpi = 300, $palign = '', $ismask = false, $imgmask = false, $border = 0, $fitbox = false, $hidden = false, $fitonpage = false, $alt = false, $altimgs = array()) {
                $this->images[preg_replace('/_test\.png$/', '', basename($file))] = array($x, $y, $w, $h);
            }
        };
        $pdf->AddPage();
        $method = new \ReflectionMethod(CertificateGenerator::class, 'applyImageOverlays');
        $method->setAccessible(true);
        $method->invoke($generator, $pdf);
        return array($pdf, $pdf->images);
    }

    /** @var array */
    private $overlayFiles = array();

    protected function tearDown(): void
    {
        foreach ($this->overlayFiles as $file) {
            @unlink($file);
        }
        parent::tearDown();
    }

    public function testOverlaysUseAutomaticPositions(): void
    {
        list($pdf, $images) = $this->overlays(array());
        $w = $pdf->getPageWidth();
        $h = $pdf->getPageHeight();

        $this->assertEqualsWithDelta(array(14, 14, 46, 46), $images['logo'], 0.01, 'Logo top left, square image keeps its ratio');
        $this->assertEqualsWithDelta($w - 14 - 36, $images['cover'][0], 0.01, 'Cover top right');
        $this->assertEqualsWithDelta(48.0, $images['cover'][3], 0.01, '300x400 cover at 36 mm wide is 48 mm tall');
        $this->assertEqualsWithDelta(array($w - 14 - 36, $h - 14 - 36), array_slice($images['seal'], 0, 2), 0.01, 'Seal bottom right without QR');
    }

    public function testSealMovesLeftOfTheQrCode(): void
    {
        list($pdf, $images) = $this->overlays(array('includeQRCode' => true));
        $qrLeft = $pdf->getPageWidth() - CertificateGenerator::QR_SIZE - CertificateGenerator::QR_MARGIN;
        $this->assertLessThan($qrLeft, $images['seal'][0] + $images['seal'][2], 'Seal must end before the QR code starts');
    }

    public function testCertificateCodeMovesUnderTheQrCode(): void
    {
        list(, $cells) = $this->render($this->generator(array('includeQRCode' => true)));
        foreach ($cells as $cell) {
            $this->assertStringNotContainsString('Certificate Code', $cell[0], 'With the QR code on, the code is printed under it, not in the body');
        }
        list(, $cells) = $this->render($this->generator(array()));
        $this->assertSame('Certificate Code: PREVIEW12345', $this->cell($cells, 'Certificate Code')[0], 'Without the QR code the code stays in the body');
    }

    public function testOverlayManualPositionAndPortraitSafety(): void
    {
        list(, $images) = $this->overlays(array('sealX' => 100, 'sealY' => 150, 'sealWidth' => 40));
        $this->assertEqualsWithDelta(array(100, 150, 40, 40), $images['seal'], 0.01);

        // A landscape X on a portrait page is pulled back onto the page
        list($pdf, $images) = $this->overlays(array('coverX' => 260), 'P');
        $this->assertLessThanOrEqual($pdf->getPageWidth(), $images['cover'][0] + $images['cover'][2]);
    }

    public function testOverlayOutsideJournalFilesIsIgnored(): void
    {
        list(, $images) = $this->overlays(array('logoImage' => '/etc/passwd', 'coverImage' => '', 'sealImage' => ''));
        $this->assertSame(array(), $images);
    }

    public function testHashLineIsTheTitleAndReplacesTheHeader(): void
    {
        $this->assertSame('title', CertificateGenerator::classifyBodyLine('# Certificate of Reviewing'));
        $this->assertSame('title', CertificateGenerator::classifyBodyLine('  #Certificate'));
        $this->assertSame('body', CertificateGenerator::classifyBodyLine('Issue #5 of the year'));

        list(, $cells) = $this->render($this->generator($this->recognitionSettings(array(
            'headerText' => 'Old header that must not be drawn',
            'bodyTemplate' => "{{\$journalName}}\n\n# Certificate of Reviewing for {{\$journalAcronym}}\n\n{{\$reviewerName}}",
        ))));
        foreach ($cells as $cell) {
            $this->assertStringNotContainsString('Old header', $cell[0]);
            $this->assertStringNotContainsString('#', $cell[0]);
        }
        $title = $this->cell($cells, 'Certificate of Reviewing for');
        $this->assertStringContainsString(sprintf('%.6F %.6F %.6F rg', 27 / 255, 111 / 255, 138 / 255), $title[4], 'Drawn in the title style');
        $this->assertGreaterThan($this->cell($cells, 'Journal of Testing')[3], $title[3]);
    }

    public function testFooterIsWrittenInTheBodyBelowADashLine(): void
    {
        $this->assertSame(array("Body", "Footer"), CertificateGenerator::splitBodyFooter("Body\n---\nFooter"));
        $this->assertSame(array("Body", "Footer"), CertificateGenerator::splitBodyFooter("Body\r\n\r\n ----- \r\nFooter"));
        $this->assertSame(array("No footer", null), CertificateGenerator::splitBodyFooter("No footer"));
        $this->assertSame(array("a --- b", null), CertificateGenerator::splitBodyFooter("a --- b"));

        list($pdf, $cells) = $this->render($this->generator($this->recognitionSettings(array(
            'footerText' => 'Old footer that must not be drawn',
            'bodyTemplate' => "{{\$journalName}}\n\n# Certificate of Reviewing\n\n{{\$reviewerName}}\n\n---\nThe Editors of {{\$journalName}}",
        ))));
        foreach ($cells as $cell) {
            $this->assertStringNotContainsString('Old footer', $cell[0]);
            $this->assertStringNotContainsString('---', $cell[0]);
        }
        $footer = $this->cell($cells, 'The Editors of Journal of Testing');
        $this->assertSame('L', $footer[5], 'Uses the footer position');
        $this->assertSame(13.0, (float) $footer[1], 'Uses the footer style');
        $this->assertGreaterThan($pdf->getPageHeight() * 0.75, $footer[3]);
    }
}
