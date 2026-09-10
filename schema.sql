-- ============================================================
-- מערכת תיק מגדלים — סכמת Supabase
-- הרץ את כל הקובץ ב-SQL Editor של הפרויקט, פעם אחת.
-- ============================================================

create extension if not exists "pgcrypto";

-- ---------- מגדלים ----------
create table if not exists growers (
  id            uuid primary key default gen_random_uuid(),
  name          text not null,
  country       text,
  ggn           text,
  cert_body     text,
  cert_no       text,
  cert_from     date,
  cert_to       date,
  products      text,
  markets       text,
  partner_of    uuid references growers(id) on delete set null,
  active        boolean not null default true,
  residue_days  int not null default 90,   -- תדירות דגימת שאריות, בימים
  micro_days    int not null default 90,   -- תדירות דגימה מיקרוביולוגית
  notes         text,
  created_at    timestamptz not null default now()
);

-- ---------- מסמכים ובדיקות ----------
-- kind: residue | micro | water | audit | cert | grasp | ppl | declaration | other
-- result: pass | pass_qualified | fail | pending | na
create table if not exists documents (
  id            uuid primary key default gen_random_uuid(),
  grower_id     uuid references growers(id) on delete cascade,
  kind          text not null default 'other',
  title         text not null,
  lab           text,
  ref_no        text,
  product       text,
  sampled_on    date,
  reported_on   date,
  received_on   date,
  expires_on    date,
  result        text not null default 'na',
  criterion     text,          -- מול מה נבחן: EC 396/2005 / 40 CFR 180 / ISO ...
  reviewed_on   date,          -- תאריך הסקירה והחתימה
  reviewed_by   text,
  link          text,          -- קישור לקובץ בדרייב
  notes         text,
  created_at    timestamptz not null default now()
);

-- ---------- יומן רגולטורי (FDA / רשויות) ----------
create table if not exists reg_log (
  id            uuid primary key default gen_random_uuid(),
  grower_id     uuid references growers(id) on delete set null,
  happened_on   date,
  kind          text not null default 'other',  -- inspection | form483 | response | closure | notice | record | other
  direction     text not null default 'int',    -- out | in | int
  title         text not null,
  title_en      text,
  party         text,
  ref_no        text,
  items         text,
  ack           boolean not null default false,
  ack_on        date,
  ack_by        text,
  ack_ref       text,
  link          text,
  notes         text,
  created_at    timestamptz not null default now()
);

create index if not exists documents_grower_idx on documents(grower_id);
create index if not exists documents_sampled_idx on documents(sampled_on desc);
create index if not exists reg_log_date_idx on reg_log(happened_on desc);

-- ---------- הרשאות ----------
alter table growers   enable row level security;
alter table documents enable row level security;
alter table reg_log   enable row level security;

drop policy if exists growers_rw   on growers;
drop policy if exists documents_rw on documents;
drop policy if exists reg_log_rw   on reg_log;

create policy growers_rw   on growers   for all to authenticated using (true) with check (true);
create policy documents_rw on documents for all to authenticated using (true) with check (true);
create policy reg_log_rw   on reg_log   for all to authenticated using (true) with check (true);


-- ============================================================
-- נתוני פתיחה — המצב כפי שאומת ב-10.09.2026
-- ============================================================

insert into growers (name, country, ggn, cert_body, cert_no, cert_from, cert_to, products, markets, notes) values
('Royal Herbs Exporters (SEZ)', 'קניה', '4063651526851', 'NSF Certification UK', '135732', '2026-04-01', '2027-02-27',
 'שרוויל, עירית, מיורן, מנטה, אורגנו, רוזמרין, טרגון, קורנית', 'EU, UK, שווייץ, סין', 'חוות Kipipiri. הכיסוי הטוב ביותר בתיק.'),
('Bendor Farm', 'קניה', '4063651777109', 'DNV Business Assurance Italy', '33828', '2026-01-19', '2027-01-11',
 'רוזמרין, מנטה, בזיליקום, קורנית', 'EU, UK, אמירויות', 'שותפים עם Greenblade. דוחות המעבדה יוצאים על שם Green Blade Growers.'),
('Greenblade Growers – Tumaini', 'קניה', '6161021000494', 'DNV Business Assurance Italy', '37359', '2026-01-26', '2026-12-08',
 'עירית, שרוויל', 'EU, UK, אמירויות', 'שותפים עם Bendor.'),
('Yair Ben Menashe', 'ישראל', '4049928097996', null, null, null, null,
 'בזיליקום, קורנית, רוזמרין', 'EU', 'חסרים פרטי תעודה — להשלים.'),
