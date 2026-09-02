-- Seed data for a fresh Hestia deployment focused on Enschede/Twente.
--
-- Run once against a freshly created database (after applying hestia.ddl):
--   docker exec -i hestia-database psql -U postgres -d hestia < misc/seed_enschede.sql
--
-- 1. hestia.meta needs exactly one row with id='default', or the scraper
--    containers stay halted forever (db.get_scraper_halted() defaults to
--    True when no row is found).
INSERT INTO hestia.meta (id, devmode_enabled, scraper_halted, workdir)
SELECT 'default', false, false, '/data'
WHERE NOT EXISTS (SELECT 1 FROM hestia.meta WHERE id = 'default');

-- 2. Roomspot (student housing in Enschede/Hengelo), verified live on
--    2026-09-02: POST https://studentenenschede-aanbodapi.zig365.nl/api/v1/actueel-aanbod?limit=200
--    returned 26/26 listings in Enschede or Hengelo. Uses the existing
--    parse_hexia() parser (agency = "hexia_<corp>").
INSERT INTO hestia.targets (agency, queryurl, method, user_info, post_data, headers, enabled)
SELECT
    'hexia_studentenenschede',
    'https://studentenenschede-aanbodapi.zig365.nl/api/v1/actueel-aanbod?limit=200',
    'POST',
    '{"agency": "Roomspot", "website": "https://www.roomspot.nl"}'::jsonb,
    '{}'::jsonb,
    '{"Content-Type": "application/json; charset=utf-8"}'::json,
    true
WHERE NOT EXISTS (SELECT 1 FROM hestia.targets WHERE agency = 'hexia_studentenenschede');

-- 3. Plaza (mosaic-plaza / plaza.newnewnew.space), verified live on
--    2026-09-02: same API shape, 26 total listings nationwide, some in
--    Enschede. First-come-first-served, hence the 1-minute schedule set
--    in docker-compose.yml for this target.
INSERT INTO hestia.targets (agency, queryurl, method, user_info, post_data, headers, enabled)
SELECT
    'hexia_mosaic-plaza',
    'https://mosaic-plaza-aanbodapi.zig365.nl/api/v1/actueel-aanbod?limit=200',
    'POST',
    '{"agency": "Plaza", "website": "https://plaza.newnewnew.space"}'::jsonb,
    '{}'::jsonb,
    '{"Content-Type": "application/json; charset=utf-8"}'::json,
    true
WHERE NOT EXISTS (SELECT 1 FROM hestia.targets WHERE agency = 'hexia_mosaic-plaza');
