<?php
/**
 * @file plugins/generic/reviewerCertificate/controllers/CertificateHandler.php
 *
 * Copyright (c) 2024
 * Modifications copyright (c) 2026 Panorama Scholarly Group Ltd. <contact@panorama-sg.com>
 * Distributed under the GNU GPL v3.
 *
 * @class CertificateHandler
 * @ingroup plugins_generic_reviewerCertificate
 *
 * @brief Handle requests for certificate operations
 */

namespace APP\plugins\generic\reviewerCertificate\controllers;

use APP\handler\Handler;
use APP\core\Application;
use PKP\security\Role;
use PKP\security\authorization\ContextAccessPolicy;
use PKP\db\DAORegistry;
use PKP\core\JSONMessage;
use PKP\plugins\PluginRegistry;
use APP\template\TemplateManager;
use Exception;

class CertificateHandler extends Handler {

    /** @var ReviewerCertificatePlugin */
    private $plugin;

    /**
     * Constructor
     */
    public function __construct() {
        parent::__construct();
        // OJS 3.3 defines role IDs as global constants via define();
        // OJS 3.4+ defines them as class constants on PKP\security\Role.
        // Note: class_exists('PKP\security\Role') returns true on OJS 3.3 due
        // to compat_autoloader aliasing, so check for the global constant instead.
        if (defined('ROLE_ID_REVIEWER')) {
            $this->addRoleAssignment(
                array(ROLE_ID_REVIEWER),
                array('download', 'myCertificates', 'emailCertificate', 'annualCertificate')
            );
            $this->addRoleAssignment(
                array(ROLE_ID_MANAGER, ROLE_ID_SITE_ADMIN),
                array('manage', 'generateBatch', 'exportCertificates', 'revokeCertificate', 'managerDownload')
            );
        } else {
            $this->addRoleAssignment(
                array(Role::ROLE_ID_REVIEWER),
                array('download', 'myCertificates', 'emailCertificate', 'annualCertificate')
            );
            $this->addRoleAssignment(
                array(Role::ROLE_ID_MANAGER, Role::ROLE_ID_SITE_ADMIN),
                array('manage', 'generateBatch', 'exportCertificates', 'revokeCertificate', 'managerDownload')
            );
        }
        // Make verify publicly accessible (no role restriction)
    }

    /**
     * @copydoc PKPHandler::authorize()
     */
    public function authorize($request, &$args, $roleAssignments) {
        $op = $request->getRequestedOp();

        // Allow public access to verify operation (no authentication required)
        if ($op === 'verify') {
            // Skip all authorization for verify - it's a public endpoint
            return true;
        }

        // For all other operations, require context access - OJS 3.4+/3.3 compatibility
        if (class_exists('PKP\security\authorization\ContextAccessPolicy')) {
            $this->addPolicy(new ContextAccessPolicy($request, $roleAssignments));
        } elseif (function_exists('import')) {
            import('lib.pkp.classes.security.authorization.ContextAccessPolicy');
            $this->addPolicy(new \ContextAccessPolicy($request, $roleAssignments));
        }

        return parent::authorize($request, $args, $roleAssignments);
    }

    /**
     * Set the plugin
     * @param $plugin ReviewerCertificatePlugin
     */
    public function setPlugin($plugin) {
        $this->plugin = $plugin;
    }

    /**
     * Get the plugin instance
     * @return ReviewerCertificatePlugin
     */
    private function getPlugin() {
        if (!$this->plugin) {
            // OJS 3.4+/3.3 compatibility
            if (class_exists('PKP\plugins\PluginRegistry')) {
                $this->plugin = PluginRegistry::getPlugin('generic', 'reviewercertificateplugin');
            } else {
                $this->plugin = \PluginRegistry::getPlugin('generic', 'reviewercertificateplugin');
            }
        }
        return $this->plugin;
    }

    /**
     * Ensure plugin locale data is loaded for the current request.
     * OJS 3.3 may fail to load locale files on public pages when registered
     * with relative paths during plugin bootstrap.
     */
    private function ensurePluginLocaleLoaded() {
        $plugin = $this->getPlugin();
        if (!$plugin) {
            return;
        }

        // Standard reload attempt
        if (method_exists($plugin, 'addLocaleData')) {
            $plugin->addLocaleData();
        }

        // Check if translations are actually available
        $testKey = 'plugins.generic.reviewerCertificate.verify.title';
        $translated = __($testKey);
        if ($translated === '##' . $testKey . '##') {
            // Translations still missing — manually register with absolute path.
            // OJS 3.3.0-22 uses .po files (via Gettext), not .xml.
            $localeDir = dirname(__DIR__) . '/locale';

            // Determine current locale
            $locale = 'en_US';
            if (class_exists('AppLocale', false)) {
                $currentLocale = \AppLocale::getLocale();
                if ($currentLocale) {
                    $locale = $currentLocale;
                }
            }

            // Register .po file with absolute path
            $localeFile = $localeDir . '/' . $locale . '/locale.po';
            if (file_exists($localeFile) && class_exists('AppLocale', false)) {
                \AppLocale::registerLocaleFile($locale, $localeFile);
            }

            // If locale was 'en', also try 'en_US' (or vice versa)
            if (strpos($locale, '_') === false) {
                $altLocale = $locale . '_US';
            } else {
                $altLocale = substr($locale, 0, 2);
            }
            $altFile = $localeDir . '/' . $altLocale . '/locale.po';
            if (file_exists($altFile) && class_exists('AppLocale', false)) {
                \AppLocale::registerLocaleFile($altLocale, $altFile);
            }
        }
    }

    /**
     * Download certificate
     * @param $args array
     * @param $request Request
     */
    public function download($args, $request) {
        $reviewId = isset($args[0]) ? (int) $args[0] : null;

        $reviewAssignment = $this->loadAuthorizedReviewAssignment($reviewId, $request, 'download');
        $certificate = $this->getOrCreateCertificate($reviewId, $reviewAssignment, $request->getContext());

        // Update download statistics
        $certificateDao = DAORegistry::getDAO('CertificateDAO');
        $certificate->incrementDownloadCount();
        $certificateDao->updateObject($certificate);

        // Generate PDF
        $this->generateAndOutputPDF($reviewAssignment, $certificate, $request->getContext());
    }

    /**
     * Load a review assignment and enforce ownership, completion and context
     * isolation. Shared by download() and emailCertificate().
     * @param $reviewId int|null
     * @param $request Request
     * @param $opLabel string For log messages
     * @return object ReviewAssignment(-like) object
     */
    private function loadAuthorizedReviewAssignment($reviewId, $request, $opLabel) {
        $user = $request->getUser();
        $context = $request->getContext();
        if (!$user || !$context) {
            http_response_code(403);
            throw new Exception('Forbidden', 403);
        }
        try {
            $row = $this->getPlugin()->getCertificateService($context->getId())->loadReview($reviewId, $user->getId());
            return DAORegistry::getDAO('CertificateDAO')->reviewAssignmentFromRow($row);
        } catch (\DomainException $e) {
            http_response_code($e->getCode());
            throw $e;
        }
    }