('Agriflow International Ltd', 'קניה', '4063651733655', 'DNV Business Assurance Italy', '35899', '2026-01-22', '2027-01-21',
 '26 מוצרים בשלושה אתרים', 'EU, אמירויות', 'Multisite ללא QMS.'),
('Aromatic Fresh Ltd', 'קניה', '4059883709506', 'DNV Business Assurance Italy', '00154-VCVNN-0002', '2025-10-30', '2026-10-29',
 'בזיליקום, מיורן, מרווה, קורנית', 'EU, UK, אמירויות', 'GRASP Assessed.'),
('Yehuda Efraim', 'ישראל', '4049928781925', 'Control Union', '154989', '2026-05-21', '2027-01-30',
 'בזיליקום, עירית', 'EU, ישראל', null),
('Rafi Cohen', 'ישראל', '4049929184619', 'Control Union', '158757', '2026-05-27', '2027-02-04',
 'בזיליקום, קורנית, רוקט, רוזמרין', 'EU, UK, ישראל', null),
('Jannet Adan (Jamal Abu Alaya)', 'רשות פלסטינית', '4056186658524', 'Control Union', '34595', '2026-01-20', '2026-10-31',
 'בזיליקום, נענע, מרווה, קורנית, עירית, שרוויל, רוזמרין, טרגון, חמעה', 'ארה"ב',
 'מאושר בכפוף לתנאים. NC ראשית FV 33.01.04 ללא ראיית סגירה. הבוחן ציין רכישת סחורה לא-מוסמכת ממגדלים אחרים.'),
('Lucille Farm Ltd', 'קניה', '4063651145847', 'Control Union', '148811', '2025-09-04', '2026-08-17',
 '12 מוצרים', 'EU, קניה', 'תעודה פגה.'),
('Greenalin Herbs Ltd', 'ישראל', '4063651136791', 'Control Union', '15284', '2025-12-04', '2026-07-27',
 'בזיליקום, קישואים, תמרים', 'EU, UK, ישראל, רוסיה', 'תעודה פגה.'),
('Mizrachi Farm Ltd', 'ישראל', '4049928951052', 'IQC', '131153', '2025-02-08', '2026-02-07',
 'פנסי (תחת Edible flower), קישואים', 'ארה"ב', 'תעודה פגה. NC FV 33.06.01 ללא ראיית סגירה.')
on conflict do nothing;

