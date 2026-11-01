<?php
/**
 * @file plugins/generic/reviewerCertificate/classes/CompactTCPDF.php
 *
 * Copyright (c) 2024
 * Distributed under the GNU GPL v3.
 *
 * @class CompactTCPDF
 * @ingroup plugins_generic_reviewerCertificate
 *
 * @brief TCPDF with tighter font subsetting, for small certificate PDFs.
 *
 * Embedded DejaVu Sans dominated certificate size (~50 KB per style, ~150 KB
 * with regular, bold and italic) because TCPDF's subsetting leaves a lot in:
 *
 *  1. It seeds every font's subset with the first 255 code points, so ~240
 *     glyphs are embedded even when a certificate uses forty. Every glyph
 *     actually drawn is still recorded as text is written
 *     (TCPDF_FONTS::UTF8StringToArray adds it to the subset), so the subset
 *     can start empty.
 *  2. The subset font keeps a full-length hmtx table (~6000 glyph metrics).
 *     Metrics of glyphs whose outlines were removed are zeroed so they
 *     compress away. PDF viewers take advance widths from the /W array.
 *  3. The CIDToGIDMap is the font's full 64K map. Entries for characters
 *     the subset does not contain are zeroed (mapped to .notdef).
 *
 * Text output is unchanged. Anything unexpected leaves a stream as TCPDF
 * produced it. Must only be loaded after tcpdf.php
 * (CertificateGenerator::ensureTCPDF()).
 */

namespace APP\plugins\generic\reviewerCertificate\classes;

class CompactTCPDF extends \TCPDF {

    /** @var bool True while TCPDF writes the font objects */
    private $compactFontStreams = false;

    /** @var array|null Characters of the subset font being written (for its CIDToGIDMap) */
    private $cidToGidChars = null;

    /**
     * @copydoc TCPDF::AddFont()
     */
    public function AddFont($family, $style = '', $fontfile = '', $subset = 'default') {
        $fontsBefore = $this->numfonts;
        $fontdata = parent::AddFont($family, $style, $fontfile, $subset);
        if ($this->numfonts > $fontsBefore && isset($fontdata['fontkey'])) {
            // A newly registered font: drop TCPDF's 0-254 pre-seed
            $this->setFontSubBuffer($fontdata['fontkey'], 'subsetchars', array());
        }
        return $fontdata;
    }

    protected function _putfonts() {
        $this->compactFontStreams = true;
        try {
            parent::_putfonts();
        } finally {
            $this->compactFontStreams = false;
        }
    }

    protected function _puttruetypeunicode($font) {
        $this->cidToGidChars = (!empty($font['subset']) && isset($font['subsetchars']) && is_array($font['subsetchars']))
            ? $font['subsetchars'] : null;
        try {
            parent::_puttruetypeunicode($font);
        } finally {
            $this->cidToGidChars = null;
        }
    }

    protected function _getrawstream($s, $n = 0) {
        if ($this->compactFontStreams && is_string($s) && strlen($s) > 2 && function_exists('gzuncompress')) {
            $compacted = $this->compactFontStream($s);
            if ($compacted !== null) {
                $s = $compacted;
            }
        }
        return parent::_getrawstream($s, $n);
    }

    /**
     * Shrink a zlib-compressed TrueType subset or CIDToGIDMap stream.
     * @param $stream string
     * @return string|null Recompressed stream, or null to keep the original
     */
    private function compactFontStream($stream) {
        // zlib header: CMF 0x78 and a valid check value
        if (ord($stream[0]) !== 0x78 || ((ord($stream[0]) << 8) | ord($stream[1])) % 31 !== 0) {
            return null;
        }
        $data = @gzuncompress($stream);
        if ($data === false) {
            return null;
        }
        if ($this->cidToGidChars !== null && strlen($data) === 131072) {
            $result = self::compactCidToGidMap($data, $this->cidToGidChars);
        } elseif (substr($data, 0, 4) === "\x00\x01\x00\x00" || substr($data, 0, 4) === 'true') {
            $result = self::zeroUnusedMetrics($data);
        } else {
            return null;
        }
        return $result === null ? null : gzcompress($result, 9);
    }

