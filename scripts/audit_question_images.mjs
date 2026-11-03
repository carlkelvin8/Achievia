// Read-only audit of every non-deleted picture-based deck and attachment.
// Uses the app's existing public key; never writes to Supabase.
import { readFile, mkdir, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';

const root = new URL('../', import.meta.url);
const constants = await readFile(new URL('lib/const.dart', root), 'utf8');
const base = constants.match(/supabaseUrl\s*=\s*'([^']+)'/)[1];
const key = constants.match(/supabaseAnon\s*=\s*'([^']+)'/)[1];
async function rows(table, filters = {}) {
  const result = [];
  for (let offset = 0; ; offset += 1000) {
    const url = new URL(`${base}/rest/v1/${table}`);
    url.search = new URLSearchParams({ select: '*', order: 'id', limit: '1000', offset: String(offset), ...filters });
    const response = await fetch(url, { headers: { apikey: key, Authorization: `Bearer ${key}` }, signal: AbortSignal.timeout(30000) });
    if (!response.ok) throw new Error(`${table}: HTTP ${response.status}`);
    const page = await response.json();
    result.push(...page);
    if (page.length < 1000) return result;
  }
}
const decks = await rows('quizzes', { deleted_at: 'is.null', title: 'ilike.*Picture*' });
const subjects = await rows('subjects');
const questions = decks.length ? await rows('questions', { deleted_at: 'is.null', quiz_id: `in.(${decks.map(d => d.id).join(',')})` }) : [];
const urls = [...new Set(questions.map(q => q.image_path?.trim()).filter(p => p && p.toLowerCase() !== 'null'))];
const checks = new Map();
let cursor = 0;
await Promise.all(Array.from({ length: 8 }, async () => {
  while (cursor < urls.length) {
    const path = urls[cursor++];
    const url = /^https?:\/\//i.test(path) ? path : new URL(path.replace(/^\/+/, ''), `${base}/storage/v1/object/public/admin/`).href;
    try {
      let response = await fetch(url, { method: 'HEAD', signal: AbortSignal.timeout(20000) });
      if ([405, 501].includes(response.status)) {
        response = await fetch(url, { headers: { Range: 'bytes=0-0' }, signal: AbortSignal.timeout(20000) });
        await response.body?.cancel();
      }
      const type = response.headers.get('content-type') || '';
      checks.set(path, { url, status: response.status, contentType: type, accessibleImage: response.ok && type.startsWith('image/') });
    } catch (error) {
      checks.set(path, { url, accessibleImage: false, error: error.message });
    }
  }
}));
const report = {
  checkedAt: new Date().toISOString(),
  scope: 'All non-deleted picture-based decks, including draft decks. HTTP availability and stored question-to-image associations; semantic image correctness requires content review.',
  decks: decks.map(d => {
    const items = questions.filter(q => q.quiz_id === d.id).map(q => {
      const path = q.image_path?.trim() || '';
      return { questionId: q.id, imagePath: path, questionText: q.question_text, ...(checks.get(path) || { accessibleImage: false, error: 'No image_path' }) };
    });
    return { deckId: d.id, title: d.title, subject: subjects.find(s => s.id === d.subject_id)?.title, status: d.status, questionCount: items.length, accessibleImages: items.filter(q => q.accessibleImage).length, questions: items };
  }),
};
await mkdir(new URL('docs/audits/', root), { recursive: true });
const output = new URL('docs/audits/question_images.json', root);
await writeFile(output, JSON.stringify(report, null, 2) + '\n');
console.log(JSON.stringify({ decks: report.decks.map(({ questions, ...summary }) => summary), totalQuestions: questions.length, uniqueImages: urls.length, failedImages: [...checks.values()].filter(c => !c.accessibleImage).length, report: fileURLToPath(output) }, null, 2));
