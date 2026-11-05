<?php
/** Existing certificates remain selectable after the issuance threshold rises. */
require __DIR__ . '/configure-fixtures.php';
if (class_exists('PKP\\cliTool\\CommandLineTool')) {
    new class([]) extends \PKP\cliTool\CommandLineTool { public function execute() {} };
} else { new \CommandLineTool([]); }
require_once __DIR__ . '/../../classes/CertificateDAO.php';
require_once __DIR__ . '/../../classes/CertificateService.php';
$plugin = new class extends \APP\plugins\generic\reviewerCertificate\ReviewerCertificatePlugin {
    public function getSetting($contextId, $name) { return $name === 'minimumReviews' ? 99999 : parent::getSetting($contextId, $name); }
};
$plugin->register('generic', 'plugins/generic/reviewerCertificate', $context->getId());
$dao = new \APP\plugins\generic\reviewerCertificate\classes\CertificateDAO();
\PKP\db\DAORegistry::registerDAO('CertificateDAO', $dao);
$reviewerId = $db->table('users')->where('username', 'testreviewer')->value('user_id');
$reviewId = $db->table('review_assignments')->where('reviewer_id', $reviewerId)->whereNotNull('date_completed')->value('review_id');
$db->beginTransaction();
try {
    (new \APP\plugins\generic\reviewerCertificate\classes\CertificateService($dao, $context->getId(), 1))->issue($reviewId, $reviewerId);
    // The pickers live on the Certificate Management page; the plugin builds them.
    $historical = $plugin->getEligibleReviewers($context->getId(), true);
    if (!in_array($reviewerId, array_column($historical, 'id'))) { throw new RuntimeException('Historical certificate hidden by raised threshold'); }
    $eligible = $plugin->getEligibleReviewers($context->getId(), false);
    if (in_array($reviewerId, array_column($eligible, 'id'))) { throw new RuntimeException('Raised issuance threshold ignored'); }
    echo "PASS: historical picker preserves issued certificates without relaxing issuance threshold\n";
} finally { $db->rollBack(); }
