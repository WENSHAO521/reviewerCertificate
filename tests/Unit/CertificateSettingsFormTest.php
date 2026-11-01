<?php
/**
 * Unit tests for CertificateSettingsForm.
 *
 * Covers the background-image lifecycle (Issue #73 — the setting could only ever
 * be overwritten by a new upload, never cleared) and the header/body layout
 * settings (Issue #74).
 *
 * Before this file, readInputData()/execute() had no test coverage at all.
 */

require_once dirname(__FILE__) . '/../bootstrap.php';
require_once BASE_SYS_DIR . '/classes/CertificateGenerator.php';
require_once BASE_SYS_DIR . '/classes/form/CertificateSettingsForm.php';

use APP\plugins\generic\reviewerCertificate\classes\form\CertificateSettingsForm;

/**
 * Minimal plugin stand-in: settings live in an array so tests can assert on them.
 */
class FakeSettingsPlugin
{
    /** @var array */
    public $settings = array();
    public $failOn;

    public function getTemplateResource($template)
    {
        return $template;
    }

    public function getName() { return 'reviewercertificateplugin'; }

    public function getSetting($contextId, $name)
    {
        return $this->settings[$name] ?? null;
    }

    public function updateSetting($contextId, $name, $value, $type = null)
    {
        if ($this->failOn === $name) { throw new \RuntimeException('Injected persistence failure'); }
        $this->settings[$name] = $value;
    }
}

class CertificateSettingsFormTest extends TestCase
{
    /** @var FakeSettingsPlugin */
    private $plugin;

    /** @var string */
    private $uploadDir;

    protected function setUp(): void
    {
        parent::setUp();

        $this->plugin = new FakeSettingsPlugin();
        \PKP\form\Form::$mockUserVars = array('bodyTemplate' => 'Body', 'minimumReviews' => '1');
        unset($_FILES['backgroundImage'], $_FILES['logoImage'], $_FILES['coverImage'], $_FILES['sealImage']);

        $this->uploadDir = sys_get_temp_dir() . '/rc-settings-form-test-' . getmypid();
        if (!is_dir($this->uploadDir)) {
            mkdir($this->uploadDir, 0777, true);
        }
    }

    protected function tearDown(): void
    {
        \PKP\form\Form::$mockUserVars = array();
        unset($_FILES['backgroundImage'], $_FILES['logoImage'], $_FILES['coverImage'], $_FILES['sealImage']);

        foreach (glob($this->uploadDir . '/*') ?: array() as $file) {
            @unlink($file);
        }
        @rmdir($this->uploadDir);

        parent::tearDown();
    }

    private function makeForm(): CertificateSettingsForm
    {
        return new class($this->plugin, 1) extends CertificateSettingsForm {
            private $testPlugin;
            public function __construct($plugin, $contextId) { parent::__construct($plugin, $contextId); $this->testPlugin = $plugin; }
            protected function getConnection() {
                return new class($this->testPlugin) {
                    private $plugin;
                    public function __construct($plugin) { $this->plugin = $plugin; }
                    public function transaction($callback) {
                        $before = $this->plugin->settings;
                        try { return $callback(); }
                        catch (\Throwable $e) { $this->plugin->settings = $before; throw $e; }
                    }
                };
            }
        };
    }

    public function testPhpUploadErrorRejectsWholeSettingsSave(): void {
        $_FILES['backgroundImage'] = ['error' => UPLOAD_ERR_INI_SIZE, 'tmp_name' => '', 'size' => 0];
        $form = $this->makeForm();
        $form->readInputData();
        $this->assertFalse($form->validate());
        $this->assertSame([], $this->plugin->settings);
    }

    public function testPersistenceFailureRollsBackAllSettingsAndKeepsPreviousImage(): void {
        $this->plugin->settings = ['headerText' => 'Old', 'backgroundImage' => '/old/image.png'];
        $this->plugin->failOn = 'fontSize';
        \PKP\form\Form::$mockUserVars['headerText'] = 'New';
        \PKP\form\Form::$mockUserVars['removeBackgroundImage'] = '1';
        $form = $this->makeForm(); $form->readInputData();
        try { $form->execute(); $this->fail('Save failure swallowed'); }
        catch (\RuntimeException $e) {
            $this->assertSame(['headerText' => 'Old', 'backgroundImage' => '/old/image.png'], $this->plugin->settings);
            $this->assertSame('/old/image.png', $form->getData('backgroundImage'));
        }
    }

    public function testReadInputDoesNotInspectOrMoveAnUpload(): void {
        $_FILES['backgroundImage'] = ['error' => UPLOAD_ERR_OK, 'tmp_name' => '/missing/upload.png', 'size' => 10];
        $form = $this->makeForm();
        $form->readInputData();
        $this->assertSame('', $form->getData('backgroundImage'));
        $this->assertFalse($form->validate());
    }

