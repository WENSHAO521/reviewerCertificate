import { test, expect } from '@playwright/test';
import { loginAsAdmin, loginAsReviewer, enablePlugin } from './helpers/ojs-auth';

/**
 * Manager overview of issued certificates (/certificate/manage), its CSV
 * export, and the reviewer's annual certificate section.
 */
test.describe('Issued certificates overview', () => {
  test.beforeEach(async ({ page }) => {
    await loginAsAdmin(page);
    await enablePlugin(page);
  });

  test('manager opens the overview in the backend layout', async ({ page }) => {
    const response = await page.goto('/index.php/testjournal/certificate/manage', {
      waitUntil: 'domcontentloaded', timeout: 15000,
    });
    expect(response?.status()).toBeLessThan(500);
    const body = await page.textContent('body');
    expect(body).toContain('Certificate Management');
    expect(body).toContain('Issued Certificates');
    expect(body).not.toContain('##plugins.generic.reviewerCertificate.');
    await expect(page.locator('table.certificate-manage-table')).toHaveCount(1);
    // Statistics, batch issuing and notifications moved here from the settings.
    await expect(page.locator('.certificate-statistics')).toHaveCount(1);
    await expect(page.locator('#rc-panel-tools')).toHaveCount(1);
  });

  test('tabs show the batch tools and load the settings form', async ({ page }) => {
    await page.goto('/index.php/testjournal/certificate/manage', { waitUntil: 'load', timeout: 15000 });
    await expect(page.locator('#rc-panel-tools')).toBeHidden();
    await page.click('#rc-tab-tools');
    await expect(page.locator('#generateBatchBtn, #rc-panel-tools .rc-manage__empty').first()).toBeVisible();
    await page.click('#rc-tab-settings');
    await expect(page.locator('#rc-panel-settings #certificateSettingsForm')).toBeVisible({ timeout: 15000 });
    // The link back to this page is only shown in the plugin settings dialog.
    await expect(page.locator('#rc-panel-settings .rc-manage-panel')).toHaveCount(0);
  });

  test('side menu links to Certificate Management below Statistics', async ({ page }) => {
    await page.goto('/index.php/testjournal/certificate/manage', { waitUntil: 'domcontentloaded', timeout: 15000 });
    await expect(page.locator('a[href*="certificate/manage"]', { hasText: 'Certificate Management' }).first()).toBeVisible();
  });

  test('page route sends notifications only with a CSRF token', async ({ page }) => {
    const response = await page.request.post('/index.php/testjournal/certificate/notifyBatch', { form: { 'reviewerIds[]': '1' } });
    expect(response.status()).toBe(403);
  });

  test('CSV export downloads with a header row', async ({ page }) => {
    const response = await page.request.get('/index.php/testjournal/certificate/exportCertificates');
    expect(response.status()).toBe(200);
    expect(response.headers()['content-type']).toContain('text/csv');
    expect(await response.text()).toContain('certificate_code,reviewer_name');
  });

  test('reviewers cannot open the overview', async ({ page }) => {
    await page.context().clearCookies();
    await loginAsReviewer(page);
    const response = await page.goto('/index.php/testjournal/certificate/manage', {
      waitUntil: 'domcontentloaded', timeout: 15000,
    });
    const body = (await page.textContent('body')) || '';
    expect(body).not.toContain('certificate_code');
    await expect(page.locator('table.certificate-manage-table')).toHaveCount(0);
    if (response) {
      expect(response.status()).toBeLessThan(500);
    }
  });
});
