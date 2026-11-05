<?php
/**
 * Revocation, annual certificates, verify-page privacy, CSV export and
 * account merges (v1.16.0).
 */

require_once dirname(__FILE__) . '/../bootstrap.php';
require_once BASE_SYS_DIR . '/controllers/CertificateHandler.php';
require_once BASE_SYS_DIR . '/classes/ReviewerCertificatePluginCore.php';
require_once BASE_SYS_DIR . '/classes/CertificateGenerator.php';

use APP\plugins\generic\reviewerCertificate\controllers\CertificateHandler;
use APP\plugins\generic\reviewerCertificate\classes\CertificateGenerator;

class CertificateFeaturesTest extends TestCase
{
    private function plugin()
    {
        return new class extends \APP\plugins\generic\reviewerCertificate\ReviewerCertificatePlugin {
            public $settings = [];
            public function getSetting($contextId, $name) { return $this->settings[$contextId][$name] ?? null; }
            public function updateSetting($contextId, $name, $value, $type = null) { $this->settings[$contextId][$name] = $value; }
        };
    }

    public function testRevokeAndRestoreArePerJournal(): void
    {
        $plugin = $this->plugin();
        $this->assertFalse($plugin->isCertificateRevoked(2, 11));
        $plugin->setCertificateRevoked(2, 11, true, '<b>Duplicate</b> review');
        $this->assertTrue($plugin->isCertificateRevoked(2, 11));
        $this->assertFalse($plugin->isCertificateRevoked(3, 11), 'Revocation must not leak to another journal');
        $this->assertSame('Duplicate review', $plugin->getRevokedCertificates(2)[11]['reason']);
        $plugin->setCertificateRevoked(2, 11, false);
        $this->assertFalse($plugin->isCertificateRevoked(2, 11));
        $this->assertSame([], $plugin->getRevokedCertificates(2));
    }

    public function testMergeUsersMovesCertificates(): void
    {
        $dao = new class extends \APP\plugins\generic\reviewerCertificate\classes\CertificateDAO {
            public $calls = [];
            public function __construct() {}
            public function update($sql, $params = [], $callHooks = true, $dieOnError = true) {
                $this->calls[] = [$sql, $params];
                return 1;
            }
        };
        $previous = \PKP\db\DAORegistry::getDAO('CertificateDAO');
        \PKP\db\DAORegistry::registerDAO('CertificateDAO', $dao);
        try {
            $this->assertFalse($this->plugin()->handleMergeUsers('UserAction::mergeUsers', [5, 9]));
            $this->assertCount(1, $dao->calls);
            $this->assertStringContainsString('UPDATE reviewer_certificates SET reviewer_id = ?', $dao->calls[0][0]);
            $this->assertSame([9, 5], $dao->calls[0][1]);
            $this->plugin()->handleMergeUsers('UserAction::mergeUsers', [5, 5]);
            $this->assertCount(1, $dao->calls, 'Merging a user into itself changes nothing');
        } finally {
            \PKP\db\DAORegistry::registerDAO('CertificateDAO', $previous);
        }
    }

    public function testVerifyPageNameDisplay(): void
    {
        $this->assertSame('Jane Smith', CertificateHandler::displayName('Jane Smith', 'full'));
        $this->assertSame('Jane Smith', CertificateHandler::displayName('Jane Smith', null));
        $this->assertSame('J. S.', CertificateHandler::displayName('Jane Smith', 'initials'));
        $this->assertSame('J. M. S.', CertificateHandler::displayName('jane mary-smith', 'initials'));
        $this->assertSame('王**', CertificateHandler::displayName('王小明', 'initials'));
        $this->assertSame('', CertificateHandler::displayName('Jane Smith', 'hidden'));
        $this->assertSame('initials', CertificateGenerator::sanitizeStructuredStringSetting('verifyNameDisplay', 'initials'));
        $this->assertSame('full', CertificateGenerator::sanitizeStructuredStringSetting('verifyNameDisplay', 'everything'));
    }

    public function testCsvCellsCannotStartFormulas(): void
    {
        $this->assertSame("'=HYPERLINK(1)", CertificateHandler::csvSafe('=HYPERLINK(1)'));
        $this->assertSame("'+1", CertificateHandler::csvSafe('+1'));
        $this->assertSame("'@cmd", CertificateHandler::csvSafe('@cmd'));
        $this->assertSame('Jane', CertificateHandler::csvSafe('Jane'));
        $this->assertSame('', CertificateHandler::csvSafe(''));
    }

    public function testNewOpsAreRoleScoped(): void
    {
        $handler = new CertificateHandler();
        $prop = new \ReflectionProperty(get_parent_class($handler), '_roleAssignments');
        $prop->setAccessible(true);
        $assignments = $prop->getValue($handler);
        foreach (['exportCertificates', 'revokeCertificate', 'managerDownload', 'manage'] as $op) {
            $this->assertContains($op, $assignments[ROLE_ID_MANAGER]);
            $this->assertNotContains($op, $assignments[ROLE_ID_REVIEWER]);
        }
        $this->assertContains('annualCertificate', $assignments[ROLE_ID_REVIEWER]);
        $this->assertNotContains('preview', $assignments[ROLE_ID_REVIEWER], 'The unused preview op stays removed');
    }

    public function testAnnualCertificateUsesExtraVariablesWithoutCode(): void
    {
        $generator = new CertificateGenerator();
        $generator->setPreviewMode(true);
        $generator->setContext(new class {
            public function getLocalizedName() { return 'Test Journal'; }
            public function getData($key) { return null; }
            public function getId() { return 2; }
            public function getPath() { return 'testjournal'; }
        });
        $generator->setTemplateSettings(['fontFamily' => 'helvetica', 'headerText' => 'Certificate',
            'bodyTemplate' => CertificateGenerator::getDefaultAnnualBodyTemplate(), 'footerText' => '']);
        $generator->setExtraVariables(['reviewCount' => 7, 'reviewYear' => 2026]);
        $text = $generator->renderText(CertificateGenerator::getDefaultAnnualBodyTemplate());
        $this->assertStringContainsString('In recognition of 7 peer reviews', $text);
        $this->assertStringContainsString('in 2026', $text);
        $this->assertStringStartsWith('%PDF-', $generator->generatePDF());
    }
}
