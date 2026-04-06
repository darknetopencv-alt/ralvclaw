/**
 * RalvClaw 翻译引擎
 * 加载翻译配置并应用到目标文件
 */

import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT_DIR = path.resolve(__dirname, '../..');
const TRANSLATIONS_DIR = path.join(ROOT_DIR, 'translations');

/**
 * 加载所有翻译配置
 */
export async function loadAllTranslations() {
  const translations = [];
  const modules = ['cli', 'dashboard', 'commands', 'wizard', 'gateway'];

  for (const module of modules) {
    const moduleDir = path.join(TRANSLATIONS_DIR, module);
    try {
      const files = await fs.readdir(moduleDir);
      for (const file of files) {
        if (file.endsWith('.json')) {
          const filePath = path.join(moduleDir, file);
          const content = await fs.readFile(filePath, 'utf-8');
          const config = JSON.parse(content);
          translations.push({
            ...config,
            module,
            configFile: file
          });
        }
      }
    } catch (err) {
      // 目录可能不存在，跳过
    }
  }

  return translations;
}

/**
 * 应用翻译到目标文件
 */
export async function applyTranslation(translation, targetDir, options = {}) {
  const { dryRun = false, verbose = false } = options;

  const targetPath = path.join(targetDir, translation.file);
  const stats = {
    file: translation.file,
    description: translation.description,
    total: Object.keys(translation.replacements).length,
    applied: 0,
    skipped: 0,
    notFound: 0
  };

  let content;
  try {
    content = await fs.readFile(targetPath, 'utf-8');
  } catch {
    console.error(`文件不存在: ${translation.file}`);
    stats.notFound = stats.total;
    return stats;
  }

  let modified = content;

  for (const [original, translated] of Object.entries(translation.replacements)) {
    // 跳过注释键
    if (original.startsWith('__')) continue;

    if (modified.includes(translated)) {
      stats.skipped++;
      if (verbose) console.log(`  已存在: ${original.slice(0, 50)}...`);
    } else if (modified.includes(original)) {
      modified = modified.replaceAll(original, translated);
      stats.applied++;
      if (verbose) {
        console.log(`  替换: ${original.slice(0, 40)}... → ${translated.slice(0, 40)}...`);
      }
    } else {
      stats.notFound++;
      if (verbose) {
        console.log(`  未找到: ${original.slice(0, 60)}...`);
      }
    }
  }

  // 写入文件
  if (!dryRun && stats.applied > 0) {
    await fs.writeFile(targetPath, modified, 'utf-8');
  }

  return stats;
}

/**
 * 打印统计报告
 */
export function printStats(allStats) {
  console.log('\n' + '═'.repeat(60));
  console.log('📊 汉化统计报告');
  console.log('═'.repeat(60));

  let totalApplied = 0;
  let totalSkipped = 0;
  let totalNotFound = 0;

  for (const stats of allStats) {
    const icon = stats.notFound > 0 ? '⚠️' : stats.applied > 0 ? '✅' : '➖';
    console.log(`\n${icon} ${stats.file}`);
    console.log(`   ${stats.description}`);
    console.log(`   应用: ${stats.applied} | 已存在: ${stats.skipped} | 未找到: ${stats.notFound}`);

    totalApplied += stats.applied;
    totalSkipped += stats.skipped;
    totalNotFound += stats.notFound;
  }

  console.log('\n' + '─'.repeat(60));
  console.log(`总计: 应用 ${totalApplied} | 已存在 ${totalSkipped} | 未找到 ${totalNotFound}`);
  console.log('═'.repeat(60));
}
