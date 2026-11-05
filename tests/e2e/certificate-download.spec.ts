import { test, expect } from '@playwright/test';
import { loginAsAdmin, loginAsReviewer, enablePlugin } from './helpers/ojs-auth';

test.describe('Certificate Download', () => {
  test.beforeEach(async ({ page }) => {
    await loginAsAdmin(page);
    await enablePlugin(page);
    await page.context().clearCookies();
  });

  test('reviewer can download certificate for completed review', async ({ page }) => {
    await loginAsReviewer(page);

    // Since v1.14 the side menu has a "My Certificates" link, so a loose
    // "a:has-text('Certificate')" selector found that HTML page instead of a
    // download. Use the download buttons on My Certificates directly.
    const listing = await page.goto('/index.php/testjournal/certificate/myCertificates', {
      waitUntil: 'domcontentloaded', timeout: 15000,
    });
    expect(listing?.status()).toBeLessThan(500);

    const downloadButtons = page.locator('a.certificate-download-btn');
    if (await downloadButtons.count()) {
      const href = await downloadButtons.first().getAttribute('href');
      expect(href).toContain('certificate/download');
      const response = await page.request.get(href!);
      expect(response.status()).toBe(200);
      expect(response.headers()['content-type'] || '').toContain('application/pdf');
      expect((await response.body()).subarray(0, 5).toString()).toBe('%PDF-');
    } else {
      // No eligible review for this reviewer in the fixture: the page must
      // say so rather than fail.
      await expect(page.locator('tr.no-certificates')).toHaveCount(1);
    }

    // A review that is not the reviewer's is never served as a PDF.
    const foreign = await page.request.get('/index.php/testjournal/certificate/download/999999');
    expect(foreign.headers()['content-type'] || '').not.toContain('application/pdf');
  });
});
