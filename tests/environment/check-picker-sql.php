<?php
/** Included by check-postgres.php inside its disposable schema, after issuance. */

// Execute the production SQL through the real DAO. Capture database rows before
// user-name hydration, which needs a complete OJS user/settings schema. The full
// MySQL UI/hydration path is covered by check-picker.php and the browser suite.
$pickerDao = new class extends \APP\plugins\generic\reviewerCertificate\classes\CertificateDAO {
    public $rows = [];
    public function retrieve($sql, $params = [], $callHooks = true): \Generator {
        $this->rows = [];
        foreach (parent::retrieve($sql, $params, $callHooks) as $row) { $this->rows[] = $row; }
        yield from [];
    }
};
\PKP\db\DAORegistry::registerDAO('CertificateDAO', $pickerDao);
// The picker query lives on the plugin (Certificate Management page). Skip the
// plugin constructor and stub the minimum review setting.
$pickerPlugin = new class extends \APP\plugins\generic\reviewerCertificate\ReviewerCertificatePlugin {
    public $minimum = 1;
    public function __construct() {}
    public function getSetting($contextId, $name) { return $this->minimum; }
};
$db->beginTransaction();
try {
    $db->table('users')->insert(['user_id' => 4]);
    $db->table('journals')->insert(['journal_id' => 2]);
    $db->table('submissions')->insert(['submission_id' => 3, 'context_id' => 2]);
    foreach ([
        [8, 2, 3, '2026-09-02 00:00:00', 0, 0], // same reviewer; missing certificate
        [9, 2, 4, null, 0, 0],                  // incomplete
        [10, 2, 3, '2026-09-02 00:00:00', 1, 0], // declined
        [11, 2, 3, '2026-09-02 00:00:00', 0, 1], // cancelled
        [12, 3, 4, '2026-09-02 00:00:00', 0, 0], // another journal
    ] as $values) {
        $db->table('review_assignments')->insert(array_combine(
            ['review_id', 'submission_id', 'reviewer_id', 'date_completed', 'declined', 'cancelled'], $values));
    }
    $pickerPlugin->getEligibleReviewers(1, false);
    check(count($pickerDao->rows) === 1, 'Picker included an ineligible or cross-journal reviewer');
    $row = $pickerDao->rows[0];
    check((int) $row->reviewer_id === 3 && (int) $row->completed_reviews === 2
        && (int) $row->missing_certificates === 1, 'Picker aggregates are incorrect');
    $pickerPlugin->minimum = 3;
    $pickerPlugin->getEligibleReviewers(1, false);
    check($pickerDao->rows === [], 'Picker ignored the minimum review count');
    $pickerPlugin->getEligibleReviewers(1, true);
    check(count($pickerDao->rows) === 1 && (int) $pickerDao->rows[0]->reviewer_id === 3,
        'Historical picker lost existing certificates after threshold increase');
    echo "PASS: $driver production picker SQL uses portable HAVING and respects eligibility/history (PR #75)\n";
} finally { $db->rollBack(); }