    // ---------------------------------------------------------------- Issue #73

    /**
     * The stored background must survive an ordinary save — the file input is
     * empty on every render, so without this the image would vanish on any edit.
     */
    public function testBackgroundImageIsPreservedWhenNotRemoved(): void
    {
        $this->plugin->settings['backgroundImage'] = '/files/journals/1/reviewerCertificate/background_1.jpg';

        $form = $this->makeForm();
        $form->readInputData();

        $this->assertSame(
            '/files/journals/1/reviewerCertificate/background_1.jpg',
            $form->getData('backgroundImage')
        );
    }

    /**
     * Issue #73: ticking "remove" must clear the setting. This is the regression —
     * readInputData() used to restore the stored path unconditionally, so there was
     * no way to end up with an empty value.
     */
    public function testBackgroundImageIsClearedWhenRemoveIsChecked(): void
    {
        $this->plugin->settings['backgroundImage'] = '/files/journals/1/reviewerCertificate/background_1.jpg';
        \PKP\form\Form::$mockUserVars['removeBackgroundImage'] = '1';

        $form = $this->makeForm();
        $form->readInputData();

        $this->assertSame('', $form->getData('backgroundImage'));
    }

    /**
     * execute() must persist the cleared value, not fall back to the old path.
     */
    public function testExecutePersistsClearedBackgroundImage(): void
    {
        $this->plugin->settings['backgroundImage'] = '/files/journals/1/reviewerCertificate/background_1.jpg';
        \PKP\form\Form::$mockUserVars['removeBackgroundImage'] = '1';

        $form = $this->makeForm();
        $form->readInputData();
        $form->execute();

        $this->assertSame('', $this->plugin->settings['backgroundImage']);
    }

    // ---------------------------------------------------------------- Issue #74

    /**
     * Issue #74: headerText must no longer be a required field, so a journal can
     * produce a certificate with no heading at all — exactly like footerText.
     *
     * Asserted against the registered validators rather than validate(), because a
     * missing 'required' rule is the actual regression to guard.
     */
    public function testHeaderTextIsNotRequired(): void
    {
        $required = array();
        foreach ($this->makeForm()->getMockChecks() as $check) {
            if (isset($check->mockType) && $check->mockType === 'required') {
                $required[] = $check->mockField;
            }
        }

        $this->assertNotContains('headerText', $required, 'headerText must be optional (Issue #74)');
        $this->assertNotContains('footerText', $required, 'footerText has always been optional');

        // Positive control: the rules that should still be enforced.
        $this->assertContains('bodyTemplate', $required);
        $this->assertContains('minimumReviews', $required);
    }

    /**
     * An empty header must also survive the save, not be coerced back to a default.
     */
    public function testEmptyHeaderTextIsPersisted(): void
    {
        $this->plugin->settings['headerText'] = 'Certificate of Recognition';
        \PKP\form\Form::$mockUserVars['headerText'] = '';
        \PKP\form\Form::$mockUserVars['bodyTemplate'] = 'Body';

        $form = $this->makeForm();
        $form->readInputData();
        $form->execute();

        $this->assertSame('', $this->plugin->settings['headerText']);
    }

    /**
     * The offset is the supported way to push the body down the page, so it must
     * round-trip through the form.
     */
    public function testBodyTopOffsetIsSaved(): void
    {
        \PKP\form\Form::$mockUserVars['bodyTopOffset'] = '25';

        $form = $this->makeForm();
        $form->readInputData();
        $form->execute();

        $this->assertSame(25, $this->plugin->settings['bodyTopOffset']);
    }

    /**
     * Clamped like the other numeric settings: a negative offset would push text
     * up into the page margin, and an absurd one off the page.
     */
    public function testBodyTopOffsetIsClamped(): void
    {
        foreach (array('-10' => 0, '999' => 100, 'abc' => 0) as $input => $expected) {
            \PKP\form\Form::$mockUserVars['bodyTopOffset'] = (string) $input;

            $form = $this->makeForm();
            $form->readInputData();
            $form->execute();

            $this->assertSame(
                $expected,
                $this->plugin->settings['bodyTopOffset'],
                "bodyTopOffset '$input' should clamp to $expected"
            );
        }
    }

    /**
     * Documents the OTHER half of Issue #74: OJS trims user vars on the way in, so
     * leading blank lines in the body template are gone before the PDF layer ever
     * sees them. That is why bodyTopOffset exists instead.
     */
    public function testLeadingBlankLinesInBodyTemplateAreTrimmedOnSave(): void
    {
        \PKP\form\Form::$mockUserVars['bodyTemplate'] = "\n\n\nThis certificate is awarded to";

        $form = $this->makeForm();
        $form->readInputData();
        $form->execute();

        $this->assertSame(
            'This certificate is awarded to',
            $this->plugin->settings['bodyTemplate'],
            'OJS Core::cleanVar() trims user vars, so blank lines cannot position the body'
        );
    }

