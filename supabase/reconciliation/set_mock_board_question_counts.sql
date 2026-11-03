-- Mock Board blueprint: how many of each section's 100 questions come from
-- each topic (public.quizzes.configured_question_count).
--
-- Counts filled in from the client's "SUBJECT and SUBTOPIC LIST" (Board Exam
-- Subjects; Topics; Distribution and Number of Items). Not in the board:
-- Molecular Biology / Molecular Diagnostics.
--
-- HOW TO USE
--   1. Every count is an integer >= 0 (0 = the topic is not used).
--   2. Each section (topic counts + pool counts) must total EXACTLY 100.
--   3. Run the whole file in the SQL Editor. It changes nothing unless every
--      check passes; any failed check raises an error and rolls back.
--
-- Topic list generated read-only from the live project on 2026-10-11
-- (154 live topics). Section mapping follows mockBoardSectionSpecs in
-- lib/core/utils/questions_helpers.dart. Not mapped to any section, so not
-- listed: subject 34 'Molecular Biology'. Subject 36 'Medtech Laws and
-- Ethics' topics added once they were uploaded (eight live topics, 35 items).
--
-- Requires proposed patches 20261008000000 and 20261008100000.
-- Writes ONLY quizzes.configured_question_count of the listed topics (and of
-- the pooled subjects' topics, cleared) and subjects.mock_board_pool_count of
-- the pooled subjects.
begin;
set local lock_timeout = '5s';

create temp table mock_board_counts (
  section integer not null,
  quiz_id integer primary key,
  title text not null,
  question_count integer
) on commit drop;

insert into mock_board_counts (section, quiz_id, title, question_count) values
  -- Section 1: Clinical Chemistry - must total 100
  --   subject 24 'Clinical Chemistry' (14 topics)
  (1, 1207, 'Vitamins', 1),
  (1, 1208, 'Toxicology', 4),
  (1, 1209, 'Therapeutic Drug Monitoring', 2),
  (1, 1210, 'Endocrinology', 9),
  (1, 1211, 'Acid-Base Metabolism', 3),
  (1, 1212, 'Electrolytes and Osmolality', 6),
  (1, 1213, 'Liver Function and Porphyrin Formation', 6),
  (1, 1214, 'Enzymes and Cardiac Assessment', 8),
  (1, 1215, 'Lipids and Lipoproteins', 8),
  (1, 1216, 'Carbohydrates', 8),
  (1, 1217, 'Nonprotein Nitrogenous Compounds', 8),
  (1, 1218, 'Proteins and Tumor Markers', 6),
  (1, 1219, 'Instrumentation and Analytical Principles', 30),
  (1, 1383, 'Clinical Chemistry Picture-Based Questions', 1),
  -- Section 2: Microbiology and Parasitology - must total 100
  --   subject 25 'Bacteriology' (9 topics)
  (2, 1220, 'Procedures and Identification of Bacteria', 15),
  (2, 1221, 'Antimicrobial Agents and Antimicrobial Susceptibility Testing', 7),
  (2, 1222, 'Spirochetes', 3),
  (2, 1223, 'Chlamydia , Ricketssia, Mycoplasma , and Similar Organisms', 3),
  (2, 1224, 'Anaerobic Bacteria', 4),
  (2, 1225, 'Mycobacteria', 3),
  (2, 1226, 'Aerobic Gram-Negative Bacteria', 16),
  (2, 1227, 'Aerobic Gram-Positive Bacteria', 16),
  (2, 1384, 'Bacteriology Picture-Based Questions', 1),
  --   subject 26 'Parasitology' (8 topics)
  (2, 1228, 'Filariae', 2),
  (2, 1229, 'Nematodes', 5),
  (2, 1230, 'Cestodes', 3),
  (2, 1231, 'Trematodes', 3),
  (2, 1232, 'Extraintestinal Protozoa', 2),
  (2, 1233, 'Intestinal Protozoa', 5),
  (2, 1234, 'Introduction to Parasitology and General Information', 7),
  (2, 1385, 'Parasitology Picture-Based Questions', 1),
  --   subjects 27 'Mycology' and 28 'Virology': pooled, see mock_board_pools
  -- Section 3: Clinical Microscopy - must total 100
  --   subject 29 'Clinical Microscopy' (11 topics)
  (3, 1249, 'Automation', 5),
  (3, 1250, 'Body Fluids and Fecal Analysis', 22),
  (3, 1251, 'Special Urine Screening Tests', 3),
  (3, 1252, 'Microscopic Examination of Urine', 19),
  (3, 1253, 'Chemical Examination of Urine', 14),
  (3, 1254, 'Physical Examination of Urine', 12),
  (3, 1255, 'Urine Volume and Sample Handling', 10),
  (3, 1256, 'Renal Pathology and Renal Function Tests', 4),
  (3, 1257, 'The Kidney and Urine Formation', 4),
  (3, 1258, 'Introduction to Clinical Microscopy and General Information', 6),
  (3, 1382, 'Clinical Microscopy Picture-Based Questions', 1),
  -- Section 4: Hematology - must total 100
  --   subject 30 'Hematology' (26 topics)
  (4, 1259, 'Anticoagulant Therapies', 1),
  (4, 1260, 'Evaluation Tests for the Fibrinolytic System', 2),
  (4, 1261, 'Evaluation Tests for Secondary Hemostasis', 5),
  (4, 1262, 'Sample Collection, Handling, and Processing for Coagulation Testing', 2),
  (4, 1263, 'Hemorrhagic Disorders', 2),
  (4, 1264, 'Thrombotic Disorders', 2),
  (4, 1265, 'Regulatory Proteins of Coagulation and Fibrinolysis', 1),
  (4, 1266, 'The Fibrinolytic System', 1),
  (4, 1267, 'Introduction to Hemostasis', 2),
  (4, 1268, 'Diseases and Conditions Associated with Thrombocytes', 3),
  (4, 1269, 'Introduction to Thrombocytes', 5),
  (4, 1270, 'Diseases and Conditions Associated with the Vascular System', 1),
  (4, 1271, 'Introduction to Vascular System', 1),
  (4, 1272, 'Hematology Tests', 40),
  (4, 1273, 'Thalassemias', 1),
  (4, 1274, 'Hemoglobinopathies', 1),
  (4, 1275, 'Anemias', 1),
  (4, 1276, 'Hemoglobin', 2),
  (4, 1277, 'Erythrocytes', 3),
  (4, 1278, 'Malignant Leukocyte Disorders', 3),
  (4, 1279, 'Lymphocytes and Plasma Cells', 2),
  (4, 1280, 'Monocytes and Macrophages', 1),
  (4, 1281, 'Granulocytes', 2),
  (4, 1282, 'Hematopoiesis', 5),
  (4, 1283, 'Fundamental Hematology Principles', 10),
  (4, 1387, 'Hematology Picture-Based Questions', 1),
  -- Section 5: Blood Banking and Serology - must total 100
  --   subject 31 'Immunology and Serology' (24 topics)
  (5, 1284, 'Human Immunodeficiency Virus Serology', 2),
  (5, 1285, 'Viral Hepatitis Serology', 2),
  (5, 1286, 'Epstein-Barr Virus Serology', 1),
  (5, 1287, 'Rubella Serology', 1),
  (5, 1288, 'Borrelia burgdorferi Serology', 1),
  (5, 1289, 'Syphillis Serology', 1),
  (5, 1290, 'Streptococccal Serology', 1),
  (5, 1291, 'Cellular Assays', 3),
  (5, 1292, 'Complement Fixation', 1),
  (5, 1293, 'Agglutination Reactions', 2),
  (5, 1294, 'Precipitation Reactions', 1),
  (5, 1295, 'Antigen-Antibody Reactions', 1),
  (5, 1296, 'Tumor Immunology', 3),
  (5, 1297, 'Transplant Immunology', 2),
  (5, 1298, 'Hypergammaglobulinemia', 1),
  (5, 1299, 'Immune Deficiency', 1),
  (5, 1300, 'Hypersensitivity', 1),
  (5, 1301, 'Autoimmune Disease', 1),
  (5, 1302, 'Adaptive Immune Response', 10),
  (5, 1303, 'Nonspecific Immune Response', 5),
  (5, 1304, 'Major Histocompatibility Complex', 1),
  (5, 1305, 'The Immune System', 4),
  (5, 1306, 'Introduction to Immunology and Serology and General Information', 3),
  (5, 1380, 'Immunology and Serology Picture-Based Questions', 1),
  --   subject 32 'Immunohematology' (18 topics)
  (5, 1307, 'Safety and Quality Assurance', 3),
  (5, 1308, 'Transfusion-Transmitted Diseases', 2),
  (5, 1309, 'Transfusion Reactions', 1),
  (5, 1310, 'Transfusion Therapy', 4),
  (5, 1311, 'Blood Component Therapy', 5),
  (5, 1312, 'Blood Components: Preparation, Storage, and Shipment', 4),
  (5, 1313, 'Blood Collection', 5),
  (5, 1314, 'Hemolytic Diseases of the Newborn', 4),
  (5, 1315, 'Pretransfusion Testing', 2),
  (5, 1316, 'Identification of Unexpected Alloantibodies', 2),
  (5, 1317, 'Direct Antiglobulin Testing', 2),
  (5, 1318, 'Blood Bank Reagents and Methods', 1),
  (5, 1319, 'Other Blood Group Systems', 4),
  (5, 1320, 'Rh Blood Groups', 4),
  (5, 1321, 'ABO and H Blood Group Systems and Secretor Status', 2),
  (5, 1322, 'Genetics', 2),
  (5, 1323, 'Introduction to Immunohematology and General Information', 2),
  (5, 1381, 'Immunohematology Picture-Based Questions', 1),
  -- Section 6: Histopathology and Medical Technology Laws/Ethics - must total 100
  --   subject 33 'Histopath' (29 topics)
  (6, 1324, 'Cytologic Techniques', 13),
  (6, 1325, 'Staining of Microorganisms', 1),
  (6, 1326, 'Staining of Nervous Tissue', 1),
  (6, 1327, 'Staining of Muscle and Bone', 1),
  (6, 1328, 'Staining of Connective Tissue', 1),
  (6, 1329, 'Staining of Bone Marrow and Blood Elements', 1),
  (6, 1330, 'Pigments and Minerals', 1),
  (6, 1331, 'Immunohistochemistry', 1),
  (6, 1332, 'Enzyme Histochemistry', 1),
  (6, 1333, 'Staining of Proteins and Nucleic Acids', 1),
  (6, 1334, 'Staining of Lipids', 1),
  (6, 1335, 'Staining of Carbohydrates', 1),
  (6, 1336, 'Stains and Staining Solutions', 1),
  (6, 1337, 'Principles of Staining', 1),
  (6, 1338, 'Adhesives and Mounting Media', 1),
  (6, 1339, 'Electron Microscopy', 1),
  (6, 1340, 'Cutting Sections', 3),
  (6, 1341, 'Microtomy', 4),
  (6, 1342, 'Impregnation and Embedding', 4),
  (6, 1343, 'Clearing', 3),
  (6, 1344, 'Dehydration', 3),
  (6, 1345, 'Decalcification', 2),
  (6, 1346, 'Chemical Fixatives', 2),
  (6, 1347, 'Fixation', 2),
  (6, 1348, 'Rapid Tissue Processing', 2),
  (6, 1349, 'Conventional Tissue Processing', 5),
  (6, 1350, 'Examination of Fresh Tissue', 2),
  (6, 1351, 'Use and Care of the Microscope', 2),
  (6, 1352, 'Risk Management and Safety in the Laboratory', 3),
  --   subject 36 'Medtech Laws and Ethics' (8 topics)
  (6, 1437, 'Professional Regulation of Medical Technology', 6),
  (6, 1438, 'PRC and Professional Regulatory Board of Medical Technology', 4),
  (6, 1439, 'Clinical Laboratory Laws and Regulation', 5),
  (6, 1440, 'Ethics and Professional Conduct', 3),
  (6, 1441, 'Patient Rights, Confidentiality, and Data Privacy', 3),
  (6, 1442, 'Legal Responsibilities in the Laboratory', 2),
  (6, 1443, 'Bioethics in Laboratory Practice', 2),
  (6, 1444, 'Professional Relationships and workplace Law concepts', 10);

-- Pooled subjects (subjects.mock_board_pool_count, patch 20261008100000):
-- each board takes pool_count questions at random from ANY live topic of the
-- subject; the topics' own counts are cleared. Client blueprint: "Randomly
-- select 2 questions from any of these topics; make sure to include all
-- topics in the pool".
create temp table mock_board_pools (
  section integer not null,
  subject_id integer primary key,
  title text not null,
  pool_count integer not null
) on commit drop;

insert into mock_board_pools (section, subject_id, title, pool_count) values
  (2, 27, 'Mycology', 2),
  (2, 28, 'Virology', 2);

-- Checks. Soft-delete columns are read through to_jsonb so the file works
-- whether or not deleted_at exists on questions/choices.
do $$
declare
  r record;
  n integer;
begin
  select count(*) into n from mock_board_counts where question_count is null;
  if n > 0 then
    raise exception '% topics still have no count (replace every null)', n;
  end if;

  for r in select quiz_id, title from mock_board_counts where question_count < 0 loop
    raise exception 'quiz % (%) has a negative count', r.quiz_id, r.title;
  end loop;

  for r in select section, sum(cnt) as total
           from (select section, question_count as cnt from mock_board_counts
                 union all
                 select section, pool_count from mock_board_pools) u
           group by section
           having sum(cnt) <> 100 order by section loop
    -- Section 6 may stay short ONLY while Medtech Laws and Ethics (subject
    -- 36) has no live topics yet: the Histopath counts are still written and
    -- the Mock Board stays "not configured" until Laws is uploaded and this
    -- script is run again with its rows. Any other shortfall aborts.
    if r.section = 6 and r.total < 100
       and not exists (select 1 from public.quizzes q
                       where q.subject_id = 36
                         and to_jsonb(q) ->> 'deleted_at' is null) then
      raise notice 'Section 6 totals % (Medtech Laws and Ethics not uploaded yet); applying the rest', r.total;
    else
      raise exception 'Section % totals %, it must be exactly 100', r.section, r.total;
    end if;
  end loop;

  -- The list must still match the live topics of the mapped subjects: the app
  -- refuses a section where any live topic has no count.
  for r in select q.id, q.title from public.quizzes q
           where q.subject_id in (24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 36)
             and to_jsonb(q) ->> 'deleted_at' is null
             and q.id not in (select quiz_id from mock_board_counts)
             and q.subject_id not in (select subject_id from mock_board_pools) loop
    raise exception 'live topic % (%) is missing from this list; regenerate the template', r.id, r.title;
  end loop;
  for r in select p.subject_id, p.title from mock_board_pools p
           where p.pool_count < 0
              or not exists (select 1 from public.quizzes q
                             where q.subject_id = p.subject_id
                               and to_jsonb(q) ->> 'deleted_at' is null) loop
    raise exception 'pooled subject % (%) has a negative count or no live topics',
      r.subject_id, r.title;
  end loop;
  for r in select m.quiz_id, m.title from mock_board_counts m
           left join public.quizzes q on q.id = m.quiz_id
           where q.id is null or to_jsonb(q) ->> 'deleted_at' is not null loop
    raise exception 'quiz % (%) no longer exists or was deleted', r.quiz_id, r.title;
  end loop;

  -- Each topic needs at least its count of usable questions: not deleted and
  -- with exactly one (live) correct choice, the same rule the app applies.
  for r in
    select m.quiz_id, m.title, m.question_count,
      (select count(*) from public.questions qu
        where qu.quiz_id = m.quiz_id
          and to_jsonb(qu) ->> 'deleted_at' is null
          and (select count(*) from public.choices c
                where c.question_id = qu.id and c.is_correct
                  and to_jsonb(c) ->> 'deleted_at' is null) = 1) as usable
    from mock_board_counts m where m.question_count > 0
  loop
    if r.usable < r.question_count then
      raise exception 'quiz % (%) needs % questions but only % are usable',
        r.quiz_id, r.title, r.question_count, r.usable;
    end if;
  end loop;
  for r in
    select p.subject_id, p.title, p.pool_count,
      (select count(*) from public.questions qu
        join public.quizzes z on z.id = qu.quiz_id
        where z.subject_id = p.subject_id
          and to_jsonb(z) ->> 'deleted_at' is null
          and to_jsonb(qu) ->> 'deleted_at' is null
          and (select count(*) from public.choices c
                where c.question_id = qu.id and c.is_correct
                  and to_jsonb(c) ->> 'deleted_at' is null) = 1) as usable
    from mock_board_pools p
  loop
    if r.usable < r.pool_count then
      raise exception 'pooled subject % (%) needs % questions but only % are usable',
        r.subject_id, r.title, r.pool_count, r.usable;
    end if;
  end loop;
end $$;

update public.quizzes q
set configured_question_count = m.question_count
from mock_board_counts m
where q.id = m.quiz_id;

update public.subjects s
set mock_board_pool_count = p.pool_count
from mock_board_pools p
where s.id = p.subject_id;

update public.quizzes q
set configured_question_count = null
from mock_board_pools p
where q.subject_id = p.subject_id;

commit;

-- Read-only check afterwards (every section should show 100):
--   select s.id, s.title, count(q.id) as topics,
--          count(q.id) filter (where q.configured_question_count is null) as missing,
--          coalesce(sum(q.configured_question_count), 0) as total
--   from public.subjects s join public.quizzes q on q.subject_id = s.id
--   group by s.id, s.title order by s.id;
