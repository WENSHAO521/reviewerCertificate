<?php
namespace APP\plugins\generic\reviewerCertificate\Tests\Unit;

use PHPUnit\Framework\TestCase;
use APP\plugins\generic\reviewerCertificate\classes\CertificateDateFormatter;

require_once dirname(__DIR__, 2) . '/classes/CertificateDateFormatter.php';

class CertificateDateFormatterTest extends TestCase {
    public function testEnglishIsTheDefaultAndMatchesEarlierVersions() {
        $this->assertSame('November 5, 2026', CertificateDateFormatter::format('2026-11-05 10:00:00'));
        $this->assertSame('November 2026', CertificateDateFormatter::format('2026-11-05', 'monthYear'));
        $this->assertSame('2026', CertificateDateFormatter::format('2026-11-05', 'year', 'zh'));
    }

    public function testChineseAndIsoFormats() {
        $this->assertSame('2026年11月5日', CertificateDateFormatter::format('2026-11-05', 'long', 'zh'));
        $this->assertSame('2026年11月', CertificateDateFormatter::format('2026-11-05', 'monthYear', 'zh'));
        $this->assertSame('2026-11-05', CertificateDateFormatter::format('2026-11-05', 'long', 'iso'));
        $this->assertSame('2026-11', CertificateDateFormatter::format('2026-11-05', 'monthYear', 'iso'));
    }

    public function testLocaleFollowsInterfaceLanguage() {
        $this->assertSame('2026年11月5日', CertificateDateFormatter::format('2026-11-05', 'long', 'locale', 'zh_TW'));
        $this->assertSame('2026年11月5日', CertificateDateFormatter::format('2026-11-05', 'long', 'locale', 'zh_Hant'));
        $this->assertSame('2026년 11월 5일', CertificateDateFormatter::format('2026-11-05', 'long', 'locale', 'ko'));
        $this->assertSame('November 5, 2026', CertificateDateFormatter::format('2026-11-05', 'long', 'locale', 'en_US'));
        $german = CertificateDateFormatter::format('2026-11-05', 'long', 'locale', 'de_DE');
        $this->assertNotSame('', $german);
        if (class_exists('IntlDateFormatter')) {
            $this->assertStringContainsString('November 2026', $german);
            $this->assertStringContainsString('5.', $german);
        }
    }

    public function testSettingsAreSanitized() {
        require_once dirname(__DIR__, 2) . '/classes/CertificateGenerator.php';
        $generator = \APP\plugins\generic\reviewerCertificate\classes\CertificateGenerator::class;
        $this->assertSame('zh', $generator::sanitizeStructuredStringSetting('dateFormat', 'zh'));
        $this->assertSame('en', $generator::sanitizeStructuredStringSetting('dateFormat', 'bogus'));
        $this->assertSame('en', $generator::sanitizeStructuredStringSetting('dateFormat', null));
        $this->assertSame('Certificate Code:', $generator::sanitizeStructuredStringSetting('certificateCodeLabel', ''));
        $this->assertSame('證書編號：', $generator::sanitizeStructuredStringSetting('certificateCodeLabel', ' <b>證書編號：</b> '));
    }
}
