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
    expect(body).toContain('Issued Certificates');
    expect(body).not.toContain('##plugins.generic.reviewerCertificate.');
    await expect(page.locator('table.certificate-manage-table')).toHaveCount(1);
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