-- ---------- בדיקות ומסמכים ----------
insert into documents (grower_id, kind, title, lab, ref_no, product, sampled_on, reported_on, result, criterion, link, notes)
select g.id, d.kind, d.title, d.lab, d.ref_no, d.product, d.sampled_on, d.reported_on, d.result, d.criterion, d.link, d.notes
from (values
 ('Royal Herbs Exporters (SEZ)','residue','SGS MA26-00382.001 — מנטה','SGS Kenya','MA26-00382.001','מנטה','2026-01-12'::date,'2026-01-23'::date,'pass','EC 396/2005','https://drive.google.com/file/d/1sD0AyA_G5lqggpaUjgaN9kogTdLFv6y5/view','בלוק 2B'),
 ('Royal Herbs Exporters (SEZ)','residue','SGS MA26-01468.001 — טרגון','SGS Kenya','MA26-01468.001','טרגון','2026-03-10','2026-03-16','pass','EC 396/2005','https://drive.google.com/file/d/1onTFJ8JCHPXKDfR4GZYsClWK5_KEmYJY/view','GH1B'),
 ('Royal Herbs Exporters (SEZ)','residue','SGS MA26-02782.001 — עירית','SGS Kenya','MA26-02782.001','עירית','2026-04-27','2026-05-11','pass','EC 396/2005','https://drive.google.com/file/d/1pVW2lptvZzCaFr8_Vn3hw3ZQnnvqYgvA/view','בלוק GH 4A'),
 ('Royal Herbs Exporters (SEZ)','residue','SGS MA26-02939.001 — עירית','SGS Kenya','MA26-02939.001','עירית','2026-05-05','2026-05-11','pass','EC 396/2005','https://drive.google.com/file/d/1jwPRXybXWVhTC_Wh6RWc-FysefcSuTk0/view','בלוק GH 4B'),
 ('Royal Herbs Exporters (SEZ)','micro','Quality Plus S2026F0985 — מנטה','Quality Plus','S2026F0985','מנטה','2026-01-27','2026-01-28','pass','ISO 4833 / ISO 11290-1','https://drive.google.com/file/d/1GGVxynfFZ31sCj7bArXrc0lTaVmB74ZK/view','פאנל מלא'),
 ('Royal Herbs Exporters (SEZ)','micro','Quality Plus S2026F0984 — עירית','Quality Plus','S2026F0984','עירית','2026-01-27','2026-01-28','pass','ISO 4833 / ISO 11290-1','https://drive.google.com/file/d/13ASn5GXDBfqB4jdMWvdgJ7ze2TYEcy8v/view','פאנל מלא'),
 ('Royal Herbs Exporters (SEZ)','micro','Quality Plus S2026F2574 — טרגון','Quality Plus','S2026F2574','טרגון','2026-02-27','2026-03-06','pass','ISO 4833 / ISO 11290-1','https://drive.google.com/file/d/1LIYRhF9L8ochy7QNLzd9wAxEmhsj9kFm/view','TVC 1.8x10^5 מול מפרט מיליון'),
 ('Bendor Farm','residue','Quality Plus S2026F181 — מנטה','Quality Plus','S2026F181','מנטה','2026-03-26','2026-04-17','pass','MRL + רשימת אנליטים LOQ 0.01','https://drive.google.com/file/d/1NcSKa3xK1cfVBt7C_OseD_2iH7yOttvI/view','חלקה G2A. הדוח האיכותי ביותר בתיק.'),
 ('Bendor Farm','residue','Quality Plus S2026F182 — בזיליקום','Quality Plus','S2026F182','בזיליקום','2026-03-26','2026-04-19','pass','MRL + רשימת אנליטים LOQ 0.01','https://drive.google.com/file/d/1gAOmuCog2bHADbhl2crPo3_XLQ_eotRE/view','חלקה GH-3'),
 ('Greenblade Growers – Tumaini','residue','Quality Plus S2026F183 — עירית','Quality Plus','S2026F183','עירית','2026-04-02','2026-04-22','pass','MRL + רשימת אנליטים LOQ 0.01','https://drive.google.com/file/d/19kWADFMgB53MdMN1LeN6iuvZmiqBBzIc/view','קוד עקיבות T/GH/8/01/04/T/2 — לאשר שיוך GGN'),
 ('Yair Ben Menashe','micro','Aminolab 012496.26 — בזיליקום','Aminolab','012496.26','בזיליקום','2026-05-20','2026-05-24','pass','ISO 6579 / ISO 11290-1','https://drive.google.com/file/d/1Z41RLbjZW_EIE-OAz6iL_ToLy65X8OVb/view','E. coli, סלמונלה וליסטריה שליליים'),
 ('Yair Ben Menashe','micro','Aminolab 012497.26 — קורנית','Aminolab','012497.26','קורנית','2026-05-20','2026-05-24','pass','ISO 6579 / ISO 11290-1','https://drive.google.com/file/d/11X43H19CSNQKXHv-5c88pcdbymYt5AWl/view',null),
 ('Yair Ben Menashe','micro','Aminolab 012498.26 — רוזמרין','Aminolab','012498.26','רוזמרין','2026-05-20','2026-05-24','pass','ISO 6579 / ISO 11290-1','https://drive.google.com/file/d/1Nd1SHGENrSv5D3IDyu5dMcLL7XuTNL-4/view',null),
 ('Yair Ben Menashe','residue','Aminolab 012765.26 — רוזמרין','Aminolab','012765.26','רוזמרין','2026-05-20','2026-05-27','pass','MRL','https://drive.google.com/file/d/1E1GLs4FJL3vIs6Cx0AzhaG69FFQa0WGA/view','ND בשתי השיטות'),
 ('Yair Ben Menashe','residue','Aminolab 012770.26 — קורנית','Aminolab','012770.26','קורנית','2026-05-20','2026-05-27','pass','MRL','https://drive.google.com/file/d/1zpCuC0gIzGGuG-cEHgI6nN3m_DBLievp/view','שלוש שאריות הרבה מתחת ל-MRL'),
 ('Yair Ben Menashe','residue','Aminolab 012990.26 — בזיליקום','Aminolab','012990.26','בזיליקום','2026-05-20','2026-05-27','pass','MRL','https://drive.google.com/file/d/1KDJvxkbVJEet4egDUp1dZ6pmC9dqgu9a/view','ארבע שאריות מתחת ל-MRL'),
 ('Jannet Adan (Jamal Abu Alaya)','residue','Katif Center 59539 — טרגון','Katif Center','59539','טרגון','2026-04-16','2026-04-19','pass_qualified','MRL אירופי','https://drive.google.com/file/d/1nMB2hUWMPkn1-xzSMx32RmliJodqS1HJ/view','אין רשימת אנליטים; עמודת MRL ריקה'),
 ('Jannet Adan (Jamal Abu Alaya)','micro','An-Najah 2026051532 — תשע אגודות','An-Najah ACU','2026051532','תשעה תבלינים','2026-05-15','2026-05-17','pass_qualified','—','https://drive.google.com/file/d/1VrZrZ1yfClpkSWvF_mX1qc8qlGqkh8mB/view','תוצאת הסלמונלה לא התקבלה — שיטת קוליפורמים'),
 ('Jannet Adan (Jamal Abu Alaya)','water','An-Najah 1531520260 — באר 3','An-Najah ACU','1531520260','מי באר','2026-05-15','2026-05-17','pass_qualified','—','https://drive.google.com/file/d/1GIDICkg9URBS_nU2AEw5Yu_lPLCZTWzS/view','כלי דגימה לא סטרילי'),
 ('Jannet Adan (Jamal Abu Alaya)','water','An-Najah 2026021571 — מי באר','An-Najah ACU','2026021571','מי באר','2026-02-15','2026-02-18','pass_qualified','—','https://drive.google.com/file/d/1GAQ8SoOC-UCGcNWr2pRS83mnYLsCeCAR/view','אותה בעיית כלי דגימה'),
 ('Jannet Adan (Jamal Abu Alaya)','residue','Bactochem 693531–693539','Bactochem','693531-693539','תשעה תבלינים','2026-02-17','2026-02-17','pass_qualified','Sanco / FDA-PAM','https://drive.google.com/file/d/1nMB2hUWMPkn1-xzSMx32RmliJodqS1HJ/view','אין רשימת אנליטים ואין LOQ'),
 ('Jannet Adan (Jamal Abu Alaya)','audit','Control Union 817681-GAP-2025-55','Control Union','817681-GAP-2025-55','—','2025-11-22','2025-11-22','pass_qualified','GLOBALG.A.P. IFA v6','https://drive.google.com/file/d/17-W3Mw30zX7uIqxORxHlsRn8MIwNhIo2/view','NC ראשית FV 33.01.04 ללא ראיית סגירה')
) as d(gname, kind, title, lab, ref_no, product, sampled_on, reported_on, result, criterion, link, notes)
join growers g on g.name = d.gname
on conflict do nothing;