    private function getOrCreateCertificate($reviewId, $reviewAssignment, $context) {
        try {
            $result = $this->getPlugin()->getCertificateService($context->getId())->issue(
                $reviewId, $reviewAssignment->getReviewerId());
            if ($this->getPlugin()->isCertificateRevoked($context->getId(), $result['certificate']->getCertificateId())) {
                throw new \DomainException('Certificate revoked', 403);
            }
            return $result['certificate'];
        } catch (\DomainException $e) {
            http_response_code($e->getCode());
            throw $e;
        }
    }

    /**
     * Email the acknowledgement letter with the certificate PDF attached to
     * the logged-in reviewer. POST + CSRF only; reviewer role.
     * @param $args array [0] => review ID
     * @param $request Request
     */
    public function emailCertificate($args, $request) {
        $this->ensurePluginLocaleLoaded();

        if (strtoupper($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
            http_response_code(405);
            throw new Exception('Method not allowed', 405);
        }
        if (!method_exists($request, 'checkCSRF') || !$request->checkCSRF()) {
            error_log('Certificate email failed: CSRF check failed');
            http_response_code(403);
            throw new Exception('Forbidden', 403);
        }

        $reviewId = isset($args[0]) ? (int) $args[0] : null;
        $context = $request->getContext();
        $user = $request->getUser();

        $reviewAssignment = $this->loadAuthorizedReviewAssignment($reviewId, $request, 'email');
        $certificate = $this->getOrCreateCertificate($reviewId, $reviewAssignment, $context);

        // One letter per certificate per minute: a reviewer clicking the
        // button repeatedly should not burn the journal's SMTP quota.
        if (!$this->claimEmailSlot($request, (int) $certificate->getCertificateId())) {
            $request->redirect(null, 'certificate', 'myCertificates', null, array('emailThrottled' => 1));
            return;
        }

        // Build the PDF and the letter with the same variable engine
        $generator = $this->createConfiguredGenerator($reviewAssignment, $certificate, $context);
        try {
            $pdfContent = $generator->generatePDF();
        } catch (\Throwable $e) {
            error_log('ReviewerCertificate: email PDF generation failed: ' . $e->getMessage());
            $request->redirect(null, 'certificate', 'myCertificates', null, array('emailError' => 1));
            return;
        }

        $plugin = $this->getPlugin();
        $subjectTemplate = $plugin ? $plugin->getSetting($context->getId(), 'ackEmailSubject') : null;
        $bodyTemplate = $plugin ? $plugin->getSetting($context->getId(), 'ackEmailBody') : null;
        if (!$subjectTemplate) {
            $subjectTemplate = __('plugins.generic.reviewerCertificate.emailCertificate.defaultSubject');
        }
        if (!$bodyTemplate) {
            $bodyTemplate = __('plugins.generic.reviewerCertificate.emailCertificate.defaultBody');
        }

        $subject = $generator->renderText($subjectTemplate);
        $body = $generator->renderText($bodyTemplate);
        $fileName = 'reviewer_certificate_' . $certificate->getCertificateId() . '.pdf';

        $downloadUrl = $request->url(null, 'certificate', 'download', array($reviewId));
        $sent = $this->sendAcknowledgementWithFallback($user, $context, $subject, $body, $pdfContent, $fileName, $request, $downloadUrl);

        $request->redirect(
            null, 'certificate', 'myCertificates', null,
            $sent ? array('emailSent' => 1) : array('emailError' => 1)
        );
    }

    /** Seconds a reviewer must wait before emailing the same certificate again. */
    const EMAIL_INTERVAL = 60;

    /**
     * Rate-limit the email action per certificate using the user's session
     * (OJS 3.3/3.4 PKP Session, OJS 3.5 Laravel session).
     * @return bool true when sending is allowed now
     */
    private function claimEmailSlot($request, $certificateId) {
        $key = 'reviewerCertificateEmail' . (int) $certificateId;
        try {
            $session = method_exists($request, 'getSession') ? $request->getSession() : null;
            if (!$session) {
                return true;
            }
            if (method_exists($session, 'getSessionVar')) {
                $last = (int) $session->getSessionVar($key);
                if ($last && time() - $last < self::EMAIL_INTERVAL) {
                    return false;
                }
                $session->setSessionVar($key, time());
            } elseif (method_exists($session, 'get') && method_exists($session, 'put')) {
                $last = (int) $session->get($key);
                if ($last && time() - $last < self::EMAIL_INTERVAL) {
                    return false;
                }
                $session->put($key, time());
            }
        } catch (\Throwable $e) {
            // Never block the email because the session is unavailable
        }
        return true;
    }

    /**
     * Send the acknowledgement letter, falling back to a link-only letter
     * when the transport rejects the attached one (e.g. SMTP 552 size limit
     * — SendPulse rejected iitlt's certificate PDFs this way while pkp-lib
     * swallowed the error).
     * @param $user User Recipient (the reviewer)
     * @param $context Context
     * @param $subject string Rendered subject
     * @param $body string Rendered plain-text body
     * @param $pdfContent string PDF bytes to attach
     * @param $fileName string Attachment file name
     * @param $request Request
     * @param $downloadUrl string Absolute URL of the certificate download
     * @return bool True when either the attached or the link-only letter was sent
     */
    private function sendAcknowledgementWithFallback($user, $context, $subject, $body, $pdfContent, $fileName, $request, $downloadUrl) {
        $sent = false;
        try {
            $sent = $this->sendAcknowledgementEmail($user, $context, $subject, $body, $pdfContent, $fileName, $request);
        } catch (\Throwable $e) {
            error_log('ReviewerCertificate: acknowledgement email failed: ' . $e->getMessage());
        }
        if ($sent) {
            return true;
        }

        error_log('ReviewerCertificate: attached acknowledgement email failed; retrying without the PDF attachment');
        $fallbackBody = $body . "\n\n"
            . __('plugins.generic.reviewerCertificate.emailCertificate.attachmentFallback') . "\n"
            . $downloadUrl;
        try {
            return $this->sendAcknowledgementEmail($user, $context, $subject, $fallbackBody, null, null, $request);
        } catch (\Throwable $e) {
            error_log('ReviewerCertificate: link-only acknowledgement email failed: ' . $e->getMessage());
            return false;
        }
    }

    /**
     * Send the acknowledgement letter (version-branched mail APIs).
     * @param $user User Recipient (the reviewer)
     * @param $context Context
     * @param $subject string Rendered subject
     * @param $body string Rendered plain-text body
     * @param $pdfContent string|null PDF bytes to attach, or null for no attachment
     * @param $fileName string|null Attachment file name (null with $pdfContent)
     * @param $request Request
     * @return bool
     */
    private function sendAcknowledgementEmail($user, $context, $subject, $body, $pdfContent, $fileName, $request) {
        require_once dirname(__DIR__) . '/classes/CertificateMailAdapter.php';
        $adapter = new \APP\plugins\generic\reviewerCertificate\classes\CertificateMailAdapter();
        return $adapter->send($user, $context, $subject, nl2br(htmlspecialchars($body, ENT_QUOTES, 'UTF-8')),
            $pdfContent, $fileName, $request);
    }

    /**
     * Context setting accessor compatible with OJS 3.3 (getSetting) and
     * 3.4+/3.5 (getData).
     */
    private function getContextSettingCompat($context, $name) {
        try {
            if (method_exists($context, 'getData')) {
                $value = $context->getData($name);
                if ($value) {
                    return is_array($value) ? (string) reset($value) : (string) $value;
                }
            }
            if (method_exists($context, 'getSetting')) {
                $value = $context->getSetting($name);
                if ($value) {
                    return is_array($value) ? (string) reset($value) : (string) $value;
                }
            }
        } catch (\Throwable $e) {
            // ignore
        }
        return '';
    }

    /**
     * Verify certificate
     * @param $args array
     * @param $request Request
     */
    protected static function parseVerificationCode($args, $request) {
        $code = $args[0] ?? $request->getUserVar('code');
        // Reject malformed explicit input; never let a URI fallback mask it.
        if ($code !== null && !is_string($code)) { return null; }
        if ($code === null || $code === '') {
            $uri = $_SERVER['REQUEST_URI'] ?? '';
            if (is_string($uri) && preg_match('~/certificate/verify/([A-Fa-f0-9]{8,32})(?:[/?#]|$)~', $uri, $matches)) {
                $code = $matches[1];
            } elseif (isset($_GET['code']) && is_string($_GET['code'])) {
                $code = $_GET['code'];
            }
        }
        return is_string($code) && preg_match('/^[A-Fa-f0-9]{8,32}$/D', trim($code))
            ? strtoupper(trim($code)) : null;
    }

    public function verify($args, $request) {
        // OJS 3.3 compatibility: ensure plugin locale is loaded for public pages
        $this->ensurePluginLocaleLoaded();

        $certificateCode = self::parseVerificationCode($args, $request);

        $templateMgr = TemplateManager::getManager($request);
        $templateMgr->assign('certificateCode', $certificateCode);

        if ($certificateCode) {
            // Lookup certificate
            $certificateDao = DAORegistry::getDAO('CertificateDAO');
            if (!$certificateDao) {
                $templateMgr->assign('isValid', false);
            } else {
                $certificate = $certificateDao->getByCertificateCode($certificateCode);

                // Verify certificate belongs to current journal context
                if ($certificate) {
                    $context = $request->getContext();
                    if (!$context || (int)$certificate->getContextId() !== (int)$context->getId()) {
                        $certificate = null; // Not from this journal
                    }
                }

                if ($certificate) {
                    // Get reviewer and context information - OJS 3.3 compatibility
                    if (class_exists('APP\facades\Repo')) {
                        $reviewer = \APP\facades\Repo::user()->get($certificate->getReviewerId());
                    } else {
                        $userDao = DAORegistry::getDAO('UserDAO');
                        $reviewer = $userDao->getById($certificate->getReviewerId());
                    }

                    // OJS 3.4+/3.3 compatibility
                    if (class_exists('APP\core\Application')) {
                        $contextDao = Application::getContextDAO();
                    } else {
                        $contextDao = \Application::getContextDAO();
                    }
                    $certContext = $contextDao->getById($certificate->getContextId());

                    if ($reviewer && $certContext) {
                        // Assign valid certificate data to template
                        $templateMgr->assign('isValid', true);
                        $plugin = $this->getPlugin();
                        $nameDisplay = $plugin ? $plugin->getSetting($certContext->getId(), 'verifyNameDisplay') : null;
                        $templateMgr->assign('reviewerName', self::displayName($reviewer->getFullName(), $nameDisplay));
                        $templateMgr->assign('showReviewerName', $nameDisplay !== 'hidden');
                        $revocation = $plugin ? ($plugin->getRevokedCertificates($certContext->getId())[(int) $certificate->getCertificateId()] ?? null) : null;
                        $templateMgr->assign('isRevoked', $revocation !== null);
                        $templateMgr->assign('dateRevoked', $revocation && !empty($revocation['date']) ? $this->formatUiDate($revocation['date']) : '');
                        // Use review completion date (matches PDF content), fall back to certificate issuance date.
                        // date_issued is the DB row creation time which may be identical for batch-generated certs.
                        $displayDate = $certificate->getDateIssued();
                        $reviewId = $certificate->getReviewId();
                        if ($reviewId) {
                            $raResult = $certificateDao->retrieve(
                                'SELECT date_completed FROM review_assignments WHERE review_id = ?',
                                array((int) $reviewId)
                            );
                            $raRow = $raResult->current();
                            if ($raRow) {
                                $raRow = (array) $raRow;
                                if (!empty($raRow['date_completed'])) {
                                    $displayDate = $raRow['date_completed'];
                                }
                            }
                        }
                        $formattedDate = $this->formatUiDate($displayDate);
                        $templateMgr->assign('dateIssued', $formattedDate);
                        $templateMgr->assign('journalName', $certContext->getLocalizedName());
                    } else {
                        $templateMgr->assign('isValid', false);
                    }
                } else {
                    // Invalid certificate
                    $templateMgr->assign('isValid', false);
                }
            }
        }

        // Display verification page
        // Get plugin instance and use its template resource
        $plugin = $this->getPlugin();
        if ($plugin) {
            $templateResource = $plugin->getTemplateResource('verify.tpl');
            return $templateMgr->display($templateResource);
        } else {
            // Fallback: construct absolute path
            // Plugin not available - use absolute path as last resort
            $pluginPath = dirname(__FILE__) . '/../templates/verify.tpl';

            // Check if file exists
            if (file_exists($pluginPath)) {
                return $templateMgr->display('file:' . $pluginPath);
            } else {
                error_log('ReviewerCertificate: ERROR - Template file not found at: ' . $pluginPath);
                echo '<p>Error: Certificate verification template not found.</p>';
                return;
            }
        }
    }

    /**
     * List all certificates for the current reviewer.
     * @param $args array
     * @param $request Request
     */
    public function myCertificates($args, $request) {
        $this->ensurePluginLocaleLoaded();

        $user = $request->getUser();
        $context = $request->getContext();

        if (!$user || !$context) {
            $request->redirect(null, 'login');
            return;
        }

        $certificateDao = DAORegistry::getDAO('CertificateDAO');
        if (!$certificateDao) {
            echo '<p>Error: Certificate system not available.</p>';
            return;
        }

        // Get current locale for title lookup
        $locale = $this->getCurrentLocale();

        // The side-menu entry appears as soon as the reviewer has a completed
        // review, but certificates used to be created only by the review
        // completion hook. Issue any that are missing (reviews completed
        // before the plugin was installed, or a hook that did not run) so the
        // page is never empty for an eligible reviewer.
        $completedReviews = 0;
        $minimumReviews = 1;
        try {
            $service = $this->getPlugin()->getCertificateService($context->getId());
            $service->issueMissing($user->getId());
            $completedReviews = $service->completedCount($user->getId());
            $minimumReviews = $service->getMinimum();
        } catch (\Throwable $e) {
            error_log('ReviewerCertificate: could not issue missing certificates: ' . $e->getMessage());
        }

        // Query certificates with review completion dates via direct SQL.
        // Pattern 3 (direct SQL for OJS 3.5) + Pattern 5 (context isolation via submissions join).
        // Join review_assignments to get date_completed (the actual review date shown in PDFs),
        // falling back to rc.date_issued when review_assignment is missing.
        $result = $certificateDao->retrieve(
            'SELECT rc.certificate_id, rc.review_id, rc.submission_id, rc.date_issued,
                    rc.certificate_code, rc.download_count,
                    ra.date_completed AS review_date_completed
             FROM reviewer_certificates rc
             INNER JOIN submissions s ON rc.submission_id = s.submission_id
             LEFT JOIN review_assignments ra ON rc.review_id = ra.review_id
             WHERE rc.reviewer_id = ? AND rc.context_id = ? AND s.context_id = ?
             ORDER BY COALESCE(ra.date_completed, rc.date_issued) DESC
             LIMIT 500',
            array(
                (int) $user->getId(),
                (int) $context->getId(),
                (int) $context->getId()
            )
        );

        $certificates = array();
        $annualYears = array();
        $revoked = $this->getPlugin()->getRevokedCertificates($context->getId());
        if ($result) {
            foreach ($result as $row) {
                $row = (array) $row;
                $title = $this->getSubmissionTitleForListing($certificateDao, (int) $row['submission_id'], $locale);
                // Use review completion date (matches PDF content), fall back to certificate issuance date
                $displayDate = !empty($row['review_date_completed'])
                    ? $row['review_date_completed']
                    : $row['date_issued'];
                $certificates[] = array(
                    'certificateId' => $row['certificate_id'],
                    'reviewId' => $row['review_id'],
                    'submissionTitle' => $title,
                    'dateIssued' => $this->formatUiDate($displayDate),
                    'downloadUrl' => $request->url(null, 'certificate', 'download', array($row['review_id'])),
                    'emailUrl' => $request->url(null, 'certificate', 'emailCertificate', array($row['review_id'])),
                    'certificateCode' => $row['certificate_code'],
                    'revoked' => isset($revoked[(int) $row['certificate_id']]),
                );
                if (!isset($revoked[(int) $row['certificate_id']]) && !empty($row['review_date_completed'])) {
                    $year = (int) date('Y', strtotime($row['review_date_completed']));
                    $annualYears[$year] = ($annualYears[$year] ?? 0) + 1;
                }
            }
        }

        $templateMgr = TemplateManager::getManager($request);
        $templateMgr->assign('certificates', $certificates);
        // Annual summary certificates: one per year with at least one certificate
        krsort($annualYears);
        $annual = array();
        foreach ($annualYears as $year => $count) {
            $annual[] = array('year' => $year, 'count' => $count,
                'url' => $request->url(null, 'certificate', 'annualCertificate', array($year)));
        }
        $templateMgr->assign('annualCertificates', $annual);
        $templateMgr->assign('cumulativeCertificate', $annualYears ? array(
            'status' => $this->reviewerStatus($context, $user->getId()),
            'count' => array_sum($annualYears),
            'url' => $request->url(null, 'certificate', 'annualCertificate', array('all')),
        ) : null);
        // Explain an empty list when the journal requires more reviews
        $templateMgr->assign('certificatesPending', !$certificates && $completedReviews > 0 && $completedReviews < $minimumReviews);
        $templateMgr->assign('completedReviews', $completedReviews);
        $templateMgr->assign('minimumReviews', $minimumReviews);
        // Result banners after the email action (redirect flags)
        $templateMgr->assign('certificateEmailSent', (bool) $request->getUserVar('emailSent'));
        $templateMgr->assign('certificateEmailError', (bool) $request->getUserVar('emailError'));
        $templateMgr->assign('certificateEmailThrottled', (bool) $request->getUserVar('emailThrottled'));

        // Render inside the OJS backend layout, like the side-menu entry that
        // links here, so the page uses OJS's default styles and colours rather
        // than the journal's frontend theme. setupBackendPage() loads the
        // backend assets and side menu on OJS 3.3, 3.4 and 3.5.
        //
        // setupBackendPage() reads the 'userRoles' template variable
        // (in_array(ROLE_ID_SITE_ADMIN, $userRoles)), which only
        // PKPHandler::setupTemplate() assigns. Without it the value is null
        // and PHP 8 throws a TypeError, so the page returned HTTP 500 in
        // v1.15.0. Call setupTemplate() first, as OJS's own backend
        // handlers do, and make sure the variable is an array regardless.
        $this->setupTemplate($request);
        if (!is_array($templateMgr->getTemplateVars('userRoles'))) {
            $userRolesAssoc = defined('ASSOC_TYPE_USER_ROLES')
                ? ASSOC_TYPE_USER_ROLES
                : \APP\core\Application::ASSOC_TYPE_USER_ROLES;
            $templateMgr->assign('userRoles', (array) $this->getAuthorizedContextObject($userRolesAssoc));
        }
        $templateMgr->assign('pageTitle', __('plugins.generic.reviewerCertificate.myCertificates.title'));
        $templateMgr->setupBackendPage();

        $plugin = $this->getPlugin();
        if ($plugin) {
            return $templateMgr->display($plugin->getTemplateResource('myCertificates.tpl'));
        } else {
            $pluginPath = dirname(__FILE__) . '/../templates/myCertificates.tpl';
            if (file_exists($pluginPath)) {
                return $templateMgr->display('file:' . $pluginPath);
            }
        }
    }

    /**
     * Format a date in the reader's interface language (My Certificates, verify page).
     * @param string $date
     * @return string
     */
    private function formatUiDate($date) {
        require_once dirname(__DIR__) . '/classes/CertificateDateFormatter.php';
        return \APP\plugins\generic\reviewerCertificate\classes\CertificateDateFormatter::format(
            $date, 'long', 'locale', $this->getCurrentLocale());
    }

    /**
     * Get current locale with fallback
     * @return string
     */
    private function getCurrentLocale() {
        // OJS 3.4+/3.5: PKP\facades\Locale (Laravel facade)
        if (class_exists('PKP\facades\Locale')) {
            try {
                $locale = \PKP\facades\Locale::getLocale();
                if ($locale) {
                    return $locale;
                }
            } catch (\Throwable $e) {
                // ignore — facade not yet bootstrapped
            }
        }
        // OJS 3.3: AppLocale (global class, loaded during bootstrap)
        if (class_exists('AppLocale')) {
            try {
                $locale = \AppLocale::getLocale();
                if ($locale) {
                    return $locale;
                }
            } catch (\Throwable $e) {
                // ignore
            }
        }
        try {
            $request = Application::get()->getRequest();
            if (method_exists($request, 'getLocale')) {
                $locale = $request->getLocale();
                if ($locale) {
                    return $locale;
                }
            }
        } catch (\Throwable $e) {
            // ignore
        }
        return 'en_US';
    }

    /**
     * Get submission title for the listing page, with locale fallback.
     * @param $dao CertificateDAO
     * @param int $submissionId
     * @param string $locale
     * @return string
     */
    private function getSubmissionTitleForListing($dao, $submissionId, $locale) {
        try {
            // Try the requested locale first, then fall back to any locale
            $result = $dao->retrieve(
                'SELECT ps.setting_value, ps.locale FROM publication_settings ps
                 JOIN publications p ON p.publication_id = ps.publication_id
                 JOIN submissions s ON s.submission_id = p.submission_id
                 WHERE p.submission_id = ? AND ps.setting_name = ?
                 AND ps.setting_value IS NOT NULL AND ps.setting_value != ?
                 ORDER BY CASE WHEN p.publication_id = s.current_publication_id THEN 0 ELSE 1 END,
                          CASE WHEN ps.locale = ? THEN 0 ELSE 1 END, p.publication_id DESC, ps.locale
                 LIMIT 1',
                array((int) $submissionId, 'title', '', $locale)
            );
            if ($result) {
                foreach ($result as $row) {
                    $row = (array) $row;
                    return strip_tags($row['setting_value']);
                }
            }
        } catch (\Throwable $e) {
            // Fallback if publication_settings query fails (e.g. OJS 3.3 schema differences)
        }

        // Last resort: try submission_settings (OJS 3.3 stores titles differently)
        try {
            $result = $dao->retrieve(
                'SELECT setting_value FROM submission_settings
                 WHERE submission_id = ? AND setting_name = ?
                 AND setting_value IS NOT NULL AND setting_value != ?
                 LIMIT 1',
                array((int) $submissionId, 'title', '')
            );
            if ($result) {
                foreach ($result as $row) {
                    $row = (array) $row;
                    return strip_tags($row['setting_value']);
                }
            }
        } catch (\Throwable $e) {
            // ignore
        }

        return '(Untitled)';
    }

    /**
     * Generate and output PDF
     * @param $reviewAssignment ReviewAssignment
     * @param $certificate Certificate
     * @param $context Context
     */
    private function generateAndOutputPDF($reviewAssignment, $certificate, $context) {
        $generator = $this->createConfiguredGenerator($reviewAssignment, $certificate, $context);

        // Generate PDF
        try {
            $pdfContent = $generator->generatePDF();
        } catch (\Throwable $e) {
            error_log(sprintf(
                'ReviewerCertificate: PDF generation failed [%s]: %s in %s:%d | review_id=%s reviewer_id=%s',
                get_class($e),
                $e->getMessage(),
                $e->getFile(),
                $e->getLine(),
                $reviewAssignment ? $reviewAssignment->getId() : 'null',
                $reviewAssignment ? $reviewAssignment->getReviewerId() : 'null'
            ));
            http_response_code(500);
            echo 'An error occurred generating the certificate. Please try again later.';
            exit;
        }

        // Output PDF
        header('Content-Type: application/pdf');
        header('Content-Disposition: attachment; filename="reviewer_certificate_' . $certificate->getCertificateId() . '.pdf"');
        header('Content-Length: ' . strlen($pdfContent));
        header('Cache-Control: private, max-age=0, must-revalidate');
        header('Pragma: public');

        echo $pdfContent;
        exit;
    }

    /**
     * Build a fully configured CertificateGenerator for a review assignment.
     * Shared by download (output) and emailCertificate (attachment + letter).
     * @param $reviewAssignment object
     * @param $certificate Certificate
     * @param $context Context
     * @return \APP\plugins\generic\reviewerCertificate\classes\CertificateGenerator
     */
    private function createConfiguredGenerator($reviewAssignment, $certificate, $context) {
        require_once(dirname(__FILE__) . '/../classes/CertificateGenerator.php');
        $generator = new \APP\plugins\generic\reviewerCertificate\classes\CertificateGenerator();

        $generator->setReviewAssignment($reviewAssignment);
        $generator->setCertificate($certificate);
        $generator->setContext($context);
        $generator->setLocale($this->getCurrentLocale());
        $generator->setTemplateSettings($this->getTemplateSettings($context));

        return $generator;
    }

    /**
     * Get template settings for context
     * @param $context Context
     * @return array
     */
    private function getTemplateSettings($context) {
        $settings = array();
        $plugin = $this->getPlugin();

        if (!$plugin) {
            error_log('ReviewerCertificate: getTemplateSettings() called but plugin instance is null');
            return $settings;
        }

        $settingNames = array(
            'backgroundImage',
            'headerText',
            'bodyTemplate',
            'footerText',
            'fontFamily',
            'fontSize',
            'textColorR',
            'textColorG',
            'textColorB',
            'includeQRCode',
            'minimumReviews',
            'pageOrientation',
            'bodyTopOffset',
            'layoutMode',
            'logoImage',
            'coverImage',
            'sealImage'
        );
        require_once dirname(__DIR__) . '/classes/CertificateGenerator.php';
        $settingNames = array_merge($settingNames, array_keys(
            \APP\plugins\generic\reviewerCertificate\classes\CertificateGenerator::getTypographySettingDefinitions()
        ), array_keys(
            \APP\plugins\generic\reviewerCertificate\classes\CertificateGenerator::getStructuredStringSettingDefaults()
        ));

        foreach ($settingNames as $name) {
            $settings[$name] = $plugin->getSetting($context->getId(), $name);
        }

        return $settings;
    }

    /**
     * Generate batch certificates
     * @param $args array
     * @param $request Request
     */
    public function generateBatch($args, $request) {
        require_once dirname(__DIR__) . '/classes/BatchAction.php';
        return \APP\plugins\generic\reviewerCertificate\classes\BatchAction::run($this->getPlugin(), $request);
    }


    /**
     * Reviewer name as shown on the public verify page.
     * @param string $name Full name
     * @param string|null $mode full (default), initials or hidden
     * @return string
     */
    public static function displayName($name, $mode) {
        $name = trim((string) $name);
        if ($mode === 'hidden') {
            return '';
        }
        if ($mode !== 'initials' || $name === '') {
            return $name;
        }
        $initials = array();
        foreach (preg_split('/[\s\-]+/u', $name, -1, PREG_SPLIT_NO_EMPTY) as $part) {
            $first = function_exists('mb_substr') ? mb_substr($part, 0, 1, 'UTF-8') : substr($part, 0, 1);
            $initials[] = function_exists('mb_strtoupper') ? mb_strtoupper($first, 'UTF-8') . '.' : strtoupper($first) . '.';
        }
        // A name written without spaces (e.g. Chinese) keeps its first character only
        if (count($initials) === 1 && (function_exists('mb_strlen') ? mb_strlen($name, 'UTF-8') : strlen($name)) > 1) {
            return (function_exists('mb_substr') ? mb_substr($name, 0, 1, 'UTF-8') : substr($name, 0, 1)) . '**';
        }
        return implode(' ', $initials);
    }

    /**
     * Annual summary certificate: one PDF covering every certified review the
     * reviewer completed for this journal in a year.
     * @param $args array [0] => year
     * @param $request Request
     */
    public function annualCertificate($args, $request) {
        $this->ensurePluginLocaleLoaded();
        $user = $request->getUser();
        $context = $request->getContext();
        // 'all' = cumulative certificate over every year (like Elsevier's
        // "Recognized Reviewer" certificate with the total review count).
        $cumulative = isset($args[0]) && $args[0] === 'all';
        $year = $cumulative ? 0 : (isset($args[0]) ? (int) $args[0] : 0);
        if (!$user || !$context || (!$cumulative && ($year < 1900 || $year > 9999))) {
            http_response_code(400);
            throw new Exception('Invalid year', 400);
        }
        $plugin = $this->getPlugin();
        $dao = DAORegistry::getDAO('CertificateDAO');
        $result = $dao->retrieve(
            'SELECT rc.certificate_id, rc.review_id, ra.date_completed
             FROM reviewer_certificates rc
             INNER JOIN submissions s ON rc.submission_id = s.submission_id
             INNER JOIN review_assignments ra ON rc.review_id = ra.review_id
             WHERE rc.reviewer_id = ? AND rc.context_id = ? AND s.context_id = ?
             AND ra.date_completed >= ? AND ra.date_completed < ?
             ORDER BY ra.date_completed DESC',
            array((int) $user->getId(), (int) $context->getId(), (int) $context->getId(),
                $cumulative ? '1900-01-01 00:00:00' : sprintf('%04d-01-01 00:00:00', $year),
                $cumulative ? '10000-01-01 00:00:00' : sprintf('%04d-01-01 00:00:00', $year + 1))
        );
        $revoked = $plugin->getRevokedCertificates($context->getId());
        $count = 0;
        $years = array();
        $latestReviewId = null;
        foreach ($result as $row) {
            $row = (array) $row;
            if (isset($revoked[(int) $row['certificate_id']])) {
                continue;
            }
            $count++;
            $years[] = (int) date('Y', strtotime($row['date_completed']));
            if ($latestReviewId === null) {
                $latestReviewId = (int) $row['review_id'];
            }
        }
        if (!$count) {
            http_response_code(404);
            throw new Exception('No certificates in this year', 404);
        }

        $reviewAssignment = $this->loadAuthorizedReviewAssignment($latestReviewId, $request, 'annual');
        require_once dirname(__DIR__) . '/classes/CertificateGenerator.php';
        $generator = new \APP\plugins\generic\reviewerCertificate\classes\CertificateGenerator();
        $generator->setReviewAssignment($reviewAssignment);
        $generator->setContext($context);
        $generator->setLocale($this->getCurrentLocale());
        $settings = $this->getTemplateSettings($context);
        $generatorClass = \APP\plugins\generic\reviewerCertificate\classes\CertificateGenerator::class;
        $settings['bodyTemplate'] = $cumulative
            ? ($plugin->getSetting($context->getId(), 'cumulativeBodyTemplate') ?: $generatorClass::getDefaultCumulativeBodyTemplate())
            : ($plugin->getSetting($context->getId(), 'annualBodyTemplate') ?: $generatorClass::getDefaultAnnualBodyTemplate());
        $generator->setTemplateSettings($settings);
        $period = $cumulative
            ? (min($years) === max($years) ? (string) min($years) : min($years) . '–' . max($years))
            : (string) $year;
        $generator->setExtraVariables(array(
            'reviewerStatus' => $this->reviewerStatus($context, $user->getId())['label'],
            'reviewCount' => $count,
            'reviewYear' => $period,
            'reviewPeriod' => $period,
            'reviewDate' => $period,
            'reviewMonthYear' => $period,
            'submissionTitle' => '',
            'certificateCode' => '',
        ));
        try {
            $pdfContent = $generator->generatePDF();
        } catch (\Throwable $e) {
            error_log('ReviewerCertificate: annual PDF generation failed: ' . $e->getMessage());
            http_response_code(500);
            echo 'An error occurred generating the certificate. Please try again later.';
            exit;
        }
        $this->sendPdf($pdfContent, 'reviewer_certificate_' . ($cumulative ? 'all' : $year) . '.pdf');
    }

    /**
     * Reviewer status for the cumulative certificate, modelled on Elsevier's
     * Recognized / Outstanding Reviewer: Outstanding when the reviewer has at
     * least the configured number of certified reviews in the last two years.
     * @return array ['outstanding' => bool, 'label' => string, 'recentReviews' => int]
     */
    private function reviewerStatus($context, $userId) {
        $plugin = $this->getPlugin();
        $generatorClass = \APP\plugins\generic\reviewerCertificate\classes\CertificateGenerator::class;
        require_once dirname(__DIR__) . '/classes/CertificateGenerator.php';
        $setting = function ($name) use ($plugin, $context, $generatorClass) {
            return $generatorClass::sanitizeStructuredStringSetting($name, $plugin->getSetting($context->getId(), $name));
        };
        $threshold = (int) $setting('outstandingMinReviews');
        $recent = 0;
        if ($threshold > 0) {
            $result = DAORegistry::getDAO('CertificateDAO')->retrieve(
                'SELECT rc.certificate_id FROM reviewer_certificates rc
                 INNER JOIN review_assignments ra ON ra.review_id = rc.review_id
                 WHERE rc.reviewer_id = ? AND rc.context_id = ? AND ra.date_completed >= ?',
                array((int) $userId, (int) $context->getId(), date('Y-m-d H:i:s', strtotime('-2 years'))));
            $revoked = $plugin->getRevokedCertificates($context->getId());
            foreach ($result ?: array() as $row) {
                if (!isset($revoked[(int) ((array) $row)['certificate_id']])) {
                    $recent++;
                }
            }
        }
        $outstanding = $threshold > 0 && $recent >= $threshold;
        return array(
            'outstanding' => $outstanding,
            'label' => $setting($outstanding ? 'outstandingLabel' : 'recognizedLabel'),
            'recentReviews' => $recent,
        );
    }

    /**
     * Output a PDF download and end the request.
     */
    private function sendPdf($pdfContent, $fileName) {
        header('Content-Type: application/pdf');
        header('Content-Disposition: attachment; filename="' . $fileName . '"');
        header('Content-Length: ' . strlen($pdfContent));
        header('Cache-Control: private, max-age=0, must-revalidate');
        header('Pragma: public');
        echo $pdfContent;
        exit;
    }

    /** Certificates per page on the manager overview. */
    const MANAGE_PAGE_SIZE = 50;

    /**
     * Manager overview of every certificate issued by this journal.
     * @param $args array
     * @param $request Request
     */
    public function manage($args, $request) {
        $this->ensurePluginLocaleLoaded();
        $context = $request->getContext();
        $search = trim((string) $request->getUserVar('search'));
        $page = max(1, (int) $request->getUserVar('page'));
        $total = $this->countContextCertificates($context, $search);
        $rows = $this->listContextCertificates($context, $search, ($page - 1) * self::MANAGE_PAGE_SIZE, self::MANAGE_PAGE_SIZE);

        $templateMgr = TemplateManager::getManager($request);
        $templateMgr->assign('certificates', $rows);
        $templateMgr->assign('search', $search);
        $templateMgr->assign('page', $page);
        $templateMgr->assign('pageCount', max(1, (int) ceil($total / self::MANAGE_PAGE_SIZE)));
        $templateMgr->assign('totalCertificates', $total);
        $templateMgr->assign('exportUrl', $request->url(null, 'certificate', 'exportCertificates', null, $search !== '' ? array('search' => $search) : array()));
        $templateMgr->assign('manageUrl', $request->url(null, 'certificate', 'manage'));
        $templateMgr->assign('prevUrl', $page > 1 ? $request->url(null, 'certificate', 'manage', null, array('search' => $search, 'page' => $page - 1)) : null);
        $templateMgr->assign('nextUrl', $page * self::MANAGE_PAGE_SIZE < $total ? $request->url(null, 'certificate', 'manage', null, array('search' => $search, 'page' => $page + 1)) : null);
        $templateMgr->assign('certificateRevoked', (bool) $request->getUserVar('revoked'));
        $templateMgr->assign('certificateRestored', (bool) $request->getUserVar('restored'));

        $this->setupTemplate($request);
        if (!is_array($templateMgr->getTemplateVars('userRoles'))) {
            $userRolesAssoc = defined('ASSOC_TYPE_USER_ROLES')
                ? ASSOC_TYPE_USER_ROLES
                : \APP\core\Application::ASSOC_TYPE_USER_ROLES;
            $templateMgr->assign('userRoles', (array) $this->getAuthorizedContextObject($userRolesAssoc));
        }
        $templateMgr->assign('pageTitle', __('plugins.generic.reviewerCertificate.manage.title'));
        $templateMgr->setupBackendPage();
        return $templateMgr->display($this->getPlugin()->getTemplateResource('manageCertificates.tpl'));
    }

    /**
     * CSV export of the manager overview (respects the search filter).
     */
    public function exportCertificates($args, $request) {
        $this->ensurePluginLocaleLoaded();
        $context = $request->getContext();
        $search = trim((string) $request->getUserVar('search'));
        $rows = $this->listContextCertificates($context, $search, 0, 10000);
        header('Content-Type: text/csv; charset=UTF-8');
        header('Content-Disposition: attachment; filename="reviewer_certificates_' . date('Ymd') . '.csv"');
        header('Cache-Control: private, max-age=0, must-revalidate');
        $out = fopen('php://output', 'w');
        fwrite($out, "\xEF\xBB\xBF"); // UTF-8 BOM so Excel reads CJK names correctly
        fputcsv($out, array('certificate_code', 'reviewer_name', 'reviewer_email', 'submission_id', 'submission_title',
            'review_completed', 'date_issued', 'downloads', 'notification', 'revoked', 'date_revoked', 'revoke_reason'));
        foreach ($rows as $row) {
            fputcsv($out, array_map(array(self::class, 'csvSafe'), array($row['certificateCode'], $row['reviewerName'], $row['reviewerEmail'],
                $row['submissionId'], $row['submissionTitle'], $row['reviewCompleted'], $row['dateIssued'],
                $row['downloads'], $row['notification'], $row['revoked'] ? 'yes' : 'no', $row['dateRevoked'], $row['revokeReason'])));
        }
        fclose($out);
        exit;
    }

    /** Neutralise spreadsheet formulas in exported cells (CSV injection). */
    public static function csvSafe($value) {
        $value = (string) $value;
        return ($value !== '' && strpos('=+-@' . "\t\r", $value[0]) !== false) ? "'" . $value : $value;
    }

    /**
     * Revoke or restore a certificate. POST + CSRF; managers only.
     */
    public function revokeCertificate($args, $request) {
        if (strtoupper($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST'
                || !method_exists($request, 'checkCSRF') || !$request->checkCSRF()) {
            http_response_code(403);
            throw new Exception('Forbidden', 403);
        }
        $context = $request->getContext();
        $certificate = $this->loadContextCertificate(isset($args[0]) ? $args[0] : null, $context);
        $restore = (bool) $request->getUserVar('restore');
        $this->getPlugin()->setCertificateRevoked($context->getId(), $certificate->getCertificateId(),
            !$restore, (string) $request->getUserVar('reason'));
        $request->redirect(null, 'certificate', 'manage', null, array(
            $restore ? 'restored' : 'revoked' => 1,
            'search' => (string) $request->getUserVar('search'),
            'page' => max(1, (int) $request->getUserVar('page')),
        ));
    }

    /**
     * Managers download any certificate of their journal (also revoked ones,
     * for their records). Does not count as a reviewer download.
     */
    public function managerDownload($args, $request) {
        $context = $request->getContext();
        $certificate = $this->loadContextCertificate(isset($args[0]) ? $args[0] : null, $context);
        $row = $this->getPlugin()->getCertificateService($context->getId())->loadReview($certificate->getReviewId());
        $reviewAssignment = DAORegistry::getDAO('CertificateDAO')->reviewAssignmentFromRow($row);
        $generator = $this->createConfiguredGenerator($reviewAssignment, $certificate, $context);
        try {
            $pdfContent = $generator->generatePDF();
        } catch (\Throwable $e) {
            error_log('ReviewerCertificate: manager PDF generation failed: ' . $e->getMessage());
            http_response_code(500);
            echo 'An error occurred generating the certificate. Please try again later.';
            exit;
        }
        $this->sendPdf($pdfContent, 'reviewer_certificate_' . $certificate->getCertificateId() . '.pdf');
    }

    /**
     * Load a certificate by ID and make sure it belongs to this journal.
     */
    private function loadContextCertificate($certificateId, $context) {
        $id = (is_string($certificateId) || is_int($certificateId)) && preg_match('/^[1-9][0-9]*$/D', (string) $certificateId)
            ? (int) $certificateId : 0;
        $certificate = $id && $context ? DAORegistry::getDAO('CertificateDAO')->getById($id) : null;
        if (!$certificate || (int) $certificate->getContextId() !== (int) $context->getId()) {
            http_response_code(404);
            throw new Exception('Certificate not found', 404);
        }
        return $certificate;
    }

    /**
     * WHERE clause and parameters for the manager list and its search box
     * (certificate code, reviewer email, username, given or family name).
     */
    private function contextCertificateFilter($context, $search) {
        $where = 'rc.context_id = ?';
        $params = array((int) $context->getId());
        if ($search !== '') {
            $lower = function_exists('mb_strtolower') ? mb_strtolower($search, 'UTF-8') : strtolower($search);
            $like = '%' . str_replace(array('\\', '%', '_'), array('\\\\', '\\%', '\\_'), $lower) . '%';
            $where .= ' AND (LOWER(rc.certificate_code) LIKE ? OR LOWER(u.email) LIKE ? OR LOWER(u.username) LIKE ?
                OR EXISTS (SELECT 1 FROM user_settings us WHERE us.user_id = u.user_id
                    AND us.setting_name IN (?, ?) AND LOWER(us.setting_value) LIKE ?))';
            array_push($params, $like, $like, $like, 'givenName', 'familyName', $like);
        }
        return array($where, $params);
    }

    private function countContextCertificates($context, $search) {
        list($where, $params) = $this->contextCertificateFilter($context, $search);
        $result = DAORegistry::getDAO('CertificateDAO')->retrieve(
            'SELECT COUNT(*) AS cnt FROM reviewer_certificates rc
             INNER JOIN users u ON u.user_id = rc.reviewer_id
             WHERE ' . $where, $params);
        $row = $result ? $result->current() : null;
        return $row ? (int) ((array) $row)['cnt'] : 0;
    }

    /**
     * One page of the journal's certificates with reviewer, title, delivery
     * and revocation details.
     * @return array
     */
    private function listContextCertificates($context, $search, $offset, $limit) {
        $dao = DAORegistry::getDAO('CertificateDAO');
        list($where, $params) = $this->contextCertificateFilter($context, $search);
        $result = $dao->retrieve(
            'SELECT rc.certificate_id, rc.reviewer_id, rc.submission_id, rc.date_issued, rc.certificate_code,
                    rc.download_count, u.email, ra.date_completed, n.status AS notification_status
             FROM reviewer_certificates rc
             INNER JOIN users u ON u.user_id = rc.reviewer_id
             LEFT JOIN review_assignments ra ON ra.review_id = rc.review_id
             LEFT JOIN reviewer_certificate_notifications n ON n.certificate_id = rc.certificate_id
             WHERE ' . $where . '
             ORDER BY rc.certificate_id DESC
             LIMIT ' . max(1, (int) $limit) . ' OFFSET ' . max(0, (int) $offset),
            $params);
        $rows = array();
        foreach ($result ?: array() as $row) {
            $rows[] = (array) $row;
        }
        $names = $this->loadUserNames(array_unique(array_map(function ($row) { return (int) $row['reviewer_id']; }, $rows)));
        $revoked = $this->getPlugin()->getRevokedCertificates($context->getId());
        $locale = $this->getCurrentLocale();
        $request = Application::get()->getRequest();
        $list = array();
        foreach ($rows as $row) {
            $id = (int) $row['certificate_id'];
            $revocation = $revoked[$id] ?? null;
            $list[] = array(
                'certificateId' => $id,
                'certificateCode' => $row['certificate_code'],
                'reviewerName' => $names[(int) $row['reviewer_id']] ?? '',
                'reviewerEmail' => $row['email'],
                'submissionId' => (int) $row['submission_id'],
                'submissionTitle' => $this->getSubmissionTitleForListing($dao, (int) $row['submission_id'], $locale),
                'reviewCompleted' => $row['date_completed'] ? date('Y-m-d', strtotime($row['date_completed'])) : '',
                'dateIssued' => date('Y-m-d', strtotime($row['date_issued'])),
                'downloads' => (int) $row['download_count'],
                'notification' => (string) $row['notification_status'],
                'revoked' => $revocation !== null,
                'dateRevoked' => $revocation && !empty($revocation['date']) ? date('Y-m-d', strtotime($revocation['date'])) : '',
                'revokeReason' => $revocation['reason'] ?? '',
                'downloadUrl' => $request->url(null, 'certificate', 'managerDownload', array($id)),
                'revokeUrl' => $request->url(null, 'certificate', 'revokeCertificate', array($id)),
            );
        }
        return $list;
    }

    /**
     * Full names for a set of users from user_settings, preferring the
     * current locale. One query regardless of the number of users.
     * @param int[] $userIds
     * @return array user ID => full name
     */
    private function loadUserNames(array $userIds) {
        $userIds = array_values(array_filter(array_map('intval', $userIds)));
        if (!$userIds) {
            return array();
        }
        $locale = $this->getCurrentLocale();
        $result = DAORegistry::getDAO('CertificateDAO')->retrieve(
            'SELECT user_id, setting_name, locale, setting_value FROM user_settings
             WHERE setting_name IN (?, ?) AND setting_value IS NOT NULL AND setting_value <> ?
             AND user_id IN (' . implode(',', array_fill(0, count($userIds), '?')) . ')',
            array_merge(array('givenName', 'familyName', ''), $userIds));
        $parts = array();
        foreach ($result ?: array() as $row) {
            $row = (array) $row;
            $uid = (int) $row['user_id'];
            $key = $row['setting_name'];
            if (!isset($parts[$uid][$key]) || $row['locale'] === $locale) {
                $parts[$uid][$key] = $row['setting_value'];
            }
        }
        $names = array();
        foreach ($parts as $uid => $p) {
            $names[$uid] = trim(($p['givenName'] ?? '') . ' ' . ($p['familyName'] ?? ''));
        }
        return $names;
    }

}
