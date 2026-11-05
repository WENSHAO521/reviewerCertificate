<?php
/**
 * @file plugins/generic/reviewerCertificate/classes/CertificateDateFormatter.php
 *
 * Copyright (c) 2026 Panorama Scholarly Group Ltd. <contact@panorama-sg.com>
 * Distributed under the GNU GPL v3.
 *
 * @class CertificateDateFormatter
 *
 * @brief Formats certificate dates in English, Chinese, Japanese, Korean or
 * ISO style, or in the style of an OJS locale. Works without the PHP intl
 * extension; intl is used when present for other languages.
 */

namespace APP\plugins\generic\reviewerCertificate\classes;

class CertificateDateFormatter {

    /** Certificate date styles a journal can choose in the settings. */
    const FORMATS = array('en', 'zh', 'iso', 'locale');

    /**
     * Format a date.
     * @param string|int|null $date Date string, UNIX timestamp, or null for now
     * @param string $style 'long' (day month year), 'monthYear' or 'year'
     * @param string $format One of FORMATS
     * @param string|null $locale OJS locale (e.g. zh_TW, en, de_DE), used by 'locale'
     * @return string
     */
    public static function format($date, $style = 'long', $format = 'en', $locale = null) {
        $timestamp = self::toTimestamp($date);
        if ($style === 'year') {
            return date('Y', $timestamp);
        }
        if ($format === 'locale') {
            $format = self::formatForLocale($locale);
        }
        switch ($format) {
            case 'iso':
                return $style === 'monthYear' ? date('Y-m', $timestamp) : date('Y-m-d', $timestamp);
            case 'zh':
            case 'ja':
                return $style === 'monthYear'
                    ? date('Y', $timestamp) . '年' . date('n', $timestamp) . '月'
                    : date('Y', $timestamp) . '年' . date('n', $timestamp) . '月' . date('j', $timestamp) . '日';
            case 'ko':
                return $style === 'monthYear'
                    ? date('Y', $timestamp) . '년 ' . date('n', $timestamp) . '월'
                    : date('Y', $timestamp) . '년 ' . date('n', $timestamp) . '월 ' . date('j', $timestamp) . '일';
            case 'intl':
                $formatted = self::formatIntl($timestamp, $style, (string) $locale);
                if ($formatted !== null) {
                    return $formatted;
                }
                // fall through to English
            default:
                return $style === 'monthYear' ? date('F Y', $timestamp) : date('F j, Y', $timestamp);
        }
    }

    /**
     * Pick a formatting style for an OJS locale.
     * @param string|null $locale
     * @return string
     */
    private static function formatForLocale($locale) {
        $language = strtolower(substr((string) $locale, 0, 2));
        if (in_array($language, array('zh', 'ja', 'ko'), true)) {
            return $language;
        }
        if ($language === '' || $language === 'en') {
            return 'en';
        }
        return 'intl';
    }

    /**
     * Format with the intl extension, or null when it is unavailable.
     */
    private static function formatIntl($timestamp, $style, $locale) {
        if (!class_exists('IntlDateFormatter')) {
            return null;
        }
        try {
            $icuLocale = str_replace('@', '_', $locale);
            $pattern = null;
            if ($style === 'monthYear') {
                $pattern = 'LLLL y';
                if (class_exists('IntlDatePatternGenerator')) {
                    $generator = new \IntlDatePatternGenerator($icuLocale);
                    $pattern = $generator->getBestPattern('yMMMM') ?: $pattern;
                }
            }
            $formatter = new \IntlDateFormatter($icuLocale, \IntlDateFormatter::LONG, \IntlDateFormatter::NONE,
                date_default_timezone_get(), \IntlDateFormatter::GREGORIAN, $pattern);
            $formatted = $formatter->format($timestamp);
            return is_string($formatted) && $formatted !== '' ? $formatted : null;
        } catch (\Throwable $e) {
            return null;
        }
    }

    private static function toTimestamp($date) {
        if ($date === null || $date === '') {
            return time();
        }
        if (is_int($date)) {
            return $date;
        }
        $timestamp = strtotime((string) $date);
        return $timestamp === false ? time() : $timestamp;
    }
}