    public function testTypographySettingsAreSavedAndClamped(): void
    {
        \PKP\form\Form::$mockUserVars = array_merge(\PKP\form\Form::$mockUserVars, array(
            'layoutMode' => 'structured',
            'nameFontSize' => '26',
            'nameBold' => '1',
            'journalFontSize' => '999',
            'bodyFontSize' => 'abc',
            'paragraphSpacing' => '-3',
            'titleColor' => '1B6F8A',
            'nameColor' => 'javascript:alert(1)',
            'footerPosition' => 'bottomLeft',
            'nameUppercase' => '1',
        ));

        $form = $this->makeForm();
        $form->readInputData();
        $form->execute();

        $this->assertSame('structured', $this->plugin->settings['layoutMode']);
        $this->assertSame(26, $this->plugin->settings['nameFontSize']);
        $this->assertSame(1, $this->plugin->settings['nameBold']);
        $this->assertSame(72, $this->plugin->settings['journalFontSize']);
        $this->assertSame(13, $this->plugin->settings['bodyFontSize'], 'Invalid input falls back to the default');
        $this->assertSame(0, $this->plugin->settings['paragraphSpacing']);
        // Unchecked bold boxes are absent from the POST and must save as off
        $this->assertSame(0, $this->plugin->settings['titleBold']);
        $this->assertSame(28, $this->plugin->settings['titleFontSize'], 'Missing sizes use the suggested default');
        $this->assertSame('#1b6f8a', $this->plugin->settings['titleColor']);
        $this->assertSame('', $this->plugin->settings['nameColor'], 'Invalid colours are dropped');
        $this->assertSame('bottomLeft', $this->plugin->settings['footerPosition']);
        $this->assertSame(1, $this->plugin->settings['nameUppercase']);

    }

    public function testUnknownLayoutModeSavesAsClassic(): void
    {
        \PKP\form\Form::$mockUserVars['layoutMode'] = '<script>';

        $form = $this->makeForm();
        $form->readInputData();
        $form->execute();

        $this->assertSame('classic', $this->plugin->settings['layoutMode']);
    }

    public function testTypographyDefaultsShownForFreshInstall(): void
    {
        $form = $this->makeForm();
        $form->initData();

        $this->assertSame('classic', $form->getData('layoutMode'));
        $this->assertSame(28, $form->getData('titleFontSize'));
        $this->assertSame(1, $form->getData('titleBold'));
        $this->assertSame(25, $form->getData('nameFontSize'));
        $this->assertSame(17, $form->getData('journalFontSize'));
        $this->assertSame(13, $form->getData('bodyFontSize'));
        $this->assertSame(10, $form->getData('detailFontSize'));
    }

    // ------------------------------------------------- logo / cover / seal images

    public function testOverlayImagesArePreservedAndCanBeRemovedIndependently(): void
    {
        $this->plugin->settings['logoImage'] = '/files/journals/1/reviewerCertificate/logo_1.png';
        $this->plugin->settings['coverImage'] = '/files/journals/1/reviewerCertificate/cover_1.jpg';
        $this->plugin->settings['sealImage'] = '/files/journals/1/reviewerCertificate/seal_1.png';
        \PKP\form\Form::$mockUserVars['removeCoverImage'] = '1';

        $form = $this->makeForm();
        $form->readInputData();
        $form->execute();

        $this->assertSame('/files/journals/1/reviewerCertificate/logo_1.png', $this->plugin->settings['logoImage']);
        $this->assertSame('', $this->plugin->settings['coverImage']);
        $this->assertSame('/files/journals/1/reviewerCertificate/seal_1.png', $this->plugin->settings['sealImage']);
    }

    public function testFailedOverlayUploadRejectsTheSave(): void
    {
        $_FILES['sealImage'] = ['error' => UPLOAD_ERR_INI_SIZE, 'tmp_name' => '', 'size' => 0];
        $form = $this->makeForm();
        $form->readInputData();
        $this->assertFalse($form->validate());
        $this->assertSame([], $this->plugin->settings);
    }

    public function testOverlayPositionsDefaultToAutomaticAndAreClamped(): void
    {
        \PKP\form\Form::$mockUserVars['logoWidth'] = '500';
        \PKP\form\Form::$mockUserVars['sealX'] = '200';
        \PKP\form\Form::$mockUserVars['sealY'] = '';

        $form = $this->makeForm();
        $form->readInputData();
        $form->execute();

        $this->assertSame(200, $this->plugin->settings['logoWidth']);
        $this->assertSame(-1, $this->plugin->settings['logoX'], 'Untouched positions stay automatic');
        $this->assertSame(200, $this->plugin->settings['sealX']);
        $this->assertSame(-1, $this->plugin->settings['sealY']);
    }
}
