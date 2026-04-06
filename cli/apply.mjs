#!/usr/bin/env node
/**
 * RalvClaw 汉化应用脚本
 * 将翻译配置应用到 OpenClaw 源码
 */

import { loadAllTranslations, applyTranslation, printStats } from './utils/i18n-engine.mjs';
import path from 'node:path';
import fs from 'node:fs/promises';

async function main() {
  const args = process.argv.slice(2);
  const dryRun = args.includes('--dry-run');
  const verbose = args.includes('--verbose') || args.includes('-v');

  // 获取目标目录
  const targetArg = args.find(a => a.startsWith('--target='));
  let targetDir = targetArg ? path.resolve(targetArg.split('=')[1]) : '/build/openclaw';

  console.log(`\n🦞 RalvClaw 汉化工具\n`);

  if (dryRun) {
    console.log('模式: 预览 (--dry-run)');
  } else {
    console.log('模式: 应用');
  }

  // 检查目标目录
  try {
    await fs.access(targetDir);
  } catch {
    console.error(`目标目录不存在: ${targetDir}`);
    process.exit(1);
  }

  console.log(`目标目录: ${targetDir}`);

  // 加载所有翻译配置
  const translations = await loadAllTranslations();
  console.log(`已加载 ${translations.length} 个翻译配置`);

  // 应用翻译
  const allStats = [];
  for (const translation of translations) {
    const stats = await applyTranslation(translation, targetDir, { dryRun, verbose });
    allStats.push(stats);
  }

  // 打印统计
  printStats(allStats);

  console.log('\n✅ 汉化完成！');
}

main().catch(err => {
  console.error('错误:', err.message);
  process.exit(1);
});