-- ---------- יומן FDA ----------
insert into reg_log (happened_on, kind, direction, title, title_en, party, ref_no, items, ack, ack_on, ack_by, notes) values
('2023-08-22','inspection','in','ביקורת FSVP קודמת','Prior FSVP inspection','FDA',null,null,false,null,null,'ליקוי כתוב על היעדר FSVP — הבסיס לסימון Observation 1 כחוזר'),
('2025-09-15','inspection','in','ביקורת FSVP 03–15/09/2025','FSVP inspection','FDA — Raymond Liu','FEI 3015407675',null,false,null,null,null),
('2025-09-15','form483','in','הונפק FDA Form 483a — שבעה ליקויים','FDA Form 483a issued','FDA — Raymond Liu',null,'שבעה ליקויים; 2–7 נוגעים לפנסי מ-Mizrachi',false,null,null,null),
('2025-12-31','closure','in','שחרור EIR וסגירת הביקורת','EIR released — closed','FDA — Spiridoula Dimopoulos','21 CFR 20.64(d)(3)',null,true,'2025-12-31','מייל מ-FDA','אין Warning Letter ואין Import Alert'),
('2026-01-04','record','int','טופסי Record Review נחתמו','Record Review forms signed','Carmel 1',null,null,false,null,null,'נחתמו ביד 04–06/01/2026'),
('2026-01-05','other','int','Agriver הועברה ל-Inactive','Agriver moved to Inactive','Carmel 1','FEI 3010140219',null,false,null,null,'הפסיקה ייצוא לארה"ב'),
('2026-01-06','response','out','התגובה הפורמלית ל-483 נשלחה','Written response to Form 483a','FDA — Raymond Liu',null,
 'מכתב נלווה / SOP-01 / SOP-02 / תיק Mizrachi / תיק Jamal Abu Alaya / יומן מעקב ספקים', true, null, null,
 'התקבל אישור קליטה — להשלים תאריך, ממי ואסמכתא. תאריך השליחה משוער.'),
('2026-09-10','record','int','רשומת סקירה — קטיף 59539 טרגון','Record review — Katif 59539','Carmel 1',null,null,false,null,null,'נחתמה אלקטרונית'),
('2026-09-10','record','int','רשומת סקירה מרוכזת — מבדק + An-Najah','Batch record review','Carmel 1',null,null,false,null,null,'סלמונלה לא התקבלה; מים בהסתייגות')
on conflict do nothing;
