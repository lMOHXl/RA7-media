Config = {}

Config.Command          = 'media'              -- opens the staff panel
Config.AdminPermissions = { 'god', 'admin' }   -- QBCore permission levels allowed to use the panel
Config.DefaultLang      = 'en'

-- who may control playing videos (play / pause / speed / volume / seek): 'admin' or 'everyone'
Config.VideoControl     = 'admin'

Config.MaxItems         = 400                  -- overlays + object removals
Config.DefaultDrawDistance = 200.0             -- metres an overlay is rendered from
Config.MaxDrawDistance  = 800.0
Config.MinDrawDistance  = 150.0                -- floor for older items saved with a shorter distance
Config.SurfaceOffset    = 0.015                -- push overlay off the wall to stop z-fighting
Config.MaxActiveDui     = 6                    -- max images/videos rendered at once (each one is a browser)
Config.PickRange        = 60.0                 -- raycast range of the picker

-- nil = any http(s) host. Or restrict, e.g. { 'i.imgur.com', 'cdn.discordapp.com', 'files.catbox.moe' }
Config.AllowedHosts     = nil

-- Model names hidden on EVERY client at join (CreateModelHide, map-wide). Names that do not exist in this build are skipped;
-- run /mediacheck in F8 to see which ones exist. Names come from a public prop list (ShiftyWreckzz/prop-list), by name only
-- (not verified in-game). Add more names from the panel's "Scan area" / "Remove object" (name is shown on screen and in F8).
Config.AutoHide = {
    -- adult magazines / DVDs
    'prop_porn_mag_01', 'prop_porn_mag_02', 'prop_porn_mag_03', 'prop_porn_mag_04',
    'v_res_tt_pornmag01', 'v_res_tt_pornmag02', 'v_res_tt_pornmag03', 'v_res_tt_pornmag04',
    'v_res_tt_porndvd01', 'v_res_tt_porndvd02', 'v_res_tt_porndvd03', 'v_res_tt_porndvd04',
    -- shop magazine racks / fashion mags
    'v_ret_ml_papers', 'v_ret_ta_mag1', 'v_ret_ta_mag2', 'v_res_fashmag1', 'v_res_fashmagopen',
    'v_res_fa_mag_rumor', 'v_res_j_magrack',
    -- lingerie / bikini displays / dancer figures (Vanilla Unicorn + shops)
    'prop_bikini_disp_01', 'prop_bikini_disp_02', 'prop_bikini_disp_03', 'prop_bikini_disp_04', 'prop_bikini_disp_05', 'prop_bikini_disp_06',
    'v_club_brablk', 'v_club_brablu', 'v_club_bragld', 'v_club_brapnk', 'v_club_slip', 'v_club_silkrobe',
    'v_club_skirtflare', 'v_club_skirtplt', 'v_club_dress1', 'v_club_vu_boa',
    'v_res_r_figdancer', 'v_res_r_figgirl',
}

-- Names only used to label models in the scan list (hash -> name)
Config.KnownModelNames = {
    'prop_strip_pole_01',
}

Config.Text = {
    ar = {
        noperm  = 'ما عندك صلاحية لوحة الوسائط',
        saved   = 'تم الحفظ',
        deleted = 'تم الحذف',
        badurl  = 'الرابط غير صالح (يبدأ بـ http أو https)',
        badhost = 'هذا الموقع غير مسموح في الإعدادات',
        invalid = 'بيانات غير صالحة',
        limit   = 'وصلت للحد الأقصى من العناصر',
        regionfail = 'ما قدرت أحدد السطح، جرب زاوية ثانية',
        t_remote = 'تحكم بالفيديو',
        v_play = 'تشغيل', v_pause = 'إيقاف', v_restart = 'من البداية', v_speed = 'السرعة', v_vol = 'الصوت', v_mute = 'كتم', v_unmute = 'تشغيل الصوت', v_seek = 'تقديم/تأخير',
        t_toggle = 'تشغيل / إيقاف', t_back = 'رجوع 10 ث', t_fwd = 'تقديم 10 ث', t_restart = 'من البداية', t_slow = 'أبطأ', t_fast = 'أسرع', t_speed1 = 'السرعة العادية',
        t_volup = 'رفع الصوت', t_voldn = 'خفض الصوت', t_mute = 'كتم / تشغيل الصوت',
    },
    en = {
        noperm  = 'You have no access to the media panel',
        saved   = 'Saved',
        deleted = 'Deleted',
        badurl  = 'Invalid link (must start with http or https)',
        badhost = 'This host is not allowed in config',
        invalid = 'Invalid data',
        limit   = 'Item limit reached',
        regionfail = 'Could not find the surface, try another angle',
        t_remote = 'Video control',
        v_play = 'Playing', v_pause = 'Paused', v_restart = 'Restarted', v_speed = 'Speed', v_vol = 'Volume', v_mute = 'Muted', v_unmute = 'Unmuted', v_seek = 'Seek',
        t_toggle = 'Play / Pause', t_back = 'Back 10 s', t_fwd = 'Forward 10 s', t_restart = 'Restart', t_slow = 'Slower', t_fast = 'Faster', t_speed1 = 'Normal speed',
        t_volup = 'Volume up', t_voldn = 'Volume down', t_mute = 'Mute / Unmute',
    },
}