    /**
     * Map every CID outside $chars to glyph 0.
     * @param $map string 65536 big-endian uint16 glyph ids
     * @param $chars array Used code points as keys
     * @return string
     */
    public static function compactCidToGidMap($map, $chars) {
        $out = str_repeat("\x00", 131072);
        foreach ($chars as $cid => $used) {
            $cid = (int) $cid;
            if ($used && $cid >= 0 && $cid < 65536) {
                $out[2 * $cid] = $map[2 * $cid];
                $out[2 * $cid + 1] = $map[2 * $cid + 1];
            }
        }
        return $out;
    }

    /**
     * Zero the hmtx entries of glyphs that have no outline in a TrueType
     * subset, then fix the table and whole-font checksums.
     * @param $font string TrueType font
     * @return string|null Changed font, or null when it cannot be parsed
     */
    public static function zeroUnusedMetrics($font) {
        $len = strlen($font);
        if ($len < 12) {
            return null;
        }
        $numTables = unpack('n', substr($font, 4, 2))[1];
        if ($len < 12 + 16 * $numTables) {
            return null;
        }
        $tables = array();
        for ($i = 0; $i < $numTables; $i++) {
            $entry = unpack('a4tag/Nsum/Noffset/Nlength', substr($font, 12 + 16 * $i, 16));
            if ($entry['offset'] + $entry['length'] > $len) {
                return null;
            }
            $tables[$entry['tag']] = array('dir' => 12 + 16 * $i) + $entry;
        }
        foreach (array('head', 'hhea', 'maxp', 'loca', 'hmtx') as $tag) {
            if (!isset($tables[$tag])) {
                return null;
            }
        }
        $head = $tables['head'];
        $longLoca = unpack('n', substr($font, $head['offset'] + 50, 2))[1] === 1;
        $numGlyphs = unpack('n', substr($font, $tables['maxp']['offset'] + 4, 2))[1];
        $numMetrics = unpack('n', substr($font, $tables['hhea']['offset'] + 34, 2))[1];
        $loca = $tables['loca'];
        $hmtx = $tables['hmtx'];
        if ($loca['length'] < ($numGlyphs + 1) * ($longLoca ? 4 : 2)
                || $numMetrics < 1 || $numMetrics > $numGlyphs
                || $hmtx['length'] < 4 * $numMetrics + 2 * ($numGlyphs - $numMetrics)) {
            return null;
        }
        $offsets = array_values(unpack(($longLoca ? 'N' : 'n') . ($numGlyphs + 1),
            substr($font, $loca['offset'], ($numGlyphs + 1) * ($longLoca ? 4 : 2))));

        $changed = false;
        // Glyph 0 (.notdef) always keeps its metrics
        for ($gid = 1; $gid < $numGlyphs; $gid++) {
            if ($offsets[$gid + 1] > $offsets[$gid]) {
                continue;
            }
            if ($gid < $numMetrics) {
                $font = substr_replace($font, "\x00\x00\x00\x00", $hmtx['offset'] + 4 * $gid, 4);
            } else {
                $font = substr_replace($font, "\x00\x00",
                    $hmtx['offset'] + 4 * $numMetrics + 2 * ($gid - $numMetrics), 2);
            }
            $changed = true;
        }
        if (!$changed) {
            return null;
        }

        // hmtx and head checksums, then head.checkSumAdjustment over the whole font
        $font = substr_replace($font, pack('N', self::tableChecksum(substr($font, $hmtx['offset'], $hmtx['length']))),
            $hmtx['dir'] + 4, 4);
        $font = substr_replace($font, "\x00\x00\x00\x00", $head['offset'] + 8, 4);
        // head's own checksum is taken with checkSumAdjustment = 0
        $font = substr_replace($font, pack('N', self::tableChecksum(substr($font, $head['offset'], $head['length']))),
            $head['dir'] + 4, 4);
        $adjustment = (0xB1B0AFBA - self::tableChecksum($font)) & 0xFFFFFFFF;
        return substr_replace($font, pack('N', $adjustment), $head['offset'] + 8, 4);
    }

    /**
     * TrueType checksum: sum of big-endian uint32 words, zero padded.
     * @param $data string
     * @return int
     */
    private static function tableChecksum($data) {
        $data .= str_repeat("\x00", (4 - strlen($data) % 4) % 4);
        $sum = 0;
        foreach (str_split($data, 32768) as $chunk) {
            foreach (unpack('N*', $chunk) as $word) {
                $sum = ($sum + $word) & 0xFFFFFFFF;
            }
        }
        return $sum;
    }
}
